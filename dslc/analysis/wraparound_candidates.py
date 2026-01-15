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
      V1 prefers `index_expr` (can be symbolic); v0-1 uses a constant `index_value`.
    """

    pump_reg: str
    accel_regs: Tuple[str, ...]
    index_value: Optional[int]
    index_expr: Optional[str]
    proj_vars: Tuple[str, ...]
    cutpoint_cond: Optional[str]
    reason: str


_RE_VAR_DECL = re.compile(r"^var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_WRITE_CALL = re.compile(
    r"^\s*call\s+(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.write\s*\(\s*(?P<idx>[^,]+)\s*,\s*(?P<val>[A-Za-z_][A-Za-z0-9_.]*)\s*\)\s*;\s*$"
)
_RE_READ_ASSIGN = re.compile(
    r"^\s*(?P<dst>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.read\s*\(\s*(?P=reg)\s*,\s*(?P<idx>[^)]+)\)\s*;\s*$"
)
_RE_ADD1_ASSIGN = re.compile(
    r"^\s*(?P<dst>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*add\.bv(?P<w>\d+)\(\s*(?P=dst)\s*,\s*1bv(?P=w)\s*\)\s*;\s*$"
)
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

    This is used to collapse symbolic index expressions (e.g., `0bv16++x`) into
    a concrete slot when the spec explicitly fixes `x`.
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
    registers by a single constant index.
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


@dataclass(frozen=True)
class _CounterWrite:
    reg: str
    idx_expr: str
    val_var: str


def _find_counter_writes(bpl_text: str) -> List[_CounterWrite]:
    """
    Heuristic: detect `reg[idx] := reg[idx] + 1` updates encoded as:
      tmp := reg.read(reg, idx);
      tmp := add.bvW(tmp, 1bvW);
      call reg.write(idx, tmp);
    """

    lines = bpl_text.splitlines()
    out: List[_CounterWrite] = []
    for i, line in enumerate(lines):
        m = _RE_WRITE_CALL.match(line)
        if not m:
            continue
        reg = m.group("reg")
        idx_expr = m.group("idx").strip()
        val_var = m.group("val").strip()

        saw_add1 = False
        saw_read = False
        # Search a small window backwards inside the same action/proc body.
        for j in range(max(0, i - 12), i):
            ln = lines[j]
            m_add = _RE_ADD1_ASSIGN.match(ln)
            if m_add and m_add.group("dst") == val_var:
                saw_add1 = True
                continue
            m_read = _RE_READ_ASSIGN.match(ln)
            if m_read and m_read.group("dst") == val_var and m_read.group("reg") == reg:
                # idx_expr string match is intentionally loose (whitespace differences).
                if m_read.group("idx").strip() == idx_expr:
                    saw_read = True
                    continue

        if saw_add1 and saw_read:
            out.append(_CounterWrite(reg=reg, idx_expr=idx_expr, val_var=val_var))

    # De-dup by (reg, idx_expr, val_var).
    seen: Set[Tuple[str, str, str]] = set()
    dedup: List[_CounterWrite] = []
    for w in out:
        k = (w.reg, w.idx_expr, w.val_var)
        if k not in seen:
            seen.add(k)
            dedup.append(w)
    return dedup


def infer_wraparound_candidates(
    *,
    spec_text: str,
    bpl_text: str,
) -> List[WraparoundCandidate]:
    """
    Infer wraparound candidates for the given spec and compiled Boogie model.

    Strategy:
      1) If the global assert directly references register slots (reg[i]),
         use those regs + the constant index (NetChain-style).
      2) Otherwise, look for counter-like (+1) register writes in the Boogie
         model and filter them by whether they update a seed variable appearing
         in the global assert (DistCache-style leafload_0/spineload_0).
    """

    cand = _infer_from_global_asserts(spec_text)
    if cand is not None:
        return [cand]

    var_types = _parse_var_types(bpl_text)
    global_const_eq = extract_constant_equalities_from_global_assumes(spec_text)
    default_proj = _default_proj_vars(var_types)
    seed_bases = {base for base, _ in extract_seed_vars_from_global_asserts(spec_text)}

    counter_writes = _find_counter_writes(bpl_text)
    selected: List[WraparoundCandidate] = []
    for w in counter_writes:
        if w.val_var not in seed_bases:
            continue
        idx_const = _maybe_eval_index_expr_to_constant(w.idx_expr, const_eq=global_const_eq, var_types=var_types)
        idx_expr: Optional[str]
        idx_value: Optional[int]
        proj: List[str]
        reason_suffix = ""
        if idx_const is not None:
            idx_value = idx_const
            idx_expr = None
            proj = list(default_proj)
            reason_suffix = f":idx_from_global_assume={idx_const}"
        else:
            idx_value = None
            idx_expr = w.idx_expr
            idx_vars = _vars_in_expr(w.idx_expr, var_types=var_types)
            proj = sorted(set(default_proj + idx_vars))
        selected.append(
            WraparoundCandidate(
                pump_reg=w.reg,
                accel_regs=(w.reg,),
                index_value=idx_value,
                index_expr=idx_expr,
                proj_vars=tuple(proj),
                cutpoint_cond=None,
                reason=f"boogie_counter_write:{w.val_var}{reason_suffix}",
            )
        )

    # Stable order: smaller element widths first if we can cheaply approximate by suffix.
    return selected
