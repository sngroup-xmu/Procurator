#!/usr/bin/env python3
"""Generate paper-facing tables from artifact evidence."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--evidence", type=Path, default=Path("artifact/evidence"))
    args = parser.parse_args()
    if not args.evidence.exists():
        print(f"missing evidence directory: {args.evidence}")
        return 1
    print("table generation skeleton: evidence directory is present")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
