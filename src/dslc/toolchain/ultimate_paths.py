from __future__ import annotations

from pathlib import Path
from typing import Iterable, Optional, Sequence

from dslc.utils.repo import repo_root as _repo_root


ULTIMATE_ASSET_SUFFIXES = {".epf", ".xml"}

_ASSET_SUBDIRS: tuple[str, ...] = (
    "toolchains",
    "settings/automizer",
    "settings/gemcutter/base",
    "settings/gemcutter/witness",
    "settings/gemcutter/4g",
    "settings/gemcutter/8g",
    "settings/gemcutter/12g",
)


def ultimate_asset_root(root: Optional[Path] = None) -> Path:
    repo = Path(root) if root is not None else _repo_root()
    return repo / "src" / "dslc" / "toolchain" / "ultimate"


def ultimate_asset_dirs(root: Optional[Path] = None) -> tuple[Path, ...]:
    base = ultimate_asset_root(root)
    return tuple(base / rel for rel in _ASSET_SUBDIRS)


def iter_ultimate_asset_candidates(root: Optional[Path], name: str) -> Iterable[Path]:
    base = ultimate_asset_root(root)
    # Legacy flat location first so temporary tests and old checkouts still work.
    yield base / name
    for directory in ultimate_asset_dirs(root):
        yield directory / name


def ultimate_asset(root: Optional[Path], name: str) -> Path:
    for candidate in iter_ultimate_asset_candidates(root, name):
        if candidate.exists():
            return candidate.resolve()
    return (ultimate_asset_root(root) / name).resolve()


def ultimate_assets(root: Optional[Path], names: Sequence[str]) -> list[Path]:
    return [ultimate_asset(root, name) for name in names]


def resolve_ultimate_asset_path(path: Path | str, *, root: Optional[Path] = None) -> Path:
    """
    Resolve user-facing Ultimate XML/EPF paths.

    Historical commands pass paths like
    `src/dslc/toolchain/ultimate/ReachSafety.xml`.  The organized layout keeps the
    same basename under subdirectories, so a missing flat path is resolved by
    basename before reporting an error.  Non-Ultimate paths are left alone.
    """

    raw = Path(path).expanduser()
    direct = raw if raw.is_absolute() else (Path.cwd() / raw)
    if direct.exists():
        return direct.resolve()

    if raw.suffix.lower() not in ULTIMATE_ASSET_SUFFIXES:
        return direct.resolve()

    relocated = ultimate_asset(root, raw.name)
    if relocated.exists():
        return relocated.resolve()
    return direct.resolve()
