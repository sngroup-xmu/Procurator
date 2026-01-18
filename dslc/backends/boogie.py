"""Boogie backend entrypoint.

This file is intentionally small: implementation lives in dedicated modules
(`dslc/backends/boogie_*.py`) to keep responsibilities separated.

Public API kept stable:
  - `BoogieBackend`
"""

from .boogie_backend import BoogieBackend
from .boogie_errors import BoogieBackendError, P4BTranslatorError

__all__ = ["BoogieBackend", "BoogieBackendError", "P4BTranslatorError"]
