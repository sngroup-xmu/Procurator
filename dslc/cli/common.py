from __future__ import annotations

import os
from datetime import datetime
from pathlib import Path
from typing import Optional

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
      1) Host-built P4B translator: `P4B-Translator/build-host/p4c-translator`
      2) Repo-shipped docker wrapper: `dslc/toolchain/p4b_docker.sh`
    """

    root = repo_root()
    candidates = [
        # Newer builds place the verify backend translator under backends/verify/.
        root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator",
        # Backward-compat path (some builds may still place it at the build root).
        root / "P4B-Translator" / "build-host" / "p4c-translator",
        root / "dslc" / "toolchain" / "p4b_docker.sh",
    ]
    for p in candidates:
        try:
            if p.exists():
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
