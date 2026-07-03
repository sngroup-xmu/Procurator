from __future__ import annotations

from pathlib import Path
from typing import Iterable


def source_root(repo_root: Path) -> Path:
    """Return the checked-in P4B/p4c fork root used by the P4B backend."""

    return repo_root / "src" / "p4b" / "source"


def translator_candidates(repo_root: Path) -> list[Path]:
    """Return supported repo-local p4c-translator binary locations."""

    p4c_source = source_root(repo_root)
    return [
        p4c_source / "build-host" / "backends" / "verify" / "p4c-translator",
        p4c_source / "build-host" / "p4c-translator",
    ]


def docker_wrapper(repo_root: Path) -> Path:
    """Return the repo-local Docker wrapper for the P4B translator."""

    return repo_root / "src" / "dslc" / "toolchain" / "p4b_docker.sh"


def tofino_include_candidates(anchor: Path) -> Iterable[Path]:
    """Yield Tofino include candidates relative to a source file or repo root."""

    start = anchor if anchor.is_dir() else anchor.parent
    for parent in [start, *start.parents]:
        yield source_root(parent) / "backends" / "tofino" / "bf-p4c" / "p4include"
        yield parent / "backends" / "tofino" / "bf-p4c" / "p4include"
