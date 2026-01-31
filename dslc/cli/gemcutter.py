from __future__ import annotations

import argparse
import json
import os
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence

from dslc.cli.common import find_default_p4b_bin, fresh_run_dir, wrap_resource_limits
from dslc.compiler import compile_spec_file
from dslc.speclang import decompose_global_asserts, emit_spec_text, parse_model, parse_tree
from dslc.utils.repo import repo_root
from dslc.workflows.wraparound_cegis import run_wraparound_cegis_multi


@dataclass(frozen=True)
class _ComposeJob:
    spec_path: Path
    out_bpl: Path
    work_dir: Path
    log_path: Path
    ultimate_home: Path


def _default_paths(spec_path: Path) -> tuple[Path, Path, Path]:
    # No-cache default: each run gets a fresh directory.
    run_dir = fresh_run_dir(category="verify", name=spec_path.stem)
    out_bpl = run_dir / f"{spec_path.stem}.bpl"
    work_dir = run_dir / "work"
    log_path = run_dir / "gemcutter.log"
    return out_bpl, work_dir, log_path


def _extract_result(log_text: str) -> Optional[str]:
    for line in log_text.splitlines():
        if "RESULT:" in line:
            return line.strip()
    return None


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


def _result_line_is_safe(result_line: Optional[str]) -> bool:
    if not result_line:
        return False
    s = result_line.lower()
    return ("result: safe" in s) or ("proved your program to be correct" in s)


def _result_line_is_unsafe(result_line: Optional[str]) -> bool:
    if not result_line:
        return False
    s = result_line.lower()
    return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)


def _wraparound_manifest_certified_unsafe(manifest_path: Path) -> bool:
    """
    A wraparound run is a sound UNSAFE witness iff:
      - ENTRY is UNSAFE (the pump cutpoint is reachable from init), and
      - CONFIRM is UNSAFE (the bug is reachable from the fast-forward state), and
      - CLOSURE is SAFE (the pump summary is sound for the chosen projection).

    We treat this as a *certificate* for early exit in the main pipeline.
    """

    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception:
        return False
    attempts = data.get("attempts") or []
    if not isinstance(attempts, list):
        return False

    for a in attempts:
        if not isinstance(a, dict):
            continue
        entry = a.get("entry") or {}
        confirm = a.get("confirm") or {}
        closure = a.get("closure") or {}
        if not isinstance(entry, dict) or not isinstance(confirm, dict) or not isinstance(closure, dict):
            continue

        if (
            _result_line_is_unsafe(entry.get("result_line"))
            and _result_line_is_unsafe(confirm.get("result_line"))
            and _result_line_is_safe(closure.get("result_line"))
        ):
            return True
    return False


def _run_one(
    *,
    job: _ComposeJob,
    p4b_bin: Optional[Path],
    max_env_inputs: bool,
    enable_slicing: bool,
    prune_env_inputs: bool,
    por_enabled: bool,
    por_guard_enabled: bool,
    boogie_harness: str,
    pipeline_two_stage: bool,
    max_steps: Optional[int],
    honor_spec_max_steps: bool,
    ultimate: Optional[Path],
    toolchain: Path,
    settings: Path,
    ultimate_async: bool,
    ultimate_timeout_seconds: int,
    resource_limits: bool,
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
        por_guard_enabled=por_guard_enabled,
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
    os_timeout = ultimate_timeout_seconds + 60 if ultimate_timeout_seconds > 0 else 0
    cmd = wrap_resource_limits(cmd, enable=resource_limits, os_timeout_s=os_timeout)
    print("[RUN] " + " ".join(cmd))

    job.ultimate_home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HOME"] = str(job.ultimate_home)
    # Preserve caller-provided JAVA_TOOL_OPTIONS (e.g., -Xmx) and force a per-run user.home
    # to keep Ultimate caches/artifacts isolated and avoid confusing cross-run reuse.
    prev_java_opts = env.get("JAVA_TOOL_OPTIONS", "").strip()
    user_home_opt = f"-Duser.home={job.ultimate_home}"
    env["JAVA_TOOL_OPTIONS"] = f"{prev_java_opts} {user_home_opt}".strip()
    job.log_path.parent.mkdir(parents=True, exist_ok=True)

    if ultimate_async:
        with job.log_path.open("w", encoding="utf-8") as log_file:
            proc = subprocess.Popen(
                cmd,
                stdout=log_file,
                stderr=subprocess.STDOUT,
                text=True,
                env=env,
                # Keep Ultimate side effects (witnesses, temp files) under the per-run output dir.
                cwd=str(job.log_path.parent),
            )
        print(f"[RUN] Ultimate running in background (pid={proc.pid}).")
        print(f"[LOG] {job.log_path}")
        return 0

    # Stream output to the log file to avoid buffering large logs in RAM.
    with job.log_path.open("wb") as log_file:
        log_file.write(("[RUN] " + " ".join(cmd) + "\n").encode("utf-8"))
        log_file.flush()
        proc = subprocess.run(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            env=env,
            # Keep Ultimate side effects (witnesses, temp files) under the per-run output dir.
            cwd=str(job.log_path.parent),
        )

    result_line: Optional[str] = None
    with job.log_path.open("rb") as log_file:
        for raw in log_file:
            line = raw.decode("utf-8", errors="replace")
            if "RESULT:" in line:
                result_line = line.strip()
                break

    if result_line:
        print(f"[RESULT] {result_line}")
    else:
        print("[RESULT] No RESULT line found; check log.")
    print(f"[LOG] {job.log_path}")
    return proc.returncode


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Compile DSL to Boogie and run Ultimate/GemCutter")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument(
        "--out",
        default="",
        help=(
            "Output .bpl path. If omitted, a fresh per-run directory is created under "
            "`.tmp/procurator/verify/<spec>/<run_id>/` (no cache by default)."
        ),
    )
    ap.add_argument("--work-dir", default="", help="Work directory for P4B outputs (default: <out>.work)")
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary")
    ap.add_argument(
        "--env",
        choices=["spec", "max"],
        default="spec",
        help="Environment model: 'spec' applies assume constraints, 'max' makes inputs fully nondet",
    )
    ap.add_argument("--no-slicing", action="store_true", help="Disable P4 slicing/pruning")
    ap.add_argument(
        "--no-env-prune",
        action="store_true",
        help="Disable env input pruning based on sliced Boogie usage",
    )
    ap.add_argument("--por", action="store_true", help="Enable commutativity-based POR")
    ap.add_argument(
        "--no-por-guard",
        action="store_true",
        help="Disable POR guards even when --por is enabled",
    )
    ap.add_argument(
        "--boogie-harness",
        choices=["concurrent", "sequential"],
        default="concurrent",
        help=(
            "Boogie harness style: 'concurrent' uses fork/atomic threads; "
            "'sequential' emits a single-thread nondet scheduler."
        ),
    )
    ap.add_argument(
        "--no-two-stage",
        action="store_true",
        help="Disable two-stage ingress/egress scheduling when it can be inferred",
    )
    ap.add_argument(
        "--max-steps",
        type=int,
        default=None,
        help=(
            "Bound the number of Procurator steps (BMC-style bug finding). "
            "UNSAFE is sound; SAFE is only within the bound. Default: unbounded."
        ),
    )
    ap.add_argument(
        "--use-spec-max-steps",
        action="store_true",
        help="Honor `global.max_steps` from the DSL spec (disabled by default).",
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
        help="Override HOME for Ultimate (default: <out_dir>/ultimate-home)",
    )
    ap.add_argument(
        "--toolchain",
        default="",
        help="Ultimate toolchain XML (default: concurrent/bpl ReachSafety.xml)",
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Ultimate settings EPF (default: dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf)",
    )
    ap.add_argument("--log", default="", help="Log file path (default: <out>.gemcutter.log)")
    ap.add_argument(
        "--no-resource-limits",
        action="store_true",
        help="Disable CPU/IO niceness limits when running Ultimate (may freeze WSL on heavy runs).",
    )
    ap.add_argument(
        "--wraparound",
        choices=["off", "auto", "force"],
        default="auto",
        help=(
            "Wraparound acceleration integrated into `procurator verify`. "
            "'auto' runs wraparound CEGIS only when wraparound candidates are inferred; "
            "'force' runs it regardless; 'off' disables it."
        ),
    )
    ap.add_argument(
        "--wraparound-max-targets",
        type=int,
        default=8,
        help="Max number of wraparound target candidates to attempt (default: 8).",
    )
    ap.add_argument(
        "--wraparound-confirm-unroll",
        type=int,
        default=3,
        help="Unroll steps for wraparound confirm (default: 3).",
    )
    ap.add_argument(
        "--wraparound-max-confirm-unroll",
        type=int,
        default=12,
        help="Max unroll steps for wraparound confirm growth (default: 12).",
    )
    ap.add_argument(
        "--wraparound-max-iters",
        type=int,
        default=6,
        help="Max refinement iterations per wraparound target (default: 6).",
    )
    ap.add_argument(
        "--wraparound-stage-order",
        choices=["entry_closure_confirm", "entry_confirm_closure"],
        default="entry_confirm_closure",
        help=(
            "Stage order for wraparound attempts. "
            "Recommended for main verification pipeline: entry_confirm_closure."
        ),
    )

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec).resolve()
    if not spec_path.exists():
        raise SystemExit(f"[ERR] spec not found: {spec_path}")

    default_out, default_work, default_log = _default_paths(spec_path)
    out_bpl = Path(args.out).resolve() if args.out else default_out
    if args.work_dir:
        work_dir = Path(args.work_dir).resolve()
    elif args.out:
        work_dir = out_bpl.with_suffix(out_bpl.suffix + ".work")
    else:
        work_dir = default_work

    if args.log:
        log_path = Path(args.log).resolve()
    elif args.out:
        log_path = out_bpl.with_suffix(".gemcutter.log")
    else:
        log_path = default_log

    root = repo_root()
    toolchain = (
        Path(args.toolchain).resolve()
        if args.toolchain
        else root / "ultimate" / "trunk" / "examples" / "concurrent" / "bpl" / "regression" / "ReachSafety.xml"
    )
    settings = (
        Path(args.settings).resolve()
        if args.settings
        else (
            (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL.epf")
            if (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL.epf").exists()
            else (root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL.epf")
        )
    )

    p4b_bin = Path(args.p4b_bin).resolve() if args.p4b_bin else None
    if not p4b_bin:
        # P4B is only required when we import P4/JSON (not pre-generated .bpl).
        try:
            spec_text_for_imports = spec_path.read_text(encoding="utf-8", errors="replace")
            model_for_imports = parse_model(spec_text_for_imports)
            needs_p4b = any((not imp.path.endswith(".bpl")) for imp in model_for_imports.imports.values())
        except Exception:
            needs_p4b = False
        if needs_p4b:
            p4b_bin = find_default_p4b_bin()
            if not p4b_bin:
                raise SystemExit(
                    "missing --p4b-bin (and no default P4B translator found at "
                    "`P4B-Translator/build-host/p4c-translator` or `dslc/toolchain/p4b_docker.sh`)"
                )

    max_env_inputs = args.env == "max"
    enable_slicing = not args.no_slicing
    prune_env_inputs = not args.no_env_prune
    por_enabled = args.por
    por_guard_enabled = not args.no_por_guard
    boogie_harness = args.boogie_harness
    pipeline_two_stage = not args.no_two_stage

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
            else out_bpl.parent / "ultimate-home",
        )

        # Wraparound first (integrated CEGIS).
        #
        # Rationale: wraparound bugs typically require an extremely long prefix (0 -> MAX),
        # which makes plain bug finding impractical. We therefore try wraparound before the
        # full verification run, and fall back to full verification only when wraparound
        # does not produce a certified counterexample.
        if args.wraparound != "off" and ultimate and not args.ultimate_async:
            wrap_dir = job.out_bpl.parent / "wraparound"
            wrap_dir.mkdir(parents=True, exist_ok=True)
            try:
                manifests = run_wraparound_cegis_multi(
                    spec_path=spec_path,
                    out_dir=wrap_dir,
                    p4b_bin=p4b_bin,
                    ultimate=ultimate,
                    timeout_seconds=max(0, int(args.ultimate_timeout_seconds)),
                    resource_limits=not args.no_resource_limits,
                    enable_slicing=enable_slicing,
                    pipeline_two_stage=pipeline_two_stage,
                    confirm_unroll=int(args.wraparound_confirm_unroll),
                    max_confirm_unroll=int(args.wraparound_max_confirm_unroll),
                    max_iters=int(args.wraparound_max_iters),
                    stage_order=str(args.wraparound_stage_order),
                    max_targets=int(args.wraparound_max_targets),
                )
            except Exception as e:
                if args.wraparound == "force":
                    raise
                print(f"[WRAP] skip: wraparound CEGIS failed ({type(e).__name__}: {e})")
                manifests = []

            for mp in manifests:
                if _wraparound_manifest_certified_unsafe(mp):
                    print(f"[WRAP] CERTIFIED UNSAFE: {mp}")
                    return 0

        rc = _run_one(
            job=job,
            p4b_bin=p4b_bin,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            por_enabled=por_enabled,
            por_guard_enabled=por_guard_enabled,
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
            max_steps=args.max_steps,
            honor_spec_max_steps=args.use_spec_max_steps,
            ultimate=ultimate,
            toolchain=toolchain,
            settings=settings,
            ultimate_async=args.ultimate_async,
            ultimate_timeout_seconds=args.ultimate_timeout_seconds,
            resource_limits=not args.no_resource_limits,
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
    # No-cache default: keep compose artifacts under the same per-run output dir.
    compose_dir = out_bpl.parent / "compose"
    compose_dir.mkdir(parents=True, exist_ok=True)

    jobs: list[_ComposeJob] = []
    for suffix, sub in parts:
        base_dir = spec_path.parent.resolve()
        for alias, imp in list(sub.imports.items()):
            p4_path = (base_dir / imp.path).resolve() if not Path(imp.path).is_absolute() else Path(imp.path)
            entries_path = None
            if imp.entries_path:
                entries_path = (
                    (base_dir / imp.entries_path).resolve()
                    if not Path(imp.entries_path).is_absolute()
                    else Path(imp.entries_path)
                )
            sub.imports[alias] = type(imp)(
                alias=imp.alias,
                path=p4_path.as_posix(),
                entries_path=entries_path.as_posix() if entries_path else None,
            )

        spec_out = compose_dir / f"{spec_path.stem}.{suffix}.prop"
        spec_out.write_text(emit_spec_text(sub), encoding="utf-8")

        stem = f"{spec_path.stem}.{suffix}"
        out_bpl_i = compose_dir / f"{stem}.bpl"
        work_dir_i = compose_dir / f"{stem}.work"
        log_i = compose_dir / f"{stem}.gemcutter.log"
        base_home = Path(args.ultimate_home).resolve() if args.ultimate_home else (compose_dir / "ultimate-home")
        ultimate_home_i = base_home / suffix

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
                por_guard_enabled=por_guard_enabled,
                boogie_harness=boogie_harness,
                pipeline_two_stage=pipeline_two_stage,
                max_steps=args.max_steps,
                honor_spec_max_steps=args.use_spec_max_steps,
                ultimate=ultimate,
                toolchain=toolchain,
                settings=settings,
                ultimate_async=args.ultimate_async,
                ultimate_timeout_seconds=args.ultimate_timeout_seconds,
                resource_limits=not args.no_resource_limits,
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
