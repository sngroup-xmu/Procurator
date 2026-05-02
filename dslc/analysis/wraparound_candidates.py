from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Sequence, Set, Tuple

from lark import Tree

from ..speclang import parse_model, parse_tree

from .wraparound_bpl_index import (
    _derive_constant_assignment_literals,
    _derive_index_expr_from_bpl_definition,
    _derive_index_expr_from_meta_definition,
    _extract_bpl_constant_literals,
    _extract_proc_bodies,
    _maybe_eval_index_expr_to_constant,
    _prefix_expr_with_known_vars,
    _resolve_prefixed_name,
    _split_args,
    _substitute_tokens,
    _vars_in_expr,
)


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
_RE_ASSIGN_STMT = re.compile(r"^\s*(?P<lhs>[^:;]+?)\s*:=\s*(?P<rhs>.*);\s*$")
_RE_CALL_ASSIGN_STMT = re.compile(
    r"^\s*call\s+(?P<lhs>[^:;]+?)\s*:=\s*(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)\((?P<args>.*)\)\s*;\s*$"
)
_RE_CALL_STMT = re.compile(
    r"^\s*call\s+(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)\((?P<args>.*)\)\s*;\s*$"
)
_RE_HAVOC_STMT = re.compile(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_PROC_HEADER = re.compile(
    r"^\s*procedure(?:\s+\{[^}]*\})?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\((?P<params>[^)]*)\)"
)
_RE_FUNCTION_DECL = re.compile(r"^\s*function\s+(?P<name>[A-Za-z_][A-Za-z0-9_.$]*)\s*\(")
_RE_ASSUME_CONST_EQ = re.compile(
    r"^\s*assume\s+\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>[^;)]+)\s*\)?\s*;\s*$"
)
_RE_CALLEE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.$]*\s*(?=\()")
_RE_ASSUME_STMT = re.compile(r"^\s*assume\s+(?P<expr>.*)\s*;\s*$")
_RE_GOTO_STMT = re.compile(r"^\s*goto\s+(?P<labels>[^;]+)\s*;\s*$")
_RE_LABEL_STMT = re.compile(r"^\s*(?P<label>[A-Za-z_][A-Za-z0-9_.$]*)\s*:\s*$")
_RE_RETURN_STMT = re.compile(r"^\s*return\s*;\s*$")
_RE_BV_ADD = re.compile(
    r"^add\.bv(?P<w>\d+)\((?P<a>[^,]+),\s*(?P<b>.+)\)$"
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


def _extract_constant_equalities_from_exprs(exprs: Iterable[Tree]) -> Dict[str, int]:
    out: Dict[str, int] = {}

    for expr in exprs:
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
    return _extract_constant_equalities_from_exprs(model.global_decl.assume_exprs)


def extract_constant_equalities_from_assumes(spec_text: str) -> Dict[str, int]:
    """
    Extract simple constant equalities from global, node, and host assume blocks.

    Node-local assumptions are system-level constraints in the generated Boogie
    harness.  Wraparound index recovery may therefore use them to resolve
    fixed-slot facts such as `meta.register_index == 0`.
    """

    parse_tree(spec_text)
    model = parse_model(spec_text)
    out = _extract_constant_equalities_from_exprs(model.global_decl.assume_exprs)
    for node in model.nodes.values():
        local = _extract_constant_equalities_from_exprs(node.assume_exprs)
        out.update(local)
        for name, value in local.items():
            out[f"{node.name}_{name}"] = value
    for host in model.hosts.values():
        local = _extract_constant_equalities_from_exprs(host.assume_exprs)
        out.update(local)
        for name, value in local.items():
            out[f"{host.name}_{name}"] = value
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


def _infer_from_global_asserts(*, spec_text: str, bpl_text: str) -> Optional[WraparoundCandidate]:
    """
    MVP inference: look for register[i] occurrences in global asserts, and group
    registers by a single constant index (NetChain-style).
    """

    seeds = extract_seed_vars_from_global_asserts(spec_text)
    # If we accelerate based on asserts alone (NetChain-style), default to a conservative
    # projection that stabilizes the scheduler bookkeeping (phase + queue counts).
    # Without this, closure_check often fails trivially because the environment/scheduler
    # can perturb whether the "pump" update executes.
    default_proj = _default_proj_vars(_parse_var_types(bpl_text))
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
        proj_vars=tuple(default_proj),
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
_INDEX0_DEBUG_SUFFIXES = (
    "__last0_value__dbg",
    "__last0_value",
    "__wrote_index0__dbg",
    "__wrote_index0",
    "__dbg0",
)


def _strip_debug_suffix(name: str) -> str:
    for suf in _DEBUG_SUFFIXES:
        if name.endswith(suf):
            return name[: -len(suf)]
    return name


def _extract_cond_text(line: str) -> Optional[str]:
    """
    Extract the condition text from a Boogie `if ( ... ) {` or `while ( ... ) {` line.

    This is best-effort and intentionally lightweight (regex-free), since the generated
    Boogie is large and we only need variable names for dependency analysis.
    """

    i = line.find("(")
    j = line.rfind(")")
    if i < 0 or j <= i:
        return None
    return line[i + 1 : j].strip()


def _infer_driver_vars_from_bpl(
    *,
    bpl_text: str,
    observed_vars: Sequence[str],
    var_types: Dict[str, str],
) -> Set[str]:
    """
    Compute a conservative set of "driver" vars for the given observed vars.

    We build a lightweight, intra-file dependency graph from Boogie text:
      - data deps: variables in RHS of `x := expr;` influence `x`
      - control deps (approx): variables in `if (cond)` / `while (cond)` influence
        assignments in the guarded block (since they decide which assignments run).

    This is intentionally imprecise but useful for selecting wraparound targets
    for functional properties (e.g., DistCache cache_frequency where the reg is
    not mentioned directly in the global assert).
    """

    if not observed_vars:
        return set()

    var_names: Set[str] = set(var_types.keys())
    obs: List[str] = [v for v in observed_vars if v in var_names]
    if not obs:
        return set()

    # Reverse edges: lhs -> {rhs_vars} so we can do backward reachability from observed vars.
    preds: Dict[str, Set[str]] = {}

    # Track active control guards using a stack keyed by brace depth.
    #
    # We use reference counts so nested guards don't require expensive unions on every line.
    guard_stack: List[Tuple[Set[str], int]] = []
    guard_refcnt: Dict[str, int] = {}
    pending_guard: Optional[Set[str]] = None
    brace_depth = 0

    def _guard_vars() -> Set[str]:
        return set(guard_refcnt.keys())

    def _guard_vars_from_cond(cond: str) -> Set[str]:
        return {tok for tok in _RE_IDENT.findall(cond) if tok in var_names}

    for raw_ln in bpl_text.splitlines():
        # Strip Boogie line comments. We keep braces in the code portion only.
        ln = raw_ln.split("//", 1)[0]
        s = ln.strip()

        # Detect if/while blocks and schedule pushing their guard vars when we see the `{`.
        if s.startswith("if "):
            cond = _extract_cond_text(ln)
            if cond:
                pending_guard = _guard_vars_from_cond(cond)
        elif s.startswith("while "):
            cond = _extract_cond_text(ln)
            if cond:
                pending_guard = _guard_vars_from_cond(cond)
        elif s.startswith("} else if"):
            # else-if: keep the old guard vars and add the new condition vars.
            old = guard_stack[-1][0] if guard_stack else set()
            cond = _extract_cond_text(ln)
            if cond:
                pending_guard = set(old) | _guard_vars_from_cond(cond)
            else:
                pending_guard = set(old)
        elif s.startswith("} else"):
            # else: keep the old guard vars (the branch is still control-dependent on the guard).
            old = guard_stack[-1][0] if guard_stack else set()
            pending_guard = set(old) if old else None

        # Add deps for assignments and call-assignments in the current guard context.
        gvars = _guard_vars()
        m_call = _RE_CALL_ASSIGN_STMT.match(ln)
        if m_call:
            lhs_part = m_call.group("lhs")
            args = m_call.group("args")
            rhs_vars = {tok for tok in _RE_IDENT.findall(args) if tok in var_names}
            srcs = rhs_vars | gvars
            for lhs in [p.strip() for p in lhs_part.split(",")]:
                if lhs in var_names:
                    preds.setdefault(lhs, set()).update(srcs)
        else:
            m_asn = _RE_ASSIGN_STMT.match(ln)
            if m_asn:
                lhs_part = m_asn.group("lhs")
                rhs = m_asn.group("rhs")
                rhs_vars = {tok for tok in _RE_IDENT.findall(rhs) if tok in var_names}
                srcs = rhs_vars | gvars
                for lhs in [p.strip() for p in lhs_part.split(",")]:
                    if lhs in var_names:
                        preds.setdefault(lhs, set()).update(srcs)

        # Update brace depth and control-guard stack char-by-char so `} else {` works.
        for ch in ln:
            if ch == "}":
                brace_depth -= 1
                # Pop any guards whose block ended.
                while guard_stack and guard_stack[-1][1] > brace_depth:
                    gv, _depth = guard_stack.pop()
                    for v in gv:
                        cur = guard_refcnt.get(v, 0) - 1
                        if cur <= 0:
                            guard_refcnt.pop(v, None)
                        else:
                            guard_refcnt[v] = cur
            elif ch == "{":
                brace_depth += 1
                if pending_guard is not None:
                    gv = pending_guard
                    pending_guard = None
                    guard_stack.append((gv, brace_depth))
                    for v in gv:
                        guard_refcnt[v] = guard_refcnt.get(v, 0) + 1

    # Backward reachability from observed vars.
    drivers: Set[str] = set(obs)
    work: List[str] = list(obs)
    while work:
        cur = work.pop()
        for p in preds.get(cur, set()):
            if p not in drivers:
                drivers.add(p)
                work.append(p)
    return drivers


def _infer_from_meta_updates(
    *,
    spec_text: str,
    bpl_text: str,
    meta_by_node: Dict[str, dict],
) -> List[WraparoundCandidate]:
    var_types = _parse_var_types(bpl_text)
    global_const_eq = extract_constant_equalities_from_assumes(spec_text)
    default_proj = _default_proj_vars(var_types)

    seed_pairs = extract_seed_vars_from_global_asserts(spec_text)
    seed_bases: Set[str] = {base for base, _ in seed_pairs}
    seed_bases |= {_strip_debug_suffix(b) for b in list(seed_bases)}
    seed_index0_bases: Set[str] = {
        _strip_debug_suffix(base)
        for base, _indices in seed_pairs
        if any(base.endswith(suf) for suf in _INDEX0_DEBUG_SUFFIXES)
    }
    # Observed -> driver reachability (approx, includes control deps).
    observed_for_driver = [b for b in seed_bases if b in var_types]
    try:
        driver_vars = _infer_driver_vars_from_bpl(
            bpl_text=bpl_text,
            observed_vars=observed_for_driver,
            var_types=var_types,
        )
    except Exception:
        driver_vars = set()

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
            if delta_is_const:
                try:
                    step_delta = int(str(delta_const))
                except Exception:
                    continue
            else:
                recovered = _recover_constant_step_delta(
                    update=u,
                    node=node,
                    bpl_text=bpl_text,
                    var_types=var_types,
                )
                if recovered is None:
                    continue
                step_delta = recovered

            pump_reg = _resolve_prefixed_name(reg, node=node, var_types=var_types)
            value_var_pref = _resolve_prefixed_name(value_var, node=node, var_types=var_types)

            # Filter by whether the updated var (or the register itself) affects the observed property.
            #
            # Historically we required the updated var to appear in the global assert text, but for
            # functional properties the counter is often only a *driver* (e.g., it controls which
            # leaf is chosen), so it does not appear syntactically in the assertion. We therefore
            # use a lightweight Boogie dependency analysis to select candidates that can influence
            # the observed vars.
            if driver_vars:
                if (
                    value_var_pref not in driver_vars
                    and pump_reg not in driver_vars
                    and pump_reg not in seed_bases
                    and reg not in seed_bases
                ):
                    continue
            else:
                # Fallback: legacy gating by syntactic mention.
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
            elif pump_reg in seed_index0_bases or reg in seed_index0_bases:
                idx_value = 0
            else:
                if isinstance(idx_expr_raw, str) and idx_expr_raw.strip():
                    idx_expr_pref = _prefix_expr_with_known_vars(idx_expr_raw, node=node, var_types=var_types)
                    idx_expr_meta = _derive_index_expr_from_meta_definition(
                        idx_expr_raw,
                        node=node,
                        meta=meta,
                        bpl_text=bpl_text,
                        var_types=var_types,
                    )
                    if idx_expr_meta is not None:
                        idx_expr_pref = idx_expr_meta
                    else:
                        idx_expr_pref = _derive_index_expr_from_bpl_definition(
                            idx_expr_pref,
                            bpl_text=bpl_text,
                            var_types=var_types,
                        )
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


def _literal_int(expr: str, *, width: Optional[int] = None) -> Optional[int]:
    cur = expr.strip()
    while cur.startswith("(") and cur.endswith(")"):
        cur = cur[1:-1].strip()
    m = _RE_BV_LIT.match(cur)
    if m:
        val = int(m.group("val"))
        w = int(m.group("w"))
        return val % (1 << w)
    if re.match(r"^-?\d+$", cur):
        val = int(cur)
        return val if width is None else val % (1 << width)
    return None


def _recover_constant_step_delta(
    *,
    update: dict,
    node: str,
    bpl_text: str,
    var_types: Dict[str, str],
) -> Optional[int]:
    """
    Recover env-fixed deltas for RegisterAction updates reported by P4B.

    P4B can identify that a RegisterAction performs an additive self update
    while leaving `delta_is_const=false` for P4 expressions such as
    `x = x + hdr.ipv4.total_len`.  At the composed Boogie level, the environment
    may fix that header field to a single literal.  We accept only the narrow
    canonical shape `local := add.bvW(local, delta)` and only when constant
    propagation makes `delta` a literal.  Otherwise callers keep the old
    conservative fallback.
    """

    context = str(update.get("context") or "")
    if not context:
        return None
    value_width_raw = update.get("value_width")
    try:
        value_width = int(str(value_width_raw))
    except Exception:
        value_width = None

    bpl_consts = _extract_bpl_constant_literals(bpl_text, var_types=var_types)
    consts = dict(bpl_consts)
    consts.update(_derive_constant_assignment_literals(
        bpl_text,
        var_types=var_types,
        initial_consts=bpl_consts,
        max_iters=12,
    ))

    proc_bodies = _extract_proc_bodies(bpl_text)
    candidate_suffixes = (
        f"_{context}.apply",
        f".{context}.apply",
        f"_{context}",
        f".{context}",
    )
    deltas: Set[int] = set()

    for proc, body in proc_bodies.items():
        if not proc.startswith(f"{node}_") and f"_{context}" in proc:
            # For composed models the node prefix should normally be present.
            # Keep scanning only same-node procedure names to avoid cross-node
            # ambiguity in multi-program specs.
            continue
        if not any(proc.endswith(suf) for suf in candidate_suffixes):
            continue
        for line in body:
            m = _RE_ASSIGN_STMT.match(line)
            if not m:
                continue
            lhs_parts = [p.strip() for p in m.group("lhs").split(",")]
            if len(lhs_parts) != 1:
                continue
            lhs = lhs_parts[0]
            rhs = m.group("rhs").strip()
            ma = _RE_BV_ADD.match(rhs)
            if not ma:
                continue
            a = ma.group("a").strip()
            b = ma.group("b").strip()
            if a == lhs:
                delta_expr = b
            elif b == lhs:
                delta_expr = a
            else:
                continue
            cur = _substitute_tokens(delta_expr, consts)
            lit = _literal_int(cur, width=value_width)
            if lit is not None:
                deltas.add(lit)

    if len(deltas) == 1:
        return next(iter(deltas))
    return None


def infer_wraparound_candidates(
    *,
    spec_text: str,
    bpl_text: str,
    meta_by_node: Optional[Dict[str, dict]] = None,
    require_meta_step_for_global_asserts: bool = False,
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

    cand = _infer_from_global_asserts(spec_text=spec_text, bpl_text=bpl_text)
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
            if require_meta_step_for_global_asserts:
                # In auto mode, we *prefer* a P4B-derived monotone update to avoid wasting
                # time on non-counters. However, some P4 programs update registers via
                # `RegisterAction.execute(...)`, which is currently not reflected in
                # `wraparound.updates` (it only tracks explicit `reg.write(...)` patterns).
                #
                # If P4B reports *no* wraparound updates at all, accept the global-asserts
                # candidate and fall back to the default step (+1). Soundness is still
                # gated by `closure_check == SAFE`.
                any_updates = False
                for meta in meta_by_node.values():
                    wrap = (meta or {}).get("wraparound") or {}
                    updates = wrap.get("updates") or []
                    if isinstance(updates, list) and updates:
                        any_updates = True
                        break
                if any_updates:
                    cand = None
        else:
            if require_meta_step_for_global_asserts:
                cand = None
        if cand is not None:
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
