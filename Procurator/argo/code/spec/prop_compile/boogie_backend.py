from __future__ import annotations

import argparse
import os
import re
import subprocess
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence, Tuple

from lark import Lark, Tree, Token

from parser import grammar


@dataclass(frozen=True)
class ImportDecl:
    alias: str
    p4_path: str
    entries_path: Optional[str] = None


@dataclass(frozen=True)
class LinkDecl:
    src: str
    dst: str
    port: str  # "ALL" or a decimal string


@dataclass
class NodeDecl:
    name: str
    external_input: bool = False
    assume_exprs: List[Tree] = field(default_factory=list)
    assert_exprs: List[Tree] = field(default_factory=list)


@dataclass
class GlobalDecl:
    queue_capacity: int = 2
    assume_exprs: List[Tree] = field(default_factory=list)
    assert_exprs: List[Tree] = field(default_factory=list)


@dataclass
class SpecModel:
    imports: Dict[str, ImportDecl] = field(default_factory=dict)  # alias -> decl
    links: List[LinkDecl] = field(default_factory=list)
    nodes: Dict[str, NodeDecl] = field(default_factory=dict)  # node -> decl
    global_decl: GlobalDecl = field(default_factory=GlobalDecl)
    symmetry_groups: List[List[str]] = field(default_factory=list)


class SpecParseError(ValueError):
    pass


class P4BTranslatorError(RuntimeError):
    pass


class P4BTranslator:
    def __init__(self, p4b_bin: str):
        self._p4b_bin = p4b_bin
        self._include_paths = _default_p4c_include_paths(p4b_bin)

    def compile_to_bpl(self, p4_path: str, out_bpl: str, entries_path: Optional[str]) -> None:
        # NOTE: p4c-style compilers require -I paths to appear before the input file.
        cmd: List[str] = [self._p4b_bin]
        for inc in self._include_paths:
            cmd.extend(["-I", inc])
        cmd.extend([p4_path, "-o", out_bpl])
        if entries_path:
            cmd.extend(["--bmv2cmds", entries_path])

        try:
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        except FileNotFoundError as e:
            raise P4BTranslatorError(
                f"p4b translator binary not found: {self._p4b_bin}. "
                f"Pass --p4b-bin explicitly."
            ) from e
        except subprocess.CalledProcessError as e:
            raise P4BTranslatorError(
                "p4b translation failed:\n"
                f"cmd: {' '.join(cmd)}\n"
                f"exit: {e.returncode}\n"
                f"out:\n{e.stdout}"
            ) from e


def _default_p4c_include_paths(p4b_bin: str) -> List[str]:
    """
    Determine a best-effort list of include directories for p4c-style preprocessors.

    Sources (in priority order):
      1) $P4C_INCLUDE_PATH (split by os.pathsep)
      2) Auto-detect a `p4include/` directory by walking up from the p4b_bin path.
    """
    out: List[str] = []

    env = os.getenv("P4C_INCLUDE_PATH", "")
    if env:
        for p in env.split(os.pathsep):
            p = p.strip()
            if not p:
                continue
            if Path(p).is_dir():
                out.append(str(Path(p)))

    bin_path = Path(p4b_bin).expanduser().resolve()
    for parent in [bin_path.parent, *bin_path.parents]:
        cand = parent / "p4include"
        if cand.is_dir():
            out.append(str(cand))
            break

    seen = set()
    dedup: List[str] = []
    for p in out:
        if p not in seen:
            seen.add(p)
            dedup.append(p)
    return dedup


class BoogiePrefixer:
    """
    Prefix all declared Boogie symbols in a single .bpl unit with `prefix_...`.

    This is a pragmatic text-based prefixer (not a full Boogie parser).
    It works well for P4B-Translator outputs (types/vars/consts/procedures/functions).
    """

    _IDENT_CHARS = r"A-Za-z0-9_\.\$"

    _TYPE_RE = re.compile(r"^\s*type\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*(?:=|;)", re.MULTILINE)
    _VAR_RE = re.compile(r"^\s*var\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", re.MULTILINE)
    _CONST_RE = re.compile(r"^\s*const(?:\s+unique)?\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", re.MULTILINE)
    _PROC_RE = re.compile(
        r"^\s*procedure(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*(?:\(|;)",
        re.MULTILINE,
    )
    _FUNC_RE = re.compile(
        r"^\s*function(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*\(",
        re.MULTILINE,
    )

    def __init__(self, prefix: str):
        if not prefix or not re.fullmatch(r"[A-Za-z0-9_]+", prefix):
            raise ValueError(f"Invalid prefix '{prefix}'; expected [A-Za-z0-9_]+")
        self._prefix = prefix

    def prefix_content(self, bpl: str) -> str:
        names = self._collect_declared_names(bpl)
        if not names:
            return bpl

        # Replace longer names first to avoid partial replacement issues.
        sorted_names = sorted(names, key=len, reverse=True)

        out = bpl
        for name in sorted_names:
            out = self._replace_ident(out, name, f"{self._prefix}_{name}")

        return out

    def _collect_declared_names(self, bpl: str) -> List[str]:
        names: List[str] = []
        for rx in (self._TYPE_RE, self._VAR_RE, self._CONST_RE, self._PROC_RE, self._FUNC_RE):
            names.extend(m.group("name") for m in rx.finditer(bpl))

        # Deduplicate, keep deterministic order
        seen = set()
        deduped: List[str] = []
        for n in names:
            if n not in seen:
                seen.add(n)
                deduped.append(n)
        return deduped

    def _replace_ident(self, text: str, old: str, new: str) -> str:
        # Token-boundary match for identifiers that may contain '.' or '$'
        # Avoid replacing substrings inside bigger identifiers.
        boundary = f"(?<![{self._IDENT_CHARS}]){re.escape(old)}(?![{self._IDENT_CHARS}])"
        return re.sub(boundary, new, text)


class BoogieHarnessEmitter:
    def __init__(
        self,
        spec: SpecModel,
        node_input_vars: Dict[str, List[str]],
        node_egress_port_type: Dict[str, str],
        node_declared_vars: Dict[str, set[str]],
        node_mainprocedure_modifies: Dict[str, set[str]],
    ):
        self._spec = spec
        self._node_input_vars = node_input_vars  # alias -> raw var names (no prefix)
        self._node_egress_port_type = node_egress_port_type  # alias -> raw type string
        self._node_declared_vars = node_declared_vars  # alias -> set(raw var name)
        self._node_mainprocedure_modifies = node_mainprocedure_modifies  # alias -> set(prefixed var name)

    def emit(self) -> str:
        k = self._spec.global_decl.queue_capacity
        if k <= 0:
            raise ValueError(f"queue_capacity must be > 0, got {k}")

        node_aliases = list(self._spec.imports.keys())

        # Inbox counters
        lines: List[str] = []
        lines.append("// Auto-generated by Procurator (DSL -> Boogie harness for GemCutter)\n")
        lines.append(f"// Message abstraction: Bag(K={k}) using inbox_count per node\n")

        for a in node_aliases:
            lines.append(f"var {a}_inbox_count: int;\n")
        lines.append("\n")

        # Forward procedures
        lines.append("// Forwarding (derived from DSL topology)\n")
        for src in node_aliases:
            lines.append(self._emit_forward_proc(src, k))
            lines.append("\n")

        # Env thread
        lines.append(self._emit_env_thread(k))
        lines.append("\n")

        # Node threads
        for a in node_aliases:
            lines.append(self._emit_node_thread(a, k))
            lines.append("\n")

        # ULTIMATE.start
        lines.append(self._emit_ultimate_start(node_aliases))
        lines.append("\n")

        return "".join(lines)

    def _emit_forward_proc(self, src: str, k: int) -> str:
        # Build port map for src
        port_map: Dict[str, str] = {}
        wildcard_dst: Optional[str] = None
        for l in self._spec.links:
            if l.src != src:
                continue
            if l.port == "ALL":
                if wildcard_dst is not None and wildcard_dst != l.dst:
                    raise SpecParseError(f"Multiple ALL links for src={src}: {wildcard_dst} vs {l.dst}")
                wildcard_dst = l.dst
            else:
                if l.port in port_map and port_map[l.port] != l.dst:
                    raise SpecParseError(f"Duplicate port mapping for {src} port {l.port}: {port_map[l.port]} vs {l.dst}")
                port_map[l.port] = l.dst

        egress_var = f"{src}_standard_metadata.egress_port"
        egress_type = self._node_egress_port_type.get(src, "")
        zero = self._boogie_port_const("0", egress_type)

        modifies = [f"{dst}_inbox_count" for dst in sorted(set(port_map.values()) | ({wildcard_dst} if wildcard_dst else set()))]
        modifies_clause = ", ".join(m for m in modifies if m)
        if not modifies_clause:
            modifies_clause = f"{src}_inbox_count"

        body: List[str] = []
        body.append(f"procedure {src}_Forward() returns()\n")
        body.append(f"  modifies {modifies_clause};\n")
        body.append("{\n")
        body.append("  // If no outgoing link matches, drop the packet abstraction.\n")
        body.append("  // Note: we only enqueue (increase inbox_count) and do not store payload.\n")

        # Guard: only forward if egress_port != 0
        body.append(f"  if ({egress_var} != {zero}) {{\n")

        # Wildcard: send to one dst
        if wildcard_dst is not None:
            body.append(self._emit_enqueue(wildcard_dst, k, indent="    "))
            body.append("  } else {\n")
            body.append("    // no-op\n")
            body.append("  }\n")
            body.append("}\n")
            return "".join(body)

        # Port-specific map
        if port_map:
            # translate as chained if-else; order doesn't matter
            first = True
            for port, dst in sorted(port_map.items(), key=lambda kv: int(kv[0])):
                port_const = self._boogie_port_const(port, egress_type)
                if first:
                    body.append(f"    if ({egress_var} == {port_const}) {{\n")
                    first = False
                else:
                    body.append(f"    else if ({egress_var} == {port_const}) {{\n")
                body.append(self._emit_enqueue(dst, k, indent="      "))
                body.append("    }\n")
            body.append("    else {\n")
            body.append("      // unknown port -> drop\n")
            body.append("    }\n")
        body.append("  }\n")
        body.append("}\n")
        return "".join(body)

    def _emit_enqueue(self, dst: str, k: int, indent: str) -> str:
        return (
            f"{indent}if ({dst}_inbox_count < {k}) {{\n"
            f"{indent}  {dst}_inbox_count := {dst}_inbox_count + 1;\n"
            f"{indent}}} else {{\n"
            f"{indent}  // drop on overflow\n"
            f"{indent}}}\n"
        )

    def _emit_env_thread(self, k: int) -> str:
        entry_nodes = [n.name for n in self._spec.nodes.values() if n.external_input]
        # Only nodes that are also imported are meaningful
        entry_nodes = [n for n in entry_nodes if n in self._spec.imports]

        modifies = ", ".join(f"{n}_inbox_count" for n in entry_nodes) if entry_nodes else "dummy"
        out: List[str] = []
        out.append("procedure EnvThread() returns()\n")
        out.append(f"  modifies {modifies};\n")
        out.append("{\n")
        out.append("  while (true) {\n")
        out.append("    atomic {\n")
        if not entry_nodes:
            out.append("      // No external_input=true nodes; Env does nothing.\n")
        for n in entry_nodes:
            out.append(f"      if (*) {{\n")
            out.append(self._emit_enqueue(n, k, indent="        "))
            out.append("      }\n")
        out.append("    }\n")
        out.append("  }\n")
        out.append("}\n")
        return "".join(out)

    def _emit_node_thread(self, node: str, k: int) -> str:
        # Determine which inbox counters this node can modify through forwarding.
        forward_targets: set[str] = set()
        for l in self._spec.links:
            if l.src == node:
                forward_targets.add(l.dst)

        input_vars = self._node_input_vars.get(node, [])

        modifies_set: set[str] = set()
        modifies_set.add(f"{node}_inbox_count")
        modifies_set.update(f"{t}_inbox_count" for t in forward_targets)
        modifies_set.update(self._node_mainprocedure_modifies.get(node, set()))
        # This thread also havocs input variables for each dequeued message.
        modifies_set.update(f"{node}_{v}" for v in input_vars)
        declared = self._node_declared_vars.get(node, set())
        clone_flags = []
        for flag in ("p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i", "p4b_recirculate"):
            if flag in declared:
                clone_flags.append(flag)
                modifies_set.add(f"{node}_{flag}")
        modifies_clause = ", ".join(sorted(modifies_set))

        havoc_lines = "".join(f"          havoc {node}_{v};\n" for v in input_vars)

        assume_lines = "".join(
            f"          assume {self._expr_to_boogie(expr, current_node=node)};\n"
            for expr in self._spec.nodes.get(node, NodeDecl(node)).assume_exprs
        )
        assert_lines = "".join(
            f"          assert {self._expr_to_boogie(expr, current_node=node)};\n"
            for expr in self._spec.nodes.get(node, NodeDecl(node)).assert_exprs
        )

        out: List[str] = []
        out.append(f"procedure {node}_Thread() returns()\n")
        out.append(f"  modifies {modifies_clause};\n")
        out.append("{\n")
        out.append("  while (true) {\n")
        out.append("    atomic {\n")
        out.append(f"      if ({node}_inbox_count > 0) {{\n")
        out.append(f"        {node}_inbox_count := {node}_inbox_count - 1;\n")
        if havoc_lines:
            out.append("        // Havoc input packet fields for this pass (Bag(K) abstraction)\n")
            out.append(havoc_lines)
        if assume_lines:
            out.append("        // DSL assumes (node scope)\n")
            out.append(assume_lines)
        out.append(f"        call {node}_mainProcedure();\n")
        if clone_flags:
            out.append("        // Handle clone/recirculate flags emitted by P4B extern modeling.\n")
            if "p4b_clone_i2e" in clone_flags:
                out.append(f"        if ({node}_p4b_clone_i2e) {{\n")
                out.append(f"          call {node}_Forward();\n")
                out.append("        }\n")
            if "p4b_clone_e2e" in clone_flags:
                out.append(f"        if ({node}_p4b_clone_e2e) {{\n")
                out.append(f"          call {node}_Forward();\n")
                out.append("        }\n")
            if "p4b_clone_i2i" in clone_flags:
                out.append(f"        if ({node}_p4b_clone_i2i) {{\n")
                out.append(self._emit_enqueue(node, k, indent="          "))
                out.append("        }\n")
            if "p4b_recirculate" in clone_flags:
                out.append(f"        if ({node}_p4b_recirculate) {{\n")
                out.append(self._emit_enqueue(node, k, indent="          "))
                out.append("        }\n")
            for flag in clone_flags:
                out.append(f"        {node}_{flag} := false;\n")
        out.append(f"        call {node}_Forward();\n")
        if assert_lines:
            out.append("        // DSL asserts (node scope)\n")
            out.append(assert_lines)
        out.append("      }\n")
        out.append("    }\n")
        out.append("  }\n")
        out.append("}\n")
        return "".join(out)

    def _emit_ultimate_start(self, node_aliases: Sequence[str]) -> str:
        out: List[str] = []
        out.append("procedure ULTIMATE.start() returns()\n")
        out.append("  modifies " + ", ".join(f"{a}_inbox_count" for a in node_aliases) + ";\n")
        out.append("{\n")
        for a in node_aliases:
            out.append(f"  {a}_inbox_count := 0;\n")
        if self._spec.symmetry_groups:
            out.append("\n")
            out.append("  // Symmetry breaking: ordered inbox counts for equivalent nodes.\n")
            for group in self._spec.symmetry_groups:
                if len(group) < 2:
                    continue
                for left, right in zip(group, group[1:]):
                    out.append(f"  assume {left}_inbox_count <= {right}_inbox_count;\n")
        out.append("\n")
        out.append("  fork 0 EnvThread();\n")
        for i, a in enumerate(node_aliases, start=1):
            out.append(f"  fork {i} {a}_Thread();\n")
        out.append("}\n")
        return "".join(out)

    def _boogie_port_const(self, port: str, typ: str) -> str:
        """
        Produce a literal that typechecks against P4B's standard_metadata.egress_port type.
        """
        m = re.fullmatch(r"bv(\d+)", typ.strip())
        if m:
            width = m.group(1)
            return f"{port}bv{width}"
        if typ.strip() == "int":
            return port
        # Fallback: best-effort
        return port

    def _expr_to_boogie(self, expr: Tree, current_node: Optional[str]) -> str:
        """
        Convert a DSL expression tree into a Boogie expression string.
        Scoping rule:
        - In node scope, bare P4 vars are implicitly scoped to that node.
        - In global scope, users should explicitly qualify cross-node vars.
        """
        if not isinstance(expr, Tree):
            return str(expr)

        t = str(expr.data)
        ch = expr.children

        if t == "number":
            return str(ch[0])
        if t == "true":
            return "true"
        if t == "false":
            return "false"
        if t == "var":
            # var wraps dotted_var
            return self._resolve_var(self._dotted_var_to_str(ch[0]), current_node)
        if t == "dotted_var":
            return self._resolve_var(self._dotted_var_to_str(expr), current_node)

        op_map = {
            "add": "+",
            "sub": "-",
            "mul": "*",
            "div": "/",
            "greater": ">",
            "greater_eq": ">=",
            "less": "<",
            "less_eq": "<=",
            "eq": "==",
            "neq": "!=",
            "and_op": "&&",
            "or_op": "||",
        }

        if t in {"add", "sub", "mul", "div", "greater", "greater_eq", "less", "less_eq", "eq", "neq", "and_op", "or_op"}:
            left = self._expr_to_boogie(ch[0], current_node)
            right = self._expr_to_boogie(ch[1], current_node)
            return f"({left} {op_map[t]} {right})"

        if t == "not_op":
            inner = self._expr_to_boogie(ch[0], current_node)
            return f"!({inner})"

        # Best-effort fallback
        return str(expr)

    def _resolve_var(self, name: str, current_node: Optional[str]) -> str:
        # Explicit cross-node reference: `s1.xxx` -> `s1_xxx`
        if "." in name:
            head, rest = name.split(".", 1)
            if head in self._spec.imports:
                return f"{head}_{rest}"
        # Already qualified with underscore prefix: s1_xxx
        for a in self._spec.imports:
            if name.startswith(a + "_"):
                return name
        # Implicit node scope only for known P4 vars; otherwise keep as local DSL var
        if current_node:
            if self._looks_like_p4_var(current_node, name):
                return f"{current_node}_{name}"
            return name
        return name

    def _looks_like_p4_var(self, node: str, name: str) -> bool:
        # Heuristic + declared var set from the translated P4 program.
        # Strip array indices for matching, e.g., sequence_reg[0] -> sequence_reg
        base = re.sub(r"\[.*?\]", "", name)
        if base in self._node_declared_vars.get(node, set()):
            return True
        # Fallback heuristic: dotted names often refer to P4 struct fields
        if "." in name:
            return True
        return False

    def _dotted_var_to_str(self, node: Any) -> str:
        if isinstance(node, Token):
            return str(node)
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            if len(node.children) == 1:
                return self._dotted_var_to_str(node.children[0])
            return ".".join(str(c) for c in node.children)

        cur = ""
        for item in node.children:
            if isinstance(item, Token):
                if item.type == "NAME":
                    cur += str(item) + "."
                elif item.type == "NUMBER":
                    cur = cur.rstrip(".")
                    cur += f"[{item}]."
        return cur.rstrip(".")


def parse_spec(spec_text: str) -> SpecModel:
    parser = Lark(grammar, start="start", parser="lalr")
    tree = parser.parse(spec_text)

    model = SpecModel()

    def ensure_node(name: str) -> NodeDecl:
        if name not in model.nodes:
            model.nodes[name] = NodeDecl(name=name)
        return model.nodes[name]

    for section in tree.children:
        if not isinstance(section, Tree):
            continue
        st = str(section.data)
        if st == "import_section":
            for imp in section.children:
                if not isinstance(imp, Tree) or str(imp.data) != "import_stmt":
                    continue
                alias = str(imp.children[0])
                p4_path = str(imp.children[1]).strip('"')
                entries_path = None
                if len(imp.children) >= 3 and isinstance(imp.children[2], Tree) and str(imp.children[2].data) == "entries_clause":
                    entries_path = str(imp.children[2].children[0]).strip('"')
                model.imports[alias] = ImportDecl(alias=alias, p4_path=p4_path, entries_path=entries_path)
                ensure_node(alias)
        elif st == "topology_section":
            for link in section.children:
                if not isinstance(link, Tree) or str(link.data) != "link":
                    continue
                src = str(link.children[0])
                dst = str(link.children[1])
                port = "ALL"
                if len(link.children) >= 3:
                    port_node = link.children[2]
                    if isinstance(port_node, Tree) and port_node.children:
                        port = str(port_node.children[0])
                    elif isinstance(port_node, Token):
                        port = str(port_node)
                model.links.append(LinkDecl(src=src, dst=dst, port=port))
        elif st == "node_section":
            node_name = str(section.children[0])
            nd = ensure_node(node_name)
            for stmt in section.children[1:]:
                if not isinstance(stmt, Tree):
                    continue
                tt = str(stmt.data)
                if tt in {"assignment", "var_decl"}:
                    # Handle directives: external_input=true/false
                    var_tree = stmt.children[0] if tt == "assignment" else stmt.children[1]
                    rhs_tree = stmt.children[2] if tt == "assignment" else stmt.children[3]
                    var_name = _dotted_var_to_str(var_tree)
                    if var_name == "external_input":
                        rhs_val = _bool_literal(rhs_tree)
                        if rhs_val is None:
                            raise SpecParseError("external_input must be true/false")
                        nd.external_input = rhs_val
                elif tt == "assume_statement":
                    nd.assume_exprs.extend(_extract_bool_exprs(stmt))
                elif tt == "assert_statement":
                    nd.assert_exprs.extend(_extract_bool_exprs(stmt))
        elif st == "global_section":
            for stmt in section.children:
                if not isinstance(stmt, Tree):
                    continue
                tt = str(stmt.data)
                if tt in {"assignment", "var_decl"}:
                    var_tree = stmt.children[0] if tt == "assignment" else stmt.children[1]
                    rhs_tree = stmt.children[2] if tt == "assignment" else stmt.children[3]
                    var_name = _dotted_var_to_str(var_tree)
                    if var_name == "queue_capacity":
                        rhs_num = _int_literal(rhs_tree)
                        if rhs_num is None:
                            raise SpecParseError("queue_capacity must be an integer literal")
                        model.global_decl.queue_capacity = rhs_num
                elif tt == "symmetry_stmt":
                    group: List[str] = []
                    for nl in stmt.find_data("node_list"):
                        for node in nl.children:
                            group.append(str(node))
                    if group:
                        model.symmetry_groups.append(group)
                elif tt == "assume_statement":
                    model.global_decl.assume_exprs.extend(_extract_bool_exprs(stmt))
                elif tt == "assert_statement":
                    model.global_decl.assert_exprs.extend(_extract_bool_exprs(stmt))

    return model


def _extract_bool_exprs(assert_or_assume_stmt: Tree) -> List[Tree]:
    # bool_expr_list: (bool_expr ";")*
    exprs: List[Tree] = []
    # In the current grammar, bool_expr is inlined (`?bool_expr`), so we usually
    # won't see a `bool_expr` node. Prefer reading the `bool_expr_list` directly.
    for bel in assert_or_assume_stmt.find_data("bool_expr_list"):
        for child in bel.children:
            if isinstance(child, Tree):
                exprs.append(child)
    if exprs:
        return exprs

    # Fallback for older grammar variants where bool_expr might not be inlined.
    for be in assert_or_assume_stmt.find_data("bool_expr"):
        if be.children and isinstance(be.children[0], Tree):
            exprs.append(be.children[0])
    return exprs


def _bool_literal(node: Any) -> Optional[bool]:
    if isinstance(node, Tree):
        if str(node.data) == "true":
            return True
        if str(node.data) == "false":
            return False
    return None


def _int_literal(node: Any) -> Optional[int]:
    if isinstance(node, Tree) and str(node.data) == "number" and node.children:
        try:
            return int(str(node.children[0]))
        except ValueError:
            return None
    if isinstance(node, Token) and node.type == "NUMBER":
        try:
            return int(str(node))
        except ValueError:
            return None
    return None


def _dotted_var_to_str(node: Any) -> str:
    if isinstance(node, Token):
        return str(node)
    if not isinstance(node, Tree):
        return str(node)
    if str(node.data) != "dotted_var":
        if len(node.children) == 1:
            return _dotted_var_to_str(node.children[0])
        return ".".join(str(c) for c in node.children)

    cur = ""
    for item in node.children:
        if isinstance(item, Token):
            if item.type == "NAME":
                cur += str(item) + "."
            elif item.type == "NUMBER":
                cur = cur.rstrip(".")
                cur += f"[{item}]."
    return cur.rstrip(".")


def _collect_p4b_input_vars_and_egress_type(raw_bpl: str) -> Tuple[List[str], str, set[str]]:
    """
    Extract (a) a conservative list of input packet field vars to havoc each pass,
    and (b) the type of standard_metadata.egress_port for forwarding decisions.
    """
    input_vars: List[str] = []
    egress_type: str = ""
    declared_vars: set[str] = set()

    var_decl_re = re.compile(r"^\s*var\s+([A-Za-z0-9_\.\$]+)\s*:\s*([^;]+);\s*$", re.MULTILINE)
    for m in var_decl_re.finditer(raw_bpl):
        name = m.group(1)
        typ = m.group(2).strip()
        declared_vars.add(name)
        if name == "standard_metadata.egress_port":
            egress_type = typ
        if name.startswith(("hdr.", "meta.", "standard_metadata.")):
            # Skip header references (Ref) and other pointer-ish carrier vars.
            if typ == "Ref" or typ.endswith("Ref"):
                continue
            input_vars.append(name)

    # De-dup, deterministic order
    seen = set()
    dedup: List[str] = []
    for v in input_vars:
        if v not in seen:
            seen.add(v)
            dedup.append(v)
    return dedup, egress_type, declared_vars


def generate_boogie_model(
    spec: SpecModel,
    p4b: P4BTranslator,
    out_bpl: Path,
    work_dir: Path,
) -> Path:
    work_dir.mkdir(parents=True, exist_ok=True)

    node_raw_bpl: Dict[str, str] = {}
    node_prefixed_bpl: Dict[str, str] = {}
    node_input_vars: Dict[str, List[str]] = {}
    node_egress_type: Dict[str, str] = {}
    node_declared_vars: Dict[str, set[str]] = {}
    node_main_modifies: Dict[str, set[str]] = {}

    # 1) Compile each imported P4 into Boogie
    for alias, imp in spec.imports.items():
        raw_path = work_dir / f"{alias}.raw.bpl"
        p4b.compile_to_bpl(imp.p4_path, str(raw_path), imp.entries_path)
        raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
        node_raw_bpl[alias] = raw_text
        input_vars, egress_t, declared_vars = _collect_p4b_input_vars_and_egress_type(raw_text)
        node_input_vars[alias] = input_vars
        node_declared_vars[alias] = declared_vars
        if egress_t:
            node_egress_type[alias] = egress_t

    # 2) Prefix each Boogie unit to avoid symbol collisions
    for alias, raw_text in node_raw_bpl.items():
        prefixed = BoogiePrefixer(alias).prefix_content(raw_text)
        node_prefixed_bpl[alias] = prefixed
        node_main_modifies[alias] = _extract_mainprocedure_modifies(prefixed, alias)

    # 3) Emit concurrent harness
    harness = BoogieHarnessEmitter(
        spec,
        node_input_vars=node_input_vars,
        node_egress_port_type=node_egress_type,
        node_declared_vars=node_declared_vars,
        node_mainprocedure_modifies=node_main_modifies,
    ).emit()

    # 4) Concatenate into a single .bpl
    merged: List[str] = []
    for alias in sorted(node_prefixed_bpl.keys()):
        merged.append(f"// ===== BEGIN NODE {alias} (prefixed) =====\n")
        merged.append(node_prefixed_bpl[alias])
        if not node_prefixed_bpl[alias].endswith("\n"):
            merged.append("\n")
        merged.append(f"// ===== END NODE {alias} =====\n\n")
    merged.append("// ===== BEGIN HARNESS =====\n")
    merged.append(harness)
    merged.append("// ===== END HARNESS =====\n")

    out_bpl.write_text("".join(merged), encoding="utf-8")
    return out_bpl


def _extract_mainprocedure_modifies(prefixed_bpl: str, alias: str) -> set[str]:
    """
    Extract the modifies-set of `<alias>_mainProcedure` from prefixed Boogie.
    We need this so that harness procedures can legally call it.
    """
    proc_name = f"{alias}_mainProcedure"
    # Capture modifies line immediately after the procedure header.
    rx = re.compile(
        rf"procedure(?:\s*\{{:[^}}]+\}}\s*)*\s+{re.escape(proc_name)}\s*\([^)]*\)\s*(?:returns\s*\([^)]*\))?\s*"
        rf"(?:\n|\r\n)\s*modifies\s+([^;]+);",
        re.MULTILINE,
    )
    m = rx.search(prefixed_bpl)
    if not m:
        # Best-effort: assume it might not have a modifies clause (rare), or name differs.
        return set()
    clause = m.group(1)
    items = [x.strip() for x in clause.split(",")]
    return {x for x in items if x}


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Procurator DSL -> concurrent Boogie model (GemCutter harness)")
    ap.add_argument("--spec", required=True, help="Path to .prop DSL file")
    ap.add_argument("--out", required=True, help="Output .bpl path")
    ap.add_argument(
        "--p4b-bin",
        required=True,
        help="Path to P4B-Translator p4c-translator binary (Boogie backend)",
    )
    ap.add_argument("--work-dir", default="", help="Working directory (defaults to <out>.work)")
    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec)
    out_path = Path(args.out)
    work_dir = Path(args.work_dir) if args.work_dir else Path(str(out_path) + ".work")

    spec_text = spec_path.read_text(encoding="utf-8")
    spec = parse_spec(spec_text)

    p4b = P4BTranslator(args.p4b_bin)
    generate_boogie_model(spec, p4b=p4b, out_bpl=out_path, work_dir=work_dir)

    print(f"[OK] Generated: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
