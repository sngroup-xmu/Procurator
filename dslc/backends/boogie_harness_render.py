from __future__ import annotations

from typing import Optional


class BoogieHarnessRenderMixin:
    def _render_index_zero(self, idx_type: str) -> str:
        idx_type = idx_type.strip()
        if idx_type.startswith("bv") and idx_type[2:].isdigit():
            return f"0{idx_type}"
        return "0"

    def _render_value_zero(self, elem_type: str) -> str:
        elem_type = elem_type.strip()
        if elem_type == "bool":
            return "false"
        if elem_type.startswith("bv") and elem_type[2:].isdigit():
            return f"0{elem_type}"
        return "0"

    def _render_typed_int(self, typ: str, value: int) -> str:
        typ = typ.strip()
        if typ == "bool":
            return "false" if int(value) == 0 else "true"
        if typ.startswith("bv") and typ[2:].isdigit():
            width = int(typ[2:])
            if width > 0:
                value = int(value) % (1 << width)
            return f"{int(value)}{typ}"
        return str(int(value))

    def _render_typed_literal_from_str(self, typ: str, raw: str) -> Optional[str]:
        raw = str(raw).strip()
        if raw == "":
            return None
        if typ.strip() == "bool":
            low = raw.lower()
            if low in {"false", "0"}:
                return "false"
            if low in {"true", "1"}:
                return "true"
            try:
                return "false" if int(raw) == 0 else "true"
            except Exception:
                return None
        try:
            return self._render_typed_int(typ, int(raw))
        except Exception:
            return None

