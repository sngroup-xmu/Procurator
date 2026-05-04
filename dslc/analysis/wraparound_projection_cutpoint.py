from __future__ import annotations

from typing import Dict, List

from dslc.analysis.wraparound_bpl_index import (
    _derive_consts_at_proc_entry,
    _extract_bpl_constant_literals,
    _node_roots_for_index_definition,
)
from dslc.analysis.wraparound_candidates import WraparoundCandidate


def cutpoint_entry_constants(
    bpl_text: str,
    *,
    var_types: Dict[str, str],
    candidate: WraparoundCandidate,
) -> Dict[str, str]:
    prefixes = _candidate_node_prefixes(candidate)
    if not prefixes:
        return {}

    base_consts = _extract_bpl_constant_literals(bpl_text, var_types=var_types)
    out: Dict[str, str] = {}
    for node in prefixes:
        for root in _node_roots_for_index_definition(node=node, bpl_text=bpl_text):
            out.update(
                _derive_consts_at_proc_entry(
                    bpl_text,
                    proc_name=root,
                    var_types=var_types,
                    initial_consts=base_consts,
                )
            )
    return out


def _candidate_node_prefixes(candidate: WraparoundCandidate) -> List[str]:
    out: List[str] = []
    seen = set()
    for reg in (candidate.pump_reg, *candidate.accel_regs):
        if "_" not in reg:
            continue
        prefix = reg.split("_", 1)[0]
        if prefix and prefix not in seen:
            seen.add(prefix)
            out.append(prefix)
    return out
