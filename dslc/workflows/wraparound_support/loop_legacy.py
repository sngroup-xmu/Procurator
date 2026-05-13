from __future__ import annotations

import re
import time
from pathlib import Path
from typing import Dict, Optional

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.speclang.parse import parse_model
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text
from dslc.transform.wraparound_analyze import _infer_deterministic_scheduler_period
from dslc.toolchain.ultimate_witness import find_latest_graphml_witness
from dslc.workflows.wraparound_cegis import (
    CegisAttemptArtifacts,
    CegisAttemptConfig,
    CegisAttemptRecord,
    StageRunner,
    WraparoundCegarMode,
    WraparoundCegisError,
    WraparoundStopAfter,
    _confirm_unroll_schedule,
    _dynamic_index_fallback_diagnostic,
    _dropped_stable_substitutions_note,
    _index_expr_undeclared_callee_deps,
    _index_expr_global_deps,
    _index_expr_unresolved_value_deps,
    _sanitize_candidate_stable_substitutions,
    _undeclared_index_callee_fallback_diagnostic,
    _unresolved_index_fallback_diagnostic,
    _write_manifest,
)
from dslc.workflows.wraparound_support.refinement import (
    _find_latest_graphml_witness_since,
    _select_refinement_assumes_from_witness_diff,
    _synthesize_refinement_assumes_from_witness,
)
from dslc.workflows.wraparound_support.results import _toolchain_has_witnessprinter
from dslc.workflows.wraparound_support.schedule.stable_projection import stable_substitution_env_shape_assumes
from dslc.workflows.wraparound_support.stage_text import _unroll_confirm_like_mainprocedure


def _run_cegis_loop(
    *,
    spec_path: Path,
    spec_text: str,
    base_bpl: Path,
    base_text: str,
    out_dir: Path,
    work_dir: Path,
    candidate: WraparoundCandidate,
    partition_ports: Dict[str, int],
    timeout_seconds: int,
    closure_timeout_cap_seconds: int,
    resource_limits: bool,
    confirm_unroll: int,
    max_confirm_unroll: int,
    max_iters: int,
    enable_env_completion_refinement: bool,
    runner: StageRunner,
    toolchain_nowitness: Path,
    toolchain_witness: Path,
    witness_settings: Path,
    closure_toolchain: Path,
    settings: Path,
    closure_settings: Path,
    confirm_settings_fallback: Optional[Path] = None,
    stage_order: str,
    stop_after: str = WraparoundStopAfter.NONE.value,
) -> Path:
    """
    Core iterative loop (unit-testable via a fake StageRunner).
    """

    stop_after = str(stop_after or WraparoundStopAfter.NONE.value)

    cand = candidate
    cand, dropped_stable_substitutions = _sanitize_candidate_stable_substitutions(candidate=cand, base_text=base_text)
    det_period = _infer_deterministic_scheduler_period(base_text.splitlines())

    index_deps = _index_expr_global_deps(index_expr=cand.index_expr, base_text=base_text)
    if index_deps:
        return _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=[],
            cegar_mode=WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
            certified=False,
            diagnostic=_dynamic_index_fallback_diagnostic(index_deps),
        )
    unresolved_index_deps = _index_expr_unresolved_value_deps(index_expr=cand.index_expr, base_text=base_text)
    if unresolved_index_deps:
        return _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=[],
            cegar_mode=WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
            certified=False,
            diagnostic=_unresolved_index_fallback_diagnostic(unresolved_index_deps),
        )
    undeclared_callee_deps = _index_expr_undeclared_callee_deps(index_expr=cand.index_expr, base_text=base_text)
    if undeclared_callee_deps:
        return _write_manifest(
            out_dir=out_dir,
            spec_path=spec_path,
            base_bpl=base_bpl,
            work_dir=work_dir,
            cand=cand,
            attempts=[],
            cegar_mode=WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
            certified=False,
            diagnostic=_undeclared_index_callee_fallback_diagnostic(undeclared_callee_deps),
        )

    try:
        spec_model = parse_model(spec_text)
    except Exception:
        # Unit tests may call `_run_cegis_loop` with dummy/empty spec text.
        # Env-completion refinement is optional; fall back to an empty model.
        from dslc.speclang.model import SpecModel

        spec_model = SpecModel()

    pump_reg = cand.pump_reg
    accel_regs = cand.accel_regs

    index_expr = cand.index_expr
    index_value = cand.index_value if cand.index_value is not None else 0
    env_shape_assumes = tuple(stable_substitution_env_shape_assumes(candidate=cand))
    # Conditional existence/profile assumptions synthesized by CEGIS refinements.
    extra_assumes: List[str] = []
    env_completion_done = False
    witness_profile_done = False
    # Do not globally "attempt only once": witness extraction can fail spuriously
    # (e.g., toolchain timeout before witnessprinter) or produce no useful env
    # constraints in early iterations. Allow a small number of retries across
    # refinements so CEGIS can make progress.
    witness_profile_attempts = 0
    # When CONFIRM times out, prefer mining the already-known-reachable ENTRY trace
    # (cheap, UNSAFE) before running ENABLE_CHECK (potentially expensive).
    entry_witness_attempts = 0
    # Once CONFIRM is UNSAFE, do not re-run it as part of refinement. Instead,
    # keep the concrete counterexample fixed and only refine the CLOSURE proof
    # obligation (witness-seeded).
    seed_confirm_res: Optional[StageRunResult] = None
    seed_confirm_bpl: Optional[Path] = None
    seed_confirm_log: Optional[Path] = None
    seed_confirm_unroll: Optional[int] = None
    # Cached GraphML text for the seeded CONFIRM witness (the one we certify).
    # This is used for witness-diff refinement in the CLOSURE stage.
    seed_confirm_witness_text: Optional[str] = None
    # Once we have a concrete CONFIRM counterexample, we also freeze the ENTRY reachability
    # witness that establishes the pump cutpoint is reachable. Subsequent refinements must
    # not re-run ENTRY under refined assumptions; refinement is closure-only.
    seed_entry_res: Optional[StageRunResult] = None
    seed_entry_bpl: Optional[Path] = None
    seed_entry_log: Optional[Path] = None

    def _sanitize_local(name: str) -> str:
        # Keep consistent with dslc/transform/wraparound_common.py
        return re.sub(r"[^A-Za-z0-9_]", "_", name)

    def _closure_failed_proc_name(log_text: str) -> Optional[str]:
        """
        Best-effort extraction of which closure assert wrapper failed.

        With per-assert wrappers, Ultimate typically logs lines like:
          "=== Iteration k === Targeting __wraparound_closure_assert_proj_xxxASSERT_VIOLATIONASSERT ==="
        """

        m = re.search(r"Targeting\s+(?P<name>__wraparound_closure_assert_[A-Za-z0-9_]+)", log_text)
        if m:
            return m.group("name")
        # Fallback: some toolchains mention the error location without "Targeting".
        m = re.search(r"(?P<name>__wraparound_closure_assert_[A-Za-z0-9_]+)", log_text)
        if m:
            return m.group("name")
        return None

    def _extract_equality_parts(expr: str) -> Optional[Tuple[str, str]]:
        """
        Extract `(lhs, rhs)` from a (possibly parenthesized) equality `lhs == rhs`.

        We accept:
          - raw:              "x == 1bv1"
          - wrapped:          "(x == 1bv1)"
          - assume wrapper:   "assume(x == 1bv1)" / "assume x == 1bv1"

        This is used to avoid adding conflicting shape constraints across refinements.
        """

        s = str(expr).strip()
        if not s:
            return None
        if s.startswith("assume(") and s.endswith(")"):
            s = s[len("assume(") : -1].strip()
        if s.startswith("assume "):
            s = s[len("assume ") :].strip()
        if s.endswith(";"):
            s = s[:-1].strip()
        while s.startswith("(") and s.endswith(")"):
            # Strip a single layer of wrapping parens if it encloses the whole string.
            depth = 0
            wraps_entire = True
            for i, ch in enumerate(s):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0 and i != len(s) - 1:
                        wraps_entire = False
                        break
            if wraps_entire and depth == 0:
                s = s[1:-1].strip()
                continue
            break
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*==\s*(.+)$", s)
        if not m:
            return None
        lhs = m.group(1).strip()
        rhs = m.group(2).strip()
        if not lhs or not rhs:
            return None
        return lhs, rhs

    # Track which LHS variables we already pinned via `lhs == rhs` constraints.
    #
    # We keep a priority so that later refinements can override weak under-approximations
    # (env-completion) with stronger, witness-derived shape constraints.
    #   - 3: hard pins from control-plane entries / fixed templates
    #   - 2: witness-derived pins (ENTRY/ENABLE/CONFIRM witness)
    #   - 1: env-completion under-approx pins
    pinned_eq: Dict[str, Tuple[str, str, int]] = {}  # lhs -> (rhs, expr, priority)

    def _add_assume(expr: str, *, priority: int = 2) -> bool:
        """
        Add an assume expression if it is new, or replace an existing weaker equality
        on the same LHS.
        """

        expr = str(expr).strip()
        if not expr:
            return False
        if expr in extra_assumes:
            return False

        parts = _extract_equality_parts(expr)
        if parts is None:
            # Non-equality constraint; treat as a pure set element.
            extra_assumes.append(expr)
            return True

        lhs, rhs = parts
        prev = pinned_eq.get(lhs)
        if prev is None:
            pinned_eq[lhs] = (rhs, expr, int(priority))
            extra_assumes.append(expr)
            return True

        prev_rhs, prev_expr, prev_pri = prev
        if rhs == prev_rhs:
            # Already pinned to the same RHS (possibly with different parentheses formatting).
            return False

        if int(priority) <= int(prev_pri):
            # Do not override stronger (or equal-strength) pins.
            return False

        # Override a weaker pin.
        try:
            extra_assumes.remove(prev_expr)
        except ValueError:
            pass
        pinned_eq[lhs] = (rhs, expr, int(priority))
        extra_assumes.append(expr)
        return True

    proj_vars = list(cand.proj_vars)

    cutpoint_cond = cand.cutpoint_cond
    step_op = cand.step_op
    step_delta = int(cand.step_delta) if cand.step_delta is not None else 1

    # Projection variables are a *certificate choice*.
    #
    # We keep `procurator_phase` mandatory because our sequential harness relies on it
    # for deterministic scheduling; without it, closure/pump reasoning becomes unstable.
    #
    # Queue counters (e.g., `<node>_inbox_count`) can help make the pump proof stronger,
    # but they are not strictly required for *bug finding* soundness: if closure cannot be
    # certified with them, we allow CEGIS to drop them and search for a weaker (still sound)
    # summary. This is important for benchmarks like NetChain where proving queue stability
    # can dominate runtime.
    mandatory_proj = ["procurator_phase"]

    attempts: List[CegisAttemptRecord] = []
    base_proj_set = set(proj_vars)
    base_index_expr = index_expr
    base_index_value = index_value

    for it in range(max_iters):
        # Timeout policy:
        # - If closure_timeout_cap_seconds == 0 (default), do not cap: run closure_check
        #   with the full timeout budget to avoid interrupting a proof attempt.
        # - If a cap is provided (>0), we still let the *final* iteration use the full
        #   timeout as a last-chance certification run.
        cap = int(closure_timeout_cap_seconds)
        if cap <= 0:
            closure_timeout_this_attempt = int(timeout_seconds)
        else:
            closure_timeout_this_attempt = min(int(timeout_seconds), max(1, cap))
            if it + 1 >= max_iters:
                closure_timeout_this_attempt = int(timeout_seconds)

        notes: List[str] = []
        if it > 0:
            notes.append(f"refine_iter={it}")
        if det_period is not None:
            notes.append(f"deterministic_scheduler_period={det_period}")
        notes.append(f"closure_timeout={closure_timeout_this_attempt}")
        if base_index_expr is not None and index_expr is None:
            notes.append("index_expr=const")
        if int(index_value) != int(base_index_value):
            notes.append(f"index_value={index_value}")
        if env_shape_assumes:
            notes.append("candidate_stable_env_shape=" + str(len(env_shape_assumes)))
        if dropped_stable_substitutions:
            notes.append("dropped_stable_env_shape=" + str(len(dropped_stable_substitutions)))
            notes.append(_dropped_stable_substitutions_note(dropped_stable_substitutions))
        dropped_proj = sorted(base_proj_set.difference(set(proj_vars)))
        if dropped_proj:
            # Keep it stable and grep-friendly for manifests.
            notes.append("drop_proj_vars=" + ",".join(dropped_proj))

        cfg = CegisAttemptConfig(
            attempt=it,
            pump_reg=pump_reg,
            accel_regs=accel_regs,
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=tuple(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            closure_assumes=tuple(extra_assumes),
            notes=tuple(notes),
        )

        stem = f"{spec_path.stem}.cegis.{it:02d}"
        entry_bpl = out_dir / f"{stem}.entry_check.bpl"
        closure_bpl = out_dir / f"{stem}.closure_check.bpl"
        entry_log = out_dir / f"{stem}.entry_check.log"
        closure_log = out_dir / f"{stem}.closure_check.log"

        entry_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            # ENTRY is a pure reachability check; do not mix in refinement assumptions.
            extra_assumes=(),
        )
        entry_bpl.write_text(entry_txt, encoding="utf-8")

        closure_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            extra_assumes=(*env_shape_assumes, *extra_assumes),
        )
        closure_bpl.write_text(closure_txt, encoding="utf-8")

        # Always emit a default CONFIRM instance so that artifacts are well-defined even
        # if we exit early after ENTRY (e.g., ENTRY is SAFE/UNKNOWN).
        #
        # For entry_confirm_closure we may emit additional confirm instances with a larger
        # unroll bound later; those are recorded as separate attempts in the manifest.
        confirm_bpl = out_dir / f"{stem}.confirm.unroll{confirm_unroll}.bpl"
        confirm_log = out_dir / f"{stem}.confirm.unroll{confirm_unroll}.log"
        confirm_txt0 = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CONFIRM,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            # CONFIRM is existential bug finding; refinements are closure-only.
            extra_assumes=env_shape_assumes,
        )
        confirm_txt0, _confirm_steps0 = _unroll_confirm_like_mainprocedure(
            bpl_text=confirm_txt0, requested_steps=confirm_unroll, deterministic_period=det_period
        )
        confirm_bpl.write_text(confirm_txt0, encoding="utf-8")

        artifacts = CegisAttemptArtifacts(
            entry_bpl=str(entry_bpl),
            closure_bpl=str(closure_bpl),
            confirm_bpl=str(confirm_bpl),
            entry_log=str(entry_log),
            closure_log=str(closure_log),
            confirm_log=str(confirm_log),
        )

        ultimate_home_root = out_dir / "ultimate-home"

        if seed_confirm_res is None:
            # ENTRY_CHECK is a pure reachability gate: is the deterministic round executable?
            # We run it with the *non-witness* toolchain to avoid witness-printer crashes on SAFE.
            entry_res = runner.run(
                stage="entry_check",
                input_bpl=entry_bpl,
                log_path=entry_log,
                ultimate_home=ultimate_home_root / stem / "entry",
                toolchain=toolchain_nowitness,
                settings=settings,
                timeout_seconds=timeout_seconds,
                resource_limits=resource_limits,
            )

            if not entry_res.is_unsafe:
                attempts.append(
                    CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=None, confirm=None)
                )
                _write_manifest(
                    out_dir=out_dir,
                    spec_path=spec_path,
                    base_bpl=base_bpl,
                    work_dir=work_dir,
                    cand=cand,
                    attempts=attempts,
                )
                break

            # Persist a reproducible "ENTRY reached" record early.
            #
            # Rationale: ENTRY is usually fast, while CONFIRM/CLOSURE may take minutes.
            # If the user interrupts mid-run, we still want a manifest describing the
            # attempted target and the generated artifacts.
            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=None, confirm=None))
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
            )
            if stop_after == WraparoundStopAfter.ENTRY.value:
                break
        else:
            # Closure-only refinement mode: do not rerun ENTRY under refined assumptions.
            if seed_entry_res is None:
                raise WraparoundCegisError("internal error: CONFIRM is seeded but ENTRY is not seeded")
            entry_res = seed_entry_res

        if stage_order not in {"entry_closure_confirm", "entry_confirm_closure"}:
            raise WraparoundCegisError(f"unknown stage_order: {stage_order}")

        closure_res: Optional[StageRunResult] = None
        confirm_res: Optional[StageRunResult] = None

        if stage_order == "entry_closure_confirm":
            closure_res = runner.run(
                stage="closure_check",
                input_bpl=closure_bpl,
                log_path=closure_log,
                ultimate_home=ultimate_home_root / stem / "closure",
                toolchain=closure_toolchain,
                settings=closure_settings,
                timeout_seconds=closure_timeout_this_attempt,
                resource_limits=resource_limits,
            )
            if closure_res.is_safe:
                # Legacy ordering: we already proved closure, so we do not need a witness.
                # Run confirm with the non-witness toolchain to avoid witness printer crashes.
                confirm_res = runner.run(
                    stage="confirm",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / "confirm",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                attempts.append(
                    CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=confirm_res)
                )
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )
                break

            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=None))
            _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)

        else:
            # entry_confirm_closure (default): treat CONFIRM as an existential bug-finding query.
            #
            # Once CONFIRM is UNSAFE, refinements are only for CLOSURE (witness-seeded).
            # Do NOT rerun CONFIRM under refined assumptions; that would turn CONFIRM
            # into part of the synthesis loop and can bias/lose the original witness.
            if seed_confirm_res is not None:
                # Closure-only refinement mode (seeded by an earlier CONFIRM counterexample).
                confirm_res = seed_confirm_res
                seed_bpl = seed_confirm_bpl if seed_confirm_bpl is not None else confirm_bpl
                seed_log = seed_confirm_log if seed_confirm_log is not None else confirm_log
                seed_unroll = seed_confirm_unroll if seed_confirm_unroll is not None else int(confirm_unroll)

                # Ensure the manifest points at the concrete CONFIRM instance that produced
                # the counterexample we are certifying.
                artifacts = CegisAttemptArtifacts(
                    entry_bpl=str(seed_entry_bpl) if seed_entry_bpl is not None else artifacts.entry_bpl,
                    closure_bpl=artifacts.closure_bpl,
                    confirm_bpl=str(seed_bpl),
                    entry_log=str(seed_entry_log) if seed_entry_log is not None else artifacts.entry_log,
                    closure_log=artifacts.closure_log,
                    confirm_log=str(seed_log),
                    closure_log_retry=artifacts.closure_log_retry,
                    enable_bpl=artifacts.enable_bpl,
                    enable_log=artifacts.enable_log,
                )
                cfg_i = CegisAttemptConfig(
                    attempt=cfg.attempt,
                    pump_reg=cfg.pump_reg,
                    accel_regs=cfg.accel_regs,
                    index_value=cfg.index_value,
                    index_expr=cfg.index_expr,
                    proj_vars=cfg.proj_vars,
                    cutpoint_cond=cfg.cutpoint_cond,
                    step_op=cfg.step_op,
                    step_delta=cfg.step_delta,
                    closure_assumes=tuple(extra_assumes),
                    notes=tuple(list(cfg.notes) + ["confirm_seeded=true", f"confirm_seed_unroll={seed_unroll}"]),
                )

                closure_res = runner.run(
                    stage="closure_check",
                    input_bpl=closure_bpl,
                    log_path=closure_log,
                    ultimate_home=ultimate_home_root / stem / "closure",
                    toolchain=closure_toolchain,
                    settings=closure_settings,
                    timeout_seconds=closure_timeout_this_attempt,
                    resource_limits=resource_limits,
                )
                closure_retry_res: Optional[StageRunResult] = None
                closure_res_eff = closure_res

                # If the user provided a cap (< full timeout) and we hit the cap, retry once
                # with the full timeout budget. Do not refine on timeout: without a concrete
                # counterexample, there's no evidence to guide synthesis.
                if (
                    closure_res.is_unknown
                    and closure_res.timed_out
                    and int(closure_timeout_this_attempt) < int(timeout_seconds)
                ):
                    closure_log_retry = out_dir / f"{stem}.closure_check.retry.log"
                    closure_retry_res = runner.run(
                        stage="closure_check.retry",
                        input_bpl=closure_bpl,
                        log_path=closure_log_retry,
                        ultimate_home=ultimate_home_root / stem / "closure.retry",
                        toolchain=closure_toolchain,
                        settings=closure_settings,
                        timeout_seconds=timeout_seconds,
                        resource_limits=resource_limits,
                    )
                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=artifacts.entry_bpl,
                        closure_bpl=artifacts.closure_bpl,
                        confirm_bpl=artifacts.confirm_bpl,
                        entry_log=artifacts.entry_log,
                        closure_log=artifacts.closure_log,
                        confirm_log=artifacts.confirm_log,
                        closure_log_retry=str(closure_log_retry),
                        enable_bpl=artifacts.enable_bpl,
                        enable_log=artifacts.enable_log,
                    )
                    closure_res_eff = closure_retry_res

                attempts.append(
                    CegisAttemptRecord(
                        cfg=cfg_i,
                        artifacts=artifacts,
                        entry=entry_res,
                        closure=closure_res,
                        closure_retry=closure_retry_res,
                        confirm=confirm_res,
                    )
                )
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )

                if closure_res_eff.is_safe:
                    break

                if closure_res_eff.is_unknown:
                    # No evidence to refine; stop and let the caller increase timeouts or
                    # optimize the spec/encoding case-by-case.
                    break

                # Witness-seeded refinement for closure (P2C-aware shape constraints).
                #
                # IMPORTANT: do not add generic env-completion under-approximations here;
                # closure refinements must preserve the already-found CONFIRM witness.
                added_any = False
                witness_timeout_s = min(timeout_seconds, max(120, min(300, int(closure_timeout_this_attempt))))
                # Cache the seeded CONFIRM witness once. We use it both to pin down a stable
                # input "shape" and to drive CEGAR-style refinement against CLOSURE counterexamples.
                if seed_confirm_witness_text is None and (witness_profile_attempts < 3) and (it + 1 < max_iters):
                    witness_profile_attempts += 1
                    witness_log = out_dir / f"{stem}.confirm_seed.witness.unroll{seed_unroll}.log"
                    t0 = time.time()
                    _ = runner.run(
                        stage=f"confirm.witness.unroll{seed_unroll}",
                        input_bpl=seed_bpl,
                        log_path=witness_log,
                        ultimate_home=ultimate_home_root / stem / f"confirm.unroll{seed_unroll}.witness.seed",
                        toolchain=toolchain_witness,
                        settings=witness_settings,
                        timeout_seconds=witness_timeout_s,
                        resource_limits=resource_limits,
                    )
                    witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                        work_dir=out_dir
                    )
                    if witness:
                        try:
                            wtxt = witness.read_text(encoding="utf-8", errors="replace")
                            seed_confirm_witness_text = wtxt
                            new_assumes = _synthesize_refinement_assumes_from_witness(
                                witness_text=wtxt,
                                base_bpl_text=base_text,
                                candidate=cand,
                                spec_model=spec_model,
                            )
                        except Exception:
                            new_assumes = []
                        for aexpr in new_assumes:
                            if _add_assume(aexpr, priority=2):
                                added_any = True
                        witness_profile_done = True

                # If CLOSURE is UNSAFE, refine using a witness diff:
                # add assumptions that match the seeded CONFIRM witness but disagree with
                # the CLOSURE counterexample witness, thereby blocking the non-closure behavior.
                if (
                    (not added_any)
                    and closure_res_eff.is_unsafe
                    and seed_confirm_witness_text is not None
                    and (it + 1 < max_iters)
                ):
                    cex_log = out_dir / f"{stem}.closure_check.witness.it{it}.log"
                    t1 = time.time()
                    _ = runner.run(
                        stage=f"closure_check.witness.it{it}",
                        input_bpl=closure_bpl,
                        log_path=cex_log,
                        ultimate_home=ultimate_home_root / stem / f"closure.witness.it{it}",
                        toolchain=toolchain_witness,
                        settings=witness_settings,
                        timeout_seconds=witness_timeout_s,
                        resource_limits=resource_limits,
                    )
                    cex = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t1) or find_latest_graphml_witness(
                        work_dir=out_dir
                    )
                    if cex:
                        try:
                            cex_txt = cex.read_text(encoding="utf-8", errors="replace")
                            diff_assumes = _select_refinement_assumes_from_witness_diff(
                                confirm_witness_text=seed_confirm_witness_text,
                                cex_witness_text=cex_txt,
                                base_bpl_text=base_text,
                                candidate=cand,
                                spec_model=spec_model,
                                max_new=max(1, min(8, 2 + it * 2)),
                            )
                        except Exception:
                            diff_assumes = []
                        for aexpr in diff_assumes:
                            if _add_assume(aexpr, priority=2):
                                added_any = True

                if added_any:
                    # We refined the closure obligation using witness evidence; rerun CLOSURE.
                    # Do not heuristically weaken the certificate (e.g., by dropping proj vars)
                    # as that makes the algorithm harder to reason about and can bias results.
                    continue

            else:
                # We do not yet have a CONFIRM counterexample; search for one.
                need_retry = False
                certified = False
                enable_refine_tried = False

                # CONFIRM is an existential bug-finding query; by default we run it once
                # (no unroll growth). Callers can opt into a small growth schedule by
                # passing a larger `max_confirm_unroll`.
                max_unroll = int(max_confirm_unroll) if int(max_confirm_unroll) > 0 else int(confirm_unroll)
                unroll_schedule = _confirm_unroll_schedule(base=confirm_unroll, max_unroll=max_unroll)
                for pos, unroll in enumerate(unroll_schedule):
                    confirm_bpl = out_dir / f"{stem}.confirm.unroll{unroll}.bpl"
                    confirm_log = out_dir / f"{stem}.confirm.unroll{unroll}.log"

                    confirm_txt = instrument_bpl_text(
                        bpl_text=base_text,
                        stage=WraparoundStage.CONFIRM,
                        pump_reg=pump_reg,
                        accel_regs=list(accel_regs),
                        index_value=index_value,
                        index_expr=index_expr,
                        proj_vars=list(proj_vars),
                        cutpoint_cond=cutpoint_cond,
                        step_op=step_op,
                        step_delta=step_delta,
                        # CONFIRM is existential bug finding; refinements are closure-only.
                        extra_assumes=env_shape_assumes,
                    )
                    confirm_txt, confirm_steps = _unroll_confirm_like_mainprocedure(
                        bpl_text=confirm_txt, requested_steps=unroll, deterministic_period=det_period
                    )
                    confirm_bpl.write_text(confirm_txt, encoding="utf-8")

                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=str(entry_bpl),
                        closure_bpl=str(closure_bpl),
                        confirm_bpl=str(confirm_bpl),
                        entry_log=str(entry_log),
                        closure_log=str(closure_log),
                        confirm_log=str(confirm_log),
                    )

                    notes = list(cfg.notes) + [f"confirm_unroll={unroll}"] + (
                        [f"confirm_steps={confirm_steps}"] if confirm_steps != int(unroll) else []
                    )

                    t0 = time.time()
                    confirm_res = runner.run(
                        stage="confirm",
                        input_bpl=confirm_bpl,
                        log_path=confirm_log,
                        ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}",
                        toolchain=toolchain_nowitness,
                        settings=settings,
                        timeout_seconds=timeout_seconds,
                        resource_limits=resource_limits,
                    )

                    if (
                        confirm_res.is_unknown
                        and confirm_res.timed_out
                        and confirm_settings_fallback is not None
                        and confirm_settings_fallback != settings
                    ):
                        confirm_res2 = runner.run(
                            stage="confirm",
                            input_bpl=confirm_bpl,
                            log_path=confirm_log,
                            ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.noz3timeout",
                            toolchain=toolchain_nowitness,
                            settings=confirm_settings_fallback,
                            timeout_seconds=timeout_seconds,
                            resource_limits=resource_limits,
                        )
                        if not confirm_res2.is_unknown:
                            confirm_res = confirm_res2
                            notes.append(f"confirm_settings={confirm_settings_fallback.name}")

                    # If CONFIRM already ran with a witness-enabled toolchain, reuse its witness
                    # instead of re-running a separate `confirm.witness` task later.
                    if (
                        confirm_res.is_unsafe
                        and seed_confirm_witness_text is None
                        and _toolchain_has_witnessprinter(toolchain_nowitness)
                    ):
                        witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                            work_dir=out_dir
                        )
                        if witness:
                            try:
                                wtxt = witness.read_text(encoding="utf-8", errors="replace")
                            except Exception:
                                wtxt = None
                            if wtxt is not None:
                                seed_confirm_witness_text = wtxt
                                # Seed closure assumptions immediately from the CONFIRM witness:
                                # closure_check is a proof obligation and should not waste time
                                # considering packet shapes that are irrelevant to the concrete
                                # CONFIRM counterexample we are trying to certify.
                                #
                                # NOTE: This does *not* affect ENTRY/CONFIRM themselves; those
                                # stages always run under the original environment. The seeded
                                # assumptions are injected into CLOSURE only.
                                before = len(extra_assumes)
                                try:
                                    seed_assumes = _synthesize_refinement_assumes_from_witness(
                                        witness_text=wtxt,
                                        base_bpl_text=base_text,
                                        candidate=cand,
                                        spec_model=spec_model,
                                    )
                                except Exception:
                                    seed_assumes = []
                                for aexpr in seed_assumes:
                                    _add_assume(aexpr, priority=2)
                                added = len(extra_assumes) - before
                                if added > 0:
                                    notes.append(f"closure_seed_assumes={added}")
                                witness_profile_done = True

                    cfg_i = CegisAttemptConfig(
                        attempt=cfg.attempt,
                        pump_reg=cfg.pump_reg,
                        accel_regs=cfg.accel_regs,
                        index_value=cfg.index_value,
                        index_expr=cfg.index_expr,
                        proj_vars=cfg.proj_vars,
                        cutpoint_cond=cfg.cutpoint_cond,
                        step_op=cfg.step_op,
                        step_delta=cfg.step_delta,
                        closure_assumes=tuple(extra_assumes),
                        notes=tuple(notes),
                    )

                    if confirm_res.is_unknown:
                        attempts.append(
                            CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                        )
                        _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )
                        # CONFIRM is existential bug finding. We do not CEGIS-refine ENTRY/CONFIRM;
                        # closure refinement is seeded by a concrete CONFIRM witness.
                        if pos == len(unroll_schedule) - 1:
                            break
                        continue

                    if not confirm_res.is_unsafe:
                        attempts.append(
                            CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                        )
                        _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )
                        continue

                    # CONFIRM found a bug. Seed it and certify via CLOSURE.
                    seed_confirm_res = confirm_res
                    seed_confirm_bpl = confirm_bpl
                    seed_confirm_log = confirm_log
                    seed_confirm_unroll = int(unroll)
                    seed_entry_res = entry_res
                    seed_entry_bpl = entry_bpl
                    seed_entry_log = entry_log

                    attempts.append(
                        CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                    )
                    _write_manifest(
                        out_dir=out_dir,
                        spec_path=spec_path,
                        base_bpl=base_bpl,
                        work_dir=work_dir,
                        cand=cand,
                        attempts=attempts,
                    )

                    # If we seeded any closure assumptions from the CONFIRM witness, we must
                    # regenerate the closure_check BPL for this attempt. (It was emitted at
                    # the top of the outer loop before we had a witness.)
                    if extra_assumes:
                        closure_txt = instrument_bpl_text(
                            bpl_text=base_text,
                            stage=WraparoundStage.CLOSURE_CHECK,
                            pump_reg=pump_reg,
                            accel_regs=list(accel_regs),
                            index_value=index_value,
                            index_expr=index_expr,
                            proj_vars=list(proj_vars),
                            cutpoint_cond=cutpoint_cond,
                            step_op=step_op,
                            step_delta=step_delta,
                    extra_assumes=(*env_shape_assumes, *extra_assumes),
                        )
                        closure_bpl.write_text(closure_txt, encoding="utf-8")

                    closure_res = runner.run(
                        stage="closure_check",
                        input_bpl=closure_bpl,
                        log_path=closure_log,
                        ultimate_home=ultimate_home_root / stem / "closure",
                        toolchain=closure_toolchain,
                        settings=closure_settings,
                        timeout_seconds=closure_timeout_this_attempt,
                        resource_limits=resource_limits,
                    )
                    closure_retry_res: Optional[StageRunResult] = None
                    closure_res_eff = closure_res

                    if (
                        closure_res.is_unknown
                        and closure_res.timed_out
                        and int(closure_timeout_this_attempt) < int(timeout_seconds)
                    ):
                        closure_log_retry = out_dir / f"{stem}.closure_check.retry.log"
                        closure_retry_res = runner.run(
                            stage="closure_check.retry",
                            input_bpl=closure_bpl,
                            log_path=closure_log_retry,
                            ultimate_home=ultimate_home_root / stem / "closure.retry",
                            toolchain=closure_toolchain,
                            settings=closure_settings,
                            timeout_seconds=timeout_seconds,
                            resource_limits=resource_limits,
                        )
                        artifacts = CegisAttemptArtifacts(
                            entry_bpl=artifacts.entry_bpl,
                            closure_bpl=artifacts.closure_bpl,
                            confirm_bpl=artifacts.confirm_bpl,
                            entry_log=artifacts.entry_log,
                            closure_log=artifacts.closure_log,
                            confirm_log=artifacts.confirm_log,
                            closure_log_retry=str(closure_log_retry),
                            enable_bpl=artifacts.enable_bpl,
                            enable_log=artifacts.enable_log,
                        )
                        closure_res_eff = closure_retry_res

                    attempts.append(
                        CegisAttemptRecord(
                            cfg=cfg_i,
                            artifacts=artifacts,
                            entry=entry_res,
                            closure=closure_res,
                            closure_retry=closure_retry_res,
                            confirm=confirm_res,
                        )
                    )
                    _write_manifest(
                        out_dir=out_dir,
                        spec_path=spec_path,
                        base_bpl=base_bpl,
                        work_dir=work_dir,
                        cand=cand,
                        attempts=attempts,
                    )

                    if closure_res_eff.is_safe:
                        # Certified: emit a CONFIRM witness for the final counterexample artifact.
                        #
                        # We intentionally do this *after* the closure proof succeeded. If closure
                        # times out/UNKNOWN (no evidence), we stop without running witnessprinter.
                        witness_timeout_s = min(timeout_seconds, max(120, min(300, int(closure_timeout_this_attempt))))
                        if seed_confirm_witness_text is None and (witness_profile_attempts < 3):
                            witness_profile_attempts += 1
                            witness_log = confirm_log.with_suffix(confirm_log.suffix + ".witness.log")
                            t0 = time.time()
                            _ = runner.run(
                                stage=f"confirm.witness.unroll{unroll}",
                                input_bpl=confirm_bpl,
                                log_path=witness_log,
                                ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.witness",
                                toolchain=toolchain_witness,
                                settings=witness_settings,
                                timeout_seconds=witness_timeout_s,
                                resource_limits=resource_limits,
                            )
                            witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                                work_dir=out_dir
                            )
                            if witness:
                                try:
                                    seed_confirm_witness_text = witness.read_text(encoding="utf-8", errors="replace")
                                except Exception:
                                    seed_confirm_witness_text = None
                                # Cache that we successfully obtained a witness (even if we do not
                                # use it for refinement in this run).
                                witness_profile_done = True
                        certified = True
                        break
                    if closure_res_eff.is_unknown:
                        # No counterexample -> no evidence to refine. Stop here and let the caller
                        # increase timeouts or optimize the spec/encoding case-by-case.
                        return _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )

                    # Not certified yet: mine witness-derived assumptions once and retry via CLOSURE-only mode.
                    added_any = False
                    witness_timeout_s = min(timeout_seconds, max(120, min(300, int(closure_timeout_this_attempt))))
                    if (not witness_profile_done) and (witness_profile_attempts < 3) and (it + 1 < max_iters):
                        witness_profile_attempts += 1
                        witness_log = confirm_log.with_suffix(confirm_log.suffix + ".witness.log")
                        t0 = time.time()
                        _ = runner.run(
                            stage=f"confirm.witness.unroll{unroll}",
                            input_bpl=confirm_bpl,
                            log_path=witness_log,
                            ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.witness",
                            toolchain=toolchain_witness,
                            settings=witness_settings,
                            timeout_seconds=witness_timeout_s,
                            resource_limits=resource_limits,
                        )
                        witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                            work_dir=out_dir
                        )
                        if witness:
                            try:
                                wtxt = witness.read_text(encoding="utf-8", errors="replace")
                                seed_confirm_witness_text = wtxt
                                new_assumes = _synthesize_refinement_assumes_from_witness(
                                    witness_text=wtxt,
                                    base_bpl_text=base_text,
                                    candidate=cand,
                                    spec_model=spec_model,
                                )
                            except Exception:
                                new_assumes = []
                            for aexpr in new_assumes:
                                if _add_assume(aexpr, priority=2):
                                    added_any = True
                            # Cache that we successfully obtained a witness (even if it adds no new assumes);
                            # future CEGAR refinements compare closure counterexamples against this witness.
                            witness_profile_done = True

                    if added_any:
                        need_retry = True
                    # Either way, stop trying longer unrolls once we have a bug witness.
                    break

                if certified:
                    break
                if need_retry:
                    # We obtained new closure assumptions from a concrete CONFIRM witness; retry.
                    continue
                if seed_confirm_res is None:
                    # No bug found and no pre-bug refinement to try.
                    break

        if index_expr is not None and cand.index_value is not None:
            index_expr = None
            index_value = int(cand.index_value)
            continue

        # No more evidence-backed refinements available (and we avoid heuristic weakening).
        break

    return _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)
