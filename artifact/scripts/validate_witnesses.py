#!/usr/bin/env python3
"""Validate UNSAFE witness artifacts listed by an E2E results JSON."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "src"
if str(SRC) not in sys.path:
    sys.path.insert(0, str(SRC))

from dslc.bench.validate_counterexample import summarize_witness, validate_wraparound_manifest


def _default_results_json(out_dir: Path = Path(".tmp/procurator/artifact")) -> Path:
    casewise = out_dir / "core_28.casewise.actual.json"
    if casewise.exists():
        return casewise
    return out_dir / "core_28.actual.json"


def _iter_unsafe_out_dirs(results_json: Path):
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
            if str(result.get("status") or "").upper() != "UNSAFE":
                continue
            out_dir = result.get("out_dir")
            if isinstance(out_dir, str) and out_dir:
                yield spec, mode, Path(out_dir)


def _validate_wraparound_evidence(out_dir: Path) -> tuple[bool, str]:
    wrap = out_dir / "wraparound"
    if not wrap.exists():
        return False, ""
    findings: list[str] = []
    for manifest in sorted(wrap.glob("target.*/wraparound.cegis.manifest.json")):
        ok, msg = validate_wraparound_manifest(manifest)
        if ok:
            return True, f"{manifest}: {msg}"
        findings.append(f"{manifest}: {msg}")
    if findings:
        return False, "; ".join(findings)
    return False, f"no wraparound.cegis.manifest.json under {wrap}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--results-json",
        type=Path,
        default=_default_results_json(),
    )
    args = parser.parse_args()

    findings: list[str] = []
    checked = 0
    wraparound_checked = 0
    for spec, mode, out_dir in _iter_unsafe_out_dirs(args.results_json):
        checked += 1
        if not out_dir.exists():
            findings.append(f"{spec}/{mode}: missing out_dir {out_dir}")
            continue
        wraparound_ok, wraparound_msg = _validate_wraparound_evidence(out_dir)
        if wraparound_ok:
            wraparound_checked += 1
            continue
        if wraparound_msg:
            findings.append(f"{spec}/{mode}: wraparound evidence invalid: {wraparound_msg}")
            continue
        summary = summarize_witness(out_dir=out_dir)
        if not summary.ok:
            findings.append(f"{spec}/{mode}: witness invalid: {summary.kind}: {summary.details}")

    for finding in findings:
        print(finding, file=sys.stderr)
    if findings:
        return 1
    print(f"validated UNSAFE witness records: {checked} (wraparound manifests: {wraparound_checked})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
