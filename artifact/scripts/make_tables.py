#!/usr/bin/env python3
"""Generate reviewer-facing summary tables from artifact actual JSON files."""

from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path
from typing import Any


def _load_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _status_for_mode(rec: dict[str, Any], mode: str) -> str:
    mode_rec = rec.get(mode)
    if not isinstance(mode_rec, dict):
        return "MISSING"
    result = mode_rec.get("result")
    if isinstance(result, dict):
        return str(result.get("status") or "MISSING")
    return str(mode_rec.get("status") or "MISSING")


def _write_e2e_summary(results_json: Path, out_csv: Path) -> int:
    data = _load_json(results_json)
    results = data.get("results")
    if not isinstance(results, dict):
        raise ValueError(f"{results_json} does not contain a results object")

    out_csv.parent.mkdir(parents=True, exist_ok=True)
    with out_csv.open("w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["spec", "category", "slicing_status", "noslicing_status"])
        for spec, rec in sorted(results.items()):
            if not isinstance(rec, dict):
                continue
            writer.writerow(
                [
                    spec,
                    rec.get("category", ""),
                    _status_for_mode(rec, "slicing"),
                    _status_for_mode(rec, "noslicing"),
                ]
            )
    return len(results)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--results-json",
        type=Path,
        default=Path(".tmp/procurator/artifact/core_28.actual.json"),
    )
    parser.add_argument(
        "--out-csv",
        type=Path,
        default=Path(".tmp/procurator/artifact/core_28_summary.csv"),
    )
    args = parser.parse_args()
    if not args.results_json.exists():
        print(f"missing results JSON: {args.results_json}")
        return 1
    count = _write_e2e_summary(args.results_json, args.out_csv)
    print(f"wrote {count} rows to {args.out_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
