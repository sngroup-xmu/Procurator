from __future__ import annotations

from pathlib import Path


def repo_root_from_test(start: Path) -> Path:
    for path in [start.resolve(), *start.resolve().parents]:
        if (path / "src" / "dslc").is_dir() and (path / "benchmarks").is_dir():
            return path
    raise RuntimeError(f"failed to locate repo root from {start}")


def legacy_bool_bpl() -> Path:
    return Path(__file__).resolve().parent / "fixtures" / "legacy_bool" / "out.bpl"
