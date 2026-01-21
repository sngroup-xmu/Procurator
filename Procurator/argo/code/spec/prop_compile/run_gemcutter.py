#!/usr/bin/env python3
from __future__ import annotations

import argparse
import os
import re
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence

from dslc.compiler import compile_spec_file
from dslc.speclang import decompose_global_asserts, emit_spec_text, parse_model, parse_tree


@dataclass(frozen=True)
class _ComposeJob:
    spec_path: Path
    out_bpl: Path
    work_dir: Path
    log_path: Path
    ultimate_home: Path


def _repo_root() -> Path:
    here = Path(__file__).resolve()
    return here.parents[5]


def _default_paths(spec_path: Path) -> tuple[Path, Path, Path]:
    root = _repo_root()
    stem = spec_path.stem
    out_dir = root / ".tmp" / "dslc"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_bpl = out_dir / f"{stem}.bpl"
    work_dir = out_dir / f"{stem}.work"
    log_path = out_dir / f"{stem}.gemcutter.log"
    return out_bpl, work_dir, log_path


def _extract_result(log_text: str) -> Optional[str]:
    last: Optional[str] = None
    for line in log_text.splitlines():
        if "RESULT:" in line:
            last = line.strip()
    return last


def _extract_result_from_file(log_path: Path) -> Optional[str]:
    last: Optional[str] = None
    try:
        with log_path.open("r", encoding="utf-8", errors="replace") as f:
            for line in f:
                if "RESULT:" in line:
                    last = line.strip()
    except FileNotFoundError:
        return None
    return last


def _is_unsafe(log_text: str) -> bool:
    result = _extract_result(log_text)
    if result:
        low = result.lower()
        if "incorrect" in low or "unsafe" in low:
            return True
        if "correct" in low or "safe" in low:
            return False
    low = log_text.lower()
    return "proved your program to be incorrect" in low or "result: unsafe" in low


def _run_one(
    *,
    job: _ComposeJob,
    p4b_bin: Optional[Path],
    max_env_inputs: bool,
    enable_slicing: bool,
    prune_env_inputs: bool,
    por_enabled: bool,
    boogie_harness: str,
    pipeline_two_stage: bool,
    max_steps: Optional[int],
    honor_spec_max_steps: bool,
    ultimate: Optional[Path],
    toolchain: Path,
    settings: Path,
    ultimate_async: bool,
    ultimate_timeout_seconds: int,
) -> int:
    compile_spec_file(
        spec_path=job.spec_path,
        backend="boogie",
        out=job.out_bpl,
        p4b_bin=p4b_bin,
        work_dir=job.work_dir,
        max_env_inputs=max_env_inputs,
        enable_slicing=enable_slicing,
        prune_env_inputs=prune_env_inputs,
        por_enabled=por_enabled,
        por_guard_enabled=True,
        boogie_harness=boogie_harness,
        pipeline_two_stage=pipeline_two_stage,
        max_steps=max_steps,
        honor_spec_max_steps=honor_spec_max_steps,
    )
    print(f"[OK] bpl: {job.out_bpl}")

    if not ultimate:
        print("[NOTE] --ultimate not provided; skipping Ultimate run.")
        return 0

    cmd = [
        str(ultimate),
        f"--core.toolchain.timeout.in.seconds={ultimate_timeout_seconds}",
        "-tc",
        str(toolchain),
        "-s",
        str(settings),
        "-i",
        str(job.out_bpl),
    ]
    print("[RUN] " + " ".join(cmd))
    job.ultimate_home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HOME"] = str(job.ultimate_home)
    env["JAVA_TOOL_OPTIONS"] = f"-Duser.home={job.ultimate_home}"
    job.log_path.parent.mkdir(parents=True, exist_ok=True)
    with job.log_path.open("w", encoding="utf-8") as log_file:
        proc = subprocess.Popen(cmd, stdout=log_file, stderr=subprocess.STDOUT, text=True, env=env)
        if ultimate_async:
            print(f"[RUN] Ultimate running in background (pid={proc.pid}).")
            print(f"[LOG] {job.log_path}")
            return 0
        returncode = proc.wait()

    result_line = _extract_result_from_file(job.log_path)
    if result_line:
        print(f"[RESULT] {result_line}")
    else:
        print("[RESULT] No RESULT line found; check log.")
    print(f"[LOG] {job.log_path}")
    return returncode


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Compile DSL to Boogie and run Ultimate/GemCutter")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument("--out", default="", help="Output .bpl path (default: repo/.tmp/dslc/<spec>.bpl)")
    ap.add_argument("--work-dir", default="", help="Work directory for P4B outputs")
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary")
    ap.add_argument(
        "--env",
        choices=["spec", "max"],
        default="spec",
        help="Environment model: 'spec' applies assume constraints, 'max' makes inputs fully nondet",
    )
    ap.add_argument(
        "--max-steps",
        type=int,
        default=None,
        help="Bound the number of Procurator steps (BMC-style bug finding). UNSAFE is sound; SAFE is only within the bound. Default: unbounded.",
    )
    ap.add_argument(
        "--use-spec-max-steps",
        action="store_true",
        help="Honor `global.max_steps` from the DSL spec (disabled by default).",
    )
    ap.add_argument(
        "--no-prune",
        action="store_true",
        help="Disable DAG-based slicing and env-input pruning",
    )
    ap.add_argument("--por", action="store_true", help="Enable commutativity-based POR")
    ap.add_argument(
        "--boogie-harness",
        choices=["concurrent", "sequential"],
        default="concurrent",
        help="Boogie harness style: 'concurrent' uses fork/atomic threads; 'sequential' emits a single-thread nondet scheduler.",
    )
    ap.add_argument(
        "--no-two-stage",
        action="store_true",
        help="Disable two-stage ingress/egress scheduling when it can be inferred",
    )
    ap.add_argument("--compose", action="store_true", help="Decompose global asserts into local specs and run in parallel")
    ap.add_argument("--compose-max-nodes", type=int, default=2, help="Max nodes per decomposed property (default: 2)")
    ap.add_argument("--compose-jobs", type=int, default=2, help="Parallel jobs for compose mode (default: 2)")
    ap.add_argument(
        "--compose-local-inputs",
        action="store_true",
        help="For single-node sub-specs, allow direct external input and drop topology (over-approx)",
    )
    ap.add_argument(
        "--ultimate-async",
        action="store_true",
        help="Run Ultimate in the background and return immediately (log file will continue to update).",
    )
    ap.add_argument("--ultimate", default="", help="Path to Ultimate CLI executable")
    ap.add_argument(
        "--ultimate-timeout-seconds",
        type=int,
        default=0,
        help="Ultimate toolchain timeout in seconds (0 disables timeout).",
    )
    ap.add_argument(
        "--ultimate-home",
        default="",
        help="Override HOME for Ultimate (default: repo/.tmp/ultimate-home)",
    )
    ap.add_argument(
        "--toolchain",
        default="",
        help="Ultimate toolchain XML (default: Procurator spec/config ReachSafety-Witness.xml)",
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Ultimate settings EPF (default: Procurator spec/config ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf)",
    )
    ap.add_argument("--log", default="", help="Log file path (default: repo/.tmp/dslc/<spec>.gemcutter.log)")

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec).resolve()
    if not spec_path.exists():
        raise SystemExit(f"[ERR] spec not found: {spec_path}")

    default_out, default_work, default_log = _default_paths(spec_path)
    out_bpl = Path(args.out).resolve() if args.out else default_out
    work_dir = Path(args.work_dir).resolve() if args.work_dir else default_work
    log_path = Path(args.log).resolve() if args.log else default_log

    root = _repo_root()
    toolchain = (
        Path(args.toolchain).resolve()
        if args.toolchain
        else root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml"
    )
    settings = (
        Path(args.settings).resolve()
        if args.settings
        else root
        / "Procurator"
        / "argo"
        / "code"
        / "spec"
        / "config"
        / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf"
    )

    p4b_bin = Path(args.p4b_bin).resolve() if args.p4b_bin else None

    max_env_inputs = args.env == "max"
    prune = not args.no_prune
    enable_slicing = prune
    prune_env_inputs = prune
    por_enabled = args.por
    boogie_harness = args.boogie_harness
    pipeline_two_stage = not args.no_two_stage
    max_steps = args.max_steps
    honor_spec_max_steps = bool(args.use_spec_max_steps)

    if max_steps is not None and max_steps <= 0:
        raise SystemExit("[ERR] --max-steps must be > 0")

    ultimate = Path(args.ultimate).resolve() if args.ultimate else None
    if ultimate and not ultimate.exists():
        raise SystemExit(f"[ERR] Ultimate executable not found: {ultimate}")
    if not toolchain.exists():
        raise SystemExit(f"[ERR] Toolchain not found: {toolchain}")
    if not settings.exists():
        raise SystemExit(f"[ERR] Settings not found: {settings}")

    if por_enabled:
        no_por = settings.with_name(settings.stem + "-no-por" + settings.suffix)
        if "-no-por" not in settings.name and no_por.exists():
            print(f"[NOTE] --por enabled; Ultimate POR is still on. Consider --settings {no_por}")

    if not args.compose:
        job = _ComposeJob(
            spec_path=spec_path,
            out_bpl=out_bpl,
            work_dir=work_dir,
            log_path=log_path,
            ultimate_home=Path(args.ultimate_home).resolve()
            if args.ultimate_home
            else _repo_root() / ".tmp" / "ultimate-home",
        )
        rc = _run_one(
            job=job,
            p4b_bin=p4b_bin,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            por_enabled=por_enabled,
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
            max_steps=max_steps,
            honor_spec_max_steps=honor_spec_max_steps,
            ultimate=ultimate,
            toolchain=toolchain,
            settings=settings,
            ultimate_async=args.ultimate_async,
            ultimate_timeout_seconds=args.ultimate_timeout_seconds,
        )
        return rc

    # Compose mode: split global asserts into local specs and run in parallel.
    spec_text = spec_path.read_text(encoding="utf-8")
    try:
        parse_tree(spec_text)  # syntax check
        model = parse_model(spec_text)
    except Exception as e:
        raise SystemExit(f"[ERR] compose parse failed: {e}") from e

    parts = decompose_global_asserts(
        model,
        max_nodes=args.compose_max_nodes,
        local_inputs=args.compose_local_inputs,
    )
    compose_tag = spec_path.parent.name if spec_path.stem == "spec" else spec_path.stem
    compose_dir = _repo_root() / ".tmp" / "dslc" / "compose" / compose_tag
    compose_dir.mkdir(parents=True, exist_ok=True)

    jobs: list[_ComposeJob] = []
    for suffix, sub in parts:
        spec_out = compose_dir / f"{spec_path.stem}.{suffix}.prop"
        spec_out.write_text(emit_spec_text(sub), encoding="utf-8")
        stem = f"{spec_path.stem}.{suffix}"
        out_bpl_i = compose_dir / f"{stem}.bpl"
        work_dir_i = compose_dir / f"{stem}.work"
        log_i = compose_dir / f"{stem}.gemcutter.log"
        ultimate_home_i = compose_dir / f"ultimate-home-{suffix}"
        jobs.append(
            _ComposeJob(
                spec_path=spec_out,
                out_bpl=out_bpl_i,
                work_dir=work_dir_i,
                log_path=log_i,
                ultimate_home=ultimate_home_i,
            )
        )

    rc = 0
    with ThreadPoolExecutor(max_workers=max(1, args.compose_jobs)) as ex:
        futs = {
            ex.submit(
                _run_one,
                job=job,
                p4b_bin=p4b_bin,
                max_env_inputs=max_env_inputs,
                enable_slicing=enable_slicing,
                prune_env_inputs=prune_env_inputs,
                por_enabled=por_enabled,
                boogie_harness=boogie_harness,
                pipeline_two_stage=pipeline_two_stage,
                max_steps=max_steps,
                honor_spec_max_steps=honor_spec_max_steps,
                ultimate=ultimate,
                toolchain=toolchain,
                settings=settings,
                ultimate_async=args.ultimate_async,
                ultimate_timeout_seconds=args.ultimate_timeout_seconds,
            ): job
            for job in jobs
        }
        for fut in as_completed(futs):
            code = fut.result()
            if code != 0:
                rc = code
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
