from __future__ import annotations

from typing import Optional


class BoogieHarnessRenderMixin:
    def _resolve_type_alias(self, typ: str) -> str:
        """
        Best-effort resolution for node-prefixed typedefs emitted by P4B.

        Example: given `sw_pair` and a node type-def mapping `pair -> bv64`,
        return `bv64` so literals like `0bv64` are well-typed.
        """
        t = typ.strip()
        if not t:
            return t
        if t in {"int", "bool"}:
            return t
        if t.startswith("bv") and t[2:].isdigit():
            return t
        if t.startswith("["):
            return t

        # Attempt to resolve `<node>_<typedef>` using `self._node_type_defs`.
        if "_" not in t:
            return t
        node, raw = t.split("_", 1)
        node_type_defs = getattr(self, "_node_type_defs", None)
        if not isinstance(node_type_defs, dict):
            return t
        defs = node_type_defs.get(node)
        if not isinstance(defs, dict):
            return t

        seen: set[str] = set()
        cur = raw
        for _ in range(16):
            if cur in {"int", "bool"} or (cur.startswith("bv") and cur[2:].isdigit()):
                return cur
            if cur in seen:
                break
            seen.add(cur)
            nxt = defs.get(cur)
            if not isinstance(nxt, str) or not nxt.strip():
                break
            cur = nxt.strip()
        return t

    def _render_index_zero(self, idx_type: str) -> str:
        idx_type = self._resolve_type_alias(idx_type.strip())
        if idx_type.startswith("bv") and idx_type[2:].isdigit():
            return f"0{idx_type}"
        return "0"

    def _render_value_zero(self, elem_type: str) -> str:
        elem_type = self._resolve_type_alias(elem_type.strip())
        if elem_type == "bool":
            return "false"
        if elem_type.startswith("bv") and elem_type[2:].isdigit():
            return f"0{elem_type}"
        return "0"

    def _render_typed_int(self, typ: str, value: int) -> str:
        typ = self._resolve_type_alias(typ.strip())
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
