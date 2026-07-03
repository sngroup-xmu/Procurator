from __future__ import annotations

from importlib import import_module
from typing import Any

__all__ = ["WraparoundWorkflowError", "generate_wraparound_tasks"]


def __getattr__(name: str) -> Any:
    if name in __all__:
        mod = import_module(".wraparound", __name__)
        return getattr(mod, name)
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
