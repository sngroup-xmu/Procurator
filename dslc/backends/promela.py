from __future__ import annotations

import shutil
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

from lark import Tree

from ..speclang.model import NodeDecl, SpecModel
from ..toolchain.p4c_translator import P4CTranslator


class PromelaBackendError(RuntimeError):
    pass


def _posix(p: Path) -> str:
    # Promela preprocessor is happier with forward slashes.
    return p.as_posix()


class _PromelaExprPrinter:
    def expr_to_str(self, expr_node) -> str:
        if isinstance(expr_node, Tree):
            expr_type = str(expr_node.data)
            ch = expr_node.children

            if expr_type == "var":
                return self.expr_to_str(ch[0])
            if expr_type == "dotted_var":
                return self._dotted_var(ch)
            if expr_type == "number":
                return str(ch[0])
            if expr_type == "true":
                return "true"
            if expr_type == "false":
                return "false"

            if expr_type in {"add", "sub", "mul", "div", "less", "less_eq", "greater", "greater_eq", "eq", "neq"}:
                op_map = {
                    "add": "+",
                    "sub": "-",
                    "mul": "*",
                    "div": "/",
                    "less": "<",
                    "less_eq": "<=",
                    "greater": ">",
                    "greater_eq": ">=",
                    "eq": "==",
                    "neq": "!=",
                }
                return f"({self.expr_to_str(ch[0])} {op_map[expr_type]} {self.expr_to_str(ch[1])})"

            if expr_type in {"or_op", "and_op"}:
                op_map = {"or_op": "||", "and_op": "&&"}
                if len(ch) == 2:
                    return f"({self.expr_to_str(ch[0])} {op_map[expr_type]} {self.expr_to_str(ch[1])})"
                # ltl grammar uses (OP_OR x y z...) style sometimes; best-effort fold
                if len(ch) >= 1:
                    acc = self.expr_to_str(ch[0])
                    for rest in ch[1:]:
                        acc = f"({acc} {op_map[expr_type]} {self.expr_to_str(rest)})"
                    return acc

            if expr_type == "not_op":
                return f"!({self.expr_to_str(ch[0])})"

            if expr_type in {"always_op", "eventually_op"}:
                op_map = {"always_op": "[]", "eventually_op": "<>"}
                # lark keeps the operator token as child[0]
                operand = ch[-1]
                return f"{op_map[expr_type]}({self.expr_to_str(operand)})"

            return ""

        # Token or literal
        return str(expr_node)

    def _dotted_var(self, children) -> str:
        var_name = ""
        for item in children:
            if hasattr(item, "type"):
                if item.type == "NAME":
                    var_name += (str(item) + ".")
                elif item.type == "NUMBER":
                    var_name = var_name.rstrip(".")
                    var_name += ("[" + str(item) + "].")
        return var_name.rstrip(".")


@dataclass(frozen=True)
class PromelaCompileResult:
    out_dir: Path
    main_model: Path


class PromelaBackend:
    """
    Promela/SPIN backend.

    This backend focuses on:
      - building per-node Promela via repo-local p4c-translator
      - generating a top-level `main_model.pml` that wires channels + spawns node processes

    NOTE: In this refactor step, we intentionally keep node-level DSL statements out of the generated
    Promela processes (to avoid fragile text insertion into Promela code). Global properties are emitted.
    """

    def __init__(self, p4c_translator_bin: Optional[Path] = None):
        self._translator = P4CTranslator(p4c_translator_bin) if p4c_translator_bin else None
        self._printer = _PromelaExprPrinter()

    def compile(self, spec: SpecModel, out_dir: Path, clean: bool = False) -> PromelaCompileResult:
        if clean and out_dir.exists():
            shutil.rmtree(out_dir)
        out_dir.mkdir(parents=True, exist_ok=True)

        hdr_info_dir = out_dir / "hdr_info"
        hdr_info_dir.mkdir(parents=True, exist_ok=True)

        # Build port mapping from topology: src -> {port: dst}
        port_dst_map: Dict[str, Dict[str, str]] = {}
        for l in spec.links:
            port_dst_map.setdefault(l.src, {})
            port = l.port if l.port else "ALL"
            port_dst_map[l.src][port] = l.dst

        # Compile/copy nodes
        type_includes: List[Path] = []
        node_includes: List[Path] = []

        for alias, imp in spec.imports.items():
            alias_dir = out_dir / alias
            alias_dir.mkdir(parents=True, exist_ok=True)

            src_path = Path(imp.path)
            if src_path.suffix in {".p4", ".json"}:
                if self._translator is None:
                    raise PromelaBackendError(
                        f"import {alias} from '{src_path}': requires p4c-translator; pass --p4c-translator-bin"
                    )
                entries = Path(imp.entries_path) if imp.entries_path else None
                res = self._translator.compile_to_promela(
                    alias=alias,
                    input_path=src_path,
                    entries_path=entries,
                    port_dst=port_dst_map.get(alias, {"ALL": alias}),
                    out_dir=alias_dir,
                )
                # Copy headers.json for global merge
                if res.headers_json_path.exists():
                    shutil.copy2(res.headers_json_path, hdr_info_dir / f"{alias}_headers.json")
                if res.type_pml_path.exists():
                    type_includes.append(res.type_pml_path)
                node_includes.append(res.pml_path)
            elif src_path.suffix == ".pml":
                # Best-effort support: treat as already a node Promela file.
                dst = alias_dir / f"{alias}.pml"
                shutil.copy2(src_path, dst)
                node_includes.append(dst)
            else:
                raise PromelaBackendError(f"unsupported import for promela backend: {src_path}")

        # Merge headers into global_channel.pml if we have any header jsons.
        global_channel_pml = hdr_info_dir / "global_channel.pml"
        if any(p.name.endswith("_headers.json") for p in hdr_info_dir.glob("*.json")):
            from ...utils.merge_hdr import compute_chan

            compute_chan(hdr_info_dir)
        elif not global_channel_pml.exists():
            # Fallback for direct .pml imports where we don't have headers.json.
            # This keeps the generated main_model syntactically valid.
            global_channel_pml.write_text(
                "typedef headers {\n"
                "    int dummy;\n"
                "};\n",
                encoding="utf-8",
            )

        # Generate main_model.pml
        k = spec.global_decl.queue_capacity if spec.global_decl.queue_capacity is not None else 5
        nodes = list(spec.imports.keys())
        marked = [n for n in nodes if spec.nodes.get(n, NodeDecl(name=n)).external_input is True]
        ingress_nodes = marked if marked else nodes

        lines: List[str] = []
        lines.append("// Auto-generated Spin model\n\n")
        lines.append(f"#define MAX_BUF_SIZE {k}\n\n")

        for p in type_includes:
            lines.append(f'#include "{_posix(p)}"\n')
        if global_channel_pml.exists():
            lines.append(f'#include "{_posix(global_channel_pml)}"\n')
        lines.append("\n")

        # Channels expected by translator-generated node code: <alias>_chan and <alias>_chan_eg
        for n in nodes:
            lines.append(f"chan {n}_chan = [MAX_BUF_SIZE] of {{ headers }};\n")
        for n in nodes:
            lines.append(f"chan {n}_chan_eg = [MAX_BUF_SIZE] of {{ headers }};\n")
        lines.append("\n")

        lines.append("// Include node processes\n")
        for p in node_includes:
            lines.append(f'#include "{_posix(p)}"\n')
        lines.append("\n")

        # Global assertions (best-effort)
        if spec.global_decl.assert_exprs:
            lines.append("// Global assertions\n")
            for e in spec.global_decl.assert_exprs:
                lines.append(f"assert({self._printer.expr_to_str(e)});\n")
            lines.append("\n")

        # Global LTL specs
        for stmt in spec.global_decl.statements:
            if isinstance(stmt, Tree) and str(stmt.data) == "ltl_statement":
                name_token = None
                ltl_expr_list = None
                if len(stmt.children) == 2:
                    name_token = stmt.children[0]
                    ltl_expr_list = stmt.children[1]
                elif len(stmt.children) == 1:
                    ltl_expr_list = stmt.children[0]
                if ltl_expr_list is None:
                    continue
                # Multiple ltl_expr; conjunct them
                parts: List[str] = []
                for formula in ltl_expr_list.children:
                    if isinstance(formula, Tree) and formula.children:
                        parts.append(self._printer.expr_to_str(formula.children[0]))
                body = " && ".join(parts) if parts else "true"
                if name_token is not None:
                    lines.append(f"ltl {name_token} {{ {body} }}\n")
                else:
                    lines.append(f"ltl {{ {body} }}\n")
        lines.append("\n")

        # Environment (external input injection)
        lines.append("proctype Env() {\n")
        lines.append("  headers pkt;\n")
        lines.append("  do\n")
        lines.append("  :: atomic {\n")
        lines.append("      // TODO: refine packet generation (havoc-like) for SPIN\n")
        lines.append("      pkt.ethernet.etherType = 2048;\n")
        if ingress_nodes:
            lines.append("      if\n")
            for n in ingress_nodes:
                lines.append(f"      :: {n}_chan ! pkt;\n")
            lines.append("      fi;\n")
        lines.append("    }\n")
        lines.append("  od\n")
        lines.append("}\n\n")

        # init
        lines.append("init {\n")
        lines.append("  atomic {\n")
        lines.append("    run Env();\n")
        for n in nodes:
            lines.append(f"    run {n}_mainProcedure();\n")
        lines.append("  }\n")
        lines.append("}\n")

        main_model = out_dir / "main_model.pml"
        main_model.write_text("".join(lines), encoding="utf-8")
        return PromelaCompileResult(out_dir=out_dir, main_model=main_model)
