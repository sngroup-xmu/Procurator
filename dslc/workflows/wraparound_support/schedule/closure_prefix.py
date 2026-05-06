from __future__ import annotations

from pathlib import Path
from typing import List, Optional, Sequence, Tuple

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text
from dslc.workflows.wraparound_support.schedule.prefix_cutpoint import insert_confirm_prefix_marker
from dslc.workflows.wraparound_support.stage_text import _unroll_confirm_like_mainprocedure


def write_prefix_closure_bpl(
    *,
    out_dir: Path,
    base_text: str,
    stem: str,
    prefix_unroll: int,
    suffix_unroll: int = 1,
    pump_reg: str,
    accel_regs: Sequence[str],
    index_value: int,
    index_expr: Optional[str],
    proj_vars: List[str],
    proj_predicates: List[str],
    proj_exprs: List[str],
    cutpoint_cond: str,
    step_op: str,
    step_delta: int,
    closure_assumes: Sequence[str],
    det_period: Optional[int],
    env_shape_assumes: Sequence[str] = (),
) -> Tuple[Path, Path, int]:
    """
    Build closure from a reached finite-prefix cutpoint.

    The generated program first executes `prefix_unroll` logical deterministic
    rounds, places the closure setup at that marker, then executes
    `suffix_unroll` more logical rounds before asserting projection equality
    and the counter net effect.  A SAFE result is therefore still a closure
    proof from a reachable replay state, not acceptance of the original closure
    counterexample.
    """

    logical_suffix = max(1, int(suffix_unroll))
    if logical_suffix == 1:
        bpl = out_dir / f"{stem}.closure_prefix.unroll{prefix_unroll}.bpl"
        log = out_dir / f"{stem}.closure_prefix.unroll{prefix_unroll}.log"
    else:
        bpl = out_dir / f"{stem}.closure_prefix.unroll{prefix_unroll}.suffix{logical_suffix}.bpl"
        log = out_dir / f"{stem}.closure_prefix.unroll{prefix_unroll}.suffix{logical_suffix}.log"
    logical_prefix = max(1, int(prefix_unroll))
    txt, effective_steps = _unroll_confirm_like_mainprocedure(
        bpl_text=base_text,
        requested_steps=logical_prefix + logical_suffix,
        deterministic_period=det_period,
    )
    prefix_step_count = logical_prefix * det_period if det_period else logical_prefix
    txt, insertion_marker = insert_confirm_prefix_marker(
        txt,
        prefix_steps=prefix_step_count,
    )
    txt = instrument_bpl_text(
        bpl_text=txt,
        stage=WraparoundStage.CLOSURE_CHECK,
        pump_reg=pump_reg,
        accel_regs=list(accel_regs),
        index_value=int(index_value),
        index_expr=index_expr,
        proj_vars=list(proj_vars),
        proj_predicates=proj_predicates,
        proj_exprs=proj_exprs,
        cutpoint_cond=cutpoint_cond,
        step_op=step_op,
        step_delta=step_delta,
        extra_assumes=(*env_shape_assumes, *closure_assumes),
        closure_insertion_marker=insertion_marker,
    )
    bpl.write_text(txt, encoding="utf-8")
    return bpl, log, effective_steps
