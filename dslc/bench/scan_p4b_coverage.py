#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Optional

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from dslc.backends.boogie.node.p4b import _maybe_tofino_cpp_defines
from dslc.bench.p4b_semantic_audit import CHECK_FAIL as SEMANTIC_FAIL
from dslc.bench.p4b_semantic_audit import CHECK_SKIP as SEMANTIC_SKIP
from dslc.bench.p4b_semantic_audit import audit_paths
from dslc.cli.common import find_default_p4b_bin
from dslc.utils.repo import repo_root


DEFAULT_SCAN_ROOTS = (Path("Procurator/argo/code/dataset"),)
TOPLEVEL_PATTERNS = (
    re.compile(r"\bV1Switch\s*\("),
    re.compile(r"\bPSA_Switch\s*\("),
    re.compile(r"\bPNA_NIC\s*\("),
    re.compile(r"\bSwitch\s*\([^;]*\)\s+main\s*;", re.DOTALL),
    re.compile(r"\bpackage\s*\("),
    re.compile(r"\bmain\s*;"),
)
SKIP_DIR_NAMES = {"build", "build-host", "__pycache__", ".git", ".tmp"}
ARCH_TARGETS = ("v1model", "tna", "psa", "pna", "ebpf", "ubpf", "xdp")


@dataclass(frozen=True)
class P4Candidate:
    path: Path
    rel: str
    target: str
    top_level_score: int
    top_level: bool


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _target_kind(text: str) -> Optional[str]:
    has_v1model = (
        "<v1model.p4>" in text
        or '"v1model.p4"' in text
        or "V1Switch" in text
        or "standard_metadata_t" in text
    )
    has_psa = "<psa.p4>" in text or '"psa.p4"' in text or "PSA_Switch" in text
    has_pna = "<pna.p4>" in text or '"pna.p4"' in text or "PNA_NIC" in text
    has_tna = (
        "<tna.p4>" in text
        or '"tna.p4"' in text
        or "<t2na.p4>" in text
        or '"t2na.p4"' in text
    )

    if has_v1model:
        return "v1model"
    if has_psa:
        return "psa"
    if has_pna:
        return "pna"
    if "<tna.p4>" in text or '"tna.p4"' in text or "<t2na.p4>" in text or '"t2na.p4"' in text:
        return "tna"
    if has_tna or "RegisterAction<" in text or "ingress_intrinsic_metadata_t" in text:
        return "tna-like"
    if "<ebpf_model.p4>" in text or '"ebpf_model.p4"' in text:
        return "ebpf"
    if "<ubpf_model.p4>" in text or '"ubpf_model.p4"' in text:
        return "ubpf"
    if "<xdp_model.p4>" in text or '"xdp_model.p4"' in text:
        return "xdp"
    return None


def _top_level_score(text: str) -> int:
    score = 0
    for pat in TOPLEVEL_PATTERNS:
        if pat.search(text):
            score += 1
    if re.search(r"\bcontrol\s+\w+", text):
        score += 1
    if re.search(r"\bparser\s+\w+", text):
        score += 1
    return score


def _is_top_level_program(text: str) -> bool:
    return any(pat.search(text) for pat in TOPLEVEL_PATTERNS)


def _should_skip(path: Path, *, scan_root: Path, include_sanitized: bool) -> bool:
    try:
        parts = path.relative_to(scan_root).parts
    except ValueError:
        parts = path.parts
    if any(part in SKIP_DIR_NAMES for part in parts):
        return True
    if not include_sanitized and path.name.startswith(".p4b_sanitized_"):
        return True
    return False


def _resolve_scan_roots(root: Path, scan_roots: Iterable[str]) -> list[Path]:
    paths: list[Path] = []
    for item in scan_roots:
        path = Path(item)
        if not path.is_absolute():
            path = root / path
        paths.append(path.resolve())
    return paths


def _rel_to_root(root: Path, path: Path) -> str:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return str(path)


def discover_candidates(root: Path, scan_roots: Iterable[Path], *, include_sanitized: bool, include_modules: bool) -> list[P4Candidate]:
    out: list[P4Candidate] = []
    seen: set[Path] = set()
    for scan_root in scan_roots:
        if not scan_root.exists():
            continue
        for p4 in sorted(scan_root.rglob("*.p4")):
            try:
                resolved = p4.resolve()
            except OSError:
                continue
            if resolved in seen:
                continue
            seen.add(resolved)
            if _should_skip(p4, scan_root=scan_root, include_sanitized=include_sanitized):
                continue
            try:
                text = _read(p4)
            except OSError:
                continue
            target = _target_kind(text)
            if target is None:
                continue
            top_level = _is_top_level_program(text)
            if not include_modules and not top_level:
                continue
            score = _top_level_score(text)
            if score == 0 and not include_modules:
                continue
            out.append(P4Candidate(path=p4, rel=_rel_to_root(root, p4), target=target, top_level_score=score, top_level=top_level))
    return out


def _include_paths(root: Path, p4: Path) -> list[Path]:
    paths: list[Path] = []
    # When scanning an external checkout such as upstream p4c, prefer its
    # architecture models if it has a nearby p4include directory.  This avoids
    # misclassifying new architectures (for example PNA) as include failures
    # just because the repo-local P4B include set is older.
    for parent in [p4.parent, *p4.parents]:
        arch_include = parent / "p4include"
        if arch_include.is_dir():
            paths.append(arch_include)
            break
        if parent == root:
            break

    p4include = root / "P4B-Translator" / "p4include"
    if p4include.is_dir():
        paths.append(p4include)

    for parent in [p4.parent, *p4.parents]:
        paths.append(parent)
        if parent == root:
            break

    # Many external programs keep includes in nearby "include"/"headers"/"p4src" dirs.
    interesting = {"include", "includes", "headers", "p4src", "p4", "common"}
    for parent in [p4.parent, *p4.parents]:
        try:
            children = list(parent.iterdir())
        except OSError:
            children = []
        for child in children:
            if child.is_dir() and child.name.lower() in interesting:
                paths.append(child)
        if parent == root:
            break

    seen: set[Path] = set()
    dedup: list[Path] = []
    for path in paths:
        try:
            resolved = path.resolve()
        except OSError:
            continue
        if resolved in seen or not resolved.is_dir():
            continue
        seen.add(resolved)
        dedup.append(resolved)
    return dedup


def _classify_failure(output: str, returncode: int) -> str:
    msg = output.lower()
    if returncode == 124 or "timed out" in msg or "timeout" in msg:
        return "timeout"
    if "no such file or directory" in msg or "could not find include" in msg or "include" in msg and "not found" in msg:
        return "include"
    if "syntax error" in msg or "parse error" in msg or "parser error" in msg:
        return "frontend_parse"
    if (
        "no argument supplied for parameter" in msg
        or "cannot unify type" in msg
        or "does not match invocation type" in msg
        or "invalid declaration" in msg and "instantiations cannot be in a control" in msg
    ):
        return "source_type"
    if "compiler bug" in msg and "frontends/" in msg:
        return "frontend_internal"
    if "type error" in msg or "type-error" in msg or "typechecking" in msg or "type checking" in msg or "cannot unify" in msg:
        return "frontend_type"
    if "function type" in msg and "does not match invocation type" in msg:
        return "frontend_type"
    if "not implemented" in msg or "unsupported" in msg or "unhandled" in msg:
        return "unsupported_p4b"
    if "bug" in msg or "check failed" in msg or "assertion" in msg or "null" in msg:
        return "backend_internal"
    if "error:" in msg:
        return "frontend_or_backend_error"
    return "unknown_failure"


def _tail(output: str, n: int = 40) -> str:
    return "\n".join(output.splitlines()[-n:])


def _run_one(
    *,
    root: Path,
    p4b_bin: Path,
    cand: P4Candidate,
    out_dir: Path,
    timeout_s: int,
    with_slicing: bool,
    include_cache: dict[Path, list[Path]],
) -> dict[str, Any]:
    stem = re.sub(r"[^A-Za-z0-9_.-]+", "_", cand.rel.replace(os.sep, "__").replace("/", "__"))
    out_bpl = out_dir / f"{stem}.bpl"
    out_meta = out_dir / f"{stem}.meta.json"

    cmd: list[str] = [str(p4b_bin)]
    try:
        cmd.extend(_maybe_tofino_cpp_defines(str(cand.path)))
    except Exception as exc:
        return {
            "path": cand.rel,
            "target": cand.target,
            "status": "FAIL",
            "category": "tofino_define",
            "returncode": None,
            "wall_s": 0.0,
            "error_tail": str(exc),
        }
    include_key = cand.path.parent.resolve()
    include_paths = include_cache.get(include_key)
    if include_paths is None:
        include_paths = _include_paths(root, cand.path)
        include_cache[include_key] = include_paths
    for inc in include_paths:
        cmd.extend(["-I", str(inc)])
    cmd.extend(["--std", "p4-16", "--goto"])
    if not with_slicing:
        cmd.append("--no-slicing")
    cmd.extend([str(cand.path), "-o", str(out_bpl), "--meta-out", str(out_meta)])

    t0 = time.perf_counter()
    try:
        cp = subprocess.run(
            cmd,
            cwd=root,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout_s,
        )
        wall = time.perf_counter() - t0
        output = cp.stdout or ""
        ok = cp.returncode == 0 and out_bpl.exists()
        return {
            "path": cand.rel,
            "target": cand.target,
            "status": "OK" if ok else "FAIL",
            "category": "ok" if ok else _classify_failure(output, cp.returncode),
            "returncode": cp.returncode,
            "wall_s": round(wall, 3),
            "top_level_score": cand.top_level_score,
            "top_level": cand.top_level,
            "out_bpl": str(out_bpl.relative_to(root)) if out_bpl.exists() else None,
            "out_meta": str(out_meta.relative_to(root)) if out_meta.exists() else None,
            "error_tail": "" if ok else _tail(output),
        }
    except subprocess.TimeoutExpired as exc:
        wall = time.perf_counter() - t0
        output = exc.stdout or ""
        if isinstance(output, bytes):
            output = output.decode("utf-8", errors="replace")
        return {
            "path": cand.rel,
            "target": cand.target,
            "status": "FAIL",
            "category": "timeout",
            "returncode": 124,
            "wall_s": round(wall, 3),
            "top_level_score": cand.top_level_score,
            "top_level": cand.top_level,
            "out_bpl": None,
            "out_meta": None,
            "error_tail": _tail(output),
        }


def _counts(records: Iterable[dict[str, Any]], key: str) -> dict[str, int]:
    counts: dict[str, int] = {}
    for rec in records:
        val = str(rec.get(key, "-"))
        counts[val] = counts.get(val, 0) + 1
    return dict(sorted(counts.items()))


def _semantic_counts(rows: Iterable[dict[str, Any]]) -> dict[str, int]:
    return _counts((r for r in rows if "semantic_status" in r), "semantic_status")


def _markdown(report: dict[str, Any]) -> str:
    rows = report["records"]
    ok_statuses = {"OK", "DISCOVERED"}
    semantic_counts = _semantic_counts(rows)
    lines: list[str] = []
    lines.append("# P4B Architecture Coverage Scan")
    lines.append("")
    lines.append(f"Generated at: `{report['generated_at']}`")
    lines.append(f"P4B: `{report['p4b_bin']}`")
    lines.append(f"Scan roots: `{', '.join(report.get('scan_roots', []))}`")
    lines.append(f"Mode: `{'with-slicing' if report.get('with_slicing') else 'base-no-slicing'}`")
    lines.append(f"Timeout per program: `{report['timeout_s']}s`")
    if report.get("offset") or report.get("limit") or report.get("max_wall_seconds"):
        lines.append(f"Batch: `offset={report.get('offset', 0)}, limit={report.get('limit', 0)}, max_wall_seconds={report.get('max_wall_seconds', 0)}`")
        lines.append(
            "Batch counts: "
            f"`before_batch={report.get('candidate_count_before_batch', len(rows))}, "
            f"in_batch={report.get('candidate_count_in_batch', len(rows))}, "
            f"recorded={len(rows)}, next_offset={report.get('next_offset', len(rows))}`"
        )
    if report.get("stopped_reason"):
        lines.append(f"Stopped early: `{report['stopped_reason']}`")
    lines.append("")
    lines.append("## Summary")
    lines.append("")
    lines.append("| group | count |")
    lines.append("|---|---:|")
    lines.append(f"| total | {len(rows)} |")
    lines.append(f"| ok | {sum(1 for r in rows if r['status'] in ok_statuses)} |")
    lines.append(f"| fail | {sum(1 for r in rows if r['status'] not in ok_statuses)} |")
    lines.append("")
    lines.append("### By Target")
    lines.append("")
    lines.append("| target | count |")
    lines.append("|---|---:|")
    for k, v in _counts(rows, "target").items():
        lines.append(f"| `{k}` | {v} |")
    lines.append("")
    lines.append("### By Category")
    lines.append("")
    lines.append("| category | count |")
    lines.append("|---|---:|")
    for k, v in _counts(rows, "category").items():
        lines.append(f"| `{k}` | {v} |")
    if semantic_counts:
        lines.append("")
        lines.append("### By Semantic Status")
        lines.append("")
        lines.append("| semantic | count |")
        lines.append("|---|---:|")
        for k, v in semantic_counts.items():
            lines.append(f"| `{k}` | {v} |")
        lines.append("")
        lines.append("### Semantic Weaknesses / Failures")
        lines.append("")
        lines.append("| path | semantic | details |")
        lines.append("|---|---|---|")
        for r in rows:
            semantic = r.get("semantic_status")
            if semantic not in {"FAIL", "WEAK"}:
                continue
            details = "<br>".join(str(x) for x in (r.get("semantic_failures") or []))
            if len(details) > 900:
                details = details[:900] + "..."
            lines.append(f"| `{r['path']}` | `{semantic}` | {details} |")
    lines.append("")
    lines.append("## Failures")
    lines.append("")
    lines.append("| path | target | category | wall(s) | tail |")
    lines.append("|---|---|---|---:|---|")
    for r in rows:
        if r["status"] in ok_statuses:
            continue
        tail = (r.get("error_tail") or "").replace("\r", "").replace("\n", "<br>")
        if len(tail) > 600:
            tail = tail[-600:]
        lines.append(f"| `{r['path']}` | `{r['target']}` | `{r['category']}` | {r['wall_s']} | {tail} |")
    lines.append("")
    lines.append("## All Programs")
    lines.append("")
    if semantic_counts:
        lines.append("| path | target | status | category | semantic | wall(s) |")
        lines.append("|---|---|---|---|---|---:|")
    else:
        lines.append("| path | target | status | category | wall(s) |")
        lines.append("|---|---|---|---|---:|")
    for r in rows:
        if semantic_counts:
            semantic = r.get("semantic_status", "-")
            lines.append(f"| `{r['path']}` | `{r['target']}` | `{r['status']}` | `{r['category']}` | `{semantic}` | {r['wall_s']} |")
        else:
            lines.append(f"| `{r['path']}` | `{r['target']}` | `{r['status']}` | `{r['category']}` | {r['wall_s']} |")
    lines.append("")
    return "\n".join(lines)


def main(argv: Optional[list[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Scan P4B translation coverage for top-level P4 architecture programs.")
    ap.add_argument("--scan-root", action="append", default=[], help="Root to scan for *.p4 files. Can be repeated. Defaults to Procurator/argo/code/dataset.")
    ap.add_argument("--out-dir", default=".tmp/procurator/p4b_coverage/latest", help="Directory for generated BPL/meta/report files.")
    ap.add_argument("--out-json", default="", help="Output JSON report path. Defaults to <out-dir>/coverage.json.")
    ap.add_argument("--out-md", default="", help="Output Markdown report path. Defaults to <out-dir>/coverage.md.")
    ap.add_argument("--p4b-bin", default="", help="Path to p4c-translator. Defaults to repo-local P4B build.")
    ap.add_argument("--timeout-seconds", type=int, default=45, help="Per-program translation timeout.")
    ap.add_argument("--target", choices=["all", *ARCH_TARGETS], default="all", help="Target family filter.")
    ap.add_argument("--offset", type=int, default=0, help="Skip this many candidates after filtering. Useful for batched scans.")
    ap.add_argument("--limit", type=int, default=0, help="Limit number of candidates after filtering.")
    ap.add_argument("--max-wall-seconds", type=float, default=0.0, help="Stop launching new translations after this wall-clock budget and still write a partial report.")
    ap.add_argument("--path-contains", action="append", default=[], help="Only include candidates whose path contains this substring.")
    ap.add_argument("--include-sanitized", action="store_true", help="Include .p4b_sanitized_* temporary files.")
    ap.add_argument("--include-modules", action="store_true", help="Also include parser/control/include modules that are not top-level architecture programs.")
    ap.add_argument("--with-slicing", action="store_true", help="Exercise default P4B slicing too. Default is base translation coverage with --no-slicing.")
    ap.add_argument("--semantic-audit", action="store_true", help="Audit source features against generated BPL/meta evidence.")
    ap.add_argument("--list-only", action="store_true", help="Only discover candidates and write reports without invoking P4B.")
    ns = ap.parse_args(argv)

    root = repo_root()
    p4b_bin = Path(ns.p4b_bin).resolve() if ns.p4b_bin else find_default_p4b_bin()
    if p4b_bin is None:
        raise SystemExit("p4c-translator not found; build P4B-Translator or pass --p4b-bin")

    scan_roots = _resolve_scan_roots(root, ns.scan_root or [str(p) for p in DEFAULT_SCAN_ROOTS])
    candidates = discover_candidates(root, scan_roots, include_sanitized=ns.include_sanitized, include_modules=ns.include_modules)
    if ns.target != "all":
        candidates = [c for c in candidates if c.target.startswith(ns.target)]
    for needle in ns.path_contains:
        candidates = [c for c in candidates if needle in c.rel]
    candidate_count_before_batch = len(candidates)
    if ns.offset > 0:
        candidates = candidates[ns.offset :]
    if ns.limit > 0:
        candidates = candidates[: ns.limit]
    candidate_count_in_batch = len(candidates)

    out_dir = (root / ns.out_dir).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    records: list[dict[str, Any]] = []
    include_cache: dict[Path, list[Path]] = {}
    scan_t0 = time.perf_counter()
    stopped_reason = ""
    for cand in candidates:
        if ns.max_wall_seconds > 0 and time.perf_counter() - scan_t0 >= ns.max_wall_seconds:
            stopped_reason = f"max-wall-seconds {ns.max_wall_seconds:g}s reached"
            print(f"stopping early: {stopped_reason}", flush=True)
            break
        if ns.list_only:
            records.append({
                "path": cand.rel,
                "target": cand.target,
                "status": "DISCOVERED",
                "category": "not_run",
                "returncode": None,
                "wall_s": 0.0,
                "top_level_score": cand.top_level_score,
                "top_level": cand.top_level,
                "error_tail": "",
            })
            continue
        rec = _run_one(
            root=root,
            p4b_bin=p4b_bin,
            cand=cand,
            out_dir=out_dir,
            timeout_s=ns.timeout_seconds,
            with_slicing=ns.with_slicing,
            include_cache=include_cache,
        )
        if ns.semantic_audit and rec.get("status") == "OK" and rec.get("out_bpl"):
            try:
                rec.update(
                    audit_paths(
                        cand.path,
                        root / rec["out_bpl"],
                        root / rec["out_meta"] if rec.get("out_meta") else None,
                        slicing_mode=ns.with_slicing,
                    )
                )
            except Exception as exc:
                rec.update(
                    {
                        "semantic_status": SEMANTIC_FAIL,
                        "semantic_features": [],
                        "semantic_checks": [],
                        "semantic_failures": [f"semantic audit crashed: {exc}"],
                    }
                )
        elif ns.semantic_audit:
            rec.update(
                {
                    "semantic_status": SEMANTIC_SKIP,
                    "semantic_features": [],
                    "semantic_checks": [],
                    "semantic_failures": [],
                }
            )
        records.append(rec)
        semantic = f" semantic={rec['semantic_status']}" if "semantic_status" in rec else ""
        print(f"{rec['status']:4} {rec['category']:24} {rec['wall_s']:8.3f}s{semantic} {rec['path']}", flush=True)

    report = {
        "generated_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
        "repo_root": str(root),
        "p4b_bin": str(p4b_bin),
        "scan_roots": [_rel_to_root(root, p) for p in scan_roots],
        "timeout_s": ns.timeout_seconds,
        "offset": ns.offset,
        "limit": ns.limit,
        "max_wall_seconds": ns.max_wall_seconds,
        "stopped_reason": stopped_reason,
        "candidate_count_before_batch": candidate_count_before_batch,
        "candidate_count_in_batch": candidate_count_in_batch,
        "next_offset": ns.offset + len(records),
        "with_slicing": ns.with_slicing,
        "semantic_audit": ns.semantic_audit,
        "records": records,
    }
    out_json = (root / ns.out_json).resolve() if ns.out_json else out_dir / "coverage.json"
    out_md = (root / ns.out_md).resolve() if ns.out_md else out_dir / "coverage.md"
    out_json.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(_markdown(report), encoding="utf-8")
    print(f"wrote {out_json}")
    print(f"wrote {out_md}")
    if not records:
        return 2
    compile_ok = all(r["status"] in {"OK", "DISCOVERED"} for r in records)
    semantic_ok = not ns.semantic_audit or all(r.get("semantic_status") != SEMANTIC_FAIL for r in records)
    return 0 if compile_ok and semantic_ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
