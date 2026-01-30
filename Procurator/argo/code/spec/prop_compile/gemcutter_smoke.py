#!/usr/bin/env python3
from __future__ import annotations

import os
import sys
from pathlib import Path


def main() -> int:
    # Legacy entrypoint kept for backward compatibility.
    # New usage: `./bin/procurator smoke ...`
    repo = Path(__file__).resolve().parents[5]
    exe = repo / "bin" / "procurator"
    cmd = [str(exe), "smoke", *sys.argv[1:]]
    os.execv(cmd[0], cmd)
    return 0  # unreachable


if __name__ == "__main__":
    raise SystemExit(main())

