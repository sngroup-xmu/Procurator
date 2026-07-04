#!/usr/bin/env python3
"""Fail-closed validation for a single benchmark case result."""

from __future__ import annotations

import argparse
import dataclasses
import json
import sys
from pathlib import Path
from typing import Any


INCONCLUSIVE_STATUSES = {"TIMEOUT", "UNKNOWN", "OOM", "ERROR", "SKIPPED", "MISSING"}


@dataclasses.dataclass(frozen=True)
class Finding:
    message: str


def _load_json(path: Path) -> tuple[Any | None, list[Finding]]:
    if not path.exists():
        return None, [Finding(f"missing results JSON: {path}")]
    try:
        return json.loads(path.read_text(encoding="utf-8")), []
    except json.JSONDecodeError as exc:
        return None, [Finding(f"invalid JSON in {path}: {exc}")]


def _matches_case(spec: str, rec: dict[str, Any], bench: str) -> bool:
    needle = bench.lower()
    name = str(rec.get("name") or "")
    return needle in spec.lower() or needle in name.lower()


def _required_modes(only: str) -> list[str]:
    if only == "all":
        return ["slicing", "noslicing"]
    return [only]


def _result_status(mode_record: dict[str, Any]) -> str:
    result = mode_record.get("result")
    if isinstance(result, dict):
        return str(result.get("status") or "MISSING").upper()
    return "MISSING"


def _result_sanity(mode_record: dict[str, Any]) -> str:
    result = mode_record.get("result")
    if isinstance(result, dict):
        return str(result.get("sanity") or "NA")
    return "NA"


def _result_out_dir(mode_record: dict[str, Any]) -> str:
    result = mode_record.get("result")
    if isinstance(result, dict):
        return str(result.get("out_dir") or "")
    return ""


def _has_wraparound_manifest(mode_record: dict[str, Any]) -> bool:
    out_dir = _result_out_dir(mode_record)
    if not out_dir:
        return False
    wrap = Path(out_dir) / "wraparound"
    return any(wrap.glob("target.*/wraparound.cegis.manifest.json"))


def validate_case_actual(actual: dict[str, Any], *, bench: str, only: str) -> list[Finding]:
    results = actual.get("results")
    if not isinstance(results, dict):
        return [Finding("actual JSON must contain a results object")]

    matches = [
        (spec, rec)
        for spec, rec in sorted(results.items())
        if isinstance(rec, dict) and _matches_case(spec, rec, bench)
    ]
    if not matches:
        return [Finding(f"no benchmark matched {bench!r}")]
    if len(matches) != 1:
        specs = ", ".join(spec for spec, _ in matches)
        return [Finding(f"benchmark selector {bench!r} matched multiple cases: {specs}")]

    spec, rec = matches[0]
    category = str(rec.get("category") or "")
    findings: list[Finding] = []
    for mode in _required_modes(only):
        mode_record = rec.get(mode)
        if not isinstance(mode_record, dict):
            findings.append(Finding(f"{spec}: missing mode {mode}"))
            continue

        status = _result_status(mode_record)
        if status in INCONCLUSIVE_STATUSES:
            findings.append(Finding(f"{spec}/{mode}: inconclusive status {status}"))
            continue
        if status not in {"SAFE", "UNSAFE", "N/A"}:
            findings.append(Finding(f"{spec}/{mode}: unsupported status {status}"))
            continue

        if category == "wraparound":
            if status != "UNSAFE":
                findings.append(Finding(f"{spec}/{mode}: wraparound status {status} is not UNSAFE"))
                continue
            if _result_sanity(mode_record) != "OK":
                findings.append(Finding(f"{spec}/{mode}: wraparound sanity is {_result_sanity(mode_record)!r}, not OK"))
                continue
            if not _has_wraparound_manifest(mode_record):
                findings.append(Finding(f"{spec}/{mode}: missing wraparound certification manifest"))
                continue

        if status == "UNSAFE" and _result_sanity(mode_record) != "OK":
            findings.append(Finding(f"{spec}/{mode}: UNSAFE sanity is {_result_sanity(mode_record)!r}, not OK"))

    return findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--results-json", type=Path, required=True)
    parser.add_argument("--bench", required=True, help="Benchmark name or spec substring to validate")
    parser.add_argument("--only", choices=["all", "slicing", "noslicing"], default="all")
    args = parser.parse_args()

    actual, findings = _load_json(args.results_json)
    if not findings:
        if not isinstance(actual, dict):
            findings = [Finding("results JSON must contain an object")]
        else:
            findings = validate_case_actual(actual, bench=args.bench, only=args.only)

    for finding in findings:
        print(finding.message, file=sys.stderr)
    if findings:
        return 1
    print(f"benchmark case check passed: {args.bench} ({args.only})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
