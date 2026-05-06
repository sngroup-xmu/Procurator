from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection_exprs import (
    array_assignment_index_expr as _array_assignment_index_expr,
    array_selects_in_expr as _array_selects_in_expr,
    array_index_width as _array_index_width,
    deps_in_expr as _deps_in_expr,
    dynamic_slot_deps as _dynamic_slot_deps,
    dynamic_slot_indices as _dynamic_slot_indices,
    dynamic_slot_projection_exprs as _dynamic_slot_projection_exprs,
    extract_cond_text as _extract_cond_text,
    is_packet_slot_var as _is_packet_slot_var,
    manifest_array_selects_are_stable as _manifest_array_selects_are_stable,
    _is_stateful_register_array,
    is_stable_cutpoint_var as _is_stable_cutpoint_var,
    is_stable_projection_predicate_text,
    normalize_expr as _normalize_expr,
    record_array_select_indices as _record_array_select_indices,
    stable_register_slot_projection_vars as _stable_register_slot_projection_vars,
    specialize_dynamic_slot_guard as _specialize_dynamic_slot_guard_expr,
    split_args as _split_args,
    strip_wrapping_parens as _strip_wrapping_parens,
    unique as _unique,
    vars_in_expr as _vars_in_expr,
    vars_in_predicates as _vars_in_predicates,
)
from dslc.analysis.wraparound_projection_bool import constant_bool_expr as _constant_bool_expr
from dslc.analysis.wraparound_projection_cutpoint import cutpoint_entry_constants as _cutpoint_entry_constants
from dslc.transform.wraparound_analyze import _extract_main_phase_bodies, _infer_deterministic_scheduler_period


_RE_VAR_DECL = re.compile(r"^\s*var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_ASSIGN = re.compile(r"^\s*(?P<lhs>[^:;]+?)\s*:=\s*(?P<rhs>.*);\s*$")
_RE_HAVOC = re.compile(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_CALL = re.compile(r"^\s*call\s+(?:(?P<lhs>[^:=;]+?)\s*:=\s*)?(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)\((?P<args>.*)\)\s*;\s*$")
_RE_PROC = re.compile(
    r"^\s*procedure(?:\s+(?P<attrs>\{[^}]*\}))?\s+"
    r"(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\((?P<params>[^)]*)\)"
    r"(?:\s+returns\s*\((?P<returns>[^)]*)\))?"
)
_RE_MODIFIES = re.compile(r"^\s*modifies\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_WRITE_CALL = re.compile(r"^(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.write$")
_RE_BRACKET_INDEX = re.compile(r"\[([^\[\]]+)\]")
@dataclass(frozen=True)
class DependencyProjectionResult:
    proj_vars: Tuple[str, ...]
    proj_predicates: Tuple[str, ...] = ()
    proj_exprs: Tuple[str, ...] = ()
    cutpoint_predicates: Tuple[str, ...] = ()
    cutpoint_guard_alternatives: Tuple[Tuple[str, ...], ...] = ()
    source: str = "dependency_projection"
    complete: bool = True
    live_deps: Tuple[str, ...] = ()
    default_state: Tuple[str, ...] = ()
    notes: Tuple[str, ...] = ()
    unresolved_calls: Tuple[str, ...] = ()


@dataclass(frozen=True)
class _AssumeRecord:
    expr: str
    deps: Tuple[str, ...]
    depth: int = 0


@dataclass(frozen=True)
class _GuardRecord:
    expr: str
    deps: Tuple[str, ...]
    depth: int = 0


@dataclass
class _Proc:
    name: str
    params: Tuple[str, ...]
    body: Tuple[str, ...]
    returns: Tuple[str, ...] = ()
    modifies: Tuple[str, ...] = ()
    inline_hint: bool = False


@dataclass
class _State:
    deps: Dict[str, Set[str]]
    exprs: Dict[str, str] = field(default_factory=dict)
    stable_exprs: Dict[str, str] = field(default_factory=dict)
    control_live_deps: Set[str] = field(default_factory=set)
    assume_records: List[_AssumeRecord] = field(default_factory=list)
    guard_records_by_var: Dict[str, List[_GuardRecord]] = field(default_factory=dict)
    guard_record_groups_by_var: Dict[str, List[Tuple[_GuardRecord, ...]]] = field(default_factory=dict)
    unresolved_calls: Set[str] = field(default_factory=set)
    array_indices: Dict[str, Set[str]] = field(default_factory=dict)


def extract_dependency_projection(
    *,
    bpl_text: str,
    candidate: WraparoundCandidate,
    max_inline_depth: int = 16,
) -> DependencyProjectionResult:
    """
    Infer the replay-acceleration projection from Boogie-level control/data deps.

    The extractor computes *cutpoint live-in* dependencies for one deterministic
    scheduler round.  Values that are overwritten or freshly havoced by the
    current round (for example env-generated packet fields) are not treated as
    projection state.  Stable scheduler/mailbox bookkeeping is always included.

    This pass intentionally produces certificate input only; witness-derived
    assumptions remain outside the certified projection.
    """

    lines = bpl_text.splitlines()
    var_types = _parse_var_types(lines)
    if not var_types:
        return DependencyProjectionResult((), complete=False, notes=("no_global_vars",))

    default_state = _default_replay_state_vars(var_types)
    period = _infer_deterministic_scheduler_period(lines)
    if period is None or period <= 0:
        return DependencyProjectionResult(
            tuple(default_state),
            complete=False,
            live_deps=(),
            default_state=tuple(default_state),
            notes=("missing_deterministic_scheduler",),
        )

    try:
        phase_bodies = _extract_main_phase_bodies(bpl_text.splitlines(keepends=True), period)
    except Exception:
        return DependencyProjectionResult(
            tuple(default_state),
            complete=False,
            live_deps=(),
            default_state=tuple(default_state),
            notes=("missing_phase_bodies",),
        )

    procs = _parse_procedures(lines)
    state = _State(
        deps={v: {v} for v in var_types},
        exprs={v: v for v in var_types},
        stable_exprs=dict(getattr(candidate, "stable_substitutions", ()) or ()),
    )
    for body in phase_bodies:
        _process_lines(
            [ln.rstrip("\n") for ln in body],
            state=state,
            var_types=var_types,
            procs=procs,
            inline_depth=0,
            max_inline_depth=max_inline_depth,
            initial_bindings=None,
        )

    candidate_index_expr = _candidate_projection_index_expr(candidate, var_types=var_types)
    target_vars = _target_observation_vars(candidate, var_types)
    live_deps: Set[str] = set()
    for v in target_vars:
        live_deps.update(state.deps.get(v, {v} if v in var_types else set()))
    live_deps.update(_vars_in_expr(str(candidate.cutpoint_cond or "procurator_phase == 0"), var_types=var_types, deps=state.deps))
    # Control dependencies that guard target updates are already folded into the
    # target deps when assignments/calls execute under active guards.  Do not add
    # every guard seen in the whole round: post-update forwarding/drop guards can
    # otherwise become spurious projection state.

    excluded = _excluded_target_state(candidate, var_types)
    cutpoint_consts = _cutpoint_entry_constants(bpl_text, var_types=var_types, candidate=candidate)
    predicate_exprs = _projection_predicates_for_live_deps(
        state.assume_records,
        live_deps=live_deps,
        default_state=set(default_state),
        excluded=excluded,
        var_types=var_types,
    )
    cutpoint_predicates, incomplete_cutpoint_guards = _cutpoint_predicates_for_target_guards(
        state.guard_records_by_var,
        target_vars=target_vars,
        live_deps=live_deps,
        default_state=set(default_state),
        excluded=excluded,
        var_types=var_types,
        candidate=candidate,
        stable_consts=cutpoint_consts,
    )
    cutpoint_guard_alternatives = _cutpoint_guard_alternatives_for_target_guards(
        state.guard_record_groups_by_var,
        target_vars=target_vars,
        live_deps=live_deps,
        default_state=set(default_state),
        excluded=excluded,
        var_types=var_types,
        candidate=candidate,
        stable_consts=cutpoint_consts,
    )
    ambiguous_cutpoint_predicates = _ambiguous_predicate_pairs(cutpoint_predicates)
    cutpoint_predicates_for_projection = [
        pred
        for pred in cutpoint_predicates
        if not _predicate_mentions_target_slots(pred, candidate=candidate)
    ]
    predicate_exprs = _unique([*predicate_exprs, *cutpoint_predicates_for_projection])
    extra_stable_vars = _stable_register_slot_projection_vars(
        live_deps=live_deps,
        var_types=var_types,
        excluded=excluded,
        dynamic_index=bool(candidate.index_expr),
    )
    predicate_vars = _vars_in_predicates(
        [*predicate_exprs, *cutpoint_predicates],
        var_types,
    )
    dynamic_slot_deps = _dynamic_slot_deps(
        live_deps=live_deps,
        var_types=var_types,
        excluded=excluded,
        dynamic_index=bool(candidate.index_expr),
        predicate_vars=predicate_vars,
    )
    dynamic_slot_exprs = _dynamic_slot_projection_exprs(
        dynamic_slot_deps,
        pump_reg=candidate.pump_reg,
        index_expr=candidate.index_expr,
        var_types=var_types,
        array_indices=state.array_indices,
        stable_substitutions=getattr(candidate, "stable_substitutions", ()) or (),
    )
    wrong_slot_dynamic_deps = tuple(
        dep
        for dep in dynamic_slot_deps
            if _normalized_dynamic_slot_indices(state.array_indices, dep, candidate=candidate)
        and candidate_index_expr not in _normalized_dynamic_slot_indices(state.array_indices, dep, candidate=candidate)
    )
    unsupported_dynamic_slot_deps = tuple(
        dep for dep in dynamic_slot_deps if dep not in dynamic_slot_exprs and dep not in wrong_slot_dynamic_deps
    )
    projection: List[str] = []
    for v in _unique([*default_state, *sorted(live_deps), *extra_stable_vars]):
        if v in excluded:
            continue
        if v not in default_state and v in predicate_vars:
            continue
        if v.endswith("_pkt_external"):
            # This is a single-slot mailbox tag.  Its value is meaningful only
            # while the corresponding mailbox is non-empty, so it must not be
            # treated as stable cutpoint state.  If future programs truly depend
            # on it, the dependency analysis should expose a guarded mailbox
            # predicate instead of a bare equality.
            continue
        if v not in default_state and not _is_stable_cutpoint_var(v):
            continue
        if not _is_snapshot_scalar(v, var_types):
            continue
        projection.append(v)

    notes: List[str] = [
        f"dependency_projection_period={period}",
        f"dependency_projection_live_deps={len(live_deps)}",
    ]
    if predicate_exprs:
        notes.append(f"dependency_projection_predicates={len(predicate_exprs)}")
    if cutpoint_predicates:
        notes.append(f"dependency_projection_cutpoint_predicates={len(cutpoint_predicates)}")
    if cutpoint_guard_alternatives:
        notes.append(f"dependency_projection_cutpoint_guard_alternatives={len(cutpoint_guard_alternatives)}")
    if ambiguous_cutpoint_predicates:
        notes.extend(("dependency_projection_ambiguous_cutpoint_predicates=" + ",".join(ambiguous_cutpoint_predicates), "dependency_projection_incomplete"))
    if incomplete_cutpoint_guards:
        notes.extend((f"dependency_projection_unstable_cutpoint_guards={incomplete_cutpoint_guards}", "dependency_projection_incomplete"))
    if state.unresolved_calls:
        notes.append("dependency_projection_unresolved_calls=" + ",".join(sorted(state.unresolved_calls)))
        notes.append("dependency_projection_incomplete")
    if unsupported_dynamic_slot_deps:
        notes.append("dependency_projection_dynamic_slot_deps=" + ",".join(unsupported_dynamic_slot_deps))
        notes.append("dependency_projection_incomplete")
    if wrong_slot_dynamic_deps:
        notes.append("dependency_projection_dynamic_slot_index_mismatch=" + ",".join(wrong_slot_dynamic_deps))
        notes.append("dependency_projection_incomplete")
    elif dynamic_slot_exprs:
        notes.append("dependency_projection_dynamic_slot_exprs=" + ",".join(dynamic_slot_exprs.values()))

    return DependencyProjectionResult(
        proj_vars=tuple(_unique(projection)),
        proj_predicates=tuple(predicate_exprs),
        proj_exprs=tuple(dynamic_slot_exprs[dep] for dep in dynamic_slot_deps if dep in dynamic_slot_exprs),
        cutpoint_predicates=tuple(cutpoint_predicates),
        cutpoint_guard_alternatives=tuple(cutpoint_guard_alternatives),
        complete=(
            not bool(state.unresolved_calls)
            and not bool(unsupported_dynamic_slot_deps)
            and not bool(wrong_slot_dynamic_deps)
            and not bool(ambiguous_cutpoint_predicates)
            and not bool(incomplete_cutpoint_guards)
        ),
        live_deps=tuple(sorted(live_deps)),
        default_state=tuple(default_state),
        notes=tuple(notes),
        unresolved_calls=tuple(sorted(state.unresolved_calls)),
    )


def _parse_var_types(lines: Sequence[str]) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for ln in lines:
        m = _RE_VAR_DECL.match(ln.strip())
        if m:
            out[m.group("name")] = m.group("type").strip()
    return out


def _parse_var_decl_names(line: str) -> Tuple[str, ...]:
    m = _RE_VAR_DECL.match(line.strip())
    if not m:
        return ()
    names: List[str] = []
    for raw in _split_args(m.group("name")):
        name = raw.strip()
        if name:
            names.append(name)
    return tuple(names)


def _default_replay_state_vars(var_types: Dict[str, str]) -> List[str]:
    out: List[str] = []
    if "procurator_phase" in var_types:
        out.append("procurator_phase")
    for name, typ in sorted(var_types.items()):
        if typ == "int" and (name.endswith("_inbox_count") or name.endswith("_egress_count")):
            out.append(name)
    return _unique(out)


def _parse_procedures(lines: Sequence[str]) -> Dict[str, _Proc]:
    out: Dict[str, _Proc] = {}
    i = 0
    n = len(lines)
    while i < n:
        m = _RE_PROC.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group("name")
        params = _parse_param_names(m.group("params"))
        returns = _parse_param_names(m.group("returns") or "")
        attrs = m.group("attrs") or ""
        inline_hint = ":inline" in attrs
        open_idx = None
        for j in range(i, n):
            if j == i:
                if "{" in lines[j][m.end() :]:
                    open_idx = j
                    break
                continue
            if _RE_PROC.match(lines[j]):
                break
            if "{" in lines[j]:
                open_idx = j
                break
        if open_idx is None:
            next_idx = _next_proc_index(lines, i + 1, n)
            out[name] = _Proc(
                name=name,
                params=params,
                returns=returns,
                body=(),
                modifies=tuple(_parse_modifies(lines[i + 1 : next_idx])),
                inline_hint=inline_hint,
            )
            i = next_idx
            continue
        depth = 0
        close_idx = None
        for j in range(open_idx, n):
            for ch in lines[j]:
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        close_idx = j
                        break
            if close_idx is not None:
                break
        if close_idx is None:
            i += 1
            continue
        out[name] = _Proc(
            name=name,
            params=params,
            returns=returns,
            body=tuple(lines[open_idx + 1 : close_idx]),
            modifies=tuple(_parse_modifies(lines[i + 1 : open_idx])),
            inline_hint=inline_hint,
        )
        i = close_idx + 1
    return out


def _next_proc_index(lines: Sequence[str], start: int, n: int) -> int:
    for j in range(start, n):
        if _RE_PROC.match(lines[j]):
            return j
    return n


def _parse_modifies(lines: Sequence[str]) -> List[str]:
    out: List[str] = []
    for ln in lines:
        m = _RE_MODIFIES.match(ln.strip())
        if not m:
            continue
        for v in _split_args(m.group("vars")):
            vv = v.strip()
            if vv:
                out.append(vv)
    return _unique(out)


def _parse_param_names(params: str) -> Tuple[str, ...]:
    out: List[str] = []
    for part in _split_args(params):
        part = part.strip()
        if not part:
            continue
        part = part.replace("in ", "").replace("out ", "").replace("inout ", "").strip()
        if ":" not in part:
            continue
        out.append(part.split(":", 1)[0].strip())
    return tuple(out)


def _process_lines(
    lines: Sequence[str],
    *,
    state: _State,
    var_types: Dict[str, str],
    procs: Dict[str, _Proc],
    inline_depth: int,
    max_inline_depth: int,
    initial_bindings: Optional[Dict[str, Set[str]]],
    initial_exprs: Optional[Dict[str, str]] = None,
    inherited_guard_deps: Optional[Set[str]] = None,
    inherited_guard_records: Optional[Sequence[_GuardRecord]] = None,
    inherited_guard_present: bool = False,
    capture_names: Optional[Sequence[str]] = None,
    capture_exprs_out: Optional[Dict[str, str]] = None,
) -> Dict[str, Set[str]]:
    saved: Dict[str, Optional[Set[str]]] = {}
    saved_exprs: Dict[str, Optional[str]] = {}
    local_saved: Dict[str, Optional[Set[str]]] = {}
    local_expr_saved: Dict[str, Optional[str]] = {}
    if initial_bindings:
        for name, deps in initial_bindings.items():
            saved[name] = set(state.deps[name]) if name in state.deps else None
            state.deps[name] = set(deps)
            saved_exprs[name] = state.exprs.get(name)
            if initial_exprs and name in initial_exprs:
                state.exprs[name] = initial_exprs[name]
            else:
                state.exprs[name] = name

    guard_stack: List[Tuple[Set[str], Tuple[_GuardRecord, ...], int]] = []
    guard_refcnt: Dict[str, int] = {}
    pending_guard: Optional[Set[str]] = None
    pending_guard_records: Optional[Tuple[_GuardRecord, ...]] = None
    last_closed_guard: Optional[Set[str]] = None
    last_closed_guard_records: Optional[Tuple[_GuardRecord, ...]] = None
    brace_depth = 0

    def active_guard_deps() -> Set[str]:
        out: Set[str] = set(inherited_guard_deps or set())
        for deps in guard_refcnt:
            out.add(deps)
        return out

    def active_guard_records() -> List[_GuardRecord]:
        out: List[_GuardRecord] = list(inherited_guard_records or ())
        for _deps, records, _depth in guard_stack:
            out.extend(records)
        return out

    def active_guard_present() -> bool:
        return inherited_guard_present or bool(guard_stack)

    def advance_braces(line: str) -> None:
        nonlocal brace_depth, pending_guard, pending_guard_records
        nonlocal last_closed_guard, last_closed_guard_records
        popped_on_line: Optional[Set[str]] = None
        popped_records_on_line: Optional[Tuple[_GuardRecord, ...]] = None
        for ch in line:
            if ch == "}":
                brace_depth -= 1
                while guard_stack and guard_stack[-1][2] > brace_depth:
                    gv, grecs, _depth = guard_stack.pop()
                    popped_on_line = set(gv)
                    popped_records_on_line = tuple(grecs)
                    for v in gv:
                        cur = guard_refcnt.get(v, 0) - 1
                        if cur <= 0:
                            guard_refcnt.pop(v, None)
                        else:
                            guard_refcnt[v] = cur
            elif ch == "{":
                brace_depth += 1
                if pending_guard is not None:
                    gv = set(pending_guard)
                    grecs = tuple(pending_guard_records or ())
                    pending_guard = None
                    pending_guard_records = None
                    guard_stack.append((gv, grecs, brace_depth))
                    for v in gv:
                        guard_refcnt[v] = guard_refcnt.get(v, 0) + 1
        if popped_on_line is not None:
            last_closed_guard = popped_on_line
            last_closed_guard_records = popped_records_on_line

    try:
        for raw in lines:
            ln = raw.split("//", 1)[0]
            s = ln.strip()
            if not s or s.startswith("var "):
                if s.startswith("var "):
                    for name in _parse_var_decl_names(s):
                        if name not in saved and name not in local_saved:
                            local_saved[name] = set(state.deps[name]) if name in state.deps else None
                            local_expr_saved[name] = state.exprs.get(name)
                        state.deps[name] = {name}
                        state.exprs[name] = name
                advance_braces(ln)
                continue

            if _is_if_stmt(s):
                cond = _extract_cond_text(ln)
                pending_guard = _deps_in_expr(cond, var_types=var_types, deps=state.deps)
                pending_guard_records = (_make_guard_record(cond, pending_guard, state=state, depth=inline_depth),)
                state.control_live_deps.update(pending_guard)
            elif _is_while_stmt(s):
                cond = _extract_cond_text(ln)
                pending_guard = _deps_in_expr(cond, var_types=var_types, deps=state.deps)
                pending_guard_records = (_make_guard_record(cond, pending_guard, state=state, depth=inline_depth),)
                state.control_live_deps.update(pending_guard)
            elif _is_else_if_stmt(s):
                old = set(last_closed_guard or (guard_stack[-1][0] if guard_stack else set()))
                old_records = tuple(last_closed_guard_records or (guard_stack[-1][1] if guard_stack else ()))
                cond = _extract_cond_text(ln)
                cond_deps = _deps_in_expr(cond, var_types=var_types, deps=state.deps)
                pending_guard = set(old) | cond_deps
                pending_guard_records = (
                    *_negate_guard_records(old_records),
                    _make_guard_record(cond, cond_deps, state=state, depth=inline_depth),
                )
                state.control_live_deps.update(pending_guard)
            elif _is_else_stmt(s):
                old = set(last_closed_guard or (guard_stack[-1][0] if guard_stack else set()))
                old_records = tuple(last_closed_guard_records or (guard_stack[-1][1] if guard_stack else ()))
                pending_guard = set(old)
                pending_guard_records = _negate_guard_records(old_records)
                state.control_live_deps.update(pending_guard)

            guard_deps = active_guard_deps()
            guard_records = active_guard_records()
            keep_old = active_guard_present()
            if s.startswith("assume"):
                assume_expr = _assume_expr_text(s)
                adeps = _deps_in_expr(assume_expr, var_types=var_types, deps=state.deps)
                state.control_live_deps.update(adeps | guard_deps)
                if assume_expr and assume_expr != "true":
                    state.assume_records.append(
                        _AssumeRecord(expr=assume_expr, deps=tuple(sorted(adeps | guard_deps)), depth=inline_depth)
                    )

            m_havoc = _RE_HAVOC.match(ln)
            if m_havoc:
                for lhs in _split_args(m_havoc.group("vars")):
                    _assign_deps(
                        lhs.strip(),
                        set(guard_deps),
                        state=state,
                        var_types=var_types,
                        keep_old=keep_old,
                        expr=lhs.strip(),
                        guard_records=guard_records,
                    )
                advance_braces(ln)
                continue

            m_call = _RE_CALL.match(ln)
            if m_call:
                _process_call(
                    m_call,
                    state=state,
                    var_types=var_types,
                    procs=procs,
                    guard_deps=guard_deps,
                    guard_records=guard_records,
                    inline_depth=inline_depth,
                    max_inline_depth=max_inline_depth,
                )
                advance_braces(ln)
                continue

            m_asn = _RE_ASSIGN.match(ln)
            if m_asn:
                rhs_deps = _deps_in_expr(m_asn.group("rhs"), var_types=var_types, deps=state.deps)
                rhs_expr = _normalize_expr(_substitute_expr(m_asn.group("rhs"), state=state))
                _record_array_select_indices(rhs_expr, array_indices=state.array_indices, var_types=var_types)
                for lhs in _split_args(m_asn.group("lhs")):
                    _assign_deps(
                        lhs.strip(),
                        rhs_deps | guard_deps,
                        state=state,
                        var_types=var_types,
                        keep_old=keep_old,
                        expr=rhs_expr,
                        guard_records=guard_records,
                        index_expr=_array_assignment_index_expr(lhs.strip()),
                    )

            advance_braces(ln)
        captured = {
            name: set(state.deps.get(name, {name}))
            for name in (capture_names or ())
        }
        if capture_exprs_out is not None:
            for name in (capture_names or ()):
                capture_exprs_out[name] = state.exprs.get(name, name)
        return captured
    finally:
        for name, old in local_saved.items():
            if old is None:
                state.deps.pop(name, None)
            else:
                state.deps[name] = old
        for name, old in local_expr_saved.items():
            if old is None:
                state.exprs.pop(name, None)
            else:
                state.exprs[name] = old
        if initial_bindings:
            for name, old in saved.items():
                if old is None:
                    state.deps.pop(name, None)
                else:
                    state.deps[name] = old
            for name, old in saved_exprs.items():
                if old is None:
                    state.exprs.pop(name, None)
                else:
                    state.exprs[name] = old
    return {}


def _process_call(
    m_call: re.Match[str],
    *,
    state: _State,
    var_types: Dict[str, str],
    procs: Dict[str, _Proc],
    guard_deps: Set[str],
    guard_records: Sequence[_GuardRecord],
    inline_depth: int,
    max_inline_depth: int,
) -> None:
    proc = m_call.group("proc").strip()
    if proc.endswith(".read.read"):
        proc = proc[: -len(".read")]
    args = _split_args(m_call.group("args"))
    lhs = (m_call.group("lhs") or "").strip()

    m_write = _RE_WRITE_CALL.match(proc)
    if m_write:
        reg = m_write.group("reg")
        idx_deps = _deps_in_expr(args[0] if args else "", var_types=var_types, deps=state.deps)
        val_deps = _deps_in_expr(args[1] if len(args) > 1 else "", var_types=var_types, deps=state.deps)
        deps = idx_deps | val_deps | guard_deps
        value_expr = _normalize_expr(_substitute_expr(args[1] if len(args) > 1 else "", state=state))
        for v in (
            reg,
            f"{reg}__last_index",
            f"{reg}__last_value",
            f"{reg}__wrote_any",
            f"{reg}__wrote_index0",
            f"{reg}__last0_value",
        ):
            if v in var_types:
                _assign_deps(
                    v,
                    deps,
                    state=state,
                    var_types=var_types,
                    keep_old=bool(guard_deps),
                    expr=value_expr or v,
                    guard_records=guard_records,
                    index_expr=args[0] if args else None,
                )
        return

    proc_obj = procs.get(proc)
    if proc_obj is not None and inline_depth < max_inline_depth:
        if lhs:
            lhs_vars = _split_args(lhs)
            if (
                not proc_obj.inline_hint
                or proc_obj.modifies
                or not proc_obj.body
                or not proc_obj.returns
                or len(lhs_vars) != len(proc_obj.returns)
            ):
                state.unresolved_calls.add(f"{proc}->assigned_call")
                return
            arg_deps = [_deps_in_expr(a, var_types=var_types, deps=state.deps) | guard_deps for a in args]
            arg_exprs = [_normalize_expr(_substitute_expr(a, state=state)) for a in args]
            bindings = {p: set(arg_deps[i]) for i, p in enumerate(proc_obj.params) if i < len(arg_deps)}
            binding_exprs = {p: arg_exprs[i] for i, p in enumerate(proc_obj.params) if i < len(arg_exprs)}
            for ret in proc_obj.returns:
                bindings.setdefault(ret, {ret})
                binding_exprs.setdefault(ret, ret)
            ret_exprs: Dict[str, str] = {}
            ret_deps = _process_lines(
                proc_obj.body,
                state=state,
                var_types=var_types,
                procs=procs,
                inline_depth=inline_depth + 1,
                max_inline_depth=max_inline_depth,
                initial_bindings=bindings,
                initial_exprs=binding_exprs,
                inherited_guard_deps=set(guard_deps),
                inherited_guard_records=guard_records,
                inherited_guard_present=False,
                capture_names=proc_obj.returns,
                capture_exprs_out=ret_exprs,
            )
            for l, ret in zip(lhs_vars, proc_obj.returns):
                deps = set(ret_deps.get(ret, set()))
                if ret in deps:
                    state.unresolved_calls.add(f"{proc}->assigned_call")
                    return
                _assign_deps(
                    l.strip(),
                    deps | guard_deps,
                    state=state,
                    var_types=var_types,
                    keep_old=bool(guard_deps),
                    expr=ret_exprs.get(ret, ret),
                    guard_records=guard_records,
                )
            return
        if not proc_obj.body:
            opaque_deps = set(guard_deps)
            for arg in args:
                opaque_deps.update(_deps_in_expr(arg, var_types=var_types, deps=state.deps))
            for mod in proc_obj.modifies:
                _assign_deps(
                    mod,
                    opaque_deps | ({mod} if mod in var_types else set()),
                    state=state,
                    var_types=var_types,
                    keep_old=True,
                    expr=mod,
                    guard_records=guard_records,
                )
            return
        arg_deps = [_deps_in_expr(a, var_types=var_types, deps=state.deps) | guard_deps for a in args]
        arg_exprs = [_normalize_expr(_substitute_expr(a, state=state)) for a in args]
        bindings = {p: set(arg_deps[i]) for i, p in enumerate(proc_obj.params) if i < len(arg_deps)}
        binding_exprs = {p: arg_exprs[i] for i, p in enumerate(proc_obj.params) if i < len(arg_exprs)}
        _process_lines(
            proc_obj.body,
            state=state,
            var_types=var_types,
            procs=procs,
            inline_depth=inline_depth + 1,
            max_inline_depth=max_inline_depth,
            initial_bindings=bindings,
            initial_exprs=binding_exprs,
            inherited_guard_deps=set(guard_deps),
            inherited_guard_records=guard_records,
            inherited_guard_present=bool(guard_deps),
        )
        return

    if lhs:
        if len(args) == 2 and "." in proc and proc.endswith(".read"):
            reg = proc.rsplit(".", 1)[0]
            if reg.endswith(".read"):
                reg = reg[: -len(".read")]
            if reg in var_types and _is_stateful_register_array(reg, var_types):
                read_expr = f"{reg}[{_normalize_expr(_substitute_expr(args[1], state=state))}]"
                read_deps = _deps_in_expr(args[1], var_types=var_types, deps=state.deps) | {reg} | set(guard_deps)
                for l in _split_args(lhs):
                    _assign_deps(
                        l.strip(),
                        read_deps,
                        state=state,
                        var_types=var_types,
                        keep_old=bool(guard_deps),
                        expr=read_expr,
                        guard_records=guard_records,
                    )
                _record_array_select_indices(read_expr, array_indices=state.array_indices, var_types=var_types)
                return
        state.unresolved_calls.add(f"{proc}->assigned_call")
        deps = set(guard_deps)
        for arg in args:
            deps.update(_deps_in_expr(arg, var_types=var_types, deps=state.deps))
        for l in _split_args(lhs):
            _assign_deps(
                l.strip(),
                deps,
                state=state,
                var_types=var_types,
                keep_old=bool(guard_deps),
                expr=l.strip(),
                guard_records=guard_records,
            )
    else:
        state.unresolved_calls.add(proc)


def _assign_deps(
    lhs: str,
    new_deps: Set[str],
    *,
    state: _State,
    var_types: Dict[str, str],
    keep_old: bool = False,
    expr: Optional[str] = None,
    guard_records: Sequence[_GuardRecord] = (),
    index_expr: Optional[str] = None,
) -> None:
    base = lhs.split("[", 1)[0].strip()
    base = base.strip("()")
    if not base:
        return
    if base not in var_types and base not in state.deps:
        return
    old = state.deps.get(base, {base} if base in var_types else set())
    deps = set(new_deps)
    if keep_old:
        deps.update(old)
    state.deps[base] = deps
    state.exprs[base] = _normalize_expr(expr or base)
    if "[" in var_types.get(base, "") and index_expr:
        state.array_indices.setdefault(base, set()).add(_normalize_expr(index_expr))
    if guard_records:
        recs = state.guard_records_by_var.setdefault(base, [])
        recs.extend(guard_records)
        groups = state.guard_record_groups_by_var.setdefault(base, [])
        group = tuple(guard_records)
        if group and (not groups or groups[-1] != group):
            groups.append(group)


def _make_guard_record(
    expr: Optional[str],
    deps: Set[str],
    *,
    state: _State,
    depth: int,
) -> _GuardRecord:
    substituted = _normalize_expr(_substitute_expr(expr or "", state=state))
    _record_array_select_indices(substituted, array_indices=state.array_indices, var_types={k: "" for k in state.deps})
    return _GuardRecord(
        expr=substituted,
        deps=tuple(sorted(deps)),
        depth=depth,
    )


def _negate_guard_records(records: Sequence[_GuardRecord]) -> Tuple[_GuardRecord, ...]:
    out: List[_GuardRecord] = []
    for rec in records:
        expr = rec.expr.strip()
        if not expr:
            continue
        out.append(_GuardRecord(expr=f"!({expr})", deps=rec.deps, depth=rec.depth))
    return tuple(out)


def _substitute_expr(expr: Optional[str], *, state: _State) -> str:
    text = str(expr or "").strip()
    if not text:
        return ""

    protected: Dict[str, str] = {}

    def protect_read_receiver(match: re.Match[str]) -> str:
        placeholder = f"__p4b_read_receiver_{len(protected)}__"
        protected[placeholder] = match.group("reg")
        return f"{match.group('reg')}.read({placeholder},"

    text = re.sub(
        r"\b(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.read\s*\(\s*(?P=reg)\s*,",
        protect_read_receiver,
        text,
    )

    def repl(match: re.Match[str]) -> str:
        tok = match.group(0)
        if tok in protected:
            return tok
        stable = state.stable_exprs.get(tok)
        if stable:
            return f"({stable})"
        replacement = state.exprs.get(tok)
        if not replacement or replacement == tok:
            return tok
        return f"({replacement})"

    substituted = _RE_IDENT.sub(repl, text)
    for placeholder, original in protected.items():
        substituted = substituted.replace(placeholder, original)
    return substituted


def _assume_expr_text(stmt: str) -> str:
    s = stmt.strip()
    if not s.startswith("assume"):
        return ""
    s = s[len("assume") :].strip()
    if s.endswith(";"):
        s = s[:-1].strip()
    return _strip_wrapping_parens(s)


def _is_if_stmt(s: str) -> bool:
    return s.startswith("if") and len(s) > 2 and s[2] in " \t("


def _is_else_if_stmt(s: str) -> bool:
    return s.startswith("} else if") or s.startswith("else if")


def _is_else_stmt(s: str) -> bool:
    return s.startswith("} else") or s.startswith("else")


def _is_while_stmt(s: str) -> bool:
    return s.startswith("while") and len(s) > 5 and s[5] in " \t("


def _projection_predicates_for_live_deps(
    records: Sequence[_AssumeRecord],
    *,
    live_deps: Set[str],
    default_state: Set[str],
    excluded: Set[str],
    var_types: Dict[str, str],
) -> List[str]:
    wanted = set(live_deps).difference(default_state).difference(excluded)
    out: List[str] = []
    seen: Set[str] = set()
    for rec in records:
        deps = set(rec.deps)
        if not deps.intersection(wanted):
            continue
        if deps and deps.issubset(default_state):
            continue
        expr = rec.expr.strip()
        if not expr or expr == "true" or expr in seen:
            continue
        expr_vars = set(_RE_IDENT.findall(expr))
        if expr_vars and expr_vars.issubset(default_state):
            continue
        if rec.depth != 0 and any(_is_packet_slot_var(v) for v in expr_vars):
            continue
        if not _is_stable_projection_predicate(expr, var_types=var_types, default_state=default_state, excluded=excluded):
            continue
        seen.add(expr)
        out.append(expr)
    return out


def _cutpoint_predicates_for_target_guards(
    records_by_var: Dict[str, List[_GuardRecord]],
    *,
    target_vars: Sequence[str],
    live_deps: Set[str],
    default_state: Set[str],
    excluded: Set[str],
    var_types: Dict[str, str],
    candidate: WraparoundCandidate,
    stable_consts: Dict[str, str],
) -> Tuple[List[str], int]:
    wanted = set(live_deps).difference(default_state).difference(excluded)
    target_arrays = {v for v in target_vars if "[" in str(var_types.get(v, ""))}
    out: List[str] = []
    seen: Set[str] = set()
    incomplete = 0
    for target in target_vars:
        for rec in records_by_var.get(target, []):
            expr = _specialize_dynamic_slot_guard(
                rec.expr.strip(),
                candidate=candidate,
                live_deps=live_deps,
                excluded=excluded,
                var_types=var_types,
                stable_consts=stable_consts,
            )
            const_val = _constant_bool_expr(expr)
            if const_val is True:
                continue
            if const_val is False:
                continue
            if not expr or expr == "true" or expr in seen:
                continue
            deps = set(rec.deps)
            if not deps.intersection(wanted):
                continue
            if deps and deps.issubset(default_state):
                continue
            if not _is_cutpoint_shape_predicate(
                expr,
                var_types=var_types,
                default_state=default_state,
                excluded=excluded,
                target_arrays=target_arrays,
                stable_indices=(_candidate_projection_index_expr(candidate, var_types=var_types),),
            ):
                incomplete += 1
                continue
            seen.add(expr)
            out.append(expr)
    return out, incomplete


def _cutpoint_guard_alternatives_for_target_guards(
    groups_by_var: Dict[str, List[Tuple[_GuardRecord, ...]]],
    *,
    target_vars: Sequence[str],
    live_deps: Set[str],
    default_state: Set[str],
    excluded: Set[str],
    var_types: Dict[str, str],
    candidate: WraparoundCandidate,
    stable_consts: Dict[str, str],
) -> List[Tuple[str, ...]]:
    """
    Preserve cutpoint guard predicates grouped by the write site that produced
    them.

    The legacy projection flattens all target-write guards into one predicate
    set, which is the right conservative certificate input but loses the
    branch structure needed for future cutpoint splitting.  Keeping alternatives
    here lets callers distinguish mutually exclusive initialization and steady
    pump branches without relaxing the current `complete` gate.
    """

    wanted = set(live_deps).difference(default_state).difference(excluded)
    target_arrays = {v for v in target_vars if "[" in str(var_types.get(v, ""))}
    out: List[Tuple[str, ...]] = []
    seen_groups: Set[Tuple[str, ...]] = set()
    for target in target_vars:
        for records in groups_by_var.get(target, []):
            group: List[str] = []
            for rec in records:
                expr = _specialize_dynamic_slot_guard(
                    rec.expr.strip(),
                    candidate=candidate,
                    live_deps=live_deps,
                    excluded=excluded,
                    var_types=var_types,
                    stable_consts=stable_consts,
                )
                const_val = _constant_bool_expr(expr)
                if const_val is True:
                    continue
                if const_val is False:
                    group = []
                    break
                if not expr or expr == "true":
                    continue
                deps = set(rec.deps)
                if not deps.intersection(wanted):
                    continue
                if deps and deps.issubset(default_state):
                    continue
                if not _is_cutpoint_shape_predicate(
                    expr,
                    var_types=var_types,
                    default_state=default_state,
                    excluded=excluded,
                    target_arrays=target_arrays,
                    stable_indices=(_candidate_projection_index_expr(candidate, var_types=var_types),),
                ):
                    continue
                group.append(expr)
            alt = tuple(_unique(group))
            if not alt or alt in seen_groups:
                continue
            seen_groups.add(alt)
            out.append(alt)
    return out


def _guard_has_dynamic_slot_dependency(
    deps: Iterable[str],
    *,
    live_deps: Set[str],
    excluded: Set[str],
    var_types: Dict[str, str],
    candidate: WraparoundCandidate,
    state: Optional[_State] = None,
) -> bool:
    target_index_width = _array_index_width(var_types.get(candidate.pump_reg, ""))
    if target_index_width is None:
        return False
    for dep in set(deps).intersection(live_deps):
        if dep in excluded:
            continue
        typ = var_types.get(dep, "")
        if "[" in typ and "]" in typ and _array_index_width(typ) == target_index_width:
            if not _is_stateful_register_array(dep, var_types):
                continue
            if state is not None and candidate.index_expr:
                indices = _normalized_dynamic_slot_indices(state.array_indices, dep, candidate=candidate)
                if indices and candidate.index_expr not in indices:
                    continue
            return True
    return False


def _normalized_dynamic_slot_indices(
    array_indices: Dict[str, Set[str]],
    dep: str,
    *,
    candidate: WraparoundCandidate,
) -> Set[str]:
    subst = dict(getattr(candidate, "stable_substitutions", ()) or ())
    out: Set[str] = set()
    for idx in _dynamic_slot_indices(array_indices, dep):
        cur = idx
        for token, value in subst.items():
            cur = re.sub(rf"\b{re.escape(token)}\b", value, cur)
        out.add(_normalize_expr(cur))
    return out


def _ambiguous_predicate_pairs(predicates: Sequence[str]) -> List[str]:
    positives = {_strip_wrapping_parens(p.strip()) for p in predicates if p.strip()}
    ambiguous: List[str] = []
    for pred in positives:
        inner = _negated_predicate_inner(pred)
        if inner and inner in positives:
            ambiguous.append(inner)
    return _unique(ambiguous)


def _negated_predicate_inner(expr: str) -> Optional[str]:
    s = expr.strip()
    if not s.startswith("!"):
        return None
    inner = s[1:].strip()
    if not inner:
        return None
    return _strip_wrapping_parens(inner)


def _specialize_dynamic_slot_guard(
    expr: str,
    *,
    candidate: WraparoundCandidate,
    live_deps: Set[str],
    excluded: Set[str],
    var_types: Dict[str, str],
    stable_consts: Optional[Dict[str, str]] = None,
) -> str:
    """Specialize register-slot guard predicates to the candidate dynamic key.

    The dependency pass is intentionally lightweight and not fully path
    sensitive.  For dynamic-index wraparound candidates, P4B's meta/index
    recovery already gives us the concrete replay key.  A guard such as
    `time_reg[meta.register_index] != 0` should therefore be recorded as a
    predicate over `time_reg[candidate.index_expr]`, instead of carrying packet
    scratch variables from the parser path used to compute `meta.register_index`.
    """
    target_excluded = set(excluded).difference(set(_unique([candidate.pump_reg, *candidate.accel_regs])))
    return _specialize_dynamic_slot_guard_expr(
        expr,
        index_expr=_candidate_projection_index_expr(candidate, var_types=var_types),
        pump_reg=candidate.pump_reg,
        live_deps=live_deps,
        excluded=target_excluded,
        var_types=var_types,
        stable_substitutions=getattr(candidate, "stable_substitutions", ()) or (),
        stable_consts=stable_consts,
    )


def _candidate_projection_index_expr(candidate: WraparoundCandidate, *, var_types: Dict[str, str]) -> Optional[str]:
    if candidate.index_expr:
        return candidate.index_expr
    if candidate.index_value is None:
        return None
    width = _array_index_width(var_types.get(candidate.pump_reg, ""))
    if width is None:
        return None
    return f"{int(candidate.index_value)}bv{width}"


def _predicate_mentions_target_slots(expr: str, *, candidate: WraparoundCandidate) -> bool:
    """
    Predicates over the accelerated target slot are cutpoint/branch conditions,
    not replay-shape invariants.

    A closure step intentionally updates `pump_reg[index]` by `step_delta`, so
    requiring target-slot predicates to stay equal across the step can reject a
    valid replay schedule.  We still keep these predicates in
    `cutpoint_predicates` / branch alternatives; this helper only filters what is
    copied into `proj_predicates` (the closure equality projection).
    """

    target_arrays = set(_unique([candidate.pump_reg, *candidate.accel_regs]))
    if not target_arrays:
        return False
    for sel in _array_selects_in_expr(_normalize_expr(str(expr))):
        if sel.array in target_arrays:
            return True
    return False


def _is_cutpoint_shape_predicate(
    expr: str,
    *,
    var_types: Dict[str, str],
    default_state: Set[str],
    excluded: Set[str],
    target_arrays: Set[str],
    stable_indices: Iterable[str] = (),
) -> bool:
    normalized_expr = _normalize_expr(expr)
    stable_index_set = {_normalize_expr(v) for v in stable_indices if str(v).strip()}
    manifest_stable_arrays = _manifest_array_selects_are_stable(normalized_expr, ignored=("true", "false", "old"))
    allowed_array_selects: Set[str] = set()
    array_index_tokens: Set[str] = set()
    for sel in _array_selects_in_expr(normalized_expr):
        if sel.array in excluded and sel.array not in target_arrays:
            return False
        if stable_index_set and _normalize_expr(sel.index) not in stable_index_set:
            continue
        allowed_array_selects.add(sel.array)
        array_index_tokens.update(_RE_IDENT.findall(sel.index))
    for m in _RE_BRACKET_INDEX.finditer(normalized_expr):
        array_index_tokens.update(_RE_IDENT.findall(m.group(1)))
    state_vars = {tok for tok in _RE_IDENT.findall(expr) if tok in var_types}
    if not state_vars:
        return False
    for v in state_vars:
        if v in excluded and v not in target_arrays:
            return False
        if v in array_index_tokens:
            continue
        typ = var_types.get(v, "")
        if "[" in typ or "]" in typ:
            if v in target_arrays:
                if not stable_index_set or v in allowed_array_selects:
                    continue
                return False
            if manifest_stable_arrays and v in allowed_array_selects:
                continue
            if _is_stateful_register_array(v, var_types):
                continue
            return False
        if v in default_state:
            continue
        if _is_stable_cutpoint_var(v):
            continue
        # Guard predicates may mention packet-derived scalars only when the
        # expression itself substitutes them away to stable register slots.  A
        # residual transient scalar would make the cutpoint depend on per-pass
        # packet scratch state, so keep that out of certified projections.
        return False
    return True


def _is_stable_projection_predicate(
    expr: str,
    *,
    var_types: Dict[str, str],
    default_state: Set[str],
    excluded: Set[str],
) -> bool:
    state_vars = {tok for tok in _RE_IDENT.findall(expr) if tok in var_types}
    if not state_vars:
        return False
    for v in state_vars:
        if v in excluded:
            return False
        if not _is_snapshot_scalar(v, var_types):
            return False
        if v in default_state:
            continue
        if not _is_stable_cutpoint_var(v):
            return False
    return True


def _target_observation_vars(candidate: WraparoundCandidate, var_types: Dict[str, str]) -> List[str]:
    out: List[str] = []
    for reg in _unique([candidate.pump_reg, *candidate.accel_regs]):
        if candidate.index_expr is None and candidate.index_value == 0 and f"{reg}__last0_value" in var_types:
            out.append(f"{reg}__last0_value")
            continue
        for v in (reg, f"{reg}__last_value", f"{reg}__last0_value"):
            if v in var_types:
                out.append(v)
                break
    return out


def _excluded_target_state(candidate: WraparoundCandidate, var_types: Dict[str, str]) -> Set[str]:
    out: Set[str] = set()
    for reg in _unique([candidate.pump_reg, *candidate.accel_regs]):
        for name in var_types:
            if name == reg or name.startswith(f"{reg}__"):
                out.add(name)
    return out


def _is_snapshot_scalar(name: str, var_types: Dict[str, str]) -> bool:
    typ = var_types.get(name)
    if not typ:
        return False
    if "[" in typ or "]" in typ:
        return False
    return True
