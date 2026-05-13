from __future__ import annotations

import re
from typing import Dict, Iterable, List, Optional, Sequence, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.transform.wraparound_analyze import _find_procedure_block, _parse_global_var_types
from dslc.transform.wraparound_common import _CLOSURE_UNROLL_MARKER_PREFIX, _RE_PROC_MAIN


def unique_exprs(exprs: Iterable[str]) -> List[str]:
    seen: set[str] = set()
    out: List[str] = []
    for raw in exprs:
        expr = str(raw or "").strip()
        if not expr or expr in seen:
            continue
        seen.add(expr)
        out.append(expr)
    return out


def strip_outer_parens(expr: str) -> str:
    s = str(expr or "").strip()
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


def negated_inner(expr: str) -> Optional[str]:
    s = strip_outer_parens(expr)
    if not s.startswith("!"):
        return None
    inner = strip_outer_parens(s[1:].strip())
    return inner or None


def select_cutpoint_guard_branch(dep_projection) -> Tuple[Tuple[str, ...], Optional[int], Tuple[str, ...]]:
    alts = [tuple(unique_exprs(alt)) for alt in getattr(dep_projection, "cutpoint_guard_alternatives", ()) or ()]
    alts = [alt for alt in alts if alt]
    if not alts:
        return (), None, ()
    ranked = sorted(enumerate(alts), key=lambda item: _branch_projection_score(item[1]), reverse=True)
    best_i, best_alt = ranked[0]
    notes = [
        f"dependency_projection_branch_alternative={best_i}",
        f"dependency_projection_branch_predicates={len(best_alt)}",
    ]
    if len(ranked) > 1 and _branch_projection_score(ranked[0][1]) == _branch_projection_score(ranked[1][1]):
        notes.append("dependency_projection_branch_tie_broken_deterministically")
    return best_alt, best_i, tuple(notes)


def branch_projection_resolves_only_ambiguity(dep_projection, branch: Sequence[str]) -> bool:
    notes = list(getattr(dep_projection, "notes", ()) or ())
    incomplete_notes = [n for n in notes if n == "dependency_projection_incomplete"]
    if not incomplete_notes:
        return True
    if not branch:
        return False
    allowed_prefixes = (
        "dependency_projection_ambiguous_cutpoint_predicates=",
        "dependency_projection_cutpoint_guard_alternatives=",
        "dependency_projection_cutpoint_predicates=",
        "dependency_projection_predicates=",
        "dependency_projection_period=",
        "dependency_projection_live_deps=",
        "dependency_projection_dynamic_slot_exprs=",
        "dependency_projection_unstable_cutpoint_guards=",
    )
    for note in notes:
        if note == "dependency_projection_incomplete":
            continue
        if note.startswith(allowed_prefixes):
            continue
        if note.startswith("dependency_projection_branch_"):
            continue
        if "incomplete" in note:
            return False
        if note.startswith("dependency_projection_unresolved_calls="):
            return False
        if note.startswith("dependency_projection_dynamic_slot_deps="):
            return False
        if note.startswith("dependency_projection_dynamic_slot_index_mismatch="):
            return False
    return not _has_ambiguous_predicate_pair(branch)


def conjoin_cutpoint(base_cond: Optional[str], branch: Sequence[str]) -> str:
    terms = []
    cond = str(base_cond or "").strip()
    if cond and cond != "true":
        terms.append(f"({cond})")
    for pred in unique_exprs(branch):
        terms.append(f"({pred})")
    return " && ".join(terms) if terms else "true"


def entry_prefix_mirror_assumes(
    *,
    branch: Sequence[str],
    var_types: Dict[str, str],
) -> Tuple[str, ...]:
    """
    Add optional mirror filters for bounded prefix ENTRY.

    These assumptions are intentionally stronger than the selected cutpoint and
    are used only for the finite reachability gate.  If no such prefix exists we
    fall back; if it does exist, the subsequent NEAR/CLOSURE stages still use the
    original dependency cutpoint.
    """

    out: List[str] = []
    for pred in unique_exprs(branch):
        inner = negated_inner(pred)
        eq_parts = _array_select_eq_parts(pred)
        neq_parts = _array_select_neq_parts(pred)
        neg_eq_parts = _array_select_eq_parts(inner) if inner else None
        neg_neq_parts = _array_select_neq_parts(inner) if inner else None

        if eq_parts is not None:
            array, idx, value = eq_parts
            value_op = "=="
        elif neg_neq_parts is not None:
            array, idx, value = neg_neq_parts
            value_op = "=="
        elif neq_parts is not None:
            array, idx, value = neq_parts
            value_op = "!="
        elif neg_eq_parts is not None:
            array, idx, value = neg_eq_parts
            value_op = "!="
        else:
            continue

        last_index = f"{array}__last_index"
        last_value = f"{array}__last_value"
        if last_index not in var_types or last_value not in var_types:
            continue
        out.append(f"{last_index} == {idx}")
        out.append(f"{last_value} {value_op} {value}")
    return tuple(unique_exprs(out))


def insert_confirm_prefix_marker(
    bpl_text: str,
    *,
    prefix_steps: int,
) -> Tuple[str, str]:
    steps = max(1, int(prefix_steps))
    marker = f"// WRAPAROUND_CONFIRM_PREFIX_CUTPOINT after {steps} steps"
    lines = bpl_text.splitlines(keepends=True)
    seen_unroll = False
    seen_steps = 0
    step_re = re.compile(r"^\s*procurator_step\s*:=\s*procurator_step\s*\+\s*1\s*;\s*$")
    for i, line in enumerate(lines):
        if _CLOSURE_UNROLL_MARKER_PREFIX in line:
            seen_unroll = True
            continue
        if not seen_unroll:
            continue
        if not step_re.match(line):
            continue
        seen_steps += 1
        if seen_steps == steps:
            indent = re.match(r"^(\s*)", line).group(1)  # type: ignore[union-attr]
            lines.insert(i + 1, f"{indent}{marker}\n")
            return "".join(lines), marker
    raise RuntimeError(f"failed to insert confirm prefix marker after {steps} scheduler steps")


def focused_near_wrap_text(
    bpl_text: str,
    *,
    candidate: WraparoundCandidate,
) -> Optional[str]:
    """
    Build a focused under-approximation for NEAR_WRAP existence.

    The normal CONFIRM/NEAR BPL rewrites all assertions through a wrapper so
    that the solver can prove/disprove the original property.  For schedule
    replay we first need only an existential suffix witness.  When the property
    is a register-mirror wrap check, a stronger final-state goal is sufficient:
    the target register's last write is at the tracked index and has the wrapped
    value.  UNSAFE is a real witness; SAFE/UNKNOWN is only diagnostic fallback.
    """

    var_types = _parse_global_var_types(bpl_text.splitlines())
    reg = candidate.pump_reg
    wrote_any = f"{reg}__wrote_any"
    last_index = f"{reg}__last_index"
    last_value = f"{reg}__last_value"
    if var_types.get(wrote_any) != "bool" or last_value not in var_types:
        return None
    value_type = var_types.get(last_value, "")
    m_val = re.match(r"^bv(?P<w>\d+)$", value_type)
    if not m_val:
        return None
    value_width = int(m_val.group("w"))
    if candidate.step_op == "add":
        wrapped_value = f"0bv{value_width}"
    elif candidate.step_op == "sub":
        wrapped_value = f"{(1 << value_width) - 1}bv{value_width}"
    else:
        return None

    index_expr: Optional[str] = candidate.index_expr
    if index_expr is None and candidate.index_value is not None and last_index in var_types:
        idx_type = var_types.get(last_index, "")
        m_idx = re.match(r"^bv(?P<w>\d+)$", idx_type)
        if m_idx:
            index_expr = f"{int(candidate.index_value)}bv{m_idx.group('w')}"

    lines = bpl_text.splitlines(keepends=True)
    stripped_any = False
    for i, raw in enumerate(lines):
        if "call __wraparound_assert" not in raw:
            continue
        indent = re.match(r"^(\s*)", raw).group(1)  # type: ignore[union-attr]
        lines[i] = f"{indent}assume true; // stripped assert for focused near-wrap\n"
        stripped_any = True
    if not stripped_any:
        return None

    try:
        _, _body_open, body_close = _find_procedure_block([ln.rstrip("\n") for ln in lines], _RE_PROC_MAIN)
    except Exception:
        return None

    goal_terms = [f"{wrote_any}", f"{last_value} == {wrapped_value}"]
    if index_expr is not None and last_index in var_types:
        goal_terms.insert(1, f"{last_index} == {index_expr}")
    if "__wraparound_confirm_active" in var_types:
        goal_terms.insert(0, "__wraparound_confirm_active")
    goal = " && ".join(f"({t})" for t in goal_terms)
    block = [
        "  // wraparound focused near-wrap existence goal (generated)\n",
        f"  assume({goal});\n",
        "  assert false; // WRAPAROUND_NEAR_FOCUSED_ASSERT\n",
    ]
    lines[body_close:body_close] = block
    return "".join(lines)


def _has_ambiguous_predicate_pair(predicates: Sequence[str]) -> bool:
    positives = {strip_outer_parens(p) for p in predicates if str(p).strip()}
    for pred in positives:
        inner = negated_inner(pred)
        if inner and inner in positives:
            return True
    return False


def _predicate_complexity(expr: str) -> int:
    return len(set(re.findall(r"\b[A-Za-z_][A-Za-z0-9_.]*\b", expr)))


def _branch_projection_score(branch: Sequence[str]) -> Tuple[int, int, int, int, str]:
    """
    Prefer the branch that carries the strongest stable cutpoint shape.

    This is deterministic and intentionally syntactic. It only chooses among
    alternatives that the dependency extractor already accepted as stable
    cutpoint predicates. The chosen predicates are then folded into the
    effective cutpoint and closure projection, so the proof still discharges the
    branch rather than trusting the heuristic.
    """

    preds = unique_exprs(branch)
    register_eq = sum(1 for p in preds if "[" in p and "]" in p and "==" in p)
    negated = sum(1 for p in preds if negated_inner(p) is not None)
    complexity = sum(_predicate_complexity(p) for p in preds)
    return (len(preds), register_eq, negated, complexity, ";".join(preds))


def _array_select_eq_parts(expr: str) -> Optional[Tuple[str, str, str]]:
    s = strip_outer_parens(expr)
    if "==" not in s:
        return None
    lhs, rhs = [p.strip() for p in s.split("==", 1)]
    m_lhs = re.match(r"^(?P<array>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<idx>[^\]]+)\]$", lhs)
    if m_lhs:
        return m_lhs.group("array"), m_lhs.group("idx").strip(), rhs
    m_rhs = re.match(r"^(?P<array>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<idx>[^\]]+)\]$", rhs)
    if m_rhs:
        return m_rhs.group("array"), m_rhs.group("idx").strip(), lhs
    return None


def _array_select_neq_parts(expr: str) -> Optional[Tuple[str, str, str]]:
    s = strip_outer_parens(expr)
    if "!=" not in s:
        return None
    lhs, rhs = [p.strip() for p in s.split("!=", 1)]
    m_lhs = re.match(r"^(?P<array>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<idx>[^\]]+)\]$", lhs)
    if m_lhs:
        return m_lhs.group("array"), m_lhs.group("idx").strip(), rhs
    m_rhs = re.match(r"^(?P<array>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<idx>[^\]]+)\]$", rhs)
    if m_rhs:
        return m_rhs.group("array"), m_rhs.group("idx").strip(), lhs
    return None
