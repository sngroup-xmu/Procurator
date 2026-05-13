from __future__ import annotations

import re
from typing import Dict, List, Optional, Set, Tuple

from .boogie_bv_eval import bv_width, eval_bv_expr


_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_BV_LIT = re.compile(r"^(?P<val>\d+)bv(?P<w>\d+)$")
_RE_TYPE_ALIAS = re.compile(r"^\s*type\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*=\s*(?P<rhs>[^;]+);\s*$")
_RE_CONST_DECL = re.compile(
    r"^\s*const(?:\s+unique)?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*:\s*(?P<type>[^;]+);\s*$"
)
_RE_ASSIGN_STMT = re.compile(r"^\s*(?P<lhs>[^:;]+?)\s*:=\s*(?P<rhs>.*);\s*$")
_RE_CALL_STMT = re.compile(
    r"^\s*call\s+(?P<proc>[A-Za-z_][A-Za-z0-9_.]*)\((?P<args>.*)\)\s*;\s*$"
)
_RE_HAVOC_STMT = re.compile(r"^\s*havoc\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_PROC_HEADER = re.compile(
    r"^\s*procedure(?:\s+\{[^}]*\})*\s+(?P<name>[A-Za-z_][A-Za-z0-9_.$]*)\((?P<params>[^)]*)\)"
)
_RE_FUNCTION_DECL = re.compile(r"^\s*function(?:\s+\{[^}]*\})*\s+(?P<name>[A-Za-z_][A-Za-z0-9_.$]*)\s*\(")
_RE_ASSUME_CONST_EQ = re.compile(
    r"^\s*assume\s+\(?\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>[^;)]+)\s*\)?\s*;\s*$"
)
_RE_CALLEE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.$]*\s*(?=\()")
_RE_ASSUME_STMT = re.compile(r"^\s*assume\s+(?P<expr>.*)\s*;\s*$")
_RE_GOTO_STMT = re.compile(r"^\s*goto\s+(?P<labels>[^;]+)\s*;\s*$")
_RE_LABEL_STMT = re.compile(r"^\s*(?P<label>[A-Za-z_][A-Za-z0-9_.$]*)\s*:\s*$")
_RE_RETURN_STMT = re.compile(r"^\s*return\s*;\s*$")
_RE_TRAILING_BV_SLICE = re.compile(r"^(?P<body>.+)\[(?P<hi>\d+):(?P<lo>\d+)\]$")


def _vars_in_expr(expr: str, *, var_types: Dict[str, str]) -> List[str]:
    vars_found: List[str] = []
    for tok in _RE_IDENT.findall(expr):
        if tok in var_types:
            vars_found.append(tok)
    return sorted(set(vars_found))

def _residual_noncallee_identifiers(expr: str) -> List[str]:
    """Return identifiers that occur as values rather than function symbols."""
    without_callees = _RE_CALLEE_IDENT.sub("", expr)
    allowed = {"true", "false", "if", "then", "else"}
    out: Set[str] = set()
    for tok in _RE_IDENT.findall(without_callees):
        if tok in allowed:
            continue
        out.add(tok)
    return sorted(out)

def _is_preloop_pure_index_expr(
    expr: str, *, var_types: Dict[str, str], declared_call_symbols: Optional[Set[str]] = None
) -> bool:
    # First reject declared Boogie globals.  Then reject any residual identifier
    # (procedure parameters, locals, unresolved temporaries) in argument/value
    # position.  This is an allowlist: only literals and calls over literals pass.
    if _vars_in_expr(expr, var_types=var_types):
        return False
    if _residual_noncallee_identifiers(expr):
        return False
    if declared_call_symbols is None:
        return True
    for callee in _RE_CALLEE_IDENT.findall(expr):
        if callee not in declared_call_symbols:
            return False
    return True

def _normalize_meta_expr_for_target_width(expr: str, target_type: Optional[str]) -> str:
    width = bv_width(target_type)
    if width is None:
        return expr
    m = _RE_TRAILING_BV_SLICE.match(expr.strip())
    if not m:
        return expr
    hi = int(m.group("hi"))
    lo = int(m.group("lo"))
    if hi >= lo and hi - lo + 1 == width:
        return f"{m.group('body')}[{hi + 1}:{lo}]"
    return expr

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

def _strip_boogie_attributes(line: str) -> str:
    # Procedure headers may contain attributes such as `{:inline 1}`.  Those
    # braces are not body delimiters and should not affect lightweight scans.
    return re.sub(r"\{:[^}]*\}", "", line)

def _parse_param_names(params: str) -> List[str]:
    out: List[str] = []
    for raw in _split_args(params or ""):
        if ":" not in raw:
            continue
        name = raw.split(":", 1)[0].strip()
        if name:
            out.append(name)
    return out

def _substitute_tokens(expr: str, mapping: Dict[str, str]) -> str:
    if not mapping:
        return expr

    def repl(m: re.Match[str]) -> str:
        tok = m.group(0)
        return mapping.get(tok, tok)

    return _RE_IDENT.sub(repl, expr)

def _literal_value_for_type(expr: str, typ: str) -> Optional[str]:
    if typ == "bool":
        return expr if expr in {"true", "false"} else None
    if typ == "int":
        return expr if re.match(r"^-?\d+$", expr) is not None else None
    return expr if _RE_BV_LIT.match(expr) is not None else None

def _type_aliases(bpl_text: str) -> Dict[str, str]:
    aliases: Dict[str, str] = {}
    for line in bpl_text.splitlines():
        m = _RE_TYPE_ALIAS.match(line.strip())
        if m:
            aliases[m.group("name")] = m.group("rhs").strip()
    changed = True
    while changed:
        changed = False
        for name, rhs in list(aliases.items()):
            seen: Set[str] = set()
            cur = rhs
            while cur in aliases and cur not in seen:
                seen.add(cur)
                cur = aliases[cur]
            if cur != rhs:
                aliases[name] = cur
                changed = True
    return aliases

def _const_types(bpl_text: str) -> Dict[str, str]:
    out: Dict[str, str] = {}
    for line in bpl_text.splitlines():
        m = _RE_CONST_DECL.match(line.strip())
        if m:
            out[m.group("name")] = m.group("type").strip()
    return out

def _extract_bpl_constant_literals(bpl_text: str, *, var_types: Dict[str, str]) -> Dict[str, str]:
    """Extract env-like constant equalities without globalizing branch guards."""

    aliases = _type_aliases(bpl_text)
    const_types = _const_types(bpl_text)
    candidates: Dict[str, Set[str]] = {}

    def record(line: str) -> None:
        m = _RE_ASSUME_CONST_EQ.match(line.strip())
        if not m:
            return
        lhs = m.group("lhs").strip()
        if lhs not in var_types:
            return
        rhs = m.group("rhs").strip()
        typ = aliases.get(var_types.get(lhs, ""), var_types.get(lhs, ""))
        if typ == "bool":
            if rhs not in {"true", "false"}:
                return
        elif typ == "int":
            if re.match(r"^-?\d+$", rhs) is None:
                return
        else:
            if _RE_BV_LIT.match(rhs) is None and const_types.get(rhs) != typ:
                return
        candidates.setdefault(lhs, set()).add(rhs)

    for line in bpl_text.splitlines():
        if line.startswith("assume"):
            record(line)

    for name, body in _extract_proc_bodies(bpl_text).items():
        if name not in {"main", "mainProcedure", "ULTIMATE.start"}:
            continue
        for stmt in _iter_bpl_statements(body):
            record(stmt)

    return {lhs: next(iter(vals)) for lhs, vals in candidates.items() if len(vals) == 1}

def _derive_constant_assignment_literals(
    bpl_text: str,
    *,
    var_types: Dict[str, str],
    initial_consts: Dict[str, str],
    max_iters: int = 4,
) -> Dict[str, str]:
    """Derive globals whose simple assignments always collapse to one literal."""

    writes: Dict[str, List[str]] = {}
    unknown_writes: Set[str] = set()

    for line in bpl_text.splitlines():
        mh = _RE_HAVOC_STMT.match(line)
        if mh:
            for lhs in [p.strip() for p in mh.group("vars").split(",")]:
                if lhs in var_types:
                    unknown_writes.add(lhs)
            continue

        m = _RE_ASSIGN_STMT.match(line)
        if not m:
            continue
        lhs_parts = [p.strip() for p in m.group("lhs").split(",")]
        if len(lhs_parts) != 1:
            for lhs in lhs_parts:
                if lhs in var_types:
                    unknown_writes.add(lhs)
            continue
        lhs = lhs_parts[0]
        if lhs not in var_types:
            continue
        rhs = m.group("rhs").strip()
        if rhs == lhs:
            # P4B inout-preserving no-op.
            continue
        writes.setdefault(lhs, []).append(rhs)

    consts = {lhs: val for lhs, val in initial_consts.items() if lhs not in unknown_writes}
    for _ in range(max(1, max_iters)):
        changed = False
        for lhs in sorted(set(initial_consts) | set(writes)):
            if lhs in unknown_writes:
                continue
            rhs_values = writes.get(lhs, [])
            vals: Set[str] = set()
            unresolved = False
            if lhs in initial_consts:
                vals.add(initial_consts[lhs])
            for rhs in rhs_values:
                substituted = _substitute_tokens(rhs, consts)
                val = _literal_value_for_type(substituted, var_types.get(lhs, ""))
                if val is None:
                    unresolved = True
                    break
                vals.add(val)
            if unresolved or len(vals) != 1:
                continue
            val = next(iter(vals))
            if consts.get(lhs) != val:
                consts[lhs] = val
                changed = True
        if not changed:
            break

    # Validate against the final stable map.  This removes initial constants
    # whose variables also have dynamic/conflicting writes, plus dependents that
    # only looked constant because of those now-invalid sources.
    for _ in range(max(1, max_iters)):
        changed = False
        for lhs in list(consts):
            if lhs in unknown_writes:
                del consts[lhs]
                changed = True
                continue
            vals: Set[str] = set()
            unresolved = False
            if lhs in initial_consts:
                vals.add(initial_consts[lhs])
            for rhs in writes.get(lhs, []):
                substituted = _substitute_tokens(rhs, consts)
                val = _literal_value_for_type(substituted, var_types.get(lhs, ""))
                if val is None:
                    unresolved = True
                    break
                vals.add(val)
            if unresolved or len(vals) != 1 or next(iter(vals)) != consts[lhs]:
                del consts[lhs]
                changed = True
        if not changed:
            break
    return consts

def _extract_proc_bodies(bpl_text: str) -> Dict[str, List[str]]:
    lines = bpl_text.splitlines()
    out: Dict[str, List[str]] = {}
    i = 0
    while i < len(lines):
        m = _RE_PROC_HEADER.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group("name")
        open_idx = None
        depth = 0
        for j in range(i, len(lines)):
            if "{" in _strip_boogie_attributes(lines[j]):
                open_idx = j
                break
            if j > i and _RE_PROC_HEADER.match(lines[j]):
                break
        if open_idx is None:
            i += 1
            continue
        close_idx = open_idx
        for j in range(open_idx, len(lines)):
            for ch in _strip_boogie_attributes(lines[j]):
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        close_idx = j
                        break
            if depth == 0 and j >= open_idx:
                break
        out[name] = [line.strip() for line in lines[open_idx + 1 : close_idx]]
        i = max(close_idx + 1, i + 1)
    return out

def _iter_bpl_statements(body_lines: List[str]) -> List[str]:
    stmts: List[str] = []
    pending: List[str] = []
    for raw in body_lines:
        line = raw.strip()
        if not line:
            continue
        if line.startswith("//"):
            continue
        if _RE_LABEL_STMT.match(line):
            if pending:
                stmts.append(" ".join(pending))
                pending = []
            stmts.append(line)
            continue
        pending.append(line)
        if ";" in line or line in {"{", "}"} or line.endswith("{") or line.endswith("}"):
            stmts.append(" ".join(pending))
            pending = []
    if pending:
        stmts.append(" ".join(pending))
    return stmts

def _same_const_env(left: Dict[str, str], right: Dict[str, str]) -> bool:
    return left == right

def _is_simple_literal_expr(expr: str) -> bool:
    cur = expr.strip()
    return cur in {"true", "false"} or re.match(r"^-?\d+$", cur) is not None or _RE_BV_LIT.match(cur) is not None

def _strip_wrapping_parens(expr: str) -> str:
    cur = expr.strip()
    while cur.startswith("(") and cur.endswith(")"):
        depth = 0
        wraps_entire = True
        for i, ch in enumerate(cur):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth < 0:
                    return cur
                if depth == 0 and i != len(cur) - 1:
                    wraps_entire = False
                    break
        if wraps_entire and depth == 0:
            cur = cur[1:-1].strip()
            continue
        break
    return cur

def _split_top_level_bool(expr: str, op: str) -> List[str]:
    parts: List[str] = []
    cur: List[str] = []
    depth = 0
    i = 0
    while i < len(expr):
        ch = expr[i]
        if ch == "(":
            depth += 1
        elif ch == ")" and depth > 0:
            depth -= 1
        if depth == 0 and expr.startswith(op, i):
            parts.append("".join(cur).strip())
            cur = []
            i += len(op)
            continue
        cur.append(ch)
        i += 1
    parts.append("".join(cur).strip())
    return [p for p in parts if p]

def _eval_simple_assume(expr: str, env: Dict[str, str]) -> Optional[bool]:
    cur = _substitute_tokens(expr.strip(), env)
    cur = _strip_wrapping_parens(cur)
    if cur == "true":
        return True
    if cur == "false":
        return False
    and_parts = _split_top_level_bool(cur, "&&")
    if len(and_parts) > 1:
        vals = [_eval_simple_assume(part, env) for part in and_parts]
        if any(v is False for v in vals):
            return False
        if all(v is True for v in vals):
            return True
        return None
    or_parts = _split_top_level_bool(cur, "||")
    if len(or_parts) > 1:
        vals = [_eval_simple_assume(part, env) for part in or_parts]
        if any(v is True for v in vals):
            return True
        if all(v is False for v in vals):
            return False
        return None
    if cur.startswith("!"):
        inner = _strip_wrapping_parens(cur[1:].strip())
        val = _eval_simple_assume(inner, env)
        return None if val is None else not val
    m_eq = re.match(r"^(?P<a>\S+)\s*==\s*(?P<b>\S+)$", cur)
    if m_eq:
        a = m_eq.group("a")
        b = m_eq.group("b")
        if a == b:
            return True
        if _is_simple_literal_expr(a) and _is_simple_literal_expr(b):
            return False
        return None
    m_neq = re.match(r"^(?P<a>\S+)\s*!=\s*(?P<b>\S+)$", cur)
    if m_neq:
        a = m_neq.group("a")
        b = m_neq.group("b")
        if a == b:
            return False
        if _is_simple_literal_expr(a) and _is_simple_literal_expr(b):
            return True
        return None
    return None

def _assume_env_after(expr: str, env: Dict[str, str], *, var_types: Dict[str, str]) -> Optional[Dict[str, str]]:
    val = _eval_simple_assume(expr, env)
    if val is False:
        return None
    if val is True:
        return dict(env)

    cur = _strip_wrapping_parens(expr)

    and_parts = _split_top_level_bool(cur, "&&")
    if len(and_parts) > 1:
        out = dict(env)
        for part in and_parts:
            out = _assume_env_after(part, out, var_types=var_types)
            if out is None:
                return None
        return out

    m_eq = re.match(r"^(?P<a>\S+)\s*==\s*(?P<b>\S+)$", cur)
    if not m_eq:
        return dict(env)

    a = m_eq.group("a")
    b = m_eq.group("b")
    lhs_var = a if a in var_types else None
    rhs_var = b if b in var_types else None
    if lhs_var is not None and rhs_var is None:
        value = _literal_value_for_type(b, var_types.get(lhs_var, ""))
        var = lhs_var
    elif rhs_var is not None and lhs_var is None:
        value = _literal_value_for_type(a, var_types.get(rhs_var, ""))
        var = rhs_var
    else:
        return dict(env)
    if value is None:
        return dict(env)
    if var in env and env[var] != value:
        return None
    out = dict(env)
    out[var] = value
    return out

def _proc_name_prefix(proc: str) -> str:
    if "_" not in proc:
        return proc
    return proc.split("_", 1)[0] + "_"

def _call_args_at_proc_callsite(
    bpl_text: str,
    *,
    proc_name: str,
    consts: Dict[str, str],
    var_types: Dict[str, str],
    max_states: int = 2000,
) -> List[List[str]]:
    """Return target-call arguments after narrow path-sensitive propagation."""

    bodies = {name: _iter_bpl_statements(lines) for name, lines in _extract_proc_bodies(bpl_text).items()}
    if proc_name not in bodies:
        return []

    prefix = _proc_name_prefix(proc_name)
    roots = [
        name
        for name in (f"{prefix}mainProcedure", f"{prefix}main", f"{prefix}pipe")
        if name in bodies
    ]
    if not roots:
        roots = [proc_name]

    labels_by_proc: Dict[str, Dict[str, int]] = {}
    for name, stmts in bodies.items():
        labels_by_proc[name] = {
            m.group("label"): idx for idx, stmt in enumerate(stmts) if (m := _RE_LABEL_STMT.match(stmt))
        }

    results: List[List[str]] = []
    work: List[Tuple[str, int, Dict[str, str], Tuple[str, ...]]] = [
        (root, 0, dict(consts), tuple()) for root in roots
    ]
    seen: Set[Tuple[str, int, Tuple[Tuple[str, str], ...], Tuple[str, ...]]] = set()

    while work and len(seen) < max_states:
        cur_proc, pc, env, stack = work.pop()
        stmts = bodies.get(cur_proc)
        if stmts is None:
            continue
        if pc >= len(stmts):
            if stack:
                caller_proc, caller_pc_s = stack[-1].split("@", 1)
                work.append((caller_proc, int(caller_pc_s), env, stack[:-1]))
            continue
        key = (cur_proc, pc, tuple(sorted(env.items())), stack)
        if key in seen:
            continue
        seen.add(key)

        stmt = stmts[pc]
        if _RE_LABEL_STMT.match(stmt):
            work.append((cur_proc, pc + 1, env, stack))
            continue
        if _RE_RETURN_STMT.match(stmt):
            if stack:
                caller_proc, caller_pc_s = stack[-1].split("@", 1)
                work.append((caller_proc, int(caller_pc_s), env, stack[:-1]))
            continue

        mg = _RE_GOTO_STMT.match(stmt)
        if mg:
            for label in [part.strip() for part in mg.group("labels").split(",")]:
                target = labels_by_proc.get(cur_proc, {}).get(label)
                if target is not None:
                    work.append((cur_proc, target + 1, dict(env), stack))
            continue

        ma = _RE_ASSUME_STMT.match(stmt)
        if ma:
            next_env = _assume_env_after(ma.group("expr"), env, var_types=var_types)
            if next_env is not None:
                work.append((cur_proc, pc + 1, next_env, stack))
            continue

        mc = _RE_CALL_STMT.match(stmt)
        if mc:
            callee = mc.group("proc")
            args = [_substitute_tokens(arg, env) for arg in _split_args(mc.group("args"))]
            if callee == proc_name:
                results.append(args)
                work.append((cur_proc, pc + 1, env, stack))
                continue
            if (
                callee in bodies
                and callee.startswith(prefix)
                and not callee.endswith(".apply")
                and len(stack) < 12
            ):
                work.append((callee, 0, env, stack + (f"{cur_proc}@{pc + 1}",)))
            else:
                work.append((cur_proc, pc + 1, env, stack))
            continue

        m = _RE_ASSIGN_STMT.match(stmt)
        if m:
            lhs_parts = [p.strip() for p in m.group("lhs").split(",")]
            new_env = dict(env)
            if len(lhs_parts) == 1 and lhs_parts[0] in var_types:
                lhs = lhs_parts[0]
                rhs = _substitute_tokens(m.group("rhs").strip(), new_env)
                val = _literal_value_for_type(rhs, var_types.get(lhs, ""))
                if val is not None:
                    new_env[lhs] = val
                elif rhs != lhs:
                    new_env.pop(lhs, None)
            else:
                for lhs in lhs_parts:
                    new_env.pop(lhs, None)
            work.append((cur_proc, pc + 1, new_env, stack))
            continue

        mh = _RE_HAVOC_STMT.match(stmt)
        if mh:
            new_env = dict(env)
            for lhs in [p.strip() for p in mh.group("vars").split(",")]:
                new_env.pop(lhs, None)
            work.append((cur_proc, pc + 1, new_env, stack))
            continue

        work.append((cur_proc, pc + 1, env, stack))

    return results

def _derive_consts_before_proc_call(
    bpl_text: str,
    *,
    callee: str,
    var_types: Dict[str, str],
    initial_consts: Dict[str, str],
) -> Dict[str, str]:
    bodies = _extract_proc_bodies(bpl_text)
    main_body = bodies.get("main")
    if not main_body:
        return dict(initial_consts)

    prefix: List[str] = []
    for stmt in _iter_bpl_statements(main_body):
        mc = _RE_CALL_STMT.match(stmt)
        if mc and mc.group("proc") == callee:
            break
        prefix.append(stmt)
    else:
        return dict(initial_consts)

    if not prefix:
        return dict(initial_consts)

    env = dict(initial_consts)
    for stmt in prefix:
        ma = _RE_ASSUME_STMT.match(stmt)
        if ma:
            next_env = _assume_env_after(ma.group("expr"), env, var_types=var_types)
            if next_env is None:
                break
            env = next_env
            continue

        mh = _RE_HAVOC_STMT.match(stmt)
        if mh:
            for lhs in [p.strip() for p in mh.group("vars").split(",")]:
                env.pop(lhs, None)
            continue

        m = _RE_ASSIGN_STMT.match(stmt)
        if m:
            lhs_parts = [p.strip() for p in m.group("lhs").split(",")]
            if len(lhs_parts) == 1 and lhs_parts[0] in var_types:
                lhs = lhs_parts[0]
                rhs = _substitute_tokens(m.group("rhs").strip(), env)
                val = _literal_value_for_type(rhs, var_types.get(lhs, ""))
                if val is not None:
                    env[lhs] = val
                elif rhs != lhs:
                    env.pop(lhs, None)
            else:
                for lhs in lhs_parts:
                    env.pop(lhs, None)
    return env

def _extract_unique_proc_assignment_to(
    bpl_text: str,
    *,
    lhs: str,
) -> Dict[str, Tuple[List[str], str]]:
    """Find inline-like procedures that assign `lhs` exactly one RHS."""

    lines = bpl_text.splitlines()
    out: Dict[str, Tuple[List[str], str]] = {}
    i = 0
    while i < len(lines):
        m = _RE_PROC_HEADER.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group("name")
        params = _parse_param_names(m.group("params"))
        open_idx = None
        depth = 0
        for j in range(i, len(lines)):
            if "{" in _strip_boogie_attributes(lines[j]):
                open_idx = j
                break
            if j > i and _RE_PROC_HEADER.match(lines[j]):
                break
        if open_idx is None:
            i += 1
            continue
        close_idx = open_idx
        for j in range(open_idx, len(lines)):
            for ch in _strip_boogie_attributes(lines[j]):
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        close_idx = j
                        break
            if depth == 0 and j >= open_idx:
                break

        rhs_values: Set[str] = set()
        stmt_lines: List[str] = []
        for body_line in lines[open_idx + 1 : close_idx]:
            stripped = body_line.strip()
            if not stripped:
                continue
            stmt_lines.append(stripped)
            if ";" not in stripped:
                continue
            stmt = " ".join(stmt_lines)
            stmt_lines = []
            ma = _RE_ASSIGN_STMT.match(stmt)
            if not ma:
                continue
            lhs_parts = [p.strip() for p in ma.group("lhs").split(",")]
            if lhs in lhs_parts:
                rhs_values.add(ma.group("rhs").strip())
        if len(rhs_values) == 1:
            out[name] = (params, next(iter(rhs_values)))
        i = max(close_idx + 1, i + 1)
    return out

def _derive_index_expr_from_bpl_definition(
    idx_expr: str,
    *,
    bpl_text: str,
    var_types: Dict[str, str],
) -> str:
    """Replace a dynamic index variable with a stable Boogie RHS when unique."""

    expr = idx_expr.strip()
    if expr not in var_types:
        return expr

    proc_defs = _extract_unique_proc_assignment_to(bpl_text, lhs=expr)
    if not proc_defs:
        return expr

    bpl_consts = _extract_bpl_constant_literals(bpl_text, var_types=var_types)
    consts = _derive_constant_assignment_literals(bpl_text, var_types=var_types, initial_consts=bpl_consts)

    derived: Set[str] = set()
    for proc, (params, rhs) in proc_defs.items():
        prefix_consts = dict(consts)
        node_prefix = _proc_name_prefix(proc)
        main_proc = f"{node_prefix}mainProcedure"
        if main_proc != proc:
            prefix_consts.update(
                _derive_consts_before_proc_call(
                    bpl_text,
                    callee=main_proc,
                    var_types=var_types,
                    initial_consts=bpl_consts,
                )
            )
        for args in _call_args_at_proc_callsite(
            bpl_text,
            proc_name=proc,
            consts=prefix_consts,
            var_types=var_types,
        ):
            if len(args) != len(params):
                continue
            subst = {param: arg for param, arg in zip(params, args)}
            cur = _substitute_tokens(rhs, subst)
            cur = _substitute_tokens(cur, prefix_consts)
            derived.add(cur)

    for line in bpl_text.splitlines():
        m = _RE_CALL_STMT.match(line.strip())
        if not m:
            continue
        proc = m.group("proc")
        if proc not in proc_defs:
            continue
        params, rhs = proc_defs[proc]
        args = _split_args(m.group("args"))
        if len(args) != len(params):
            continue
        subst = {param: arg for param, arg in zip(params, args)}
        cur = _substitute_tokens(rhs, subst)
        cur = _substitute_tokens(cur, consts)
        derived.add(cur)

    # Ignore pre-pass mailbox copies; only a unique pure computation is stable.
    declared = _declared_call_symbols(bpl_text)
    pure = {
        d
        for d in derived
        if _is_preloop_pure_index_expr(d, var_types=var_types, declared_call_symbols=declared)
    }
    if len(pure) == 1:
        return next(iter(pure))
    return expr

def _candidate_index_definition_keys(idx_expr_raw: str, idx_expr_pref: str, *, node: str) -> Set[str]:
    keys = {idx_expr_raw.strip(), idx_expr_pref.strip()}
    pref = f"{node}_"
    if idx_expr_pref.startswith(pref):
        keys.add(idx_expr_pref[len(pref) :])
    changed = True
    while changed:
        changed = False
        more: Set[str] = set()
        for key in keys:
            if key.endswith("_0"):
                more.add(key[:-2])
            else:
                more.add(f"{key}_0")
            if key.startswith(pref):
                more.add(key[len(pref) :])
        before = len(keys)
        keys |= {k for k in more if k}
        changed = len(keys) != before
    return {k for k in keys if k}

def _meta_wraparound_definitions(meta: dict) -> List[dict]:
    wrap = (meta or {}).get("wraparound") or {}
    out: List[dict] = []
    for key in ("deterministic_definitions", "index_definitions"):
        defs = wrap.get(key) or []
        if isinstance(defs, list):
            out.extend(item for item in defs if isinstance(item, dict))
    return out

def _definition_context_aliases(
    expr: str,
    item: dict,
    *,
    node: str,
    var_types: Dict[str, str],
) -> Dict[str, str]:
    context = item.get("context", "")
    if not isinstance(context, str) or not context.strip():
        return {}
    out: Dict[str, str] = {}
    for tok in _RE_IDENT.findall(expr):
        if tok in var_types or tok in {"true", "false"}:
            continue
        matches = sorted(
            name
            for name in var_types
            if name.startswith(f"{node}_") and name.endswith(f".{context}.{tok}")
        )
        if len(matches) == 1:
            out[tok] = matches[0]
    return out

def _derive_stable_meta_definition_map(
    raw_defs: List[dict],
    *,
    node: str,
    bpl_text: str,
    var_types: Dict[str, str],
    root_consts: Dict[str, str],
    consts: Dict[str, str],
    declared: Set[str],
) -> Dict[str, str]:
    """
    Compute a conservative fixed point over P4B deterministic/index definitions.

    P4B may describe an index through intermediate metadata, e.g.
    `meta.register_index = hash(..., meta.hdr_srcport, ...)` and
    `meta.hdr_srcport = hdr.tcp.src_port`.  A definition becomes usable only
    when every value dependency resolves to literals or calls over literals.
    Multiple pure definitions for the same target are treated as ambiguous.
    """

    stable: Dict[str, str] = {}
    for _ in range(max(1, len(raw_defs) + 1)):
        candidates: Dict[str, Set[str]] = {}
        for item in raw_defs:
            target = item.get("target_var", item.get("target", ""))
            expr = item.get("expr", "")
            if not isinstance(target, str) or not isinstance(expr, str):
                continue
            if item.get("ambiguous") is True:
                continue
            target_pref = _prefix_expr_with_known_vars(target.strip(), node=node, var_types=var_types)
            if target_pref not in var_types:
                continue
            cur = _prefix_expr_with_known_vars(expr.strip(), node=node, var_types=var_types)
            cur = _substitute_tokens(
                cur,
                _definition_context_aliases(cur, item, node=node, var_types=var_types),
            )
            # Meta may still mention high-level hash call symbols (e.g., *_idx_calc.get$...)
            # that do not exist after P4B lowering. Rewrite such expressions to the actual
            # declared/lowered assignment RHS when uniquely recoverable.
            rewritten = _rewrite_hash_model_expr_to_declared(
                cur,
                node=node,
                target_pref=target_pref,
                bpl_text=bpl_text,
                var_types=var_types,
            )
            if rewritten is not None:
                cur, quality = rewritten
                if quality == "low":
                    # Do not turn a dynamic hash index into a pass-through copy such
                    # as `io_meta.register_index`; such copies are pre-loop globals.
                    # Keep the original expression and let normal purity checks decide.
                    cur = _prefix_expr_with_known_vars(expr.strip(), node=node, var_types=var_types)
                    cur = _substitute_tokens(
                        cur,
                        _definition_context_aliases(cur, item, node=node, var_types=var_types),
                    )
            cur = _prefix_callees_with_declared_symbols(cur, node=node, declared=declared)
            cur = _substitute_tokens(cur, root_consts)
            cur = _substitute_tokens(cur, consts)
            cur = _substitute_tokens(
                cur,
                {name: value for name, value in stable.items() if name != target_pref},
            )
            cur = _canonicalize_call_arg_spacing(cur)
            cur = _normalize_meta_expr_for_target_width(cur, var_types.get(target_pref))
            if _is_preloop_pure_index_expr(cur, var_types=var_types, declared_call_symbols=declared):
                candidates.setdefault(target_pref, set()).add(cur)

        next_stable = {
            target: next(iter(values))
            for target, values in candidates.items()
            if len(values) == 1
        }
        if next_stable == stable:
            break
        stable = next_stable
    return stable

def _derive_stable_expr_from_meta_definition(
    target_expr_raw: str,
    *,
    node: str,
    meta: dict,
    bpl_text: str,
    var_types: Dict[str, str],
) -> Optional[str]:
    if not isinstance(target_expr_raw, str) or not target_expr_raw.strip():
        return None
    raw_defs = _meta_wraparound_definitions(meta)
    if not raw_defs:
        return None

    target_expr_pref = _prefix_expr_with_known_vars(target_expr_raw, node=node, var_types=var_types)
    keys = _candidate_index_definition_keys(target_expr_raw, target_expr_pref, node=node)
    declared = _declared_call_symbols(bpl_text)

    bpl_consts = _extract_bpl_constant_literals(bpl_text, var_types=var_types)
    derived_consts = _derive_constant_assignment_literals(
        bpl_text,
        var_types=var_types,
        initial_consts=bpl_consts,
        max_iters=12,
    )
    consts = dict(derived_consts)
    # Structured P4B index definitions describe the expression at the P4 pass
    # boundary.  Env/header assumptions are valid before the first scheduler
    # iteration even if the same field is later assigned by table/action code,
    # so keep those direct literals available for pre-loop fast-forward.
    consts.update(bpl_consts)

    root_consts: Dict[str, str] = {}
    for root in _node_roots_for_index_definition(node=node, bpl_text=bpl_text):
        root_consts.update(
            _derive_consts_at_proc_entry(
                bpl_text,
                proc_name=root,
                var_types=var_types,
                initial_consts=bpl_consts,
            )
        )

    stable_defs = _derive_stable_meta_definition_map(
        raw_defs,
        node=node,
        bpl_text=bpl_text,
        var_types=var_types,
        root_consts=root_consts,
        consts=consts,
        declared=declared,
    )
    prefixed_keys = {
        _prefix_expr_with_known_vars(key, node=node, var_types=var_types)
        for key in keys
    }
    candidates: Set[str] = {
        expr for target, expr in stable_defs.items() if target in prefixed_keys
    }

    for item in raw_defs:
        if not isinstance(item, dict):
            continue
        target = item.get("target_var", item.get("target", ""))
        expr = item.get("expr", "")
        if not isinstance(target, str) or not isinstance(expr, str):
            continue
        if item.get("ambiguous") is True:
            continue
        if target.strip() not in keys:
            continue
        target_pref_item = _prefix_expr_with_known_vars(target.strip(), node=node, var_types=var_types)
        cur = _prefix_expr_with_known_vars(expr.strip(), node=node, var_types=var_types)
        cur = _substitute_tokens(
            cur,
            _definition_context_aliases(cur, item, node=node, var_types=var_types),
        )
        rewritten = _rewrite_hash_model_expr_to_declared(
            cur,
            node=node,
            target_pref=target_pref_item,
            bpl_text=bpl_text,
            var_types=var_types,
        )
        if rewritten is not None:
            cur, quality = rewritten
            if quality == "low":
                cur = _prefix_expr_with_known_vars(expr.strip(), node=node, var_types=var_types)
                cur = _substitute_tokens(
                    cur,
                    _definition_context_aliases(cur, item, node=node, var_types=var_types),
                )
        cur = _prefix_callees_with_declared_symbols(cur, node=node, declared=declared)
        cur = _substitute_tokens(cur, root_consts)
        cur = _substitute_tokens(cur, consts)
        cur = _substitute_tokens(
            cur,
            {name: value for name, value in stable_defs.items() if name != target_expr_pref},
        )
        cur = _canonicalize_call_arg_spacing(cur)
        cur = _normalize_meta_expr_for_target_width(cur, var_types.get(target_pref_item))
        if _is_preloop_pure_index_expr(cur, var_types=var_types, declared_call_symbols=declared):
            candidates.add(cur)

    return next(iter(candidates)) if len(candidates) == 1 else None

def _derive_index_expr_from_meta_definition(
    idx_expr_raw: str,
    *,
    node: str,
    meta: dict,
    bpl_text: str,
    var_types: Dict[str, str],
) -> Optional[str]:
    """
    Prefer P4B's structured index/deterministic definition meta over Boogie text recovery.

    The P4B definition is emitted in a node-local namespace.  We prefix variables
    against composed Boogie globals and prefix callee symbols against composed
    function/procedure declarations.  We only accept a unique pre-loop-pure
    expression; otherwise callers fall back to the legacy Boogie recovery path.
    """

    return _derive_stable_expr_from_meta_definition(
        idx_expr_raw,
        node=node,
        meta=meta,
        bpl_text=bpl_text,
        var_types=var_types,
    )

def _derive_stable_expr_substitutions_from_meta_definitions(
    *,
    node: str,
    meta: dict,
    bpl_text: str,
    var_types: Dict[str, str],
) -> Dict[str, str]:
    raw_defs = _meta_wraparound_definitions(meta)
    if not raw_defs:
        return {}

    bpl_consts = _extract_bpl_constant_literals(bpl_text, var_types=var_types)
    derived_consts = _derive_constant_assignment_literals(
        bpl_text,
        var_types=var_types,
        initial_consts=bpl_consts,
        max_iters=12,
    )
    consts = dict(derived_consts)
    consts.update(bpl_consts)

    root_consts: Dict[str, str] = {}
    for root in _node_roots_for_index_definition(node=node, bpl_text=bpl_text):
        root_consts.update(
            _derive_consts_at_proc_entry(
                bpl_text,
                proc_name=root,
                var_types=var_types,
                initial_consts=bpl_consts,
            )
        )

    stable = _derive_stable_meta_definition_map(
        raw_defs,
        node=node,
        bpl_text=bpl_text,
        var_types=var_types,
        root_consts=root_consts,
        consts=consts,
        declared=_declared_call_symbols(bpl_text),
    )
    folded: Dict[str, str] = {}
    for target, expr in stable.items():
        value = eval_bv_expr(expr, const_eq={}, var_types=var_types)
        folded[target] = f"{value.value}bv{value.width}" if value is not None else expr
    return folded

def _node_roots_for_index_definition(*, node: str, bpl_text: str) -> List[str]:
    prefix = f"{node}_"
    bodies = _extract_proc_bodies(bpl_text)
    return [name for name in (f"{prefix}mainProcedure", f"{prefix}main", f"{prefix}pipe") if name in bodies]

def _derive_consts_at_proc_entry(
    bpl_text: str,
    *,
    proc_name: str,
    var_types: Dict[str, str],
    initial_consts: Dict[str, str],
) -> Dict[str, str]:
    """
    Derive literals known at the entry of a node-local procedure.

    System harnesses copy env-pinned IO fields into node-local packet/meta
    globals immediately before invoking the node pipeline.  These constants are
    valid at the P4 pass boundary even when parser branches later assign the
    same metadata from packet fields.  This helper follows the harness prefix up
    to `call proc_name()` and returns that entry environment.
    """

    bodies = _extract_proc_bodies(bpl_text)
    roots = [name for name in ("main", "mainProcedure", "ULTIMATE.start") if name in bodies]
    if not roots:
        return {}

    labels_by_proc: Dict[str, Dict[str, int]] = {}
    iter_bodies = {name: _iter_bpl_statements(lines) for name, lines in bodies.items()}
    for name, stmts in iter_bodies.items():
        labels_by_proc[name] = {
            m.group("label"): idx for idx, stmt in enumerate(stmts) if (m := _RE_LABEL_STMT.match(stmt))
        }

    results: List[Dict[str, str]] = []
    work: List[Tuple[str, int, Dict[str, str], Tuple[str, ...]]] = [
        (root, 0, dict(initial_consts), tuple()) for root in roots
    ]
    seen: Set[Tuple[str, int, Tuple[Tuple[str, str], ...], Tuple[str, ...]]] = set()

    while work and len(seen) < 4000:
        cur_proc, pc, env, stack = work.pop()
        stmts = iter_bodies.get(cur_proc)
        if stmts is None:
            continue
        if pc >= len(stmts):
            if stack:
                caller_proc, caller_pc_s = stack[-1].split("@", 1)
                work.append((caller_proc, int(caller_pc_s), env, stack[:-1]))
            continue
        key = (cur_proc, pc, tuple(sorted(env.items())), stack)
        if key in seen:
            continue
        seen.add(key)

        stmt = stmts[pc]
        if _RE_LABEL_STMT.match(stmt):
            work.append((cur_proc, pc + 1, env, stack))
            continue
        if _RE_RETURN_STMT.match(stmt):
            if stack:
                caller_proc, caller_pc_s = stack[-1].split("@", 1)
                work.append((caller_proc, int(caller_pc_s), env, stack[:-1]))
            continue

        mg = _RE_GOTO_STMT.match(stmt)
        if mg:
            for label in [part.strip() for part in mg.group("labels").split(",")]:
                target = labels_by_proc.get(cur_proc, {}).get(label)
                if target is not None:
                    work.append((cur_proc, target + 1, dict(env), stack))
            continue

        ma = _RE_ASSUME_STMT.match(stmt)
        if ma:
            next_env = _assume_env_after(ma.group("expr"), env, var_types=var_types)
            if next_env is not None:
                work.append((cur_proc, pc + 1, next_env, stack))
            continue

        mc = _RE_CALL_STMT.match(stmt)
        if mc:
            callee = mc.group("proc")
            if callee == proc_name:
                results.append(dict(env))
                work.append((cur_proc, pc + 1, env, stack))
                continue
            if callee in iter_bodies and len(stack) < 12:
                work.append((callee, 0, env, stack + (f"{cur_proc}@{pc + 1}",)))
            else:
                work.append((cur_proc, pc + 1, env, stack))
            continue

        m = _RE_ASSIGN_STMT.match(stmt)
        if m:
            lhs_parts = [p.strip() for p in m.group("lhs").split(",")]
            new_env = dict(env)
            if len(lhs_parts) == 1 and lhs_parts[0] in var_types:
                lhs = lhs_parts[0]
                rhs = _substitute_tokens(m.group("rhs").strip(), new_env)
                val = _literal_value_for_type(rhs, var_types.get(lhs, ""))
                if val is not None:
                    new_env[lhs] = val
                elif rhs != lhs:
                    new_env.pop(lhs, None)
            else:
                for lhs in lhs_parts:
                    new_env.pop(lhs, None)
            work.append((cur_proc, pc + 1, new_env, stack))
            continue

        mh = _RE_HAVOC_STMT.match(stmt)
        if mh:
            new_env = dict(env)
            for lhs in [p.strip() for p in mh.group("vars").split(",")]:
                new_env.pop(lhs, None)
            work.append((cur_proc, pc + 1, new_env, stack))
            continue

        work.append((cur_proc, pc + 1, env, stack))

    if not results:
        return {}
    keys = set().union(*(env.keys() for env in results))
    out: Dict[str, str] = {}
    for key in keys:
        vals = {env.get(key) for env in results}
        if len(vals) == 1 and None not in vals:
            out[key] = next(iter(vals))  # type: ignore[arg-type]
    return out

def _maybe_eval_index_expr_to_constant(
    idx_expr: str, *, const_eq: Dict[str, int], var_types: Dict[str, str]
) -> Optional[int]:
    value = eval_bv_expr(idx_expr, const_eq=const_eq, var_types=var_types)
    return None if value is None else value.value
def _resolve_prefixed_name(name: str, *, node: str, var_types: Dict[str, str]) -> str:
    """
    Map an unprefixed P4B name to the composed Boogie name.

    dslc prefixes Boogie symbols using `node_...`. P4B sometimes emits both
    `<x>` and `<x>_0` variants; we prefer whichever exists in `var_types`.
    """

    if name in var_types:
        return name
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

def _declared_call_symbols(bpl_text: str) -> Set[str]:
    out: Set[str] = set()
    for line in bpl_text.splitlines():
        mf = _RE_FUNCTION_DECL.match(line.strip())
        if mf:
            out.add(mf.group("name"))
            continue
        mp = _RE_PROC_HEADER.match(line.strip())
        if mp:
            out.add(mp.group("name"))
    return out

def _normalize_hash_callee_to_declared(tok: str, *, node: str, declared: Set[str]) -> Optional[str]:
    candidates = {tok}
    pref = f"{node}_{tok}"
    candidates.add(pref)
    for cand in list(candidates):
        if cand in declared:
            return cand
    for cand in candidates:
        if "$" not in cand:
            continue
        base = cand.split("$", 1)[0]
        matches = sorted(d for d in declared if d.startswith(base + "$"))
        if len(matches) == 1:
            return matches[0]
    return None

def _prefix_callees_with_declared_symbols(expr: str, *, node: str, declared: Set[str]) -> str:
    if not declared:
        return expr

    def repl(m: re.Match[str]) -> str:
        raw = m.group(0)
        stripped = raw.rstrip()
        suffix = raw[len(stripped) :]
        tok = stripped
        if tok in declared:
            return raw
        pref = f"{node}_{tok}"
        if pref in declared:
            return pref + suffix
        normalized = _normalize_hash_callee_to_declared(tok, node=node, declared=declared)
        if normalized is not None:
            return normalized + suffix
        return raw

    return _RE_CALLEE_IDENT.sub(repl, expr)


def _rewrite_hash_model_expr_to_declared(
    expr: str,
    *,
    node: str,
    target_pref: str,
    bpl_text: str,
    var_types: Dict[str, str],
) -> Optional[Tuple[str, str]]:
    """
    Rewrite unsupported meta hash-call expressions into declared lowered formulas.

    P4B meta may expose deterministic/index definitions as high-level hash callee
    symbols (e.g., `Ingress_idx_calc.get$...`) while the final Boogie model has
    already lowered hashes to inlined CRC formulas. In that case the meta callee is
    undeclared in the composed BPL. This helper recovers the actual assigned RHS by
    scanning assignments to `target_pref` inside node-local procedures.
    """

    if not isinstance(expr, str):
        return None
    if "get$" not in expr:
        return None

    declared = _declared_call_symbols(bpl_text)
    undeclared = [c for c in _RE_CALLEE_IDENT.findall(expr) if c not in declared]
    if not undeclared:
        return None

    def _expand_rhs_with_local_aliases(rhs: str, alias_map: Dict[str, str]) -> str:
        """
        Expand local temporaries with in-procedure aliases.

        Example in lowered TNA models:
          srcPort_1 := meta.hdr_srcport;
          dstPort_1 := meta.hdr_dstport;
          meta.register_index := crc(... srcPort_1 ... dstPort_1 ...);
        We want the target RHS to inline those temporaries.
        """

        cur = rhs
        seen: Set[str] = {cur}
        for _ in range(16):
            nxt = _substitute_tokens(cur, alias_map)
            if nxt == cur or nxt in seen:
                return nxt
            seen.add(nxt)
            cur = nxt
        return cur

    proc_bodies = _extract_proc_bodies(bpl_text)
    prefix = f"{node}_"
    candidates: Set[str] = set()
    for proc, body in proc_bodies.items():
        if not proc.startswith(prefix):
            continue
        local_aliases: Dict[str, str] = {}
        for stmt in _iter_bpl_statements(body):
            mh = _RE_HAVOC_STMT.match(stmt)
            if mh:
                for lhs in [part.strip() for part in mh.group("vars").split(",")]:
                    local_aliases.pop(lhs, None)
                continue

            if stmt.lstrip().startswith("call "):
                # Calls may clobber locals/globals through modifies; avoid
                # carrying stale temporary aliases across call boundaries.
                local_aliases.clear()
                continue

            m = _RE_ASSIGN_STMT.match(stmt)
            if not m:
                continue
            lhs_parts = [p.strip() for p in m.group("lhs").split(",")]
            rhs_raw = m.group("rhs").strip()
            rhs_expanded = _expand_rhs_with_local_aliases(rhs_raw, local_aliases)
            if target_pref in lhs_parts and rhs_expanded:
                candidates.add(rhs_expanded)

            if len(lhs_parts) != 1:
                for lhs in lhs_parts:
                    local_aliases.pop(lhs, None)
                continue

            lhs = lhs_parts[0]
            if lhs in _RE_IDENT.findall(rhs_expanded):
                local_aliases.pop(lhs, None)
            else:
                local_aliases[lhs] = rhs_expanded
    if len(candidates) != 1:
        return None
    # Prefer real hash-like lowered formulas (CRC/concat/slice), not trivial copies
    # from harness/meta passthrough assignments.
    preferred = [
        rhs
        for rhs in candidates
        if ("crc" in rhs.lower()) or ("++" in rhs) or ("[" in rhs and ":" in rhs and "]" in rhs)
    ]
    if len(preferred) == 1:
        return preferred[0], "high"
    return next(iter(candidates)), "low"


def _canonicalize_call_arg_spacing(expr: str) -> str:
    """
    Normalize call argument spacing to keep deterministic expression strings.
    """

    text = str(expr or "")
    text = re.sub(r"\(\s+", "(", text)
    text = re.sub(r"\s+,\s*", ", ", text)
    return text
