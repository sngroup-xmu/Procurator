from __future__ import annotations

from typing import Dict, List, Optional


class BoogieHarnessTraceMixin:
    @staticmethod
    def _register_debug_var_name(reg_name: str) -> str:
        return f"{reg_name}__dbg0"

    @staticmethod
    def _register_last_index_name(reg_name: str) -> str:
        return f"{reg_name}__last_index"

    @staticmethod
    def _register_last_value_name(reg_name: str) -> str:
        return f"{reg_name}__last_value"

    @staticmethod
    def _register_wrote_any_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_any"

    @staticmethod
    def _register_wrote_index0_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_index0"

    @staticmethod
    def _register_last0_value_name(reg_name: str) -> str:
        return f"{reg_name}__last0_value"

    @staticmethod
    def _register_last_index_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__last_index__dbg"

    @staticmethod
    def _register_last_value_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__last_value__dbg"

    @staticmethod
    def _register_wrote_any_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_any__dbg"

    @staticmethod
    def _register_wrote_index0_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__wrote_index0__dbg"

    @staticmethod
    def _register_last0_value_dbg_name(reg_name: str) -> str:
        return f"{reg_name}__last0_value__dbg"

    @staticmethod
    def _trace_node_exec_name(node: str) -> str:
        return f"trace_{node}_exec"

    @staticmethod
    def _trace_node_seq_name(node: str) -> str:
        return f"trace_{node}_seq"

    @staticmethod
    def _trace_node_op_name(node: str) -> str:
        return f"trace_{node}_op"

    @staticmethod
    def _trace_node_key_name(node: str) -> str:
        return f"trace_{node}_key"

    @staticmethod
    def _trace_reg_dbg0_name(reg_name: str) -> str:
        return f"trace_{reg_name}__dbg0"

    @staticmethod
    def _trace_reg_wrote_any_name(reg_name: str) -> str:
        return f"trace_{reg_name}__wrote_any"

    @staticmethod
    def _trace_reg_wrote_index0_name(reg_name: str) -> str:
        return f"trace_{reg_name}__wrote_index0"

    @staticmethod
    def _trace_reg_last0_value_name(reg_name: str) -> str:
        return f"trace_{reg_name}__last0_value"

    @staticmethod
    def _trace_enqueue_exec_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_exec"

    @staticmethod
    def _trace_enqueue_seq_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_seq"

    @staticmethod
    def _trace_enqueue_op_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_op"

    @staticmethod
    def _trace_enqueue_key_name(src: str, dst: str) -> str:
        return f"trace_enq_{src}_{dst}_key"

    def _trace_field_types(self, node: str) -> Dict[str, str]:
        fields = {
            "seq": "hdr.nc_hdr.seq",
            "op": "hdr.nc_hdr.op",
            "key": "hdr.nc_hdr.key",
        }
        out: Dict[str, str] = {}
        for label, base in fields.items():
            width = self._infer_bv_width_for_node(node, base)
            if width is None:
                continue
            out[label] = f"bv{width}"
        return out

    def _emit_trace_decls(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        if not self._emit_trace or not node_aliases:
            return ""
        out.append("var trace_node_id: [int]int;\n")
        out.append("var trace_stage: [int]int;\n")
        for node in node_aliases:
            out.append(f"var {self._trace_node_exec_name(node)}: [int]bool;\n")
            types = self._trace_field_types(node)
            if "seq" in types:
                out.append(f"var {self._trace_node_seq_name(node)}: [int]{types['seq']};\n")
            if "op" in types:
                out.append(f"var {self._trace_node_op_name(node)}: [int]{types['op']};\n")
            if "key" in types:
                out.append(f"var {self._trace_node_key_name(node)}: [int]{types['key']};\n")
        for regs in self._node_register_arrays.values():
            for name, (_, elem_type) in sorted(regs.items()):
                out.append(f"var {self._trace_reg_dbg0_name(name)}: [int]{elem_type};\n")
                out.append(f"var {self._trace_reg_wrote_any_name(name)}: [int]bool;\n")
                out.append(f"var {self._trace_reg_wrote_index0_name(name)}: [int]bool;\n")
                out.append(f"var {self._trace_reg_last0_value_name(name)}: [int]{elem_type};\n")
        for link in self._spec.links:
            types = self._trace_field_types(link.src)
            out.append(f"var {self._trace_enqueue_exec_name(link.src, link.dst)}: [int]bool;\n")
            if "seq" in types:
                out.append(f"var {self._trace_enqueue_seq_name(link.src, link.dst)}: [int]{types['seq']};\n")
            if "op" in types:
                out.append(f"var {self._trace_enqueue_op_name(link.src, link.dst)}: [int]{types['op']};\n")
            if "key" in types:
                out.append(f"var {self._trace_enqueue_key_name(link.src, link.dst)}: [int]{types['key']};\n")
        return "".join(out)

    def _emit_trace_step_reset(self, node_aliases: List[str], *, indent: str) -> str:
        if not self._emit_trace or not node_aliases:
            return ""

        def try_zero(typ: str) -> Optional[str]:
            typ = typ.strip()
            if typ == "bool":
                return "false"
            if typ == "int":
                return "0"
            if typ.startswith("bv") and typ[2:].isdigit():
                return f"0{typ}"
            return None

        out: List[str] = []
        out.append(f"{indent}trace_node_id[procurator_step] := 0;\n")
        out.append(f"{indent}trace_stage[procurator_step] := 0;\n")
        for node in node_aliases:
            out.append(f"{indent}{self._trace_node_exec_name(node)}[procurator_step] := false;\n")
            types = self._trace_field_types(node)
            if "seq" in types:
                out.append(
                    f"{indent}{self._trace_node_seq_name(node)}[procurator_step] := {self._render_value_zero(types['seq'])};\n"
                )
            if "op" in types:
                out.append(
                    f"{indent}{self._trace_node_op_name(node)}[procurator_step] := {self._render_value_zero(types['op'])};\n"
                )
            if "key" in types:
                out.append(
                    f"{indent}{self._trace_node_key_name(node)}[procurator_step] := {self._render_value_zero(types['key'])};\n"
                )
        for regs in self._node_register_arrays.values():
            for name, (_, elem_type) in sorted(regs.items()):
                out.append(f"{indent}{self._trace_reg_wrote_any_name(name)}[procurator_step] := false;\n")
                out.append(f"{indent}{self._trace_reg_wrote_index0_name(name)}[procurator_step] := false;\n")
                zero = try_zero(elem_type)
                if zero is None:
                    continue
                out.append(f"{indent}{self._trace_reg_dbg0_name(name)}[procurator_step] := {zero};\n")
                out.append(f"{indent}{self._trace_reg_last0_value_name(name)}[procurator_step] := {zero};\n")
        for link in self._spec.links:
            out.append(
                f"{indent}{self._trace_enqueue_exec_name(link.src, link.dst)}[procurator_step] := false;\n"
            )
            types = self._trace_field_types(link.src)
            if "seq" in types:
                out.append(
                    f"{indent}{self._trace_enqueue_seq_name(link.src, link.dst)}[procurator_step] := {self._render_value_zero(types['seq'])};\n"
                )
            if "op" in types:
                out.append(
                    f"{indent}{self._trace_enqueue_op_name(link.src, link.dst)}[procurator_step] := {self._render_value_zero(types['op'])};\n"
                )
            if "key" in types:
                out.append(
                    f"{indent}{self._trace_enqueue_key_name(link.src, link.dst)}[procurator_step] := {self._render_value_zero(types['key'])};\n"
                )
        return "".join(out)

    def _emit_trace_assignments(self, node: str, *, indent: str, stage_id: int) -> str:
        if not self._emit_trace or self._harness_mode != "sequential":
            return ""
        if not node:
            return ""
        out: List[str] = []
        node_id = getattr(self, "_trace_node_ids", {}).get(node, 0)
        out.append(f"{indent}trace_node_id[procurator_step] := {node_id};\n")
        out.append(f"{indent}trace_stage[procurator_step] := {stage_id};\n")
        out.append(f"{indent}{self._trace_node_exec_name(node)}[procurator_step] := true;\n")
        types = self._trace_field_types(node)
        if "seq" in types:
            out.append(f"{indent}{self._trace_node_seq_name(node)}[procurator_step] := {node}_hdr.nc_hdr.seq;\n")
        if "op" in types:
            out.append(f"{indent}{self._trace_node_op_name(node)}[procurator_step] := {node}_hdr.nc_hdr.op;\n")
        if "key" in types:
            out.append(f"{indent}{self._trace_node_key_name(node)}[procurator_step] := {node}_hdr.nc_hdr.key;\n")
        regs = self._node_register_arrays.get(node, {})
        for name in sorted(regs.keys()):
            out.append(
                f"{indent}{self._trace_reg_dbg0_name(name)}[procurator_step] := {self._register_debug_var_name(name)};\n"
            )
            out.append(
                f"{indent}{self._trace_reg_wrote_any_name(name)}[procurator_step] := {self._register_wrote_any_name(name)};\n"
            )
            out.append(
                f"{indent}{self._trace_reg_wrote_index0_name(name)}[procurator_step] := {self._register_wrote_index0_name(name)};\n"
            )
            out.append(
                f"{indent}{self._trace_reg_last0_value_name(name)}[procurator_step] := {self._register_last0_value_name(name)};\n"
            )
        return "".join(out)

    def _emit_register_debug_decls(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                if elem_type == "Ref" or elem_type.endswith("Ref"):
                    continue
                dbg = self._register_debug_var_name(name)
                out.append(f"var {dbg}: {elem_type};\n")
                out.append(f"var {self._register_last_index_dbg_name(name)}: {idx_type};\n")
                out.append(f"var {self._register_last_value_dbg_name(name)}: {elem_type};\n")
                out.append(f"var {self._register_wrote_any_dbg_name(name)}: bool;\n")
                out.append(f"var {self._register_wrote_index0_dbg_name(name)}: bool;\n")
                out.append(f"var {self._register_last0_value_dbg_name(name)}: {elem_type};\n")
        return "".join(out)

    def _emit_register_debug_assignments(self, *, indent: str) -> str:
        out: List[str] = []
        for regs in self._node_register_arrays.values():
            for name, (idx_type, elem_type) in sorted(regs.items()):
                if elem_type == "Ref" or elem_type.endswith("Ref"):
                    continue
                dbg = self._register_debug_var_name(name)
                idx_zero = self._render_index_zero(idx_type)
                out.append(f"{indent}{dbg} := {name}[{idx_zero}];\n")
                out.append(f"{indent}{self._register_last_index_dbg_name(name)} := {self._register_last_index_name(name)};\n")
                out.append(f"{indent}{self._register_last_value_dbg_name(name)} := {self._register_last_value_name(name)};\n")
                out.append(f"{indent}{self._register_wrote_any_dbg_name(name)} := {self._register_wrote_any_name(name)};\n")
                out.append(f"{indent}{self._register_wrote_index0_dbg_name(name)} := {self._register_wrote_index0_name(name)};\n")
                out.append(f"{indent}{self._register_last0_value_dbg_name(name)} := {self._register_last0_value_name(name)};\n")
        return "".join(out)

    def _emit_register_write_debug_init(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                idx_zero = self._render_index_zero(idx_type)
                val_zero = self._render_value_zero(elem_type)
                out.append(f"  {self._register_last_index_name(name)} := {idx_zero};\n")
                out.append(f"  {self._register_last_value_name(name)} := {val_zero};\n")
                out.append(f"  {self._register_wrote_any_name(name)} := false;\n")
                out.append(f"  {self._register_wrote_index0_name(name)} := false;\n")
                out.append(f"  {self._register_last0_value_name(name)} := {val_zero};\n")
        return "".join(out)

