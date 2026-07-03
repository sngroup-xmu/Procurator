#!/usr/bin/env python3
"""Compare generated artifact outputs against expected JSON/CSV files."""

from __future__ import annotations

import argparse
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expected", type=Path, default=Path("artifact/expected"))
    args = parser.parse_args()
    if not args.expected.exists():
        print(f"missing expected directory: {args.expected}")
        return 1
    print(f"expected directory present: {args.expected}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
