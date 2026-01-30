from __future__ import annotations

from pathlib import Path


def repo_root(start: Path | None = None) -> Path:
    """
    Resolve the repository root directory.

    We avoid hard-coding "parents[N]" so code can move without breaking.
    """
    p = (start or Path(__file__)).resolve()
    if p.is_file():
        p = p.parent

    for cand in [p, *p.parents]:
        # Prefer a git checkout when present.
        if (cand / ".git").exists():
            return cand
        # Fallback for exported trees.
        if (cand / "AGENTS.md").exists() and (cand / "dslc").is_dir():
            return cand

    raise RuntimeError(f"failed to locate repo root from: {start or Path(__file__)}")

