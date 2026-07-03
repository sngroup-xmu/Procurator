"""Unit tests for the dslc package (unittest-based).

Tests are physically grouped by feature, but legacy module names such as
``dslc.tests.test_boogie_backend_smoke`` remain importable by extending this
package search path.
"""

from __future__ import annotations

from pathlib import Path

_ROOT = Path(__file__).resolve().parent
for _path in sorted(p for p in _ROOT.rglob("*") if p.is_dir() and p.name != "__pycache__"):
    __path__.append(str(_path))  # type: ignore[name-defined]
