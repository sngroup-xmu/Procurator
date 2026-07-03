from __future__ import annotations

"""
Wraparound transformations (public API).

This file is intentionally thin: it re-exports the stable public entrypoints
from smaller, responsibility-focused modules under `dslc.transform`.
"""

from .wraparound_common import (
    WraparoundConfig,
    WraparoundStage,
    WraparoundTarget,
    WraparoundTransformError,
)
from .wraparound_instrument import instrument_bpl_file, instrument_bpl_text
from .wraparound_unroll import (
    unroll_mainprocedure_loop_file,
    unroll_mainprocedure_loop_text,
)

__all__ = [
    "WraparoundConfig",
    "WraparoundStage",
    "WraparoundTarget",
    "WraparoundTransformError",
    "instrument_bpl_file",
    "instrument_bpl_text",
    "unroll_mainprocedure_loop_file",
    "unroll_mainprocedure_loop_text",
]
