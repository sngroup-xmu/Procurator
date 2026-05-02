from __future__ import annotations

import argparse
import json
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence

from dslc.cli.common import find_default_p4b_bin, find_default_ultimate, fresh_run_dir
from dslc.compiler import compile_spec_file
from dslc.speclang import decompose_global_asserts, emit_spec_text, parse_model, parse_tree
from dslc.toolchain.ultimate_runner import run_ultimate
from dslc.toolchain.ultimate_paths import (
    resolve_ultimate_asset_path,
    ultimate_asset,
    ultimate_assets,
)
from dslc.transform.wraparound_stages import _rewrite_forall_bv32_array_inits
from dslc.utils.repo import repo_root
from dslc.workflows.wraparound_cegis import (
    _manifest_certified_unsafe_data,
    run_wraparound_cegis_multi,
)


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


def _optimize_bpl_for_ultimate(bpl_path: Path) -> None:
    """
    Best-effort Boogie post-pass before invoking Ultimate.

    Motivation (WSL safety): some translated P4 programs emit quantified register
    initialization assumptions like:
      assume (forall i:bv32 :: reg[i] == 0bvW);
    Even when the register is only accessed at a small bounded set of indices,
    these quantifiers can cause Z3 to OOM during CFG/RCFG construction.

    The rewrite is semantics-preserving when we can infer a finite accessed
    index domain from explicit `assume` bounds and/or constant indices.
    """

    try:
        src = bpl_path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        print(f"[WARN] bpl optimize skipped (read failed): {e}")
        return

    before = src.count("forall i:bv32")
    if before <= 0:
        return

    lines = src.splitlines(keepends=True)
    try:
        _rewrite_forall_bv32_array_inits(lines)
    except Exception as e:
        print(f"[WARN] bpl optimize skipped (rewrite failed): {e}")
        return

    out = "".join(lines)
    if out == src:
        return

    after = out.count("forall i:bv32")
    try:
        bpl_path.write_text(out, encoding="utf-8")
    except Exception as e:
        print(f"[WARN] bpl optimize skipped (write failed): {e}")
        return

    print(f"[OPT] forall-init elimination: {before} -> {after} ({bpl_path.name})")


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
    return _manifest_certified_unsafe_data(data)


def _toolchain_includes_witnessprinter(toolchain: Path) -> bool:
    toolchain = resolve_ultimate_asset_path(toolchain)
    try:
        txt = toolchain.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return False
    return "de.uni_freiburg.informatik.ultimate.witnessprinter" in txt


def _run_one(
    *,
    job: _ComposeJob,
    p4b_bin: Optional[Path],
    max_env_inputs: bool,
    enable_slicing: bool,
    prune_env_inputs: bool,
    keep_control_seeds: bool,
    por_enabled: bool,
    por_guard_enabled: bool,
    boogie_harness: str,
    pipeline_two_stage: bool,
    max_steps: Optional[int],
    honor_spec_max_steps: bool,
    emit_reg_debug: bool,
    skip_duplicated_fail_fast_global_asserts: bool,
    ultimate: Optional[Path],
    toolchain: Path,
    witness_toolchain: Optional[Path],
    settings: Path,
    ultimate_async: bool,
    ultimate_timeout_seconds: int,
    resource_limits: bool,
    ultimate_xmx_gb: int,
    witness_rerun: bool,
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
        keep_control_seeds=keep_control_seeds,
        por_enabled=por_enabled,
        por_guard_enabled=por_guard_enabled,
        boogie_harness=boogie_harness,
        pipeline_two_stage=pipeline_two_stage,
        max_steps=max_steps,
        honor_spec_max_steps=honor_spec_max_steps,
        emit_reg_debug=emit_reg_debug,
        skip_duplicated_fail_fast_global_asserts=skip_duplicated_fail_fast_global_asserts,
    )
    print(f"[OK] bpl: {job.out_bpl}")

    # Post-pass optimizations (WSL safety / Ultimate robustness).
    _optimize_bpl_for_ultimate(job.out_bpl)

    if not ultimate:
        print("[NOTE] --ultimate not provided; skipping Ultimate run.")
        return 0

    # Give Ultimate a bit more time to shut down cleanly after the toolchain timeout.
    # Some toolchains need >60s to flush logs / finish witnessprinter output.
    os_timeout = ultimate_timeout_seconds + 300 if ultimate_timeout_seconds > 0 else 0
    # Keep Ultimate side effects (witnesses, temp files) under the per-run output dir.
    job.log_path.parent.mkdir(parents=True, exist_ok=True)
    res = run_ultimate(
        ultimate=ultimate,
        toolchain=toolchain,
        settings=settings,
        input_bpl=job.out_bpl,
        log_path=job.log_path,
        ultimate_home=job.ultimate_home,
        toolchain_timeout_seconds=ultimate_timeout_seconds if ultimate_timeout_seconds > 0 else None,
        os_timeout_seconds=os_timeout,
        cwd=job.log_path.parent,
        async_run=ultimate_async,
        resource_limits=resource_limits,
        launcher_xmx_gb=max(1, int(ultimate_xmx_gb)),
    )

    if ultimate_async:
        print(f"[RUN] Ultimate running in background (pid={res.pid}).")
        print(f"[LOG] {job.log_path}")
        return 0

    result_line = res.result_line

    if result_line:
        print(f"[RESULT] {result_line}")
        # Ultimate often exits with 0 for both SAFE and UNSAFE, so use the RESULT
        # marker to provide a meaningful CLI exit status.
        if _result_line_is_unsafe(result_line):
            print(f"[LOG] {job.log_path}")

            # Two-phase witness strategy: run the main verification with a *non-witness*
            # toolchain for speed/robustness, then (if UNSAFE) re-run with witnessprinter
            # enabled to produce an auditable counterexample artifact.
            if witness_rerun and witness_toolchain and witness_toolchain.exists() and witness_toolchain != toolchain:
                wlog = job.log_path.with_suffix(".witness.log")
                wres = run_ultimate(
                    ultimate=ultimate,
                    toolchain=witness_toolchain,
                    settings=settings,
                    input_bpl=job.out_bpl,
                    log_path=wlog,
                    ultimate_home=job.ultimate_home / "witness",
                    toolchain_timeout_seconds=ultimate_timeout_seconds if ultimate_timeout_seconds > 0 else None,
                    os_timeout_seconds=os_timeout,
                    cwd=wlog.parent,
                    async_run=False,
                    resource_limits=resource_limits,
                    launcher_xmx_gb=max(1, int(ultimate_xmx_gb)),
                )
                if wres.result_line:
                    print(f"[RESULT] {wres.result_line} (witness rerun)")
                print(f"[LOG] {wlog}")
            elif not witness_rerun:
                print("[NOTE] witness rerun disabled by --no-witness-rerun")
            return 1
        if _result_line_is_safe(result_line):
            print(f"[LOG] {job.log_path}")
            return 0
        print(f"[LOG] {job.log_path}")
        return res.returncode

    print("[RESULT] No RESULT line found; check log.")
    print(f"[LOG] {job.log_path}")
    return res.returncode


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
        "--no-slicing-control-seeds",
        action="store_true",
        help=(
            "Disable implicit forwarding/drop/clone/recirc control seeds in P4 slicing. "
            "This can significantly shrink single-switch models, but may be unsound for "
            "distributed/topology-sensitive properties."
        ),
    )
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
            "Optional bounded bug-finding/benchmark step limit. UNSAFE is sound; "
            "SAFE is only within the bound. Default: unbounded."
        ),
    )
    ap.add_argument(
        "--use-spec-max-steps",
        action="store_true",
        help=(
            "Use `global.max_steps` from the DSL spec as an explicit benchmark/debug bound. "
            "Default: ignore it and keep the model unbounded."
        ),
    )
    ap.add_argument(
        "--no-reg-debug",
        action="store_true",
        help="Disable per-pass register debug snapshots in the generated Boogie harness (can greatly reduce SMT load).",
    )
    ap.add_argument(
        "--skip-duplicated-fail-fast-global-asserts",
        action="store_true",
        help=(
            "When P4B duplicates an exact register-mirror global assertion at register write sites, "
            "omit the duplicate end-of-step harness assertion. Opt-in performance knob for large bounded checks."
        ),
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
        default=900,
        help=(
            "Ultimate toolchain timeout in seconds (default: 900). "
            "0 disables timeout (not recommended on WSL; can run indefinitely)."
        ),
    )
    ap.add_argument(
        "--ultimate-xmx-gb",
        type=int,
        default=4,
        help="Max Java heap for Ultimate in GB (WSL safety; default: 4).",
    )
    ap.add_argument(
        "--ultimate-home",
        default="",
        help="Override HOME for Ultimate (default: <out_dir>/ultimate-home)",
    )
    ap.add_argument(
        "--no-witness-rerun",
        action="store_true",
        help=(
            "After a main UNSAFE result, do not run the second witness-printer toolchain. "
            "Useful for short staged exploration when the main log is enough evidence."
        ),
    )
    ap.add_argument(
        "--toolchain",
        default="",
        help="Ultimate toolchain XML (default: prefer ReachSafety-Witness.xml when available)",
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
        default=0,
        help=(
            "Unroll steps for wraparound confirm. "
            "0 means auto (default): start from a small number of *rounds* (typically 3), "
            "and (by default) do not grow it further. "
            "Note: a round may expand to multiple scheduler steps under deterministic scheduling."
        ),
    )
    ap.add_argument(
        "--wraparound-max-confirm-unroll",
        type=int,
        default=0,
        help=(
            "Max unroll steps for wraparound confirm growth. "
            "0 (default) disables growth and runs CONFIRM once."
        ),
    )
    ap.add_argument(
        "--wraparound-max-iters",
        type=int,
        default=6,
        help="Max refinement iterations per wraparound target (default: 6).",
    )
    ap.add_argument(
        "--wraparound-closure-timeout-cap",
        type=int,
        default=0,
        help=(
            "Cap each wraparound closure_check attempt timeout (seconds). "
            "0 (default) disables capping and lets closure_check use the full "
            "--ultimate-timeout-seconds budget. "
            "Note: timeout-driven refinement is intentionally disabled; refinements "
            "only happen when closure_check produces a concrete counterexample (UNSAFE)."
        ),
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
    ap.add_argument(
        "--wraparound-cegar-mode",
        choices=["legacy_closure_assumes", "schedule_replay"],
        default="legacy_closure_assumes",
        help=(
            "Wraparound CEGAR implementation mode. "
            "schedule_replay is the paper-aligned ENTRY -> NEAR_WRAP -> CLOSURE loop; "
            "legacy_closure_assumes keeps the existing closure-only refinement path."
        ),
    )
    ap.add_argument(
        "--wraparound-stop-after",
        choices=["none", "entry", "near_wrap", "closure"],
        default="none",
        help=(
            "Debug/staged execution: stop the wraparound CEGAR pipeline after the selected stage "
            "and do not fall back to the ordinary GemCutter run. Intended for stage-by-stage testing."
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
    witness_toolchain: Optional[Path] = None
    if args.toolchain:
        toolchain = resolve_ultimate_asset_path(args.toolchain, root=root)
        # Best-effort: if the user-provided toolchain does NOT already include the witnessprinter,
        # pick up the in-repo witness toolchain for a second UNSAFE rerun.
        if not _toolchain_includes_witnessprinter(toolchain):
            cand_witness = ultimate_asset(root, "ReachSafety-Witness.xml")
            if cand_witness.exists():
                witness_toolchain = cand_witness.resolve()
    else:
        # Two-phase default: use the non-witness toolchain for the main run, and only
        # enable witnessprinter when we actually see UNSAFE.
        cand_nowitness = ultimate_asset(root, "ReachSafety.xml")
        cand_witness = ultimate_asset(root, "ReachSafety-Witness.xml")
        if cand_nowitness.exists():
            toolchain = cand_nowitness.resolve()
            witness_toolchain = cand_witness.resolve() if cand_witness.exists() else None
        elif cand_witness.exists():
            toolchain = cand_witness.resolve()
            witness_toolchain = None
        else:
            toolchain = (root / "ultimate" / "trunk" / "examples" / "concurrent" / "bpl" / "regression" / "ReachSafety.xml").resolve()
    if args.settings:
        settings = resolve_ultimate_asset_path(args.settings, root=root)
    else:
        # Default to a WSL-safe GemCutter-style profile.
        #
        # IMPORTANT: some profiles set Z3's `-memory:` to 8-12GB. On many WSL setups this
        # can OOM the whole VM even if Ultimate's JVM heap is small. Prefer the ~2GB Z3
        # profiles by default; users can opt into larger profiles via --settings.
        candidates = ultimate_assets(root, [
            # Low-memory (default) profiles.
            "ReachSafety-32bit-GemCutter-ALL.epf",
            "ReachSafety-32bit-GemCutter-ALL-no-por.epf",
            "ReachSafety-32bit-GemCutter-internal.epf",
            "ReachSafety-32bit-GemCutter-internal-no-por.epf",
            # Higher-memory fallbacks (use explicitly on machines that can handle it).
            "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf",
            "ReachSafety-32bit-GemCutter-ALL-8g.epf",
            "ReachSafety-32bit-GemCutter-ALL-12g.epf",
            "ReachSafety-32bit-BuchiAutomizer-12g.epf",
        ]) + [
            # Legacy path fallback.
            root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL.epf",
        ]
        settings = next((p for p in candidates if p.exists()), candidates[0])

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
    keep_control_seeds = not bool(args.no_slicing_control_seeds)
    por_enabled = args.por
    por_guard_enabled = not args.no_por_guard
    boogie_harness = args.boogie_harness
    pipeline_two_stage = not args.no_two_stage

    ultimate = Path(args.ultimate).resolve() if args.ultimate else find_default_ultimate()
    if ultimate:
        ultimate = ultimate.resolve()
        if not args.ultimate:
            print(f"[NOTE] Using default Ultimate: {ultimate}")
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

            confirm_unroll = int(args.wraparound_confirm_unroll)
            max_confirm_unroll = int(args.wraparound_max_confirm_unroll)
            if confirm_unroll <= 0:
                # Auto base for bug finding (round units, not raw scheduler steps).
                #
                # A "round" is later expanded by wraparound_cegis.py based on the inferred
                # deterministic scheduler period, so using spec.max_steps directly here
                # can overshoot (e.g., 10 steps with period=2 would become 20 unrolled steps).
                confirm_unroll = 3

            try:
                # Wraparound runs multiple Ultimate stages (ENTRY/CONFIRM/CLOSURE). A 0 timeout
                # can hang indefinitely and wastes iteration time; pick a conservative fallback.
                wrap_timeout_s = int(args.ultimate_timeout_seconds)
                if wrap_timeout_s <= 0:
                    wrap_timeout_s = 1200
                    print(f"[WRAP] note: --ultimate-timeout-seconds=0; using {wrap_timeout_s}s for wraparound stages")

                require_meta_step = (args.wraparound == "auto")
                manifests = run_wraparound_cegis_multi(
                    spec_path=spec_path,
                    out_dir=wrap_dir,
                    p4b_bin=p4b_bin,
                    ultimate=ultimate,
                    ultimate_xmx_gb=int(args.ultimate_xmx_gb),
                    timeout_seconds=wrap_timeout_s,
                    # 0 disables per-attempt capping; do not force it to >=1.
                    closure_timeout_cap_seconds=max(0, int(args.wraparound_closure_timeout_cap)),
                    resource_limits=not args.no_resource_limits,
                    enable_slicing=enable_slicing,
                    pipeline_two_stage=pipeline_two_stage,
                    confirm_unroll=confirm_unroll,
                    max_confirm_unroll=max_confirm_unroll,
                    max_iters=int(args.wraparound_max_iters),
                    stage_order=str(args.wraparound_stage_order),
                    max_targets=int(args.wraparound_max_targets),
                    require_meta_step_for_global_asserts=require_meta_step,
                    emit_reg_debug=not args.no_reg_debug,
                    cegar_mode=str(args.wraparound_cegar_mode),
                    stop_after=str(args.wraparound_stop_after),
                )
            except Exception as e:
                if args.wraparound == "force":
                    raise
                print(f"[WRAP] skip: wraparound CEGIS failed ({type(e).__name__}: {e})")
                if str(args.wraparound_stop_after) != "none":
                    return 2
                manifests = []

            if str(args.wraparound_stop_after) != "none":
                for mp in manifests:
                    print(f"[WRAP] STOP-AFTER {args.wraparound_stop_after}: {mp}")
                if not manifests:
                    print(f"[WRAP] STOP-AFTER {args.wraparound_stop_after}: no wraparound candidates")
                return 0

            for mp in manifests:
                if _wraparound_manifest_certified_unsafe(mp):
                    print(f"[WRAP] CERTIFIED UNSAFE: {mp}")
                    try:
                        from dslc.bench.validate_counterexample import validate_wraparound_manifest

                        _ok, _msg = validate_wraparound_manifest(mp)
                        tag = "[CEX]" if _ok else "[CEX-WARN]"
                        print(f"{tag} {_msg}")
                    except Exception as e:
                        print(f"[CEX-WARN] wraparound manifest validation failed ({type(e).__name__}: {e})")
                    return 1

        if ultimate and not args.ultimate_async and int(args.ultimate_timeout_seconds) <= 0:
            print("[WARN] --ultimate-timeout-seconds=0 disables timeouts; runs may take arbitrarily long.")

        rc = _run_one(
            job=job,
            p4b_bin=p4b_bin,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            keep_control_seeds=keep_control_seeds,
            por_enabled=por_enabled,
            por_guard_enabled=por_guard_enabled,
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
            max_steps=args.max_steps,
            honor_spec_max_steps=args.use_spec_max_steps,
            emit_reg_debug=not args.no_reg_debug,
            skip_duplicated_fail_fast_global_asserts=bool(args.skip_duplicated_fail_fast_global_asserts),
            ultimate=ultimate,
            toolchain=toolchain,
            witness_toolchain=witness_toolchain,
            settings=settings,
            ultimate_async=args.ultimate_async,
            ultimate_timeout_seconds=args.ultimate_timeout_seconds,
            resource_limits=not args.no_resource_limits,
            ultimate_xmx_gb=int(args.ultimate_xmx_gb),
            witness_rerun=not bool(args.no_witness_rerun),
        )
        if rc == 1:
            # Best-effort witness sanity classification: distinguish "DSL global assert violated"
            # vs "some internal assert violated". This is a regression aid; it does not change rc.
            try:
                from dslc.bench.validate_counterexample import summarize_witness

                summ = summarize_witness(out_dir=job.out_bpl.parent)
                tag = "[CEX]" if summ.ok else "[CEX-WARN]"
                print(f"{tag} {summ.kind}: {summ.details}")
            except Exception as e:
                print(f"[CEX-WARN] witness summary failed ({type(e).__name__}: {e})")
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
                keep_control_seeds=keep_control_seeds,
                por_enabled=por_enabled,
                por_guard_enabled=por_guard_enabled,
                boogie_harness=boogie_harness,
                pipeline_two_stage=pipeline_two_stage,
                max_steps=args.max_steps,
                honor_spec_max_steps=args.use_spec_max_steps,
                emit_reg_debug=not args.no_reg_debug,
                skip_duplicated_fail_fast_global_asserts=bool(args.skip_duplicated_fail_fast_global_asserts),
                ultimate=ultimate,
                toolchain=toolchain,
                witness_toolchain=witness_toolchain,
                settings=settings,
                ultimate_async=args.ultimate_async,
                ultimate_timeout_seconds=args.ultimate_timeout_seconds,
                resource_limits=not args.no_resource_limits,
                ultimate_xmx_gb=int(args.ultimate_xmx_gb),
                witness_rerun=not bool(args.no_witness_rerun),
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
