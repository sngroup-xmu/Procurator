#!/usr/bin/env python3
from __future__ import annotations

import argparse
import copy
import os
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parents[5]
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

from dslc.speclang import decompose_global_asserts, emit_spec_text, parse_model
from dslc.speclang.model import GlobalDecl, SpecModel


@dataclass(frozen=True)
class RunResult:
    system: str
    variant: str
    part: str
    status: str
    time_ms: Optional[float]
    note: str
    out_dir: Path


def _strip_symmetry(spec: SpecModel) -> SpecModel:
    spec = copy.deepcopy(spec)
    g = spec.global_decl
    spec.global_decl = GlobalDecl(
        queue_capacity=g.queue_capacity,
        env_thread=g.env_thread,
        host_eager=g.host_eager,
        statements=g.statements,
        assume_exprs=g.assume_exprs,
        assert_exprs=g.assert_exprs,
        reachability=g.reachability,
        runtime_reachability=g.runtime_reachability,
        symmetry_groups=[],
    )
    return spec


def _write_spec(path: Path, spec: SpecModel) -> None:
    text = emit_spec_text(spec)
    path.write_text(text, encoding="utf-8")


def _parse_log_result(log_text: str) -> Tuple[str, Optional[float], str]:
    if "proved your program to be incorrect" in log_text:
        status = "UNSAFE"
    elif "proved your program to be correct" in log_text or "AllSpecificationsHoldResult" in log_text:
        status = "SAFE"
    elif "timed out" in log_text.lower():
        status = "TIMEOUT"
    elif "Toolchain returned no result" in log_text:
        status = "UNKNOWN"
    else:
        status = "UNKNOWN"

    time_ms = None
    m = re.search(r"Toolchain \(without parser\) took ([0-9.]+)ms", log_text)
    if m:
        try:
            time_ms = float(m.group(1))
        except Exception:
            time_ms = None
    return status, time_ms, ""


def _run_cmd(cmd: List[str], *, timeout_s: Optional[int] = None, log_path: Optional[Path] = None, env: Dict[str, str] | None = None) -> Tuple[int, str]:
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("w", encoding="utf-8") as fh:
            try:
                proc = subprocess.run(cmd, stdout=fh, stderr=subprocess.STDOUT, env=env, timeout=timeout_s, check=False)
                return proc.returncode, ""
            except subprocess.TimeoutExpired:
                fh.write("\n[timeout]\n")
                return 124, "timeout"
    try:
        proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env, timeout=timeout_s, check=False, text=True)
        return proc.returncode, proc.stdout
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def _run_one(
    *,
    python_bin: Path,
    ultimate_bin: Path,
    tc: Path,
    epf: Path,
    p4b_bin: Path,
    spec_path: Path,
    out_dir: Path,
    work_dir: Path,
    timeout_s: Optional[int],
    env_mode: str,
) -> Tuple[str, Optional[float], str]:
    out_dir.mkdir(parents=True, exist_ok=True)
    work_dir.mkdir(parents=True, exist_ok=True)

    bpl_path = out_dir / (spec_path.stem + ".bpl")
    compile_cmd = [
        str(python_bin),
        "-m",
        "dslc.compiler",
        "--backend",
        "boogie",
        "--spec",
        str(spec_path),
        "--out",
        str(bpl_path),
        "--p4b-bin",
        str(p4b_bin),
        "--work-dir",
        str(work_dir),
        "--env",
        env_mode,
    ]
    rc, msg = _run_cmd(compile_cmd, timeout_s=None)
    if rc != 0:
        return "COMPILE_ERR", None, msg or "compile failed"

    log_path = out_dir / (spec_path.stem + ".gemcutter.log")
    ultimate_home = out_dir / "ultimate-home"
    ultimate_ws = out_dir / "ultimate-ws"
    env = os.environ.copy()
    env["HOME"] = str(ultimate_home)
    env["JAVA_TOOL_OPTIONS"] = f"-Duser.home={ultimate_home}"

    run_cmd = [
        str(ultimate_bin),
        "-data",
        str(ultimate_ws),
        "-tc",
        str(tc),
        "-s",
        str(epf),
        "-i",
        str(bpl_path),
    ]
    rc, msg = _run_cmd(run_cmd, timeout_s=timeout_s, log_path=log_path, env=env)
    if rc == 124:
        return "TIMEOUT", None, "timeout"

    log_text = log_path.read_text(encoding="utf-8", errors="replace")
    status, time_ms, note = _parse_log_result(log_text)
    if not note and msg:
        note = msg
    return status, time_ms, note


def _variants(spec: SpecModel, *, enable_sym: bool, enable_split: bool, max_nodes: int) -> List[Tuple[str, SpecModel]]:
    if not enable_sym:
        spec = _strip_symmetry(spec)
    if enable_split:
        parts = decompose_global_asserts(spec, max_nodes=max_nodes)
        return parts
    return [("full", spec)]


def run_matrix(
    *,
    system: str,
    spec_path: Path,
    out_root: Path,
    python_bin: Path,
    ultimate_bin: Path,
    tc: Path,
    epf: Path,
    p4b_bin: Path,
    timeout_s: Optional[int],
    env_mode: str,
    max_nodes: int,
) -> List[RunResult]:
    spec = parse_model(spec_path.read_text(encoding="utf-8"))
    has_sym = bool(spec.global_decl.symmetry_groups)
    results: List[RunResult] = []
    combos = [
        ("base", False, False),
        ("sym", True, False),
        ("split", False, True),
        ("sym_split", True, True),
    ]
    for variant, use_sym, use_split in combos:
        if use_sym and not has_sym:
            results.append(
                RunResult(system, variant, "full", "SKIP", None, "no symmetry groups in spec", out_root)
            )
            continue
        parts = _variants(spec, enable_sym=use_sym, enable_split=use_split, max_nodes=max_nodes)
        if use_split and len(parts) == 1 and parts[0][0] == "full":
            results.append(
                RunResult(system, variant, "full", "SKIP", None, "no split possible", out_root)
            )
            continue
        for part_name, part_spec in parts:
            part_dir = out_root / system / variant / part_name
            part_dir.mkdir(parents=True, exist_ok=True)
            part_spec_path = part_dir / f"{system}.{variant}.{part_name}.prop"
            _write_spec(part_spec_path, part_spec)
            status, time_ms, note = _run_one(
                python_bin=python_bin,
                ultimate_bin=ultimate_bin,
                tc=tc,
                epf=epf,
                p4b_bin=p4b_bin,
                spec_path=part_spec_path,
                out_dir=part_dir,
                work_dir=part_dir / "work",
                timeout_s=timeout_s,
                env_mode=env_mode,
            )
            results.append(RunResult(system, variant, part_name, status, time_ms, note, part_dir))
    return results


def write_results(path: Path, results: Iterable[RunResult], *, append: bool = False) -> None:
    lines = []
    if not append or not path.exists():
        lines.append("# GemCutter Ablation Results (symmetry + property split)\n")
        lines.append("| system | variant | part | status | time_ms | note | out_dir |\n")
        lines.append("| --- | --- | --- | --- | --- | --- | --- |\n")
    elif append:
        existing = path.read_text(encoding="utf-8", errors="replace").splitlines(keepends=True)
        lines.extend(existing)
    for r in results:
        t = "" if r.time_ms is None else f"{r.time_ms:.2f}"
        note = r.note.replace("|", "/") if r.note else ""
        lines.append(f"| {r.system} | {r.variant} | {r.part} | {r.status} | {t} | {note} | {r.out_dir} |\n")
    path.write_text("".join(lines), encoding="utf-8")


def main(argv: Optional[List[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Run symmetry/split ablation for a spec")
    ap.add_argument("--spec", required=True, help="Path to .prop")
    ap.add_argument("--system", required=True, help="System name for reporting")
    ap.add_argument("--out-root", required=True, help="Output root directory")
    ap.add_argument("--results", default="", help="Optional results path (defaults to <out-root>/RESULTS.md)")
    ap.add_argument("--append-results", action="store_true", help="Append to results file if it exists")
    ap.add_argument("--python", default=sys.executable, help="Python interpreter")
    ap.add_argument("--ultimate", required=True, help="Ultimate CLI path")
    ap.add_argument("--tc", required=True, help="Ultimate toolchain XML")
    ap.add_argument("--epf", required=True, help="Ultimate settings EPF")
    ap.add_argument("--p4b-bin", required=True, help="P4B translator binary")
    ap.add_argument("--timeout", type=int, default=300, help="Timeout per run (seconds)")
    ap.add_argument("--env", choices=["spec", "max"], default="spec", help="Env model")
    ap.add_argument("--max-nodes", type=int, default=2, help="Max nodes per split part")
    args = ap.parse_args(argv)

    results = run_matrix(
        system=args.system,
        spec_path=Path(args.spec),
        out_root=Path(args.out_root),
        python_bin=Path(args.python),
        ultimate_bin=Path(args.ultimate),
        tc=Path(args.tc),
        epf=Path(args.epf),
        p4b_bin=Path(args.p4b_bin),
        timeout_s=args.timeout,
        env_mode=args.env,
        max_nodes=args.max_nodes,
    )
    results_path = Path(args.results) if args.results else Path(args.out_root) / "RESULTS.md"
    write_results(results_path, results, append=args.append_results)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
