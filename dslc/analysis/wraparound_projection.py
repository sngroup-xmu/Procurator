from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate
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


@dataclass(frozen=True)
class DependencyProjectionResult:
    proj_vars: Tuple[str, ...]
    proj_predicates: Tuple[str, ...] = ()
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
    control_live_deps: Set[str] = field(default_factory=set)
    assume_records: List[_AssumeRecord] = field(default_factory=list)
    unresolved_calls: Set[str] = field(default_factory=set)


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
        return DependencyProjectionResult((), notes=("no_global_vars",))

    default_state = _default_replay_state_vars(var_types)
    period = _infer_deterministic_scheduler_period(lines)
    if period is None or period <= 0:
        return DependencyProjectionResult(
            tuple(default_state),
            live_deps=(),
            default_state=tuple(default_state),
            notes=("missing_deterministic_scheduler",),
        )

    try:
        phase_bodies = _extract_main_phase_bodies(bpl_text.splitlines(keepends=True), period)
    except Exception:
        return DependencyProjectionResult(
            tuple(default_state),
            live_deps=(),
            default_state=tuple(default_state),
            notes=("missing_phase_bodies",),
        )

    procs = _parse_procedures(lines)
    state = _State(deps={v: {v} for v in var_types})
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
    predicate_exprs = _projection_predicates_for_live_deps(
        state.assume_records,
        live_deps=live_deps,
        default_state=set(default_state),
        excluded=excluded,
        var_types=var_types,
    )
    extra_stable_vars = _stable_register_slot_projection_vars(
        live_deps=live_deps,
        var_types=var_types,
        excluded=excluded,
    )
    predicate_vars = _vars_in_predicates(predicate_exprs, var_types)
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
    if state.unresolved_calls:
        notes.append("dependency_projection_unresolved_calls=" + ",".join(sorted(state.unresolved_calls)))
        notes.append("dependency_projection_incomplete")

    return DependencyProjectionResult(
        proj_vars=tuple(_unique(projection)),
        proj_predicates=tuple(predicate_exprs),
        complete=not bool(state.unresolved_calls),
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
    inherited_guard_deps: Optional[Set[str]] = None,
    inherited_guard_present: bool = False,
    capture_names: Optional[Sequence[str]] = None,
) -> Dict[str, Set[str]]:
    saved: Dict[str, Optional[Set[str]]] = {}
    local_saved: Dict[str, Optional[Set[str]]] = {}
    if initial_bindings:
        for name, deps in initial_bindings.items():
            saved[name] = set(state.deps[name]) if name in state.deps else None
            state.deps[name] = set(deps)

    guard_stack: List[Tuple[Set[str], int]] = []
    guard_refcnt: Dict[str, int] = {}
    pending_guard: Optional[Set[str]] = None
    last_closed_guard: Optional[Set[str]] = None
    brace_depth = 0

    def active_guard_deps() -> Set[str]:
        out: Set[str] = set(inherited_guard_deps or set())
        for deps in guard_refcnt:
            out.add(deps)
        return out

    def active_guard_present() -> bool:
        return inherited_guard_present or bool(guard_stack)

    def advance_braces(line: str) -> None:
        nonlocal brace_depth, pending_guard, last_closed_guard
        popped_on_line: Optional[Set[str]] = None
        for ch in line:
            if ch == "}":
                brace_depth -= 1
                while guard_stack and guard_stack[-1][1] > brace_depth:
                    gv, _depth = guard_stack.pop()
                    popped_on_line = set(gv)
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
                    pending_guard = None
                    guard_stack.append((gv, brace_depth))
                    for v in gv:
                        guard_refcnt[v] = guard_refcnt.get(v, 0) + 1
        if popped_on_line is not None:
            last_closed_guard = popped_on_line

    try:
        for raw in lines:
            ln = raw.split("//", 1)[0]
            s = ln.strip()
            if not s or s.startswith("var "):
                if s.startswith("var "):
                    for name in _parse_var_decl_names(s):
                        if name not in saved and name not in local_saved:
                            local_saved[name] = set(state.deps[name]) if name in state.deps else None
                        state.deps[name] = {name}
                advance_braces(ln)
                continue

            if _is_if_stmt(s):
                pending_guard = _deps_in_expr(_extract_cond_text(ln), var_types=var_types, deps=state.deps)
                state.control_live_deps.update(pending_guard)
            elif _is_while_stmt(s):
                pending_guard = _deps_in_expr(_extract_cond_text(ln), var_types=var_types, deps=state.deps)
                state.control_live_deps.update(pending_guard)
            elif _is_else_if_stmt(s):
                old = set(last_closed_guard or (guard_stack[-1][0] if guard_stack else set()))
                pending_guard = set(old) | _deps_in_expr(_extract_cond_text(ln), var_types=var_types, deps=state.deps)
                state.control_live_deps.update(pending_guard)
            elif _is_else_stmt(s):
                old = set(last_closed_guard or (guard_stack[-1][0] if guard_stack else set()))
                pending_guard = set(old)
                state.control_live_deps.update(pending_guard)

            guard_deps = active_guard_deps()
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
                    inline_depth=inline_depth,
                    max_inline_depth=max_inline_depth,
                )
                advance_braces(ln)
                continue

            m_asn = _RE_ASSIGN.match(ln)
            if m_asn:
                rhs_deps = _deps_in_expr(m_asn.group("rhs"), var_types=var_types, deps=state.deps)
                for lhs in _split_args(m_asn.group("lhs")):
                    _assign_deps(
                        lhs.strip(),
                        rhs_deps | guard_deps,
                        state=state,
                        var_types=var_types,
                        keep_old=keep_old,
                    )

            advance_braces(ln)
        captured = {
            name: set(state.deps.get(name, {name}))
            for name in (capture_names or ())
        }
        return captured
    finally:
        for name, old in local_saved.items():
            if old is None:
                state.deps.pop(name, None)
            else:
                state.deps[name] = old
        if initial_bindings:
            for name, old in saved.items():
                if old is None:
                    state.deps.pop(name, None)
                else:
                    state.deps[name] = old
    return {}


def _process_call(
    m_call: re.Match[str],
    *,
    state: _State,
    var_types: Dict[str, str],
    procs: Dict[str, _Proc],
    guard_deps: Set[str],
    inline_depth: int,
    max_inline_depth: int,
) -> None:
    proc = m_call.group("proc").strip()
    args = _split_args(m_call.group("args"))
    lhs = (m_call.group("lhs") or "").strip()

    m_write = _RE_WRITE_CALL.match(proc)
    if m_write:
        reg = m_write.group("reg")
        idx_deps = _deps_in_expr(args[0] if args else "", var_types=var_types, deps=state.deps)
        val_deps = _deps_in_expr(args[1] if len(args) > 1 else "", var_types=var_types, deps=state.deps)
        deps = idx_deps | val_deps | guard_deps
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
            bindings = {p: set(arg_deps[i]) for i, p in enumerate(proc_obj.params) if i < len(arg_deps)}
            for ret in proc_obj.returns:
                bindings.setdefault(ret, {ret})
            ret_deps = _process_lines(
                proc_obj.body,
                state=state,
                var_types=var_types,
                procs=procs,
                inline_depth=inline_depth + 1,
                max_inline_depth=max_inline_depth,
                initial_bindings=bindings,
                inherited_guard_deps=set(guard_deps),
                inherited_guard_present=False,
                capture_names=proc_obj.returns,
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
                )
            return
        arg_deps = [_deps_in_expr(a, var_types=var_types, deps=state.deps) | guard_deps for a in args]
        bindings = {p: set(arg_deps[i]) for i, p in enumerate(proc_obj.params) if i < len(arg_deps)}
        _process_lines(
            proc_obj.body,
            state=state,
            var_types=var_types,
            procs=procs,
            inline_depth=inline_depth + 1,
            max_inline_depth=max_inline_depth,
            initial_bindings=bindings,
            inherited_guard_deps=set(guard_deps),
            inherited_guard_present=bool(guard_deps),
        )
        return

    if lhs:
        state.unresolved_calls.add(f"{proc}->assigned_call")
        deps = set(guard_deps)
        for arg in args:
            deps.update(_deps_in_expr(arg, var_types=var_types, deps=state.deps))
        for l in _split_args(lhs):
            _assign_deps(l.strip(), deps, state=state, var_types=var_types, keep_old=bool(guard_deps))
    else:
        state.unresolved_calls.add(proc)


def _assign_deps(
    lhs: str,
    new_deps: Set[str],
    *,
    state: _State,
    var_types: Dict[str, str],
    keep_old: bool = False,
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


def _strip_wrapping_parens(expr: str) -> str:
    s = expr.strip()
    while s.startswith("(") and s.endswith(")"):
        depth = 0
        wraps = True
        for i, ch in enumerate(s):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and i != len(s) - 1:
                    wraps = False
                    break
        if not wraps:
            break
        s = s[1:-1].strip()
    return s


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


def is_stable_projection_predicate_text(
    expr: str,
    *,
    var_types: Optional[Dict[str, str]] = None,
    default_state: Iterable[str] = (),
    excluded: Iterable[str] = (),
) -> bool:
    """
    Conservative manifest-facing stability check for certified projection predicates.

    The extractor has full Boogie type information and uses
    `_is_stable_projection_predicate`.  Manifest certification sometimes only has
    serialized text, so this helper also supports a syntax-only mode.  In that
    mode every identifier that is not a literal/keyword must itself look like
    stable cutpoint state (`procurator_*`, mailbox counters, or DSL state).
    """

    default = set(default_state)
    banned = set(excluded)
    ignored = {"true", "false", "old"}
    toks = [tok for tok in _RE_IDENT.findall(expr) if tok not in ignored]

    if var_types is not None:
        state_vars = {tok for tok in toks if tok in var_types}
    else:
        state_vars = set(toks)

    if not state_vars:
        return False

    for v in state_vars:
        if v in banned:
            return False
        if var_types is not None and not _is_snapshot_scalar(v, var_types):
            return False
        if v in default:
            continue
        if not _is_stable_cutpoint_var(v):
            return False
    return True


def _vars_in_predicates(predicates: Sequence[str], var_types: Dict[str, str]) -> Set[str]:
    out: Set[str] = set()
    for expr in predicates:
        for tok in _RE_IDENT.findall(expr):
            if tok in var_types:
                out.add(tok)
    return out


def _deps_in_expr(expr: Optional[str], *, var_types: Dict[str, str], deps: Dict[str, Set[str]]) -> Set[str]:
    if not expr:
        return set()
    out: Set[str] = set()
    for tok in _RE_IDENT.findall(expr):
        if tok in deps:
            out.update(deps[tok])
        elif tok in var_types:
            out.add(tok)
    return out


def _vars_in_expr(expr: str, *, var_types: Dict[str, str], deps: Dict[str, Set[str]]) -> Set[str]:
    return _deps_in_expr(expr, var_types=var_types, deps=deps)


def _extract_cond_text(line: str) -> str:
    i = line.find("(")
    j = line.rfind(")")
    if i < 0 or j <= i:
        return ""
    return line[i + 1 : j].strip()


def _split_args(args: str) -> List[str]:
    out: List[str] = []
    cur: List[str] = []
    depth = 0
    for ch in args:
        if ch == "," and depth == 0:
            out.append("".join(cur).strip())
            cur = []
            continue
        cur.append(ch)
        if ch in "([{":
            depth += 1
        elif ch in ")]}" and depth > 0:
            depth -= 1
    tail = "".join(cur).strip()
    if tail:
        out.append(tail)
    return out


def _target_observation_vars(candidate: WraparoundCandidate, var_types: Dict[str, str]) -> List[str]:
    out: List[str] = []
    for reg in _unique([candidate.pump_reg, *candidate.accel_regs]):
        for v in (f"{reg}__last0_value", f"{reg}__last_value", reg):
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


def _stable_register_slot_projection_vars(
    *,
    live_deps: Set[str],
    var_types: Dict[str, str],
    excluded: Set[str],
) -> List[str]:
    """
    Promote fixed-slot P4 register dependencies to their scalar slot mirrors.

    Dependency extraction naturally tracks array registers such as
    `foo_reg:[bv16]bv32`, but closure projection can only snapshot scalar
    variables.  P4B emits `foo_reg__last0_value` mirrors for slot 0, and the
    harness maintains them as a scalar view of `foo_reg[0]`.  When a live dep is
    a non-target register array and the slot-0 mirror exists, include that
    mirror in the projection.  The target counter itself remains excluded so the
    pump is still allowed to change it.
    """

    out: List[str] = []
    for dep in sorted(live_deps):
        typ = var_types.get(dep)
        if not typ or "[" not in typ or dep in excluded:
            continue
        mirror = f"{dep}__last0_value"
        if mirror in var_types and mirror not in excluded:
            out.append(mirror)
    return _unique(out)


def _is_snapshot_scalar(name: str, var_types: Dict[str, str]) -> bool:
    typ = var_types.get(name)
    if not typ:
        return False
    if "[" in typ or "]" in typ:
        return False
    return True


def _is_stable_cutpoint_var(name: str) -> bool:
    if name == "procurator_phase" or name.startswith("procurator_"):
        return True
    if name.endswith("_inbox_count") or name.endswith("_egress_count"):
        return True
    if name.startswith("dsl_") or name.endswith("dsl_pump_mode"):
        return True
    if name.endswith("__last0_value"):
        return True
    return False


def _is_packet_slot_var(name: str) -> bool:
    return "_hdr." in name or name.endswith("_pkt_external")


def _unique(values: Iterable[str]) -> List[str]:
    seen: Set[str] = set()
    out: List[str] = []
    for v in values:
        if v in seen:
            continue
        seen.add(v)
        out.append(v)
    return out
