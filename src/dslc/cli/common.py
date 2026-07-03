from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path
from typing import Optional

from p4b.paths import docker_wrapper, translator_candidates

from dslc.utils.exec import wrap_resource_limits as _wrap_resource_limits
from dslc.utils.repo import repo_root


def fresh_run_id() -> str:
    # Timestamp + a short random suffix to avoid collisions in fast repeated runs.
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    rnd = os.urandom(2).hex()
    return f"{ts}-{rnd}"


def fresh_run_dir(*, category: str, name: str, base_dir: Optional[Path] = None) -> Path:
    """
    Create a fresh per-run output directory under `.tmp/procurator/<category>/<name>/<run_id>`.

    This is the default "no cache" policy: every invocation gets a new directory, so we never
    silently reuse old work dirs, Ultimate HOME, or logs.
    """

    root = (base_dir or (repo_root() / ".tmp" / "procurator")).resolve()
    out_dir = root / category / name / fresh_run_id()
    out_dir.mkdir(parents=True, exist_ok=False)
    return out_dir


def find_default_p4b_bin() -> Optional[Path]:
    """
    Best-effort resolver for a usable P4->Boogie translator.

    Preference order:
      1) Host-built P4B translator:
         - `src/p4b/source/build-host/backends/verify/p4c-translator` (preferred)
         - `src/p4b/source/build-host/p4c-translator`
      2) Repo-shipped docker wrapper: `src/dslc/toolchain/p4b_docker.sh`
    """

    root = repo_root()
    candidates = [*translator_candidates(root), docker_wrapper(root)]
    for p in candidates:
        try:
            if p.exists():
                return p
        except OSError:
            continue
    return None


def find_default_ultimate() -> Optional[Path]:
    """
    Best-effort resolver for a usable Ultimate CLI executable.

    Preference order:
      1) A vendored Ultimate under `.tmp/orphan-worktree-*/UGemCutter-linux/Ultimate`
         (we pick the most recently modified one).
      2) `UGemCutter-linux/Ultimate` at repo root.
      3) `Ultimate` at repo root (legacy).
    """

    root = repo_root()

    # Prefer the most recently modified orphan worktree.
    orphan_candidates: list[Path] = []
    try:
        orphan_candidates = list(root.glob(".tmp/orphan-worktree-*/UGemCutter-linux/Ultimate"))
    except OSError:
        orphan_candidates = []
    orphan_candidates.sort(key=lambda p: p.stat().st_mtime if p.exists() else 0, reverse=True)

    candidates = (
        orphan_candidates
        + [
            root / "third_party" / "ultimate" / "UGemCutter-linux" / "Ultimate",
            root / "Ultimate",
        ]
    )
    for p in candidates:
        try:
            # On Windows-mounted filesystems (e.g., /mnt/e) path casing can be
            # effectively case-insensitive, so `Ultimate` may accidentally match
            # the vendored Ultimate *source* directory `ultimate/`. Require an
            # executable file to avoid confusing failures.
            if p.is_file() and p.exists():
                return p
        except OSError:
            continue
    return None


def wrap_resource_limits(cmd: list[str], *, enable: bool, os_timeout_s: int) -> list[str]:
    """
    Best-effort safety wrapper for WSL: lower CPU/IO priority, pin to 1 core,
    and optionally apply an OS-level timeout.
    """
    return _wrap_resource_limits(cmd, enable=enable, os_timeout_s=os_timeout_s)
