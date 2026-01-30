from __future__ import annotations

import argparse
import copy
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from dslc.cli.common import fresh_run_dir, wrap_resource_limits
from dslc.compiler import compile_spec_file
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
    path.write_text(emit_spec_text(spec), encoding="utf-8")


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
    m = re.search(r"Toolchain \\(without parser\\) took ([0-9.]+)ms", log_text)
    if m:
        try:
            time_ms = float(m.group(1))
        except Exception:
            time_ms = None
    return status, time_ms, ""


def _run_cmd(
    cmd: list[str],
    *,
    timeout_s: Optional[int] = None,
    log_path: Optional[Path] = None,
    env: Dict[str, str] | None = None,
    cwd: Optional[Path] = None,
) -> Tuple[int, str]:
    if log_path:
        log_path.parent.mkdir(parents=True, exist_ok=True)
        with log_path.open("w", encoding="utf-8") as fh:
            try:
                proc = subprocess.run(
                    cmd,
                    stdout=fh,
                    stderr=subprocess.STDOUT,
                    env=env,
                    timeout=timeout_s,
                    check=False,
                    # Keep Ultimate side effects (witnesses, temp files) under the per-run output dir.
                    cwd=str(cwd) if cwd else None,
                )
                return proc.returncode, ""
            except subprocess.TimeoutExpired:
                fh.write("\n[timeout]\n")
                return 124, "timeout"
    try:
        proc = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, env=env, timeout=timeout_s, check=False, text=True
        )
        return proc.returncode, proc.stdout
    except subprocess.TimeoutExpired:
        return 124, "timeout"


def _run_one(
    *,
    ultimate_bin: Path,
    tc: Path,
    epf: Path,
    p4b_bin: Path,
    spec_path: Path,
    out_dir: Path,
    work_dir: Path,
    timeout_s: Optional[int],
    env_mode: str,
    resource_limits: bool,
) -> Tuple[str, Optional[float], str]:
    out_dir.mkdir(parents=True, exist_ok=True)
    work_dir.mkdir(parents=True, exist_ok=True)

    bpl_path = out_dir / (spec_path.stem + ".bpl")
    try:
        compile_spec_file(
            spec_path=spec_path,
            backend="boogie",
            out=bpl_path,
            p4b_bin=p4b_bin,
            work_dir=work_dir,
            max_env_inputs=(env_mode == "max"),
            enable_slicing=True,
            prune_env_inputs=True,
            por_enabled=False,
            por_guard_enabled=True,
            boogie_harness="concurrent",
            pipeline_two_stage=True,
        )
    except Exception as e:
        return "COMPILE_ERR", None, str(e)

    log_path = out_dir / (spec_path.stem + ".gemcutter.log")
    ultimate_home = out_dir / "ultimate-home"
    ultimate_ws = out_dir / "ultimate-ws"
    env = os.environ.copy()
    env["HOME"] = str(ultimate_home)
    # Preserve caller-provided JAVA_TOOL_OPTIONS (e.g., -Xmx) and force a per-run user.home
    # to keep Ultimate caches/artifacts isolated and avoid confusing cross-run reuse.
    prev_java_opts = env.get("JAVA_TOOL_OPTIONS", "").strip()
    user_home_opt = f"-Duser.home={ultimate_home}"
    env["JAVA_TOOL_OPTIONS"] = f"{prev_java_opts} {user_home_opt}".strip()

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
    os_timeout = (timeout_s + 60) if (timeout_s and timeout_s > 0) else 0
    run_cmd = wrap_resource_limits(run_cmd, enable=resource_limits, os_timeout_s=os_timeout)

    rc, msg = _run_cmd(run_cmd, timeout_s=timeout_s, log_path=log_path, env=env, cwd=out_dir)
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
        return decompose_global_asserts(spec, max_nodes=max_nodes)
    return [("full", spec)]


def run_matrix(
    *,
    system: str,
    spec_path: Path,
    out_root: Path,
    ultimate_bin: Path,
    tc: Path,
    epf: Path,
    p4b_bin: Path,
    timeout_s: Optional[int],
    env_mode: str,
    max_nodes: int,
    resource_limits: bool,
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
            results.append(RunResult(system, variant, "full", "SKIP", None, "no symmetry groups in spec", out_root))
            continue
        parts = _variants(spec, enable_sym=use_sym, enable_split=use_split, max_nodes=max_nodes)
        if use_split and len(parts) == 1 and parts[0][0] == "full":
            results.append(RunResult(system, variant, "full", "SKIP", None, "no split possible", out_root))
            continue

        for part_name, part_spec in parts:
            part_dir = out_root / variant / part_name
            part_dir.mkdir(parents=True, exist_ok=True)
            part_spec_path = part_dir / f"{system}.{variant}.{part_name}.prop"
            _write_spec(part_spec_path, part_spec)

            status, time_ms, note = _run_one(
                ultimate_bin=ultimate_bin,
                tc=tc,
                epf=epf,
                p4b_bin=p4b_bin,
                spec_path=part_spec_path,
                out_dir=part_dir,
                work_dir=part_dir / "work",
                timeout_s=timeout_s,
                env_mode=env_mode,
                resource_limits=resource_limits,
            )
            results.append(RunResult(system, variant, part_name, status, time_ms, note, part_dir))
    return results


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Run symmetry/splitting ablations and record times")
    ap.add_argument("--spec", required=True, help="Input .prop spec")
    ap.add_argument("--system", default="", help="System name to label outputs (default: spec stem)")
    ap.add_argument(
        "--out-root",
        default="",
        help=(
            "Output directory. If omitted, a fresh per-run directory is created under "
            "`.tmp/procurator/ablation/<system>/<run_id>/` (no cache by default)."
        ),
    )
    ap.add_argument("--ultimate", required=True, help="Ultimate CLI executable")
    ap.add_argument("--toolchain", required=True, help="Ultimate toolchain XML")
    ap.add_argument("--settings", required=True, help="Ultimate settings EPF")
    ap.add_argument("--p4b-bin", required=True, help="P4->Boogie translator binary")
    ap.add_argument("--timeout-s", type=int, default=1200, help="Timeout per run (seconds)")
    ap.add_argument("--env", choices=["spec", "max"], default="spec", help="Environment mode")
    ap.add_argument("--max-nodes", type=int, default=2, help="Max nodes per decomposed property")
    ap.add_argument(
        "--no-resource-limits",
        action="store_true",
        help="Disable CPU/IO niceness limits when running Ultimate (may freeze WSL on heavy runs).",
    )

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec).resolve()
    system = args.system or spec_path.stem
    out_root = Path(args.out_root).resolve() if args.out_root else fresh_run_dir(category="ablation", name=system)

    ultimate_bin = Path(args.ultimate).resolve()
    tc = Path(args.toolchain).resolve()
    epf = Path(args.settings).resolve()
    p4b_bin = Path(args.p4b_bin).resolve()

    results = run_matrix(
        system=system,
        spec_path=spec_path,
        out_root=out_root,
        ultimate_bin=ultimate_bin,
        tc=tc,
        epf=epf,
        p4b_bin=p4b_bin,
        timeout_s=args.timeout_s,
        env_mode=args.env,
        max_nodes=args.max_nodes,
        resource_limits=not args.no_resource_limits,
    )

    # Print a small table to stdout (TSV-ish).
    print("system\tvariant\tpart\tstatus\ttime_ms\tnote\tout_dir")
    for r in results:
        t = "" if r.time_ms is None else f"{r.time_ms:.3f}"
        print(f"{r.system}\t{r.variant}\t{r.part}\t{r.status}\t{t}\t{r.note}\t{r.out_dir}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
