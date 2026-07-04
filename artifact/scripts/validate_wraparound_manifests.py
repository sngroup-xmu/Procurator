#!/usr/bin/env python3
"""Validate certified wraparound manifests listed by an E2E results JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from dslc.bench.validate_counterexample import validate_wraparound_manifest


def _iter_manifest_paths(results_json: Path):
    data = json.loads(results_json.read_text(encoding="utf-8"))
    results = data.get("results", {})
    if not isinstance(results, dict):
        raise ValueError(f"{results_json} does not contain a results object")
    for spec, rec in sorted(results.items()):
        if not isinstance(rec, dict):
            continue
        for mode in ("slicing", "noslicing"):
            mode_rec = rec.get(mode)
            if not isinstance(mode_rec, dict):
                continue
            result = mode_rec.get("result")
            if not isinstance(result, dict):
                continue
            out_dir = result.get("out_dir")
            if not isinstance(out_dir, str) or not out_dir:
                continue
            wrap = Path(out_dir) / "wraparound"
            if not wrap.exists():
                continue
            for manifest in sorted(wrap.glob("target.*/wraparound.cegis.manifest.json")):
                yield spec, mode, manifest


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--results-json",
        type=Path,
        default=Path(".tmp/procurator/artifact/wraparound_4.actual.json"),
    )
    args = parser.parse_args()

    findings: list[str] = []
    checked = 0
    for spec, mode, manifest in _iter_manifest_paths(args.results_json):
        checked += 1
        ok, msg = validate_wraparound_manifest(manifest)
        if not ok:
            findings.append(f"{spec}/{mode}: {manifest}: {msg}")

    if checked == 0:
        findings.append(f"no wraparound manifests found in {args.results_json}")
    for finding in findings:
        print(finding, file=sys.stderr)
    if findings:
        return 1
    print(f"validated certified wraparound manifests: {checked}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
