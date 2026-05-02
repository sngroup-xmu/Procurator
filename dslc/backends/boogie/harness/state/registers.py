from __future__ import annotations

from typing import Dict, List, Set


class BoogieHarnessRegistersMixin:
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
    def _register_type_is_ref_like(elem_type: str) -> bool:
        elem_type = elem_type.strip()
        return elem_type == "Ref" or elem_type.endswith("Ref")

    @classmethod
    def _register_debug_enabled_for_type(cls, elem_type: str) -> bool:
        return not cls._register_type_is_ref_like(elem_type)

    def _register_tracking_var_names(self, reg_name: str) -> Set[str]:
        return {
            self._register_last_index_name(reg_name),
            self._register_last_value_name(reg_name),
            self._register_wrote_any_name(reg_name),
            self._register_wrote_index0_name(reg_name),
            self._register_last0_value_name(reg_name),
        }

    def _register_debug_var_names(self, reg_name: str) -> Set[str]:
        return {
            self._register_debug_var_name(reg_name),
            self._register_last_index_dbg_name(reg_name),
            self._register_last_value_dbg_name(reg_name),
            self._register_wrote_any_dbg_name(reg_name),
            self._register_wrote_index0_dbg_name(reg_name),
            self._register_last0_value_dbg_name(reg_name),
        }

    def _register_modifies_for_nodes(self, node_aliases: List[str], *, include_debug: bool) -> Set[str]:
        mods: Set[str] = set()
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (_idx_type, elem_type) in regs.items():
                mods.update(self._register_tracking_var_names(name))
                if include_debug and self._register_debug_enabled_for_type(elem_type):
                    mods.update(self._register_debug_var_names(name))
        return mods

    def _all_register_debug_modifies(self) -> Set[str]:
        mods: Set[str] = set()
        if not getattr(self, "_emit_reg_debug", True):
            return mods
        for regs in self._node_register_arrays.values():
            for name, (_idx_type, elem_type) in regs.items():
                if not self._register_debug_enabled_for_type(elem_type):
                    continue
                mods.update(self._register_debug_var_names(name))
        return mods

    def _emit_register_init_assumes(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                raw = name[len(node) + 1 :] if name.startswith(f"{node}_") else name
                init_map = self._meta_register_inits.get(node, {}).get(raw, {})

                if self._register_type_is_ref_like(elem_type):
                    continue

                default_lit = self._render_value_zero(elem_type)
                if isinstance(init_map, dict) and "*" in init_map:
                    lit = self._render_typed_literal_from_str(elem_type, init_map.get("*", ""))
                    if lit is not None:
                        default_lit = lit

                cell_inits: Dict[int, str] = {}
                if isinstance(init_map, dict):
                    for k, v in init_map.items():
                        if str(k) == "*":
                            continue
                        try:
                            idx_int = int(str(k))
                        except Exception:
                            continue
                        lit = self._render_typed_literal_from_str(elem_type, str(v))
                        if lit is None:
                            continue
                        cell_inits[idx_int] = lit

                raw_size = self._meta_register_sizes.get(node, {}).get(raw)
                if raw_size == 1:
                    idx_zero = self._render_index_zero(idx_type)
                    out.append(f"  assume {name}[{idx_zero}] == {cell_inits.get(0, default_lit)};\n")
                    continue

                if cell_inits:
                    idx_lits = [self._render_typed_int(idx_type, i) for i in sorted(cell_inits.keys())]
                    guard = " && ".join(f"(i != {lit})" for lit in idx_lits)
                    out.append(f"  assume (forall i:{idx_type} :: ({guard}) ==> {name}[i] == {default_lit});\n")
                else:
                    out.append(f"  assume (forall i:{idx_type} :: {name}[i] == {default_lit});\n")

                idx_zero = self._render_index_zero(idx_type)
                out.append(f"  assume {name}[{idx_zero}] == {cell_inits.get(0, default_lit)};\n")

                for idx, val in sorted(cell_inits.items()):
                    out.append(f"  assume {name}[{self._render_typed_int(idx_type, idx)}] == {val};\n")
        return "".join(out)

    def _emit_register_debug_decls(self, node_aliases: List[str]) -> str:
        if not getattr(self, "_emit_reg_debug", True):
            return ""
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                if not self._register_debug_enabled_for_type(elem_type):
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
        if not getattr(self, "_emit_reg_debug", True):
            return ""
        out: List[str] = []
        for regs in self._node_register_arrays.values():
            for name, (idx_type, elem_type) in sorted(regs.items()):
                if not self._register_debug_enabled_for_type(elem_type):
                    continue
                dbg = self._register_debug_var_name(name)
                idx_zero = self._render_index_zero(idx_type)
                out.append(f"{indent}{dbg} := {name}[{idx_zero}];\n")
                out.append(
                    f"{indent}{self._register_last_index_dbg_name(name)} := {self._register_last_index_name(name)};\n"
                )
                out.append(
                    f"{indent}{self._register_last_value_dbg_name(name)} := {self._register_last_value_name(name)};\n"
                )
                out.append(
                    f"{indent}{self._register_wrote_any_dbg_name(name)} := {self._register_wrote_any_name(name)};\n"
                )
                out.append(
                    f"{indent}{self._register_wrote_index0_dbg_name(name)} := {self._register_wrote_index0_name(name)};\n"
                )
                out.append(
                    f"{indent}{self._register_last0_value_dbg_name(name)} := {self._register_last0_value_name(name)};\n"
                )
        return "".join(out)

    def _emit_register_write_debug_init(self, node_aliases: List[str]) -> str:
        out: List[str] = []
        for node in node_aliases:
            regs = self._node_register_arrays.get(node, {})
            for name, (idx_type, elem_type) in sorted(regs.items()):
                idx_zero = self._render_index_zero(idx_type)
                out.append(f"  {self._register_last_index_name(name)} := {idx_zero};\n")
                if self._register_type_is_ref_like(elem_type):
                    out.append(f"  assume {self._register_last_value_name(name)} == {name}[{idx_zero}];\n")
                else:
                    val_zero = self._render_value_zero(elem_type)
                    out.append(f"  {self._register_last_value_name(name)} := {val_zero};\n")
                out.append(f"  {self._register_wrote_any_name(name)} := false;\n")
                out.append(f"  {self._register_wrote_index0_name(name)} := false;\n")
                if self._register_type_is_ref_like(elem_type):
                    out.append(f"  assume {self._register_last0_value_name(name)} == {name}[{idx_zero}];\n")
                else:
                    out.append(f"  {self._register_last0_value_name(name)} := {val_zero};\n")
        return "".join(out)
