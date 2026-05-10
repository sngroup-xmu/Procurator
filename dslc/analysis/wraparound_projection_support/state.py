from __future__ import annotations

from typing import Dict, List, Set

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.analysis.wraparound_projection_exprs import unique


def target_observation_vars(candidate: WraparoundCandidate, var_types: Dict[str, str]) -> List[str]:
    out: List[str] = []
    for reg in unique([candidate.pump_reg, *candidate.accel_regs]):
        if candidate.index_expr is None and candidate.index_value == 0 and f"{reg}__last0_value" in var_types:
            out.append(f"{reg}__last0_value")
            continue
        for v in (reg, f"{reg}__last_value", f"{reg}__last_old_value", f"{reg}__last0_value", f"{reg}__last0_old_value"):
            if v in var_types:
                out.append(v)
                break
    return out


def excluded_target_state(candidate: WraparoundCandidate, var_types: Dict[str, str]) -> Set[str]:
    out: Set[str] = set()
    for reg in unique([candidate.pump_reg, *candidate.accel_regs]):
        for name in var_types:
            if name == reg or name.startswith(f"{reg}__"):
                out.add(name)
    return out


def is_snapshot_scalar(name: str, var_types: Dict[str, str]) -> bool:
    typ = var_types.get(name)
    if not typ:
        return False
    if "[" in typ or "]" in typ:
        return False
    return True

