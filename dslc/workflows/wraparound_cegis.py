from __future__ import annotations

import json
import os
import re
import signal
import time
from dataclasses import asdict, dataclass, field, replace
from enum import Enum
from pathlib import Path
from typing import Callable, Dict, List, Optional, Protocol, Sequence, Set, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate, infer_wraparound_candidates
from dslc.analysis.wraparound_projection import extract_dependency_projection
from dslc.compiler import compile_spec_file
from dslc.speclang.parse import parse_model
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text
from dslc.transform.wraparound_analyze import _infer_deterministic_scheduler_period, _parse_global_var_types
# NOTE: We rewrite quantified register init assumptions only when it is provably safe.
#
# Ultimate often struggles with init patterns like:
#   assume (forall i:bv32 :: reg[i] == 0bvW);
# For wraparound stages, this is safe to expand to finitely many indices *only if*
# we can infer a finite bound on the accessed index domain (from `assume` constraints).
#
# The actual rewriting happens in `dslc/transform/wraparound_stages.py` and is
# conservative by construction: if no finite bound is inferred, we keep the quantifier
# to preserve semantics and avoid spurious counterexamples.
from dslc.toolchain.ultimate_witness import (
    extract_assumptions_from_graphml,
    find_latest_graphml_witness,
    synthesize_boogie_assumes,
)
from dslc.toolchain.ultimate_paths import ultimate_asset
from dslc.toolchain.ultimate_runner import extract_result_line as ultimate_extract_result_line
from dslc.toolchain.ultimate_runner import run_ultimate
from dslc.utils.repo import repo_root
from dslc.workflows.wraparound_support.distcache import (
    _apply_hash_caps_to_bpl,
    _infer_distcache_cache_frequency_get_optype,
    _infer_distcache_cache_frequency_update_profile,
    _infer_distcache_cache_lookup_idx,
    _infer_distcache_hash_caps,
    _infer_distcache_partition_eports,
    _is_distcache_like,
)
from dslc.workflows.wraparound_support.certification.manifest import (
    manifest_certified_unsafe_data as _manifest_certified_unsafe_data,
)
from dslc.workflows.wraparound_support.refinement import (
    _find_latest_graphml_witness_since,
    _select_refinement_assumes_from_witness_diff,
    _synthesize_env_completion_assumes,
    _synthesize_refinement_assumes_from_witness,
    _synthesize_shape_assumes_from_witness,
)
from dslc.workflows.wraparound_support.results import (
    StageRunResult,
    _extract_result_line,
    _read_tail_text,
    _select_stage_result_line,
    _toolchain_has_witnessprinter,
)
from dslc.workflows.wraparound_support.stage_text import _unroll_confirm_like_mainprocedure
from dslc.workflows.wraparound_support.toolchains import (
    _default_toolchain_paths,
    _schedule_replay_allinline_settings,
    _schedule_replay_closure_settings,
    _schedule_replay_stage_settings,
)
from dslc.workflows.wraparound_schedule import (
    ActorSchedule,
    ScheduleBlocker,
    blocker_exprs,
    compute_actor_schedule_id,
    compute_wraparound_candidate_id,
    infer_static_deterministic_schedule,
    make_schedule_blocker,
    projection_predicates_from_assumes,
    sha256_text,
)


class WraparoundCegisError(RuntimeError):
    pass


class WraparoundCegarMode(str, Enum):
    LEGACY_CLOSURE_ASSUMES = "legacy_closure_assumes"
    SCHEDULE_REPLAY = "schedule_replay"


class WraparoundStopAfter(str, Enum):
    NONE = "none"
    ENTRY = "entry"
    NEAR_WRAP = "near_wrap"
    CLOSURE = "closure"


_RE_BPL_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_BPL_CALLEE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.$]*\s*(?=\()")
_RE_BPL_FUNCTION_DECL = re.compile(r"^\s*function(?:\s+\{[^}]*\})*\s+(?P<name>[A-Za-z_][A-Za-z0-9_.$]*)\s*\(")
_RE_BPL_PROC_HEADER = re.compile(r"^\s*procedure(?:\s+\{[^}]*\})*\s+(?P<name>[A-Za-z_][A-Za-z0-9_.$]*)\s*\(")


def normalize_wraparound_cegar_mode(value: str) -> str:
    v = str(value or WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value).strip()
    allowed = {m.value for m in WraparoundCegarMode}
    if v not in allowed:
        raise WraparoundCegisError(f"unknown wraparound CEGAR mode: {value!r}")
    return v


def normalize_wraparound_stop_after(value: str) -> str:
    v = str(value or WraparoundStopAfter.NONE.value).strip()
    allowed = {m.value for m in WraparoundStopAfter}
    if v not in allowed:
        raise WraparoundCegisError(f"unknown wraparound stop-after stage: {value!r}")
    return v


class StageRunner(Protocol):
    """
    Runner interface for solver stages.

    This indirection makes the CEGIS loop unit-testable (mockable) without requiring
    Ultimate to be installed/runnable in the test environment.
    """

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> "StageRunResult": ...


@dataclass(frozen=True)
class CegisAttemptConfig:
    attempt: int
    pump_reg: str
    accel_regs: Tuple[str, ...]
    index_value: int
    index_expr: Optional[str]
    proj_vars: Tuple[str, ...]
    cutpoint_cond: Optional[str]
    step_op: str
    step_delta: int
    proj_predicates: Tuple[str, ...] = ()
    proj_predicate_sources: Tuple[str, ...] = ()
    proj_exprs: Tuple[str, ...] = ()
    env_shape_assumes: Tuple[str, ...] = ()
    projection_complete: bool = True
    # CEGIS-synthesized constraints used for *CLOSURE only* (Boogie expressions).
    #
    # ENTRY/CONFIRM are existential checks and must be run under the original environment;
    # refinement assumptions are applied only to CLOSURE (seeded from a concrete CONFIRM witness).
    closure_assumes: Tuple[str, ...] = ()
    notes: Tuple[str, ...] = ()


@dataclass(frozen=True)
class CegisAttemptArtifacts:
    entry_bpl: str
    closure_bpl: str
    confirm_bpl: str
    entry_log: str
    closure_log: str
    confirm_log: str
    # Optional source artifacts when confirm_bpl/confirm_log point at a focused
    # under-approximation derived from the ordinary near-wrap program.
    source_confirm_bpl: str = ""
    source_confirm_log: str = ""
    # Optional retry log for closure_check when we re-run it with a larger timeout.
    closure_log_retry: str = ""
    # Optional artifacts for the pump-enable (reach `target != MAX`) refinement.
    enable_bpl: str = ""
    enable_log: str = ""


@dataclass(frozen=True)
class CegisAttemptRecord:
    cfg: CegisAttemptConfig
    artifacts: CegisAttemptArtifacts
    entry: Optional[StageRunResult]
    closure: Optional[StageRunResult]
    # Optional second closure attempt (e.g. full-timeout retry after a capped run).
    # Kept for reproducibility/debugging; not part of the certification predicate.
    closure_retry: Optional[StageRunResult] = None
    confirm: Optional[StageRunResult] = None
    schedule: Optional[dict] = None
    near_wrap: Optional[StageRunResult] = None
    certified: bool = False
    diagnostic: str = ""


@dataclass(frozen=True)
class CegisManifest:
    spec: str
    base_bpl: str
    work_dir: str
    cegar_mode: str
    base_bpl_sha256: str
    # Full candidate information for reproducibility (e.g., pump_reg/index/step/proj/cutpoint).
    # Keep `candidate_reason` as a human-readable summary for grep-friendly manifests.
    candidate: dict
    candidate_reason: str
    attempts: List[CegisAttemptRecord]
    blockers: List[dict] = field(default_factory=list)
    certified: bool = False
    diagnostic: str = ""


def _write_manifest(
    *,
    out_dir: Path,
    spec_path: Path,
    base_bpl: Path,
    work_dir: Path,
    cand: WraparoundCandidate,
    attempts: List[CegisAttemptRecord],
    cegar_mode: str = WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
    base_bpl_sha256: str = "",
    blockers: Sequence[ScheduleBlocker] = (),
    certified: bool = False,
    diagnostic: str = "",
) -> Path:
    """
    Write the current CEGIS manifest (incremental).

    We write after each attempt so an interrupted run still leaves a reproducible
    record of what was tried and which artifacts/logs were produced.
    """

    manifest = CegisManifest(
        spec=str(spec_path),
        base_bpl=str(base_bpl),
        work_dir=str(work_dir),
        cegar_mode=cegar_mode,
        base_bpl_sha256=base_bpl_sha256,
        candidate=asdict(cand),
        candidate_reason=cand.reason,
        attempts=attempts,
        blockers=[b.to_manifest() for b in blockers],
        certified=bool(certified),
        diagnostic=diagnostic,
    )
    manifest_path = out_dir / "wraparound.cegis.manifest.json"
    manifest_path.write_text(json.dumps(asdict(manifest), indent=2, sort_keys=True), encoding="utf-8")
    return manifest_path


class UltimateStageRunner:
    def __init__(self, *, ultimate: Path, xmx_gb: int = 6) -> None:
        self._ultimate = ultimate
        self._xmx_gb = max(1, int(xmx_gb))

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> StageRunResult:
        # Keep some progress visible on stdout. Ultimate itself writes to log_path.
        # This also makes E2E runs (dslc/bench/run_e2e_ablations.py) easier to monitor.
        print(
            f"[WRAP] stage={stage} input={input_bpl.name} timeout_s={timeout_seconds} toolchain={toolchain.name} settings={settings.name}",
            flush=True,
        )
        start = time.time()
        os_timeout = timeout_seconds + 60 if timeout_seconds > 0 else 0
        spawn = run_ultimate(
            ultimate=self._ultimate,
            toolchain=toolchain,
            settings=settings,
            input_bpl=input_bpl,
            log_path=log_path,
            ultimate_home=ultimate_home,
            toolchain_timeout_seconds=timeout_seconds,
            os_timeout_seconds=os_timeout,
            cwd=log_path.parent,
            async_run=True,
            resource_limits=resource_limits,
            launcher_xmx_gb=self._xmx_gb,
        )

        if spawn.pid is None:
            raise WraparoundCegisError(f"internal error: async Ultimate run did not return a pid (stage={stage})")

        pid = int(spawn.pid)
        rc: Optional[int] = None
        killed_early = False
        observed_result_line: Optional[str] = None
        # Do NOT early-stop on SAFE by default.
        #
        # Why:
        # - We previously sent SIGTERM immediately after observing SAFE in the live tail.
        # - Some Ultimate pipelines then log synthetic timeout/no-result tails (or teardown
        #   exceptions) after shutdown is requested, which can blur stage diagnostics and
        #   make NEAR_WRAP look like SAFE while the final log says no-result.
        # - For wraparound soundness/debuggability we prefer complete stage logs on SAFE.
        #
        # UNSAFE early-stop remains enabled (with witness guard) because it is existential
        # evidence and keeps long runs practical.
        allow_safe_early_stop = os.environ.get("PROCURATOR_WRAP_SAFE_EARLY_STOP", "0").strip() == "1"

        def _witness_required_on_unsafe(st: str) -> bool:
            # For wraparound CEGIS, we only need a witness to seed closure refinements.
            # Entry/closure are feasibility/proof obligations that do not require witnesses.
            if st == "confirm":
                return True
            if st.startswith("confirm.witness."):
                return True
            if st.startswith("closure_check.witness."):
                return True
            if st.startswith("enable_check"):
                return True
            return False

        need_witness = _witness_required_on_unsafe(stage)

        def _stage_witness_path() -> Path:
            # Ultimate's witness printer typically emits "<input>.bpl-witness.graphml"
            # next to the input. Prefer this deterministic path to avoid confusing
            # older stage witnesses in the same directory (mtime resolution on /mnt
            # can be coarse and cause false positives).
            return log_path.parent / f"{input_bpl.name}-witness.graphml"

        # Early-stop policy:
        # - Some Ultimate toolchains keep running (post-processing) after they already
        #   registered SAFE/UNSAFE. This makes runs look "hung" and regresses throughput.
        # - For witness-producing stages, only stop once a GraphML witness exists.
        while True:
            try:
                wpid, status = os.waitpid(pid, os.WNOHANG)
            except ChildProcessError:
                # Already reaped.
                wpid, status = (pid, 0)
            if wpid == pid:
                # Finished naturally (or already reaped).
                if os.WIFEXITED(status):
                    rc = int(os.WEXITSTATUS(status))
                elif os.WIFSIGNALED(status):
                    rc = -int(os.WTERMSIG(status))
                else:
                    rc = 0
                break

            tail = _read_tail_text(log_path)
            res_line = ultimate_extract_result_line(tail) if tail else None
            if res_line == "RESULT: SAFE":
                if allow_safe_early_stop:
                    killed_early = True
                    observed_result_line = res_line
            elif res_line == "RESULT: UNSAFE":
                if not need_witness:
                    killed_early = True
                    observed_result_line = res_line
                else:
                    # Only stop when the witness for *this input* has been written.
                    # Do not use a "latest witness in dir" heuristic: entry/closure
                    # stages can leave witnesses behind, and timestamp resolution on
                    # Windows-backed file systems can make them look "newer".
                    wit = _stage_witness_path()
                    if wit.exists():
                        killed_early = True
                        observed_result_line = res_line

            if killed_early:
                # run_ultimate() starts Ultimate in its own session (start_new_session=True),
                # so killpg(pid) is safe and terminates the whole process tree.
                try:
                    os.killpg(pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass

                # Give it a moment to exit cleanly; then SIGKILL.
                t_kill = time.time()
                while time.time() - t_kill < 5.0:
                    try:
                        wpid2, _status2 = os.waitpid(pid, os.WNOHANG)
                    except ChildProcessError:
                        wpid2 = pid
                    if wpid2 == pid:
                        break
                    time.sleep(0.05)
                else:
                    try:
                        os.killpg(pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    try:
                        os.waitpid(pid, 0)
                    except ChildProcessError:
                        pass

                # Treat early-stop as a successful run; the semantic result is in the log.
                rc = 0
                break

            time.sleep(0.5)

        wall = time.time() - start
        txt = log_path.read_text(encoding="utf-8", errors="replace")
        final_line = ultimate_extract_result_line(txt)

        effective_line = _select_stage_result_line(
            killed_early=killed_early,
            observed_result_line=observed_result_line,
            final_result_line=final_line,
        )
        out = StageRunResult(stage=stage, returncode=int(rc or 0), wall_time_s=wall, result_line=effective_line)
        print(
            f"[WRAP] stage={stage} rc={out.returncode} early_stop={str(killed_early).lower()} "
            f"result={out.result_line or 'RESULT: <missing>'} wall_s={out.wall_time_s:.1f}",
            flush=True,
        )
        if killed_early and final_line and (final_line != effective_line):
            print(f"[WRAP] stage={stage} early_stop_note: log ended with {final_line!r}", flush=True)
        return out


def _refine_proj_vars_greedy(
    proj_vars: List[str],
    *,
    mandatory: Sequence[str],
    max_drops: int,
) -> List[str]:
    """
    Simple, predictable refinement: drop at most `max_drops` non-mandatory vars.

    This is intentionally conservative; we can upgrade to ddmin later if needed.
    """

    mandatory_set = set(mandatory)

    def _noise_rank(v: str) -> Tuple[int, int]:
        """
        Lower rank = drop earlier.

        Heuristic:
          - Packet-local meta/hash/index values tend to break closure and add SMT noise.
          - Inbox/egress counts can matter for scheduler/queue stability, but we allow
            dropping them if needed to make progress. We therefore drop them late.
        """

        low = v.lower()
        noisy = 0
        if "hash" in low:
            noisy = -3
        elif "switchidx" in low or low.endswith("idx") or ".idx" in low:
            noisy = -2
        elif "inbox_count" in low or "egress_count" in low:
            noisy = 3
        elif "tmp" in low or "scratch" in low:
            noisy = -1
        # Prefer dropping meta.* over other namespaces.
        ns = 0
        if "_meta." in v or v.startswith("meta."):
            ns = -1
        return (noisy, ns)

    out = list(proj_vars)
    # Choose a deterministic drop order to keep manifests stable.
    candidates = [v for v in out if v not in mandatory_set]
    candidates.sort(key=_noise_rank)

    drops = 0
    for v in candidates:
        if drops >= max_drops:
            break
        try:
            out.remove(v)
        except ValueError:
            continue
        drops += 1
    return out


def _effective_scalar_projection_vars(base_text: str, proj_vars: Sequence[str]) -> List[str]:
    """Return exactly the projection globals the closure transform can snapshot."""

    var_types = _parse_global_var_types(base_text.splitlines())
    out: List[str] = []
    seen: set[str] = set()
    for v in proj_vars:
        if v in seen:
            continue
        t = var_types.get(v)
        if t is None or "[" in t or "]" in t:
            continue
        seen.add(v)
        out.append(v)
    return out


def _index_expr_global_deps(*, index_expr: Optional[str], base_text: str) -> List[str]:
    """
    Return Boogie globals referenced by a symbolic wraparound index expression.

    Wraparound acceleration writes the target register slot before the scheduler
    loop.  A symbolic index is sound only when it is already a pure expression
    (for example an uninterpreted hash over env literals).  If it still mentions
    a Boogie global such as `meta.register_index`, that global may not have been
    computed yet at the fast-forward point, so the run must fall back to direct
    verification.
    """

    expr = str(index_expr or "").strip()
    if not expr:
        return []
    var_types = _parse_global_var_types(base_text.splitlines())
    return sorted({tok for tok in _RE_BPL_IDENT.findall(expr) if tok in var_types})


def _index_expr_unresolved_value_deps(*, index_expr: Optional[str], base_text: str) -> List[str]:
    """
    Return value-position identifiers left in an index expression.

    This is stricter than `_index_expr_global_deps`: a procedure-local/parameter
    identifier is still unsafe for pre-loop fast-forward, even if it is not a
    declared global in the composed Boogie file.
    """

    expr = str(index_expr or "").strip()
    if not expr:
        return []
    without_callees = _RE_BPL_CALLEE_IDENT.sub("", expr)
    allowed = {"true", "false", "if", "then", "else"}
    unresolved = {
        tok
        for tok in _RE_BPL_IDENT.findall(without_callees)
        if tok not in allowed
    }
    globals_ = set(_index_expr_global_deps(index_expr=index_expr, base_text=base_text))
    return sorted(unresolved - globals_)


def _declared_call_symbols_from_bpl(base_text: str) -> Set[str]:
    """
    Collect declared function/procedure symbols in the composed Boogie text.

    Wraparound transforms may inject dynamic index/hash expressions and stable-shape
    assumptions into stage programs. We must guard against stale/unprefixed symbols
    that are not declared in the composed model, otherwise Ultimate reports a generic
    "Toolchain returned no result" after type-check failures.
    """

    out: Set[str] = set()
    for raw in base_text.splitlines():
        line = raw.strip()
        if not line or line.startswith("//"):
            continue
        m_fun = _RE_BPL_FUNCTION_DECL.match(line)
        if m_fun:
            out.add(m_fun.group("name"))
            continue
        m_proc = _RE_BPL_PROC_HEADER.match(line)
        if m_proc:
            out.add(m_proc.group("name"))
    return out


def _callee_declared_alias(*, callee: str, declared_symbols: Sequence[str]) -> Optional[str]:
    """
    Best-effort aliasing from an unqualified callee to a declared symbol.

    Typical case in composed models:
      - candidate/meta uses `Ingress_idx_calc.get$...`
      - composed Boogie declares `flowrest_Ingress_idx_calc.get$...`

    We only rewrite when the mapping is unique; otherwise callers keep the
    original symbol and fallback logic remains in charge.
    """

    token = str(callee or "").strip()
    if not token:
        return None
    declared = set(declared_symbols)
    if token in declared:
        return token

    # 1) Exact node-prefix suffix match: "<node>_<token>"
    suffix_matches = sorted(d for d in declared if d.endswith("_" + token))
    if len(suffix_matches) == 1:
        return suffix_matches[0]

    # 2) If the token is mangled (contains '$'), align by base + signature.
    if "$" in token:
        base, sig = token.split("$", 1)
        pat = "_" + base + "$" + sig
        sig_matches = sorted(d for d in declared if d.endswith(pat))
        if len(sig_matches) == 1:
            return sig_matches[0]

    return None


def _rewrite_expr_callees_to_declared(
    *,
    expr: Optional[str],
    declared_symbols: Sequence[str],
) -> tuple[str, List[Tuple[str, str]]]:
    """
    Rewrite callee symbols in `expr` to uniquely matching declared symbols.

    Returns `(rewritten_expr, rewrites)` where `rewrites` contains `(old, new)`
    pairs for applied substitutions.
    """

    text = str(expr or "")
    if not text:
        return text, []

    allowed = {"if", "then", "else", "old"}
    rewrites: List[Tuple[str, str]] = []

    def repl(m: re.Match[str]) -> str:
        raw = m.group(0)
        stripped = raw.rstrip()
        suffix = raw[len(stripped) :]
        callee = stripped
        if not callee or callee in allowed:
            return raw
        alias = _callee_declared_alias(callee=callee, declared_symbols=declared_symbols)
        if alias is None or alias == callee:
            return raw
        rewrites.append((callee, alias))
        return alias + suffix

    return _RE_BPL_CALLEE_IDENT.sub(repl, text), rewrites


def _rewrite_candidate_declared_callees(
    *,
    candidate: WraparoundCandidate,
    base_text: str,
) -> WraparoundCandidate:
    """
    Normalize candidate call symbols to declared names in the composed Boogie model.

    This repairs stale/non-prefixed hash-calculation symbols so stage Boogie files
    stay type-correct and do not fail with "undeclared function/procedure".
    """

    declared = _declared_call_symbols_from_bpl(base_text)
    if not declared:
        return candidate

    changed = False
    idx_expr = getattr(candidate, "index_expr", None)
    idx_new, idx_rw = _rewrite_expr_callees_to_declared(expr=idx_expr, declared_symbols=declared)
    if idx_rw:
        changed = True

    substitutions = tuple(getattr(candidate, "stable_substitutions", ()) or ())
    rewritten_subs: List[Tuple[str, str]] = []
    for lhs, rhs in substitutions:
        lhs_s = str(lhs or "").strip()
        rhs_s = str(rhs or "").strip()
        lhs_new, lhs_rw = _rewrite_expr_callees_to_declared(expr=lhs_s, declared_symbols=declared)
        rhs_new, rhs_rw = _rewrite_expr_callees_to_declared(expr=rhs_s, declared_symbols=declared)
        if lhs_rw or rhs_rw:
            changed = True
        rewritten_subs.append((lhs_new.strip(), rhs_new.strip()))

    if not changed:
        return candidate
    return replace(
        candidate,
        index_expr=idx_new.strip() if idx_new.strip() else None,
        stable_substitutions=tuple(rewritten_subs),
    )


def _expr_undeclared_callee_deps(*, expr: Optional[str], declared_symbols: Sequence[str]) -> List[str]:
    """
    Return callee symbols used in `expr` but missing from `declared_symbols`.
    """

    text = str(expr or "").strip()
    if not text:
        return []
    declared = set(declared_symbols)
    allowed = {"if", "then", "else", "old"}
    out: List[str] = []
    seen: Set[str] = set()
    for tok in _RE_BPL_CALLEE_IDENT.findall(text):
        callee = tok.strip()
        if not callee or callee in allowed:
            continue
        if callee in declared or callee in seen:
            continue
        seen.add(callee)
        out.append(callee)
    return out


def _index_expr_undeclared_callee_deps(*, index_expr: Optional[str], base_text: str) -> List[str]:
    declared = _declared_call_symbols_from_bpl(base_text)
    return _expr_undeclared_callee_deps(expr=index_expr, declared_symbols=declared)


def _sanitize_candidate_stable_substitutions(
    *, candidate: WraparoundCandidate, base_text: str
) -> tuple[WraparoundCandidate, List[str]]:
    """
    Drop stable substitutions whose expressions call undeclared symbols.
    """

    candidate = _rewrite_candidate_declared_callees(candidate=candidate, base_text=base_text)
    substitutions = tuple(getattr(candidate, "stable_substitutions", ()) or ())
    if not substitutions:
        return candidate, []

    declared = _declared_call_symbols_from_bpl(base_text)
    kept: List[Tuple[str, str]] = []
    dropped: List[str] = []
    for lhs, rhs in substitutions:
        lhs_s = str(lhs or "").strip()
        rhs_s = str(rhs or "").strip()
        missing = sorted(
            set(
                _expr_undeclared_callee_deps(expr=lhs_s, declared_symbols=declared)
                + _expr_undeclared_callee_deps(expr=rhs_s, declared_symbols=declared)
            )
        )
        if missing:
            dropped.append(f"{lhs_s} == {rhs_s} (missing: {', '.join(missing)})")
            continue
        kept.append((lhs_s, rhs_s))
    if len(kept) == len(substitutions):
        return candidate, []
    return replace(candidate, stable_substitutions=tuple(kept)), dropped


def _dynamic_index_fallback_diagnostic(deps: Sequence[str]) -> str:
    shown = ", ".join(str(d) for d in deps[:6])
    if len(deps) > 6:
        shown += ", ..."
    return (
        "dynamic index expression depends on pre-loop globals"
        + (f" ({shown})" if shown else "")
        + "; falling back to direct verification"
    )


def _unresolved_index_fallback_diagnostic(deps: Sequence[str]) -> str:
    shown = ", ".join(str(d) for d in deps[:6])
    if len(deps) > 6:
        shown += ", ..."
    return (
        "dynamic index expression contains unresolved pre-loop values"
        + (f" ({shown})" if shown else "")
        + "; falling back to direct verification"
    )


def _undeclared_index_callee_fallback_diagnostic(deps: Sequence[str]) -> str:
    shown = ", ".join(str(d) for d in deps[:6])
    if len(deps) > 6:
        shown += ", ..."
    return (
        "dynamic index expression references undeclared call symbols"
        + (f" ({shown})" if shown else "")
        + "; falling back to direct verification"
    )


def _dropped_stable_substitutions_note(entries: Sequence[str]) -> str:
    shown = ", ".join(str(v) for v in entries[:3])
    if len(entries) > 3:
        shown += ", ..."
    return (
        "dropped candidate stable substitutions with undeclared call symbols"
        + (f" ({shown})" if shown else "")
    )


def _confirm_unroll_schedule(*, base: int, max_unroll: int) -> List[int]:
    """
    Generate a small, deterministic unroll schedule for CONFIRM.

    Motivation: some wraparound bugs require a slightly longer suffix than the
    default bound (e.g., P2C after overflow), while other cases become harder
    when an unnecessary extra suffix is unrolled. We therefore start at the
    smallest meaningful suffix and grow toward the requested/default bound.
    """

    b = max(1, int(base))
    cap = max(b, int(max_unroll))
    # Additive growth:
    # - Our deterministic two-phase harness typically needs a few extra "actor steps"
    #   to accommodate an additional injected packet / pass.
    # - Multiplying the bound (e.g., 6 -> 12 -> 24) can easily overshoot into a much
    #   harder search (or timeout) before we tried the next meaningful small bound.
    #
    # We keep the schedule short and align to common "one more packet/round" increments.
    out: List[int] = []
    for v in range(1, min(b, cap) + 1):
        out.append(v)
    for inc in (1, 2, 4):
        v = min(cap, b + inc)
        if v not in out:
            out.append(v)
    if cap not in out:
        out.append(cap)
    return out


def run_wraparound_cegis(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Optional[Path],
    ultimate: Path,
    candidate: Optional[WraparoundCandidate] = None,
    timeout_seconds: int = 1200,
    # If >0, cap each closure_check attempt to this timeout (seconds).
    #
    # Default: 0 (no cap). This avoids interrupting a long-running proof attempt
    # that might succeed with a larger budget.
    closure_timeout_cap_seconds: int = 0,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    emit_reg_debug: bool = True,
    confirm_unroll: int = 3,
    # 0 => do not grow (single confirm).
    max_confirm_unroll: int = 0,
    max_iters: int = 6,
    # Heuristic refinement: if CONFIRM times out, under-approximate env by zeroing unassigned inputs.
    enable_env_completion_refinement: bool = True,
    # Default order for the standalone wraparound workflow.
    stage_order: str = "entry_confirm_closure",
    # Auto mode policy: require P4B monotone-update meta when inferring candidates from global asserts.
    require_meta_step_for_global_asserts: bool = False,
    runner: Optional[StageRunner] = None,
    # Toolchain selection:
    #   - toolchain_nowitness: used by default for ENTRY/CONFIRM to avoid witness-printer crashes on SAFE.
    #   - toolchain_witness: used only when we need a witness (CEGIS refinement).
    toolchain: Optional[Path] = None,
    witness_toolchain: Optional[Path] = None,
    closure_toolchain: Optional[Path] = None,
    settings: Optional[Path] = None,
    closure_settings: Optional[Path] = None,
    cegar_mode: str = WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
    stop_after: str = WraparoundStopAfter.NONE.value,
) -> Path:
    """
    Iterative wraparound CEGIS loop for sound bug finding.

    We support multiple stage orders:

      - entry_closure_confirm (default): ENTRY -> CLOSURE -> CONFIRM
        Useful when you expect closure to hold and want to gate confirm on a
        proven pump summary.

      - entry_confirm_closure: ENTRY -> CONFIRM -> CLOSURE
        Recommended when integrating wraparound into the main verification
        pipeline: if CONFIRM does not find a bug, CLOSURE is wasted work.

    Refinement (when closure_check is not SAFE):
      - distcache-specific index stabilization (index_expr -> constant eport), if applicable;
      - witness-guided refinement when closure_check is UNSAFE (add assumptions that
        preserve the seeded CONFIRM witness but block the closure counterexample).

    All artifacts and outcomes are recorded into `wraparound.cegis.manifest.json`.
    """

    cegar_mode = normalize_wraparound_cegar_mode(cegar_mode)
    stop_after = normalize_wraparound_stop_after(stop_after)

    spec_path = spec_path.resolve()
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    work_dir = out_dir / "work"
    base_bpl = out_dir / f"{spec_path.stem}.base.bpl"

    # 1) Compile base model (sequential harness; deterministic scheduler expected for closure/entry).
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=enable_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=pipeline_two_stage,
        max_steps=None,
        honor_spec_max_steps=False,
        emit_reg_debug=emit_reg_debug,
    )

    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")

    # 2) P4B meta is an optimization input; tolerate missing meta files.
    meta_by_node: Dict[str, dict] = {}
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            meta_by_node[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue

    # 3) DistCache stabilization: hash caps and constant partition eports.
    partition_ports: Dict[str, int] = {}
    if _is_distcache_like(spec_text):
        caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
        if caps:
            node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
            patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=caps)
            if patched != base_text:
                base_text = patched
                base_bpl.write_text(base_text, encoding="utf-8")
        partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

    # 4) Infer candidates from spec/meta unless caller provided an explicit candidate.
    if candidate is None:
        cands = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=base_text,
            meta_by_node=meta_by_node,
            require_meta_step_for_global_asserts=require_meta_step_for_global_asserts,
        )
        if not cands:
            raise WraparoundCegisError("failed to infer wraparound candidates; pass a spec that exposes a counter update")
        cand = cands[0]
    else:
        cand = candidate

    # 5) Resolve defaults for solver toolchains/settings.
    root = repo_root()
    tc_nowit_def, tc_wit_def, tc_cl_def, st_nowit_def, st_wit_def, st_cl_def = _default_toolchain_paths(
        root=root, ultimate_xmx_gb=0
    )
    toolchain_nowitness = (toolchain or tc_nowit_def).resolve()
    toolchain_witness = (witness_toolchain or tc_wit_def).resolve()
    closure_toolchain = (closure_toolchain or tc_cl_def).resolve()
    settings = (settings or st_nowit_def).resolve()
    witness_settings = st_wit_def.resolve()
    closure_settings = (closure_settings or st_cl_def).resolve()

    runner = runner or UltimateStageRunner(ultimate=ultimate)

    loop_kwargs = dict(
        spec_path=spec_path,
        spec_text=spec_text,
        base_bpl=base_bpl,
        base_text=base_text,
        out_dir=out_dir,
        work_dir=work_dir,
        candidate=cand,
        partition_ports=partition_ports,
        timeout_seconds=timeout_seconds,
        closure_timeout_cap_seconds=closure_timeout_cap_seconds,
        resource_limits=resource_limits,
        confirm_unroll=confirm_unroll,
        max_confirm_unroll=max_confirm_unroll,
        max_iters=max_iters,
        enable_env_completion_refinement=enable_env_completion_refinement,
        runner=runner,
        toolchain_nowitness=toolchain_nowitness,
        toolchain_witness=toolchain_witness,
        witness_settings=witness_settings,
        closure_toolchain=closure_toolchain,
        settings=settings,
        closure_settings=closure_settings,
        confirm_settings_fallback=None,
        stage_order=stage_order,
        stop_after=stop_after,
    )
    if cegar_mode == WraparoundCegarMode.SCHEDULE_REPLAY.value:
        manifest_path = _run_schedule_replay_cegar_loop(**loop_kwargs)
    else:
        manifest_path = _run_cegis_loop(**loop_kwargs)
    return manifest_path




def _sync_loop_module(module: object) -> None:
    "Propagate facade monkey-patches into moved loop modules for tests."

    for name in (
        "CegisAttemptArtifacts",
        "CegisAttemptConfig",
        "CegisAttemptRecord",
        "WraparoundCegarMode",
        "WraparoundStopAfter",
        "WraparoundCegisError",
        "_confirm_unroll_schedule",
        "_dynamic_index_fallback_diagnostic",
        "_effective_scalar_projection_vars",
        "_find_latest_graphml_witness_since",
        "_index_expr_global_deps",
        "_index_expr_unresolved_value_deps",
        "_infer_deterministic_scheduler_period",
        "_refine_proj_vars_greedy",
        "_select_refinement_assumes_from_witness_diff",
        "_synthesize_refinement_assumes_from_witness",
        "_toolchain_has_witnessprinter",
        "_unresolved_index_fallback_diagnostic",
        "_unroll_confirm_like_mainprocedure",
        "_write_manifest",
        "blocker_exprs",
        "extract_dependency_projection",
        "find_latest_graphml_witness",
        "infer_static_deterministic_schedule",
        "instrument_bpl_text",
        "make_schedule_blocker",
        "normalize_wraparound_stop_after",
        "parse_model",
        "projection_predicates_from_assumes",
        "sha256_text",
    ):
        if name in globals():
            setattr(module, name, globals()[name])


def _run_schedule_replay_cegar_loop(*args, **kwargs) -> Path:
    from dslc.workflows.wraparound_support import loop_schedule

    _sync_loop_module(loop_schedule)
    return loop_schedule._run_schedule_replay_cegar_loop(*args, **kwargs)


def _run_cegis_loop(*args, **kwargs) -> Path:
    from dslc.workflows.wraparound_support import loop_legacy

    _sync_loop_module(loop_legacy)
    return loop_legacy._run_cegis_loop(*args, **kwargs)

def run_wraparound_cegis_multi(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Optional[Path],
    ultimate: Path,
    ultimate_xmx_gb: int = 6,
    timeout_seconds: int = 1200,
    # Default: 0 (no cap). Avoid interrupting long-running closure proofs; do not refine on timeout.
    closure_timeout_cap_seconds: int = 0,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    emit_reg_debug: bool = True,
    confirm_unroll: int = 3,
    # 0 => do not grow (single confirm).
    max_confirm_unroll: int = 0,
    max_iters: int = 6,
    stage_order: str = "entry_confirm_closure",
    max_targets: int = 8,
    require_meta_step_for_global_asserts: bool = False,
    cegar_mode: str = WraparoundCegarMode.LEGACY_CLOSURE_ASSUMES.value,
    stop_after: str = WraparoundStopAfter.NONE.value,
) -> List[Path]:
    """
    Run wraparound CEGIS for multiple candidates (best-effort).

    This is intended for integration into the main verification pipeline:
      - try a coarse "group" first (when candidates are compatible),
      - then fall back to per-register candidates.

    Returns a list of manifest paths (one per attempted target), in order.
    """

    cegar_mode = normalize_wraparound_cegar_mode(cegar_mode)
    stop_after = normalize_wraparound_stop_after(stop_after)
    spec_path = spec_path.resolve()
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    # Compile once and infer candidates.
    work_dir = out_dir / "work"
    base_bpl = out_dir / f"{spec_path.stem}.base.bpl"
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=enable_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=pipeline_two_stage,
        max_steps=None,
        honor_spec_max_steps=False,
        emit_reg_debug=emit_reg_debug,
    )
    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")

    meta_by_node: Dict[str, dict] = {}
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            meta_by_node[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue

    partition_ports: Dict[str, int] = {}
    if _is_distcache_like(spec_text):
        caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
        if caps:
            node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
            patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=caps)
            if patched != base_text:
                base_text = patched
                base_bpl.write_text(base_text, encoding="utf-8")
        partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

    cands = infer_wraparound_candidates(
        spec_text=spec_text,
        bpl_text=base_text,
        meta_by_node=meta_by_node,
        require_meta_step_for_global_asserts=require_meta_step_for_global_asserts,
    )
    if not cands:
        return []

    # Deterministic target ordering for reproducibility.
    cands = sorted(cands, key=lambda c: (c.pump_reg, str(c.index_value), str(c.index_expr)))

    # If multiple wraparound candidates exist, prefer the one that matches the
    # benchmark's intent. This matters for DistCache where both leafload/spineload
    # are monotone counters but a given .prop is usually written to target one of them.
    stem_lower = spec_path.stem.lower()
    prefer_token: Optional[str] = None
    if "spineload" in stem_lower:
        prefer_token = "spineload"
    elif "leafload" in stem_lower:
        prefer_token = "leafload"
    elif "cache_frequency" in stem_lower:
        prefer_token = "cache_frequency"
    if prefer_token is not None and len(cands) > 1:
        def _pref_key(c: WraparoundCandidate) -> tuple[int, str, str, str]:
            hit = 0 if (prefer_token in c.pump_reg.lower() or prefer_token in c.reason.lower()) else 1
            return (hit, c.pump_reg, str(c.index_value), str(c.index_expr))

        cands = sorted(cands, key=_pref_key)
        # If the preferred token matches at least one candidate, drop the rest.
        # This keeps `--wraparound auto` aligned with the benchmark's intent and
        # avoids spending time on irrelevant counters.
        preferred = [
            c
            for c in cands
            if (prefer_token in c.pump_reg.lower() or prefer_token in c.reason.lower())
        ]
        if preferred:
            cands = preferred
    cands = cands[: max(1, int(max_targets))]

    roots: List[WraparoundCandidate] = []

    # Try a coarse group if (step_op, step_delta, cutpoint) align.
    if cands:
        base0 = cands[0]
        compatible = all(
            (c.step_op == base0.step_op)
            and (int(c.step_delta or 1) == int(base0.step_delta or 1))
            and (str(c.cutpoint_cond) == str(base0.cutpoint_cond))
            for c in cands
        )
        same_index = all((c.index_value == base0.index_value) and (c.index_expr == base0.index_expr) for c in cands)
        if compatible and same_index and len(cands) > 1:
            regs: List[str] = []
            for c in cands:
                regs.append(c.pump_reg)
                regs.extend(list(c.accel_regs))
            seen = set()
            uniq_regs: List[str] = []
            for r in regs:
                if r not in seen:
                    seen.add(r)
                    uniq_regs.append(r)
            proj: List[str] = []
            for c in cands:
                proj.extend(list(c.proj_vars))
            roots.append(
                WraparoundCandidate(
                    pump_reg=base0.pump_reg,
                    accel_regs=tuple(sorted(set(uniq_regs))),
                    index_value=base0.index_value,
                    index_expr=base0.index_expr,
                    proj_vars=tuple(sorted(set(proj))),
                    cutpoint_cond=base0.cutpoint_cond,
                    reason="group0(all_regs): " + "; ".join(sorted(set(c.reason for c in cands))),
                    step_op=base0.step_op,
                    step_delta=base0.step_delta,
                    stable_substitutions=base0.stable_substitutions,
                )
            )

    # Then try each candidate individually.
    roots.extend(cands)

    # Run CEGIS per root candidate, in isolated subdirectories (reuse the compiled base model).
    manifests: List[Path] = []
    root = repo_root()
    tc_nowit_def, tc_wit_def, tc_cl_def, st_nowit_def, st_wit_def, st_cl_def = _default_toolchain_paths(
        root=root, ultimate_xmx_gb=int(ultimate_xmx_gb)
    )
    runner = UltimateStageRunner(ultimate=ultimate, xmx_gb=int(ultimate_xmx_gb))
    # If available, retry CONFIRM with a "no z3 timeout" settings profile when
    # the default settings return UNKNOWN due to timeouts. This improves
    # determinism for wraparound bug finding and reduces spurious fallbacks.
    confirm_settings_fallback: Optional[Path] = None
    # WSL safety: only try the high-memory "no z3 timeout" fallback when the user
    # explicitly allocates a larger heap. Otherwise, prefer deterministic timeouts
    # over risking an OOM.
    if int(ultimate_xmx_gb) >= 8:
        st_confirm_noz3 = ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf")
        st_confirm_noz3_legacy = (
            root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "config"
            / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf"
        )
        cand = (st_confirm_noz3 if st_confirm_noz3.exists() else st_confirm_noz3_legacy)
        if cand.exists():
            confirm_settings_fallback = cand

    def _is_certified_unsafe(manifest_path: Path) -> bool:
        """
        Best-effort check for a certified wraparound manifest.

        We use this to early-stop `run_wraparound_cegis_multi`: once we have a certified
        counterexample for one candidate, running additional candidates is wasted work
        (and can be confusing in logs/experiments).
        """

        try:
            j = json.loads(manifest_path.read_text(encoding="utf-8"))
        except Exception:
            return False

        return _manifest_certified_unsafe_data(j)

    for i, cand in enumerate(roots):
        subdir = out_dir / f"target.{i:02d}.{cand.pump_reg}"
        subdir.mkdir(parents=True, exist_ok=True)
        if cegar_mode == WraparoundCegarMode.SCHEDULE_REPLAY.value:
            stage_toolchain = tc_nowit_def
            closure_settings = _schedule_replay_closure_settings(
                root=root,
                closure_settings=st_cl_def,
                ultimate_xmx_gb=int(ultimate_xmx_gb),
            )
            stage_settings = _schedule_replay_stage_settings(
                root=root,
                settings_nowitness=st_nowit_def,
                closure_settings=closure_settings,
                ultimate_xmx_gb=int(ultimate_xmx_gb),
            )
        else:
            # Legacy mode still needs witness artifacts for refinement/certification,
            # but running all CONFIRM queries with witnessprinter enabled is brittle:
            # Ultimate can throw witnessprinter exceptions on SAFE outcomes, which
            # then surface as "Toolchain returned no result" and mask the true stage
            # result. Keep stage execution on the no-witness fast path and re-run
            # witness collection only when the loop explicitly asks for it.
            stage_toolchain = tc_nowit_def
            stage_settings = st_nowit_def
            closure_settings = st_cl_def
        loop_kwargs = dict(
            spec_path=spec_path,
            spec_text=spec_text,
            base_bpl=base_bpl,
            base_text=base_text,
            out_dir=subdir,
            work_dir=work_dir,
            candidate=cand,
            partition_ports=partition_ports,
            timeout_seconds=timeout_seconds,
            closure_timeout_cap_seconds=closure_timeout_cap_seconds,
            resource_limits=resource_limits,
            confirm_unroll=confirm_unroll,
            max_confirm_unroll=max_confirm_unroll,
            # ENTRY/CONFIRM are existential checks and should not be part of synthesis.
            # Refinements are closure-only and must be evidence-backed (witness-guided).
            enable_env_completion_refinement=False,
            runner=runner,
            # Schedule replay keeps ENTRY/NEAR_WRAP on the no-witness fast path;
            # witness printing is only used after an UNKNOWN closure for diagnostic
            # refinement. Legacy mode keeps its witness-enabled confirm behavior.
            toolchain_nowitness=stage_toolchain,
            toolchain_witness=tc_wit_def,
            witness_settings=st_wit_def,
            closure_toolchain=tc_cl_def,
            settings=stage_settings,
            closure_settings=closure_settings,
            confirm_settings_fallback=confirm_settings_fallback,
            stage_order=stage_order,
            stop_after=stop_after,
        )
        if cegar_mode == WraparoundCegarMode.SCHEDULE_REPLAY.value:
            mpath = _run_schedule_replay_cegar_loop(max_iters=max_iters, **loop_kwargs)
        else:
            mpath = _run_cegis_loop(max_iters=max_iters, **loop_kwargs)
        manifests.append(mpath)
        if stop_after != WraparoundStopAfter.NONE.value:
            break
        if _is_certified_unsafe(mpath):
            break
    return manifests
