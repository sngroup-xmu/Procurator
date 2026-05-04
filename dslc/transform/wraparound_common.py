from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple


class WraparoundStage(str, Enum):
    PUMP = "pump"
    ACCEL = "accel"
    ACCEL_PROBE = "accel_probe"
    CONFIRM = "confirm"
    ENABLE_CHECK = "enable_check"
    CLOSURE_CHECK = "closure_check"
    ENTRY_CHECK = "entry_check"


@dataclass(frozen=True)
class WraparoundTarget:
    reg_var: str
    """Boogie global register array variable (e.g., `s1_sequence_reg`)."""

    elem_width: int
    """Element bitwidth (e.g., 16 for `bv16`)."""

    index_width: int
    """Index bitwidth (e.g., 32 for `[bv32]...`)."""

    index_value: Optional[int] = 0
    """Target index (v0-1 supports constant indices; v1 may leave this as None when using `index_expr_override`)."""

    index_expr_override: Optional[str] = None
    """Optional Boogie expression for the index (must have type `bv<index_width>`)."""

    use_last0_value: bool = False
    """Prefer scalar `<reg>__last0_value` over array select when available (dramatically reduces solver load)."""

    @property
    def index_expr(self) -> str:
        if self.index_expr_override is not None:
            return self.index_expr_override
        if self.index_value is None:
            raise ValueError("WraparoundTarget.index_value is None and no index_expr_override was provided")
        return f"{self.index_value}bv{self.index_width}"

    @property
    def max_elem_expr(self) -> str:
        return f"{(1 << self.elem_width) - 1}bv{self.elem_width}"

    @property
    def last0_value_var(self) -> str:
        return f"{self.reg_var}__last0_value"

    @property
    def write_proc(self) -> str:
        return f"{self.reg_var}.write"


@dataclass(frozen=True)
class WraparoundConfig:
    stage: WraparoundStage
    pump_target: WraparoundTarget
    accel_targets: Tuple[WraparoundTarget, ...]
    proj_vars: Tuple[str, ...]
    proj_predicates: Tuple[str, ...]
    proj_exprs: Tuple[str, ...]
    cutpoint_cond: str
    step_op: str
    step_delta_int: int
    step_delta_bv: str


class WraparoundTransformError(RuntimeError):
    pass


_RE_GLOBAL_VAR = re.compile(r"^var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_REG_DECL = re.compile(r"^var\s+(?P<name>\S+)\s*:\s*\[bv(?P<idx>\d+)\]\s*bv(?P<elem>\d+);\s*$")
_RE_PROC_MAIN = re.compile(r"^procedure\s+mainProcedure\(\)\s+returns\(\)\s*$")
_RE_PROC_SCHED = re.compile(r"^procedure\s+main\(\)\s+returns\(\)\s*$")
_RE_PROC_ULTIMATE_START = re.compile(r"^procedure\s+ULTIMATE\.start\(\)\s+returns\(\)\s*$")
_RE_WHILE_TRUE = re.compile(r"^\s*while\s*\(\s*true\s*\)\s*(\{\s*)?$")
_RE_WHILE_STEP_BOUND = re.compile(r"^\s*while\s*\(\s*procurator_step\s*<[^)]*\)\s*(\{\s*)?$")
_RE_ASSERT_STMT = re.compile(r"^(?P<indent>\s*)assert\b")
_RE_ASSIGN_STMT = re.compile(r"^(?P<indent>\s*)(?P<lhs>[A-Za-z0-9_.]+)\s*:=\s*")
_RE_PHASE_WRAP = re.compile(r"\bif\s*\(\s*procurator_phase\s*==\s*(?P<n>\d+)\s*\)\s*\{")
_RE_PHASE_RESET = re.compile(r"\bprocurator_phase\s*:=\s*0\s*;")
_RE_STEP_INC = re.compile(r"^\s*procurator_step\s*:=\s*procurator_step\s*\+\s*1\s*;\s*$")
_RE_CALL_MAIN = re.compile(r"^\s*call\s+main\(\)\s*;\s*$")
_RE_ASSUME_FORALL_BV_INIT = re.compile(
    r"^(?P<indent>\s*)assume\s*\(\s*forall\s+(?P<var>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*"
    r"bv(?P<idx_w>\d+)\s*::\s*"
    r"(?P<array>[A-Za-z_][A-Za-z0-9_]*)\[\s*(?P=var)\s*\]\s*==\s*(?P<value>[^)]+?)\s*\)\s*;\s*$"
)
# Conditional init where all indices except one constant are set to a value.
#
# Example (DistCache `latest_reg` style):
#   assume (forall i:bv32 :: ((i != 7bv32)) ==> latest_reg[i] == 0bv1);
#
# We use this in wraparound stages to safely eliminate expensive quantifiers when we can
# infer a finite accessed index domain.
_RE_ASSUME_FORALL_BV_INIT_EXCEPT = re.compile(
    r"^(?P<indent>\s*)assume\s*\(\s*forall\s+(?P<var>[A-Za-z_][A-Za-z0-9_]*)\s*:\s*"
    r"bv(?P<idx_w>\d+)\s*::\s*"
    r"\(+\s*(?P=var)\s*!=\s*(?P<exc>\d+)bv(?P<exc_w>\d+)\s*\)+\s*==>\s*"
    r"(?P<array>[A-Za-z_][A-Za-z0-9_]*)\[\s*(?P=var)\s*\]\s*==\s*(?P<value>[^)]+?)\s*\)\s*;\s*$"
)
_RE_ASSUME_BV_INDEX_INIT = re.compile(
    r"^\s*assume\s+(?P<array>[A-Za-z_][A-Za-z0-9_]*)\[\s*(?P<idx>\d+)bv(?P<idx_w>\d+)\s*\]\s*"
    r"==\s*(?P<value>[^;]+?)\s*;\s*$"
)
_RE_BVULE_BV_CALL = re.compile(
    r"\b(?:bvule|bule)\.bv(?P<width>\d+)(?:\$builtin)?\(\s*(?P<a>[^,]+?)\s*,\s*"
    r"(?P<b>\d+)bv(?P<lit_w>\d+)\s*\)"
)

# Backward-compatible names used by older transform modules/tests.  The regexes
# are now generic over bvN even though the function names still mention bv32.
_RE_ASSUME_FORALL_BV32_INIT = _RE_ASSUME_FORALL_BV_INIT
_RE_ASSUME_FORALL_BV32_INIT_EXCEPT = _RE_ASSUME_FORALL_BV_INIT_EXCEPT
_RE_ASSUME_BV32_INDEX_INIT = _RE_ASSUME_BV_INDEX_INIT
_RE_BVULE_BV32_CALL = _RE_BVULE_BV_CALL

_PUMP_ERROR_PROC = "__wraparound_pump_error"
_PUMP_ASSERT_MARKER = "WRAPAROUND_PUMP_ASSERT"
_ENTRY_ERROR_PROC = "__wraparound_entry_error"
_ENTRY_ASSERT_MARKER = "WRAPAROUND_ENTRY_ASSERT"
_ASSERT_WRAPPER_PROC = "__wraparound_assert"
_CLOSURE_UNROLL_MARKER_PREFIX = "// UNROLLED"

_MAX_FORALL_INIT_EXPANSION = 64


def _sanitize_local(name: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", name)
