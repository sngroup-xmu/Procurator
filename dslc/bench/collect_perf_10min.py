#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shlex
import signal
import subprocess
import tempfile
import time
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple

try:
    from dslc.speclang import parse_model
except Exception:  # pragma: no cover
    parse_model = None  # type: ignore[assignment]


_RE_RESULT = re.compile(r"RESULT:\s*([A-Z]+)")
_RE_OUT_DIR = re.compile(r"(/mnt/e/p4-verify/\.tmp/procurator/verify/[^\s'\"`]+/[0-9]{8}-[0-9]{6}-[0-9a-f]+)")
_RE_8BIT_REG = re.compile(r"register\s*<\s*bit<8>", re.IGNORECASE)
_RE_INCLUDE = re.compile(r"^\s*#\s*include\s*[<\"]([^\">]+)[\">]", re.MULTILINE)


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def _save_json(path: Path, obj: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def _replace_timeout_args(cmd: List[str], timeout_s: int) -> List[str]:
    out = list(cmd)
    if "--ultimate-timeout-seconds" in out:
        i = out.index("--ultimate-timeout-seconds")
        if i + 1 < len(out):
            out[i + 1] = str(timeout_s)
        return out
    return out + ["--ultimate-timeout-seconds", str(timeout_s)]


def _derive_compile_cmd(
    verify_cmd: List[str],
    *,
    spec: str,
    out_bpl: Path,
) -> List[str]:
    # verify cmd shape: ./bin/procurator verify <flags> --spec <spec>
    flags = set(verify_cmd)

    cmd: List[str] = [
        "./bin/procurator",
        "compile",
        "--spec",
        spec,
        "--out",
        str(out_bpl),
    ]

    def _opt_with_val(name: str) -> Optional[str]:
        if name not in verify_cmd:
            return None
        i = verify_cmd.index(name)
        if i + 1 >= len(verify_cmd):
            return None
        return verify_cmd[i + 1]

    harness = _opt_with_val("--boogie-harness")
    if harness:
        cmd += ["--boogie-harness", harness]
    if "--no-two-stage" in flags:
        cmd.append("--no-two-stage")
    env = _opt_with_val("--env")
    if env:
        cmd += ["--env", env]
    if "--use-spec-max-steps" in flags:
        cmd.append("--use-spec-max-steps")
    ms = _opt_with_val("--max-steps")
    if ms:
        cmd += ["--max-steps", ms]
    if "--no-reg-debug" in flags:
        cmd.append("--no-reg-debug")
    if "--no-slicing-control-seeds" in flags:
        cmd.append("--no-slicing-control-seeds")

    # compile CLI uses --no-prune instead of verify's --no-slicing --no-env-prune.
    if "--no-slicing" in flags and "--no-env-prune" in flags:
        cmd.append("--no-prune")

    return cmd


def _run_compile_profile(
    *,
    root: Path,
    compile_cmd: List[str],
    profile_jsonl: Path,
    tag: str,
) -> Dict[str, Any]:
    env = os.environ.copy()
    env["PROCURATOR_COMPILE_PROFILE_JSON"] = str(profile_jsonl)
    env["PROCURATOR_COMPILE_PROFILE_TAG"] = tag

    t0 = time.perf_counter()
    cp = subprocess.run(
        compile_cmd,
        cwd=root,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )
    wall = time.perf_counter() - t0

    profile_rec: Optional[Dict[str, Any]] = None
    if profile_jsonl.exists():
        for ln in profile_jsonl.read_text(encoding="utf-8", errors="replace").splitlines():
            try:
                rec = json.loads(ln)
            except Exception:
                continue
            if rec.get("event") == "boogie_backend_compile" and rec.get("tag") == tag:
                profile_rec = rec

    return {
        "returncode": cp.returncode,
        "wall_s": round(wall, 3),
        "stdout_tail": "\n".join(cp.stdout.splitlines()[-40:]),
        "profile": profile_rec,
    }


def _run_verify_10min_mem(
    *,
    root: Path,
    verify_cmd: List[str],
    timeout_s: int,
) -> Dict[str, Any]:
    def _spec_stem(cmd: List[str]) -> Optional[str]:
        if "--spec" not in cmd:
            return None
        i = cmd.index("--spec")
        if i + 1 >= len(cmd):
            return None
        try:
            return Path(cmd[i + 1]).stem
        except Exception:
            return None

    def _ps_snapshot() -> Dict[int, Tuple[int, int]]:
        cp = subprocess.run(
            ["ps", "-e", "-o", "pid=,ppid=,rss="],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        snap: Dict[int, Tuple[int, int]] = {}
        for ln in (cp.stdout or "").splitlines():
            parts = ln.strip().split()
            if len(parts) != 3:
                continue
            try:
                pid = int(parts[0])
                ppid = int(parts[1])
                rss = int(parts[2])
            except Exception:
                continue
            snap[pid] = (ppid, rss)
        return snap

    def _tree_rss_kb(root_pid: int) -> int:
        snap = _ps_snapshot()
        children: Dict[int, List[int]] = {}
        for pid, (ppid, _) in snap.items():
            children.setdefault(ppid, []).append(pid)
        total = 0
        stack = [root_pid]
        seen: set[int] = set()
        while stack:
            pid = stack.pop()
            if pid in seen:
                continue
            seen.add(pid)
            rec = snap.get(pid)
            if rec is not None:
                total += max(0, rec[1])
            for c in children.get(pid, []):
                if c not in seen:
                    stack.append(c)
        return total

    t0 = time.perf_counter()
    timed_out = False
    peak_rss_kb = 0
    proc: Optional[subprocess.Popen[str]] = None
    spec_stem = _spec_stem(verify_cmd)

    with tempfile.NamedTemporaryFile(prefix="proc.verify.out.", suffix=".log", delete=False) as out_f, tempfile.NamedTemporaryFile(
        prefix="proc.verify.err.", suffix=".log", delete=False
    ) as err_f:
        out_path = Path(out_f.name)
        err_path = Path(err_f.name)

    try:
        with open(out_path, "w", encoding="utf-8") as out_fp, open(err_path, "w", encoding="utf-8") as err_fp:
            proc = subprocess.Popen(
                verify_cmd,
                cwd=root,
                stdout=out_fp,
                stderr=err_fp,
                text=True,
                preexec_fn=os.setsid,
            )
            while True:
                rc = proc.poll()
                now = time.perf_counter()
                elapsed = now - t0
                try:
                    peak_rss_kb = max(peak_rss_kb, _tree_rss_kb(proc.pid))
                except Exception:
                    pass
                if rc is not None:
                    break
                if elapsed >= timeout_s:
                    timed_out = True
                    try:
                        os.killpg(proc.pid, signal.SIGTERM)
                    except Exception:
                        pass
                    try:
                        proc.wait(timeout=8.0)
                    except Exception:
                        try:
                            os.killpg(proc.pid, signal.SIGKILL)
                        except Exception:
                            pass
                        try:
                            proc.wait(timeout=3.0)
                        except Exception:
                            pass
                    break
                time.sleep(0.5)
            wall = time.perf_counter() - t0

        try:
            stdout_txt = out_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            stdout_txt = ""
        try:
            stderr_txt = err_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            stderr_txt = ""
        if timed_out and spec_stem:
            # `procurator verify` may spawn nested timeout/Ultimate workers that
            # survive parent termination; clean them to avoid cross-case interference.
            try:
                subprocess.run(
                    ["pkill", "-f", f"/.tmp/procurator/verify/{spec_stem}/"],
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                )
            except Exception:
                pass
    finally:
        try:
            out_path.unlink(missing_ok=True)
        except Exception:
            pass
        try:
            err_path.unlink(missing_ok=True)
        except Exception:
            pass

    merged = stdout_txt + "\n" + stderr_txt
    result = None
    all_results = _RE_RESULT.findall(merged)
    if all_results:
        result = all_results[-1]
    out_dir = None
    out_dirs = _RE_OUT_DIR.findall(merged)
    if out_dirs:
        out_dir = out_dirs[-1]
    return {
        "returncode": proc.returncode if proc is not None else None,
        "timed_out_10min": timed_out,
        "wall_s": round(wall, 3),
        "max_rss_kb": peak_rss_kb,
        "max_rss_gb": round((peak_rss_kb or 0) / 1024.0 / 1024.0, 3) if peak_rss_kb else None,
        "result_line": result,
        "out_dir": out_dir,
        "stdout_tail": "\n".join((stdout_txt or "").splitlines()[-40:]),
        "stderr_tail": "\n".join((stderr_txt or "").splitlines()[-80:]),
    }


def _wraparound_stage_times(out_dir: Path) -> Optional[Dict[str, Any]]:
    manifests = sorted((out_dir / "wraparound").glob("target.*/wraparound.cegis.manifest.json"))
    for mp in manifests:
        try:
            data = json.loads(mp.read_text(encoding="utf-8"))
        except Exception:
            continue
        for a in data.get("attempts", []):
            e = a.get("entry") or {}
            c = a.get("confirm") or {}
            cl = a.get("closure") or {}
            er = str(e.get("result_line", "")).upper()
            cr = str(c.get("result_line", "")).upper()
            clr = str(cl.get("result_line", "")).upper()
            if "UNSAFE" in er and "UNSAFE" in cr and "SAFE" in clr:
                es = float(e.get("wall_time_s") or 0.0)
                cs = float(c.get("wall_time_s") or 0.0)
                cls = float(cl.get("wall_time_s") or 0.0)
                return {
                    "manifest": str(mp),
                    "entry_s": round(es, 3),
                    "confirm_s": round(cs, 3),
                    "closure_s": round(cls, 3),
                    "total_s": round(es + cs + cls, 3),
                }
    return None


def _spec_has_8bit_register(root: Path, spec_path: str) -> Tuple[bool, List[str]]:
    if parse_model is None:
        return False, []
    p = root / spec_path
    if not p.exists():
        return False, []
    try:
        model = parse_model(p.read_text(encoding="utf-8", errors="replace"))
    except Exception:
        return False, []
    hits: List[str] = []

    def _scan_include_closure(start: Path) -> List[str]:
        include_roots = [
            start.parent,
            (root / "P4B-Translator" / "p4include"),
        ]
        stack: List[Path] = [start]
        seen: set[Path] = set()
        local_hits: List[str] = []
        while stack:
            cur = stack.pop()
            cur = cur.resolve()
            if cur in seen or not cur.exists() or cur.suffix.lower() != ".p4":
                continue
            seen.add(cur)
            try:
                txt = cur.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue
            if _RE_8BIT_REG.search(txt):
                local_hits.append(str(cur))
            for inc in _RE_INCLUDE.findall(txt):
                candidates: List[Path] = [(cur.parent / inc)]
                for r in include_roots:
                    candidates.append(r / inc)
                for cand in candidates:
                    if cand.exists() and cand.suffix.lower() == ".p4":
                        stack.append(cand)
                        break
        return local_hits

    for imp in model.imports.values():
        src = imp.path
        if not src:
            continue
        src_p = Path(src)
        if not src_p.is_absolute():
            src_p = (p.parent / src).resolve()
        if not src_p.exists():
            continue
        if src_p.suffix not in {".p4", ".P4"}:
            continue
        hits.extend(_scan_include_closure(src_p))
    dedup = sorted(set(hits))
    return bool(dedup), dedup


def _fmt(v: Optional[float]) -> str:
    if v is None:
        return "-"
    return f"{v:.3f}"


def _build_report_md(metrics: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append(f"# 10min Perf Profiling\n")
    lines.append(f"Generated at: `{metrics.get('generated_at', '-')}`\n")
    lines.append(f"Timeout per verify run: `{metrics.get('timeout_s', '-')}` seconds\n")
    lines.append("")
    lines.append("## Per-case Memory + Compile Breakdown")
    lines.append("")
    lines.append(
        "| spec | mode | verify wall(s) | max RSS(GB) | 10min timeout | frontend compile wall(s) | prune(s) | translate(s) | python harness(s) |"
    )
    lines.append("|---|---:|---:|---:|---|---:|---:|---:|---:|")

    for spec in sorted(metrics.get("cases", {}).keys()):
        rec = metrics["cases"][spec]
        for mode in ("slicing", "noslicing"):
            m = rec.get(mode) or {}
            vm = m.get("verify_mem") or {}
            cp = m.get("compile_profile") or {}
            prof = cp.get("profile") or {}
            lines.append(
                "| "
                + f"`{spec}` | `{mode}` | {_fmt(vm.get('wall_s'))} | {_fmt(vm.get('max_rss_gb'))} | "
                + ("yes" if vm.get("timed_out_10min") else "no")
                + f" | {_fmt(cp.get('wall_s'))} | {_fmt(prof.get('frontend_prune_total_s'))} | {_fmt(prof.get('frontend_translate_total_s'))} | {_fmt(prof.get('python_harness_emit_s'))} |"
            )

    lines.append("")
    lines.append("## Wraparound Stage Times (from solidified runs)")
    lines.append("")
    lines.append("| spec | mode | entry(s) | confirm(s) | closure(s) | total(s) | out_dir |")
    lines.append("|---|---:|---:|---:|---:|---:|---|")
    for spec in sorted(metrics.get("wraparound_stage_times", {}).keys()):
        for mode in ("slicing", "noslicing"):
            w = (metrics["wraparound_stage_times"][spec] or {}).get(mode) or {}
            lines.append(
                "| "
                + f"`{spec}` | `{mode}` | {_fmt(w.get('entry_s'))} | {_fmt(w.get('confirm_s'))} | {_fmt(w.get('closure_s'))} | {_fmt(w.get('total_s'))} | `{w.get('out_dir', '-')}` |"
            )

    lines.append("")
    lines.append("## 8-bit Register Cases (Wraparound Trial)")
    lines.append("")
    lines.append("| spec | mode | result | entry(s) | confirm(s) | closure(s) | total(s) | note |")
    lines.append("|---|---:|---|---:|---:|---:|---:|---|")
    for row in metrics.get("eight_bit_wrap_trials", []):
        st = row.get("stages") or {}
        lines.append(
            "| "
            + f"`{row.get('spec','-')}` | `{row.get('mode','-')}` | `{row.get('status','-')}` | "
            + f"{_fmt(st.get('entry_s'))} | {_fmt(st.get('confirm_s'))} | {_fmt(st.get('closure_s'))} | {_fmt(st.get('total_s'))} | {row.get('note','-')} |"
        )

    lines.append("")
    return "\n".join(lines)


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Collect 10min memory + compile/harness profiling per E2E case")
    ap.add_argument(
        "--results-json",
        default=".tmp/procurator/e2e_ablations_1h_v2.json",
        help="Existing E2E result checkpoint with per-case slicing/noslicing commands",
    )
    ap.add_argument(
        "--out-json",
        default=".tmp/procurator/perf_10min_metrics.json",
        help="Output metrics JSON (supports resume)",
    )
    ap.add_argument(
        "--out-md",
        default=".tmp/procurator/perf_10min_report.md",
        help="Output markdown table",
    )
    ap.add_argument("--timeout-seconds", type=int, default=600, help="Hard timeout per verify run")
    ap.add_argument("--resume", action="store_true", help="Reuse existing per-mode records in --out-json")
    ap.add_argument(
        "--bench",
        action="append",
        default=[],
        help="Only run specs containing this substring (repeatable)",
    )
    ap.add_argument("--max-cases", type=int, default=0, help="Stop after N specs (0 = all)")
    ap.add_argument(
        "--run-8bit-wrap-trials",
        action="store_true",
        help="Run additional wraparound trials for selected 8-bit register cases",
    )
    ns = ap.parse_args(argv)

    root = _repo_root()
    results_json = (root / ns.results_json).resolve()
    out_json = (root / ns.out_json).resolve()
    out_md = (root / ns.out_md).resolve()
    profile_jsonl = out_json.with_suffix(".compile_profile.jsonl")

    e2e = _load_json(results_json, {})
    if not isinstance(e2e, dict) or not isinstance(e2e.get("results"), dict):
        raise SystemExit(f"invalid results json: {results_json}")
    results: Dict[str, Any] = e2e["results"]

    metrics = _load_json(out_json, {})
    if not isinstance(metrics, dict):
        metrics = {}
    metrics.setdefault("generated_at", dt.datetime.now().isoformat(timespec="seconds"))
    metrics["timeout_s"] = int(ns.timeout_seconds)
    metrics.setdefault("cases", {})
    metrics.setdefault("wraparound_stage_times", {})
    metrics.setdefault("eight_bit_specs", {})
    metrics.setdefault("eight_bit_wrap_trials", [])

    bench_filters = [b.strip() for b in ns.bench if b.strip()]
    specs = sorted(results.keys())
    if bench_filters:
        specs = [s for s in specs if any(b in s for b in bench_filters)]
    if ns.max_cases and ns.max_cases > 0:
        specs = specs[: ns.max_cases]

    seen_cases = 0
    for spec in specs:
        seen_cases += 1
        rec = results.get(spec) or {}
        if not isinstance(rec, dict):
            continue
        cases_dict = metrics.get("cases")
        if not isinstance(cases_dict, dict):
            cases_dict = {}
            metrics["cases"] = cases_dict
        case_out = cases_dict.setdefault(spec, {})

        has_8b, hit_files = _spec_has_8bit_register(root, spec)
        metrics["eight_bit_specs"][spec] = {
            "has_8bit_register": bool(has_8b),
            "import_files": hit_files,
        }

        wrap_cat = rec.get("category") == "wraparound"
        if wrap_cat:
            wrap_map = metrics.get("wraparound_stage_times")
            if not isinstance(wrap_map, dict):
                wrap_map = {}
                metrics["wraparound_stage_times"] = wrap_map
            wrap_map.setdefault(spec, {})

        for mode in ("slicing", "noslicing"):
            mode_rec = rec.get(mode) or {}
            if not isinstance(mode_rec, dict):
                continue
            verify_cmd = mode_rec.get("cmd")
            if not isinstance(verify_cmd, list) or not verify_cmd:
                continue
            mode_out = case_out.setdefault(mode, {})
            if ns.resume and mode_out.get("verify_mem") and mode_out.get("compile_profile"):
                continue

            # 1) compile profiling
            stem = Path(spec).stem
            compile_out = root / ".tmp" / "procurator" / "perf_compile" / f"{stem}.{mode}.bpl"
            compile_out.parent.mkdir(parents=True, exist_ok=True)
            compile_cmd = _derive_compile_cmd(verify_cmd, spec=spec, out_bpl=compile_out)
            tag = f"{stem}:{mode}:{uuid.uuid4().hex[:8]}"
            cp_info = _run_compile_profile(
                root=root,
                compile_cmd=compile_cmd,
                profile_jsonl=profile_jsonl,
                tag=tag,
            )
            mode_out["compile_cmd"] = compile_cmd
            mode_out["compile_profile"] = cp_info

            # 2) verify memory (10min cap)
            verify_cmd_10m = _replace_timeout_args(verify_cmd, int(ns.timeout_seconds))
            vm_info = _run_verify_10min_mem(
                root=root,
                verify_cmd=verify_cmd_10m,
                timeout_s=int(ns.timeout_seconds),
            )
            mode_out["verify_cmd_10m"] = verify_cmd_10m
            mode_out["verify_mem"] = vm_info

            # 3) wraparound stage extraction from out_dir (if applicable)
            if wrap_cat:
                out_dir = vm_info.get("out_dir")
                # We don't store out_dir in vm_info; read from command output path via known run directory pattern:
                # fallback to checkpoint's existing out_dir.
                mode_result = mode_rec.get("result") if isinstance(mode_rec.get("result"), dict) else None
                out_dir = out_dir or (mode_result or {}).get("out_dir")
                if out_dir:
                    w = _wraparound_stage_times(Path(str(out_dir)))
                    if w:
                        w["out_dir"] = str(out_dir)
                        metrics["wraparound_stage_times"][spec][mode] = w

            _save_json(out_json, metrics)

    # Optional: trial wraparound on selected 8-bit register cases.
    if ns.run_8bit_wrap_trials:
        trial_specs = [
            "Procurator/argo/code/spec/bench/atp_bug.prop",
            "Procurator/argo/code/spec/bench/atp_count_mismatch_bug.prop",
            "Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop",
        ]
        trials: List[Dict[str, Any]] = []
        for spec in trial_specs:
            base = results.get(spec) or {}
            mode = "slicing"
            src = base.get(mode) or {}
            cmd = src.get("cmd") if isinstance(src, dict) else None
            if not isinstance(cmd, list):
                continue
            cmd2 = list(cmd)
            # Force wraparound auto for trial.
            if "--wraparound" in cmd2:
                i = cmd2.index("--wraparound")
                if i + 1 < len(cmd2):
                    cmd2[i + 1] = "auto"
            else:
                cmd2 += ["--wraparound", "auto"]
            cmd2 = _replace_timeout_args(cmd2, int(ns.timeout_seconds))
            vm = _run_verify_10min_mem(root=root, verify_cmd=cmd2, timeout_s=int(ns.timeout_seconds))

            mode_result = src.get("result") if isinstance(src.get("result"), dict) else {}
            out_dir = vm.get("out_dir") or (mode_result or {}).get("out_dir")
            w = _wraparound_stage_times(Path(str(out_dir))) if out_dir else None
            note = "no certified wraparound manifest found"
            status = vm.get("result_line") or ("TIMEOUT" if vm.get("timed_out_10min") else f"RC={vm.get('returncode')}")
            if w:
                note = "certified wraparound"
            trials.append(
                {
                    "spec": spec,
                    "mode": mode,
                    "status": status,
                    "stages": w,
                    "note": note,
                }
            )
        metrics["eight_bit_wrap_trials"] = trials
        _save_json(out_json, metrics)

    metrics["generated_at"] = dt.datetime.now().isoformat(timespec="seconds")
    _save_json(out_json, metrics)
    out_md.write_text(_build_report_md(metrics), encoding="utf-8")
    print(f"[OK] wrote metrics: {out_json}")
    print(f"[OK] wrote report:  {out_md}")
    print(f"[OK] specs covered: {seen_cases}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
