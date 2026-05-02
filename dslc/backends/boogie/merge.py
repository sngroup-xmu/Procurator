from __future__ import annotations

from typing import Dict, Protocol

from ...speclang.model import SpecModel
from .core.prefix import dedup_bvbuiltin_decls, ultimate_rewrite_bvbuiltin_attrs


class _EnqueueEmitter(Protocol):
    def _emit_enqueue_proc(self, src: str, dst: str, k: int) -> str:
        ...


def merge_boogie_program(
    *,
    spec: SpecModel,
    helpers: str,
    node_prefixed: Dict[str, str],
    harness: str,
    enqueue_emitter: _EnqueueEmitter,
) -> str:
    merged: list[str] = []
    if helpers:
        merged.append("// ===== BEGIN PREAMBLE =====\n")
        merged.append(helpers)
        if not helpers.endswith("\n"):
            merged.append("\n")
        merged.append("// ===== END PREAMBLE =====\n\n")

    seen_bvbuiltins: set[str] = set()
    for alias in sorted(node_prefixed.keys()):
        merged.append(f"// ===== BEGIN NODE {alias} (prefixed) =====\n")
        node_body = dedup_bvbuiltin_decls(node_prefixed[alias], seen_bvbuiltins)
        merged.append(node_body)
        if not node_body.endswith("\n"):
            merged.append("\n")
        merged.append(f"// ===== END NODE {alias} =====\n\n")

    merged.append("// ===== BEGIN ENQUEUE PROCEDURES =====\n")
    k = spec.global_decl.queue_capacity if spec.global_decl.queue_capacity is not None else 5
    for link in spec.links:
        merged.append(enqueue_emitter._emit_enqueue_proc(link.src, link.dst, k))
        merged.append("\n")
    merged.append("// ===== END ENQUEUE PROCEDURES =====\n\n")

    merged.append("// ===== BEGIN HARNESS =====\n")
    merged.append(harness)
    merged.append("// ===== END HARNESS =====\n")

    return ultimate_rewrite_bvbuiltin_attrs("".join(merged))
