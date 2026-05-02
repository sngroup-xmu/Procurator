#!/usr/bin/env python3
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import subprocess
import time
import uuid
from pathlib import Path
from typing import Any, Dict, List, Optional


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


def _derive_compile_cmd(verify_cmd: List[str], *, spec: str, out_bpl: Path) -> List[str]:
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
    max_steps = _opt_with_val("--max-steps")
    if max_steps:
        cmd += ["--max-steps", max_steps]
    if "--no-reg-debug" in flags:
        cmd.append("--no-reg-debug")
    if "--no-slicing-control-seeds" in flags:
        cmd.append("--no-slicing-control-seeds")
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
                break

    return {
        "returncode": cp.returncode,
        "wall_s": round(wall, 3),
        "stdout_tail": "\n".join((cp.stdout or "").splitlines()[-30:]),
        "profile": profile_rec,
    }


def _wraparound_stage_times(out_dir: Path) -> Optional[Dict[str, Any]]:
    manifests = sorted((out_dir / "wraparound").glob("target.*/wraparound.cegis.manifest.json"))
    for mp in manifests:
        try:
            data = json.loads(mp.read_text(encoding="utf-8"))
        except Exception:
            continue
        for a in data.get("attempts", []) or []:
            if not isinstance(a, dict):
                continue
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


def _fmt(v: Optional[float]) -> str:
    if v is None:
        return "-"
    return f"{v:.3f}"


def _build_report_md(metrics: Dict[str, Any]) -> str:
    lines: List[str] = []
    lines.append("# Compile/Runtime Integrated Report")
    lines.append("")
    lines.append(f"Generated at: `{metrics.get('generated_at', '-')}`")
    lines.append("")
    lines.append("## Case-by-case Runtime + Compile Stage Times")
    lines.append("")
    lines.append(
        "| spec | mode | runtime wall(s) | status | compile wall(s) | frontend prune(s) | frontend translate(s) | python harness(s) | backend total(s) |"
    )
    lines.append("|---|---:|---:|---|---:|---:|---:|---:|---:|")
    for spec in sorted(metrics.get("cases", {}).keys()):
        rec = metrics["cases"][spec]
        for mode in ("slicing", "noslicing"):
            m = rec.get(mode) or {}
            rt = m.get("runtime") or {}
            cp = m.get("compile_profile") or {}
            prof = cp.get("profile") or {}
            lines.append(
                "| "
                + f"`{spec}` | `{mode}` | {_fmt(rt.get('wall_s'))} | `{rt.get('status','-')}` | {_fmt(cp.get('wall_s'))} | {_fmt(prof.get('frontend_prune_total_s'))} | {_fmt(prof.get('frontend_translate_total_s'))} | {_fmt(prof.get('python_harness_emit_s'))} | {_fmt(prof.get('total_backend_compile_s'))} |"
            )
    lines.append("")
    lines.append("## Wraparound Stage Times (from existing certified manifests)")
    lines.append("")
    lines.append("| spec | mode | stage1 entry(s) | stage2 confirm(s) | stage3 closure(s) | total(s) |")
    lines.append("|---|---:|---:|---:|---:|---:|")
    for spec in sorted(metrics.get("wraparound_stage_times", {}).keys()):
        rec = metrics["wraparound_stage_times"][spec]
        for mode in ("slicing", "noslicing"):
            w = rec.get(mode) or {}
            lines.append(
                "| "
                + f"`{spec}` | `{mode}` | {_fmt(w.get('entry_s'))} | {_fmt(w.get('confirm_s'))} | {_fmt(w.get('closure_s'))} | {_fmt(w.get('total_s'))} |"
            )
    lines.append("")
    return "\n".join(lines)


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Collect compile stage times and integrate with current runtime")
    ap.add_argument(
        "--results-json",
        default=".tmp/procurator/e2e_ablations_1h_v2.json",
        help="E2E ablation checkpoint json",
    )
    ap.add_argument(
        "--out-json",
        default=".tmp/procurator/compile_runtime_integrated.json",
        help="Output metrics json",
    )
    ap.add_argument(
        "--out-md",
        default="EXPERIMENT_STAGE_RUNTIME_CURRENT.md",
        help="Output markdown report",
    )
    ap.add_argument(
        "--bench",
        action="append",
        default=[],
        help="Only include specs containing this substring (repeatable)",
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

    if profile_jsonl.exists():
        profile_jsonl.unlink()

    bench_filters = [b.strip() for b in ns.bench if b.strip()]
    specs = sorted(results.keys())
    if bench_filters:
        specs = [s for s in specs if any(b in s for b in bench_filters)]

    metrics: Dict[str, Any] = {
        "generated_at": dt.datetime.now().isoformat(timespec="seconds"),
        "results_json": str(results_json),
        "cases": {},
        "wraparound_stage_times": {},
    }

    for idx, spec in enumerate(specs, start=1):
        rec = results.get(spec) or {}
        if not isinstance(rec, dict):
            continue
        print(f"[{idx}/{len(specs)}] collect {spec}")
        metrics["cases"].setdefault(spec, {})

        for mode in ("slicing", "noslicing"):
            mode_rec = rec.get(mode) or {}
            if not isinstance(mode_rec, dict):
                continue
            verify_cmd = mode_rec.get("cmd")
            if not isinstance(verify_cmd, list) or not verify_cmd:
                continue
            runtime = mode_rec.get("result") if isinstance(mode_rec.get("result"), dict) else {}
            out_bpl = root / ".tmp" / "procurator" / "perf_compile" / f"{Path(spec).stem}.{mode}.integrated.bpl"
            out_bpl.parent.mkdir(parents=True, exist_ok=True)
            compile_cmd = _derive_compile_cmd(verify_cmd, spec=spec, out_bpl=out_bpl)
            tag = f"{Path(spec).stem}:{mode}:{uuid.uuid4().hex[:8]}"
            cp_info = _run_compile_profile(root=root, compile_cmd=compile_cmd, profile_jsonl=profile_jsonl, tag=tag)
            metrics["cases"][spec][mode] = {
                "runtime": {
                    "status": runtime.get("status"),
                    "wall_s": runtime.get("wall_s"),
                    "out_dir": runtime.get("out_dir"),
                    "log_path": runtime.get("log_path"),
                    "sanity": runtime.get("sanity"),
                },
                "compile_cmd": compile_cmd,
                "compile_profile": cp_info,
            }

        if rec.get("category") == "wraparound":
            metrics["wraparound_stage_times"].setdefault(spec, {})
            for mode in ("slicing", "noslicing"):
                mode_rec = rec.get(mode) or {}
                runtime = mode_rec.get("result") if isinstance(mode_rec.get("result"), dict) else {}
                out_dir = runtime.get("out_dir")
                if not out_dir:
                    continue
                st = _wraparound_stage_times(Path(str(out_dir)))
                if st:
                    st["out_dir"] = out_dir
                    metrics["wraparound_stage_times"][spec][mode] = st

    metrics["generated_at"] = dt.datetime.now().isoformat(timespec="seconds")
    _save_json(out_json, metrics)
    out_md.write_text(_build_report_md(metrics), encoding="utf-8")
    print(f"[OK] wrote {out_json}")
    print(f"[OK] wrote {out_md}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
