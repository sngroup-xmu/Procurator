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
    for line in log_text.splitlines():
        if "RESULT:" in line:
            return line.strip()
    return None


def _run_one(
    *,
    job: _ComposeJob,
    p4b_bin: Optional[Path],
    max_env_inputs: bool,
    enable_slicing: bool,
    ultimate: Optional[Path],
    toolchain: Path,
    settings: Path,
) -> int:
    compile_spec_file(
        spec_path=job.spec_path,
        backend="boogie",
        out=job.out_bpl,
        p4b_bin=p4b_bin,
        work_dir=job.work_dir,
        max_env_inputs=max_env_inputs,
        enable_slicing=enable_slicing,
    )
    print(f"[OK] bpl: {job.out_bpl}")

    if not ultimate:
        print("[NOTE] --ultimate not provided; skipping Ultimate run.")
        return 0

    cmd = [str(ultimate), "-tc", str(toolchain), "-s", str(settings), "-i", str(job.out_bpl)]
    print("[RUN] " + " ".join(cmd))
    job.ultimate_home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HOME"] = str(job.ultimate_home)
    env["JAVA_TOOL_OPTIONS"] = f"-Duser.home={job.ultimate_home}"
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, env=env)
    job.log_path.parent.mkdir(parents=True, exist_ok=True)
    job.log_path.write_text(proc.stdout, encoding="utf-8")

    result_line = _extract_result(proc.stdout)
    if result_line:
        print(f"[RESULT] {result_line}")
    else:
        print("[RESULT] No RESULT line found; check log.")
    print(f"[LOG] {job.log_path}")
    return proc.returncode


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
    ap.add_argument("--no-slicing", action="store_true", help="Disable P4 slicing/pruning")
    ap.add_argument("--compose", action="store_true", help="Decompose global asserts into local specs and run in parallel")
    ap.add_argument("--compose-max-nodes", type=int, default=2, help="Max nodes per decomposed property (default: 2)")
    ap.add_argument("--compose-jobs", type=int, default=2, help="Parallel jobs for compose mode (default: 2)")
    ap.add_argument(
        "--compose-local-inputs",
        action="store_true",
        help="For single-node sub-specs, allow direct external input and drop topology (over-approx)",
    )
    ap.add_argument("--ultimate", default="", help="Path to Ultimate CLI executable")
    ap.add_argument(
        "--ultimate-home",
        default="",
        help="Override HOME for Ultimate (default: repo/.tmp/ultimate-home)",
    )
    ap.add_argument(
        "--toolchain",
        default="",
        help="Ultimate toolchain XML (default: concurrent/bpl ReachSafety.xml)",
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Ultimate settings EPF (default: Procurator spec/config ReachSafety-32bit-GemCutter-ALL.epf)",
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
        else root / "ultimate" / "trunk" / "examples" / "concurrent" / "bpl" / "regression" / "ReachSafety.xml"
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
        / "ReachSafety-32bit-GemCutter-ALL.epf"
    )

    p4b_bin = Path(args.p4b_bin).resolve() if args.p4b_bin else None

    max_env_inputs = args.env == "max"
    enable_slicing = not args.no_slicing

    ultimate = Path(args.ultimate).resolve() if args.ultimate else None
    if ultimate and not ultimate.exists():
        raise SystemExit(f"[ERR] Ultimate executable not found: {ultimate}")
    if not toolchain.exists():
        raise SystemExit(f"[ERR] Toolchain not found: {toolchain}")
    if not settings.exists():
        raise SystemExit(f"[ERR] Settings not found: {settings}")

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
        return _run_one(
            job=job,
            p4b_bin=p4b_bin,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            ultimate=ultimate,
            toolchain=toolchain,
            settings=settings,
        )

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
                ultimate=ultimate,
                toolchain=toolchain,
                settings=settings,
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
