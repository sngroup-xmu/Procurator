from __future__ import annotations

import re
from typing import Dict, List, Optional, Set, Tuple


_RE_IDENT = re.compile(r"\b[A-Za-z_][A-Za-z0-9_.]*\b")
_RE_BV_LIT = re.compile(r"^(?P<val>\d+)bv(?P<w>\d+)$")
_RE_TYPE_ALIAS = re.compile(r"^\s*type\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*=\s*(?P<rhs>[^;]+);\s*$")
_RE_CONCAT_LIT_VAR = re.compile(
    r"^(?P<prefix>\d+)bv(?P<pw>\d+)\s*\+\+\s*(?P<var>[A-Za-z_][A-Za-z0-9_.]*)$"
)
_RE_ASSIGN_STMT = re.compile(r"^\s*(?P<lhs>[^:;]+?)\s*:=\s*(?P<rhs>.*);\s*$")
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


def _vars_in_expr(expr: str, *, var_types: Dict[str, str]) -> List[str]:
    vars_found: List[str] = []
    for tok in _RE_IDENT.findall(expr):
        if tok in var_types:
            vars_found.append(tok)
    return sorted(set(vars_found))

def _residual_noncallee_identifiers(expr: str) -> List[str]:
    """
    Return identifiers that occur as values rather than function symbols.

    A pre-loop fast-forward index may safely call an uninterpreted function over
    literals, e.g. `Hash.get(1bv32, 2bv16)`.  The function name itself is an
    identifier in Boogie text, but it is not a runtime value.  Any identifier
    left after removing callee positions is a value dependency and is unsafe
    unless it is one of Boogie's literal keywords.
    """

    without_callees = _RE_CALLEE_IDENT.sub("", expr)
    allowed = {"true", "false"}
    out: Set[str] = set()
    for tok in _RE_IDENT.findall(without_callees):
        if tok in allowed:
            continue
        out.add(tok)
    return sorted(out)

def _is_preloop_pure_index_expr(expr: str, *, var_types: Dict[str, str]) -> bool:
    # First reject declared Boogie globals.  Then reject any residual identifier
    # (procedure parameters, locals, unresolved temporaries) in argument/value
    # position.  This is an allowlist: only literals and calls over literals pass.
    if _vars_in_expr(expr, var_types=var_types):
        return False
    return not _residual_noncallee_identifiers(expr)

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

def _extract_bpl_constant_literals(bpl_text: str, *, var_types: Dict[str, str]) -> Dict[str, str]:
    """
    Extract Boogie-level constant equalities from generated env assumptions.

    This complements DSL global assumes: host/node env blocks are emitted as typed
    Boogie assumptions (`assume x == 7bv16;`).  For a dynamic register index such
    as `meta.register_index := Hash.get(five_tuple)`, these equalities let us
    turn the pre-loop fast-forward index into `Hash.get(constants...)` instead
    of the uninitialized packet/meta variables at the cutpoint.
    """

    aliases = _type_aliases(bpl_text)
    candidates: Dict[str, Set[str]] = {}
    for line in bpl_text.splitlines():
        m = _RE_ASSUME_CONST_EQ.match(line.strip())
        if not m:
            continue
        lhs = m.group("lhs").strip()
        if lhs not in var_types:
            continue
        rhs = m.group("rhs").strip()
        typ = aliases.get(var_types.get(lhs, ""), var_types.get(lhs, ""))
        if typ == "bool":
            if rhs not in {"true", "false"}:
                continue
        elif typ == "int":
            if re.match(r"^-?\d+$", rhs) is None:
                continue
        else:
            if _RE_BV_LIT.match(rhs) is None:
                continue
        candidates.setdefault(lhs, set()).add(rhs)

    return {lhs: next(iter(vals)) for lhs, vals in candidates.items() if len(vals) == 1}

def _derive_constant_assignment_literals(
    bpl_text: str,
    *,
    var_types: Dict[str, str],
    initial_consts: Dict[str, str],
    max_iters: int = 4,
) -> Dict[str, str]:
    """
    Derive additional constant-valued globals from simple assignments.

    Example from Flowrest:
      meta.hdr_srcport := hdr.tcp.src_port;

    If `hdr.tcp.src_port` is fixed by env assumptions (and all assignments to
    `meta.hdr_srcport` collapse to the same literal), we can safely use the
    metadata value in a pre-loop index expression.
    """

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
            # P4B table/action stubs often emit `x := x;` to preserve an inout
            # parameter.  Treat it as a no-op; it should not poison an otherwise
            # constant env copy chain.
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

def _eval_simple_assume(expr: str, env: Dict[str, str]) -> Optional[bool]:
    cur = _substitute_tokens(expr.strip(), env)
    cur = cur.strip()
    while cur.startswith("(") and cur.endswith(")"):
        cur = cur[1:-1].strip()
    if cur == "true":
        return True
    if cur == "false":
        return False
    if cur.startswith("!"):
        inner = cur[1:].strip()
        while inner.startswith("(") and inner.endswith(")"):
            inner = inner[1:-1].strip()
        val = _eval_simple_assume(inner, env)
        return None if val is None else not val
    if "&&" in cur:
        vals = [_eval_simple_assume(part, env) for part in cur.split("&&")]
        if any(v is False for v in vals):
            return False
        if all(v is True for v in vals):
            return True
        return None
    m_eq = re.match(r"^(?P<a>\S+)\s*==\s*(?P<b>\S+)$", cur)
    if m_eq:
        return m_eq.group("a") == m_eq.group("b")
    m_neq = re.match(r"^(?P<a>\S+)\s*!=\s*(?P<b>\S+)$", cur)
    if m_neq:
        return m_neq.group("a") != m_neq.group("b")
    return None

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
    """
    Return target-call arguments after path-sensitive constant propagation.

    This is intentionally narrow and conservative.  It follows intra-node inline
    procedure calls and parser gotos, prunes branches whose `assume` is false
    under the current constants, and records only values at the target callsite.
    If the Boogie shape is outside this small fragment, the caller simply falls
    back to the original dynamic index.
    """

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
            val = _eval_simple_assume(ma.group("expr"), env)
            if val is not False:
                work.append((cur_proc, pc + 1, env, stack))
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
    return _derive_constant_assignment_literals(
        "\n".join(prefix),
        var_types=var_types,
        initial_consts=initial_consts,
        max_iters=12,
    )

def _extract_unique_proc_assignment_to(
    bpl_text: str,
    *,
    lhs: str,
) -> Dict[str, Tuple[List[str], str]]:
    """
    Find inline-like procedures that assign `lhs` exactly one RHS.

    Returned mapping is `proc_name -> (params, rhs)`.  We intentionally ignore
    procedures with multiple different assignments to `lhs`.
    """

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
    """
    Replace a dynamic index variable with its deterministic Boogie definition.

    Flowrest/TNA often emits meta like `idx_expr = meta.register_index`, while
    the generated Boogie computes that variable by calling a small action:

      call Ingress_get_register_index(meta.hdr_srcport, meta.hdr_dstport);
      ...
      procedure Ingress_get_register_index(src, dst) {
        meta.register_index := Hash.get(hdr.src, hdr.dst, src, dst, hdr.proto);
      }

    The wraparound fast-forward runs before the first scheduler iteration, so
    using `meta.register_index` directly would read an uninitialized/havoced
    value.  This helper recovers the pure RHS, substitutes call arguments and
    env constants, and returns a stable expression such as
    `Hash.get(10.0.0.1, 10.0.0.2, 1234, 443, TCP)`.
    """

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

    # The generated system harness may also copy mailbox/host metadata into the
    # node-local meta variables (e.g. `mainProcedure` assigning
    # `meta.register_index := io_meta.register_index`).  Those pre-pass copies
    # are not the register-action index computation and are unsafe to use for a
    # pre-loop fast-forward.  Prefer a uniquely recovered pure expression, such
    # as a hash function over env literals.  If we cannot get exactly one pure
    # expression, keep the original dynamic index so the CEGAR layer falls back.
    pure = {d for d in derived if _is_preloop_pure_index_expr(d, var_types=var_types)}
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

def _derive_index_expr_from_meta_definition(
    idx_expr_raw: str,
    *,
    node: str,
    meta: dict,
    bpl_text: str,
    var_types: Dict[str, str],
) -> Optional[str]:
    """
    Prefer P4B's structured index definition meta over Boogie text recovery.

    The P4B definition is emitted in a node-local namespace.  We prefix variables
    against composed Boogie globals and prefix callee symbols against composed
    function/procedure declarations.  We only accept a unique pre-loop-pure
    expression; otherwise callers fall back to the legacy Boogie recovery path.
    """

    if not isinstance(idx_expr_raw, str) or not idx_expr_raw.strip():
        return None
    wrap = (meta or {}).get("wraparound") or {}
    defs = wrap.get("index_definitions") or []
    if not isinstance(defs, list) or not defs:
        return None

    idx_expr_pref = _prefix_expr_with_known_vars(idx_expr_raw, node=node, var_types=var_types)
    keys = _candidate_index_definition_keys(idx_expr_raw, idx_expr_pref, node=node)
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

    candidates: Set[str] = set()
    for item in defs:
        if not isinstance(item, dict):
            continue
        target = item.get("target_var", item.get("target", ""))
        expr = item.get("expr", "")
        if not isinstance(target, str) or not isinstance(expr, str):
            continue
        if target.strip() not in keys:
            continue
        cur = _prefix_expr_with_known_vars(expr.strip(), node=node, var_types=var_types)
        cur = _prefix_callees_with_declared_symbols(cur, node=node, declared=declared)
        cur = _substitute_tokens(cur, consts)
        if _is_preloop_pure_index_expr(cur, var_types=var_types):
            candidates.add(cur)

    return next(iter(candidates)) if len(candidates) == 1 else None

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
        if tok.startswith("hash_"):
            normalized = _normalize_hash_callee_to_declared(tok, node=node, declared=declared)
            if normalized is not None:
                return normalized + suffix
        return raw

    return _RE_CALLEE_IDENT.sub(repl, expr)
