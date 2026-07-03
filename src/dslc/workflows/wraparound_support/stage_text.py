from __future__ import annotations

from typing import Optional, Tuple

from dslc.transform.wraparound import unroll_mainprocedure_loop_text
from dslc.transform.wraparound_analyze import _inline_deterministic_round_into_mainprocedure
from dslc.transform.wraparound_common import _RE_PROC_SCHED


def _unroll_confirm_like_mainprocedure(
    *,
    bpl_text: str,
    requested_steps: int,
    deterministic_period: Optional[int],
) -> Tuple[str, int]:
    """
    Unroll `mainProcedure` for a "confirm-like" stage (CONFIRM/ENABLE_CHECK).

    Important subtlety: in the sequential harness with `deterministic_scheduler=true`,
    one logical external input + node processing "round" may require multiple scheduler
    steps (phases). The user's `requested_steps` is specified in *round* units, but
    `unroll_mainprocedure_loop_text()` operates on the low-level scheduler loop body.

    We therefore scale the unroll bound by the inferred deterministic scheduler period
    when available, and opportunistically inline the round-robin dispatcher to reduce
    solver load.
    """

    req = max(1, int(requested_steps))
    steps = req
    if deterministic_period is not None and deterministic_period > 0:
        steps = req * deterministic_period

    txt = unroll_mainprocedure_loop_text(bpl_text=bpl_text, steps=steps)

    # Optional post-processing: inline deterministic phases and eliminate heavy forall inits.
    lines = txt.splitlines(keepends=True)
    no_nl = [ln.rstrip("\n") for ln in lines]
    has_sched_proc = any(_RE_PROC_SCHED.match(ln.strip()) for ln in no_nl)
    if deterministic_period is not None and has_sched_proc:
        try:
            _inline_deterministic_round_into_mainprocedure(lines, period=deterministic_period, steps=steps)
        except Exception:
            # Best-effort: inlining is a performance optimization only.
            pass

    return "".join(lines), steps
