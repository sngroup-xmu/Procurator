from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

from lark import Tree

from ..speclang import parse_model, parse_tree


@dataclass(frozen=True)
class WraparoundCandidate:
    """
    A single wraparound-acceleration target.

    - `pump_reg` is the primary counter register (used for gating/diagnostics).
    - `accel_regs` are the registers we fast-forward to MAX in confirm.
    - `index_value`/`index_expr` describe the slot/key being tracked.
      v0-1 prefers a constant `index_value`; if unknown, we fall back to `index_expr`.
    - `step_op`/`step_delta` describe the single-step counter update we treat as the "pump".
      v0-1 supports only constant deltas (from P4B meta); unknown deltas default to +1.
    """

    pump_reg: str
    accel_regs: Tuple[str, ...]
    index_value: Optional[int]
    index_expr: Optional[str]
    proj_vars: Tuple[str, ...]
    cutpoint_cond: Optional[str]
    reason: str
    step_op: str = "add"
    step_delta: Optional[int] = 1


_RE_VAR_DECL = re.compile(r"^var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_BV_LIT = re.compile(r"^(?P<val>\d+)bv(?P<w>\d+)$")
_RE_CONCAT_LIT_VAR = re.compile(
    r"^(?P<prefix>\d+)bv(?P<pw>\d+)\s*\+\+\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)$"
)


def _unwrap_var(expr: Tree) -> Tree:
    cur = expr
    while isinstance(cur, Tree) and str(cur.data) == "var" and cur.children:
        child = cur.children[0]
        if isinstance(child, Tree):
            cur = child
        else:
            break
    return cur


def _parse_number(expr: Tree) -> Optional[int]:
    e = _unwrap_var(expr)
    if not isinstance(e, Tree) or str(e.data) != "number" or not e.children:
        return None
    try:
        return int(str(e.children[0]))
    except ValueError:
        return None


def extract_constant_equalities_from_global_assumes(spec_text: str) -> Dict[str, int]:
    """
    Extract simple constant equalities from `global { assume { ... } }`.

    Example:
      `clientTrack_meta.leafswitchidx == 2`
    yields:
      {"clientTrack_meta.leafswitchidx": 2}
    """

    parse_tree(spec_text)
    model = parse_model(spec_text)
    out: Dict[str, int] = {}

    for expr in model.global_decl.assume_exprs:
        if not isinstance(expr, Tree):
            continue
        e = _unwrap_var(expr)
        if not isinstance(e, Tree) or str(e.data) != "eq" or len(e.children) != 2:
            continue

        left = _unwrap_var(e.children[0]) if isinstance(e.children[0], Tree) else None
        right = _unwrap_var(e.children[1]) if isinstance(e.children[1], Tree) else None

        if isinstance(left, Tree) and str(left.data) == "dotted_var":
            n = _parse_number(e.children[1]) if isinstance(e.children[1], Tree) else None
            if n is None:
                continue
            base, indices = _extract_dotted_var_base_and_indices(left)
            if indices:
                continue
            out[base] = n
            continue

        if isinstance(right, Tree) and str(right.data) == "dotted_var":
            n = _parse_number(e.children[0]) if isinstance(e.children[0], Tree) else None
            if n is None:
                continue
            base, indices = _extract_dotted_var_base_and_indices(right)
            if indices:
                continue
            out[base] = n

    return out


def _parse_var_types(bpl_text: str) -> Dict[str, str]:
    types: Dict[str, str] = {}
    for line in bpl_text.splitlines():
        m = _RE_VAR_DECL.match(line.strip())
        if not m:
            continue
        types[m.group("name")] = m.group("type").strip()
    return types


def _default_proj_vars(var_types: Dict[str, str]) -> List[str]:
    proj: List[str] = []
    if "procurator_phase" in var_types:
        proj.append("procurator_phase")
    for name, typ in var_types.items():
        if typ != "int":
            continue
        if name.endswith("_inbox_count") or name.endswith("_egress_count"):
            proj.append(name)
    return sorted(set(proj))


def _vars_in_expr(expr: str, *, var_types: Dict[str, str]) -> List[str]:
    vars_found: List[str] = []
    for tok in _RE_IDENT.findall(expr):
        if tok in var_types:
            vars_found.append(tok)
    return sorted(set(vars_found))


def _bv_width(typ: Optional[str]) -> Optional[int]:
    if typ is None:
        return None
    m = re.match(r"^bv(?P<w>\d+)$", typ.strip())
    if not m:
        return None
    return int(m.group("w"))


def _maybe_eval_index_expr_to_constant(
    idx_expr: str, *, const_eq: Dict[str, int], var_types: Dict[str, str]
) -> Optional[int]:
    expr = idx_expr.strip()
    while expr.startswith("(") and expr.endswith(")"):
        expr = expr[1:-1].strip()

    if expr in const_eq:
        return const_eq[expr]

    m = _RE_CONCAT_LIT_VAR.match(expr.replace(" ", ""))
    if not m:
        return None

    prefix_val = int(m.group("prefix"))
    prefix_w = int(m.group("pw"))
    var = m.group("var")
    if var not in const_eq:
        return None

    var_val = const_eq[var]
    var_w = _bv_width(var_types.get(var))
    if var_w is None:
        return None

    if prefix_val < 0 or prefix_val >= (1 << prefix_w):
        return None
    if var_val < 0 or var_val >= (1 << var_w):
        return None
    return (prefix_val << var_w) | var_val


def _extract_dotted_var_base_and_indices(dv: Tree) -> Tuple[str, Tuple[int, ...]]:
    if str(dv.data) != "dotted_var":
        raise ValueError("not a dotted_var")
    base_parts: List[str] = []
    indices: List[int] = []
    for item in dv.children:
        if not hasattr(item, "type"):
            continue
        if item.type in {"NAME", "INTSEG"}:
            base_parts.append(str(item))
        elif item.type == "INT":
            indices.append(int(str(item)))
    return ".".join(base_parts), tuple(indices)


def _iter_dotted_vars(expr: Tree) -> Iterable[Tree]:
    yield from expr.find_data("dotted_var")


def extract_seed_vars_from_global_asserts(spec_text: str) -> List[Tuple[str, Tuple[int, ...]]]:
    """
    Return (base, indices) pairs referenced by global asserts.

    Example:
      `s1_sequence_reg_0[0] >= s2_sequence_reg_0[0]`
    yields:
      ("s1_sequence_reg_0", (0,)), ("s2_sequence_reg_0", (0,))
    """

    parse_tree(spec_text)
    model = parse_model(spec_text)
    out: List[Tuple[str, Tuple[int, ...]]] = []
    for expr in model.global_decl.assert_exprs:
        if not isinstance(expr, Tree):
            continue
        for dv in _iter_dotted_vars(expr):
            base, indices = _extract_dotted_var_base_and_indices(dv)
            out.append((base, indices))
    return out


def _infer_from_global_asserts(spec_text: str) -> Optional[WraparoundCandidate]:
    """
    MVP inference: look for register[i] occurrences in global asserts, and group
    registers by a single constant index (NetChain-style).
    """

    seeds = extract_seed_vars_from_global_asserts(spec_text)
    regs: List[str] = []
    idx: Optional[int] = None
    for base, indices in seeds:
        if len(indices) != 1:
            continue
        cur_idx = indices[0]
        if idx is None:
            idx = cur_idx
        if cur_idx != idx:
            continue
        reg = base
        if reg.endswith("_0"):
            reg = reg[:-2]
        if reg not in regs:
            regs.append(reg)
    if idx is None or not regs:
        return None

    return WraparoundCandidate(
        pump_reg=regs[0],
        accel_regs=tuple(regs),
        index_value=idx,
        index_expr=None,
        proj_vars=tuple(),  # let transform pick defaults
        cutpoint_cond=None,
        reason="global_asserts",
    )


_DEBUG_SUFFIXES = (
    "__last0_value__dbg",
    "__last0_value",
    "__last_value__dbg",
    "__last_value",
    "__last_index__dbg",
    "__last_index",
    "__wrote_index0__dbg",
    "__wrote_index0",
    "__dbg0",
)


def _strip_debug_suffix(name: str) -> str:
    for suf in _DEBUG_SUFFIXES:
        if name.endswith(suf):
            return name[: -len(suf)]
    return name


def _resolve_prefixed_name(name: str, *, node: str, var_types: Dict[str, str]) -> str:
    """
    Map an unprefixed P4B name to the composed Boogie name.

    dslc prefixes Boogie symbols using `node_...`. P4B sometimes emits both
    `<x>` and `<x>_0` variants; we prefer whichever exists in `var_types`.
    """

    cand = f"{node}_{name}"
    if cand in var_types:
        return cand
    if name.endswith("_0"):
        alt = f"{node}_{name[:-2]}"
        if alt in var_types:
            return alt
    else:
        alt = f"{node}_{name}_0"
        if alt in var_types:
            return alt
    return cand


def _prefix_expr_with_known_vars(expr: str, *, node: str, var_types: Dict[str, str]) -> str:
    """
    Prefix identifiers inside an unprefixed Boogie expression using `node_...`,
    but only when the prefixed name exists in `var_types`.
    """

    def repl(m: re.Match[str]) -> str:
        tok = m.group(0)
        pref = _resolve_prefixed_name(tok, node=node, var_types=var_types)
        return pref if pref in var_types else tok

    return _RE_IDENT.sub(repl, expr)


def _infer_from_meta_updates(
    *,
    spec_text: str,
    bpl_text: str,
    meta_by_node: Dict[str, dict],
) -> List[WraparoundCandidate]:
    var_types = _parse_var_types(bpl_text)
    global_const_eq = extract_constant_equalities_from_global_assumes(spec_text)
    default_proj = _default_proj_vars(var_types)

    seed_pairs = extract_seed_vars_from_global_asserts(spec_text)
    seed_bases: Set[str] = {base for base, _ in seed_pairs}
    seed_bases |= {_strip_debug_suffix(b) for b in list(seed_bases)}

    out: List[WraparoundCandidate] = []
    seen: Set[Tuple[str, Optional[int], Optional[str], str, Optional[int]]] = set()

    for node, meta in sorted(meta_by_node.items()):
        wrap = (meta or {}).get("wraparound") or {}
        updates = wrap.get("updates") or []
        if not isinstance(updates, list):
            continue
        for u in updates:
            if not isinstance(u, dict):
                continue
            reg = str(u.get("reg") or "")
            value_var = str(u.get("value_var") or "")
            op = str(u.get("op") or "")
            delta_is_const = bool(u.get("delta_is_const"))
            delta_const = u.get("delta_const")

            if not reg or not value_var:
                continue
            if op != "add":
                # v0-1 pipeline currently accelerates overflow (MAX -> ...), so only handle +delta.
                continue
            if not delta_is_const:
                continue
            try:
                step_delta = int(str(delta_const))
            except Exception:
                continue

            pump_reg = _resolve_prefixed_name(reg, node=node, var_types=var_types)
            value_var_pref = _resolve_prefixed_name(value_var, node=node, var_types=var_types)

            # Filter by whether the updated var (or the register itself) appears in global asserts.
            if (
                value_var_pref not in seed_bases
                and value_var not in seed_bases
                and pump_reg not in seed_bases
                and reg not in seed_bases
            ):
                continue

            idx_const = u.get("idx_const", None)
            idx_expr_raw = u.get("idx_expr", None)
            idx_value: Optional[int] = None
            idx_expr: Optional[str] = None
            proj: List[str] = list(default_proj)

            if isinstance(idx_const, int) and idx_const >= 0:
                idx_value = idx_const
            else:
                if isinstance(idx_expr_raw, str) and idx_expr_raw.strip():
                    idx_expr_pref = _prefix_expr_with_known_vars(idx_expr_raw, node=node, var_types=var_types)
                    idx_eval = _maybe_eval_index_expr_to_constant(
                        idx_expr_pref, const_eq=global_const_eq, var_types=var_types
                    )
                    if idx_eval is not None:
                        idx_value = idx_eval
                    else:
                        idx_expr = idx_expr_pref
                        proj = sorted(set(proj + _vars_in_expr(idx_expr_pref, var_types=var_types)))
                else:
                    # Best-effort: keep index symbolic via a single var if we can.
                    idx_vars = u.get("idx_vars") or []
                    if isinstance(idx_vars, list) and len(idx_vars) == 1 and isinstance(idx_vars[0], str):
                        idx_expr_pref = _resolve_prefixed_name(idx_vars[0], node=node, var_types=var_types)
                        idx_eval = _maybe_eval_index_expr_to_constant(
                            idx_expr_pref, const_eq=global_const_eq, var_types=var_types
                        )
                        if idx_eval is not None:
                            idx_value = idx_eval
                        else:
                            idx_expr = idx_expr_pref
                            proj = sorted(set(proj + [idx_expr_pref]))

            accel_regs = (pump_reg,)
            reason = f"meta_wraparound_update:{value_var}"
            key = (pump_reg, idx_value, idx_expr, reason, step_delta)
            if key in seen:
                continue
            seen.add(key)

            out.append(
                WraparoundCandidate(
                    pump_reg=pump_reg,
                    accel_regs=accel_regs,
                    index_value=idx_value,
                    index_expr=idx_expr,
                    proj_vars=tuple(proj),
                    cutpoint_cond=None,
                    reason=reason,
                    step_op="add",
                    step_delta=step_delta,
                )
            )

    return out


def infer_wraparound_candidates(
    *,
    spec_text: str,
    bpl_text: str,
    meta_by_node: Optional[Dict[str, dict]] = None,
) -> List[WraparoundCandidate]:
    """
    Infer wraparound candidates for the given spec and compiled Boogie model.

    Strategy:
      1) If the global assert directly references register slots (reg[i]),
         use those regs + the constant index (NetChain-style).
      2) Otherwise, consult P4B meta (`wraparound.updates`) to find monotonic
         register writes whose updated value variable (or register) appears in
         the global assert (DistCache-style leafload/spineload).
    """

    cand = _infer_from_global_asserts(spec_text)
    if cand is not None:
        # If meta is available, try to recover the step size for the pump reg.
        if meta_by_node:
            step = _find_step_info_for_pump_reg(cand.pump_reg, meta_by_node=meta_by_node)
            if step is not None:
                op, delta = step
                return [
                    WraparoundCandidate(
                        pump_reg=cand.pump_reg,
                        accel_regs=cand.accel_regs,
                        index_value=cand.index_value,
                        index_expr=cand.index_expr,
                        proj_vars=cand.proj_vars,
                        cutpoint_cond=cand.cutpoint_cond,
                        reason=cand.reason,
                        step_op=op,
                        step_delta=delta,
                    )
                ]
        return [cand]

    if not meta_by_node:
        return []

    return _infer_from_meta_updates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)


def _find_step_info_for_pump_reg(pump_reg: str, *, meta_by_node: Dict[str, dict]) -> Optional[Tuple[str, int]]:
    """
    Best-effort lookup of (op, delta) for a composed `pump_reg`.

    For node-prefixed names (e.g., `s1_sequence_reg`), we strip the prefix and
    search the corresponding node's meta updates. For unprefixed names, we try
    all nodes and return the first match.
    """

    def match_reg(update_reg: str, target: str) -> bool:
        if update_reg == target:
            return True
        if update_reg.endswith("_0") and update_reg[:-2] == target:
            return True
        if target.endswith("_0") and target[:-2] == update_reg:
            return True
        return False

    def search_node_meta(meta: dict, *, unpref_reg: str) -> Optional[Tuple[str, int]]:
        wrap = (meta or {}).get("wraparound") or {}
        updates = wrap.get("updates") or []
        if not isinstance(updates, list):
            return None
        for u in updates:
            if not isinstance(u, dict):
                continue
            reg = str(u.get("reg") or "")
            if not reg or not match_reg(reg, unpref_reg):
                continue
            op = str(u.get("op") or "")
            if op != "add":
                continue
            if not bool(u.get("delta_is_const")):
                continue
            try:
                delta = int(str(u.get("delta_const")))
            except Exception:
                continue
            return ("add", delta)
        return None

    for node, meta in meta_by_node.items():
        prefix = f"{node}_"
        if pump_reg.startswith(prefix):
            return search_node_meta(meta, unpref_reg=pump_reg[len(prefix) :])

    # Unprefixed: try all nodes.
    for _node, meta in meta_by_node.items():
        res = search_node_meta(meta, unpref_reg=pump_reg)
        if res is not None:
            return res
    return None
