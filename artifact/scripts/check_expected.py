#!/usr/bin/env python3
"""Compare generated artifact outputs against expected JSON/CSV files.

This checker is intentionally conservative.  A placeholder expected file, a
missing witness, a timeout, or an unknown solver result is reported as a failed
check rather than silently counted as reproduced evidence.
"""

from __future__ import annotations

import argparse
import csv
import dataclasses
import json
from pathlib import Path
from typing import Any


PLACEHOLDER_STATUSES = {"pending", "skeleton", "todo"}
INCONCLUSIVE_STATUSES = {"TIMEOUT", "UNKNOWN", "OOM", "ERROR", "SKIPPED", "MISSING"}


@dataclasses.dataclass(frozen=True)
class Finding:
    message: str


def _remove_suffix(text: str, suffix: str) -> str:
    if suffix and text.endswith(suffix):
        return text[: -len(suffix)]
    return text


def _load_json(path: Path) -> tuple[Any | None, list[Finding]]:
    if not path.exists():
        return None, [Finding(f"missing JSON file: {path}")]
    try:
        return json.loads(path.read_text(encoding="utf-8")), []
    except json.JSONDecodeError as exc:
        return None, [Finding(f"invalid JSON in {path}: {exc}")]


def _profile_from_expected(path: Path, data: Any) -> str:
    if isinstance(data, dict) and isinstance(data.get("profile"), str):
        return str(data["profile"])
    return _remove_suffix(path.name, ".expected.json")


def _validate_expected_json(path: Path) -> list[Finding]:
    data, findings = _load_json(path)
    if findings:
        return findings
    if not isinstance(data, dict):
        return [Finding(f"{path} must contain a JSON object")]

    out: list[Finding] = []
    profile = _profile_from_expected(path, data)
    expected_profile = _remove_suffix(path.name, ".expected.json")
    if profile != expected_profile:
        out.append(Finding(f"{path} profile {profile!r} does not match filename {expected_profile!r}"))

    status = str(data.get("status", "")).lower()
    if status in PLACEHOLDER_STATUSES:
        out.append(Finding(f"{path} is still a placeholder expected profile: status={status}"))
    if status and status not in {"checkable", "archival"}:
        out.append(Finding(f"{path} has unsupported expected status {status!r}"))
    return out


def _validate_expected_csv(path: Path) -> list[Finding]:
    if not path.exists():
        return [Finding(f"missing CSV file: {path}")]
    try:
        rows = list(csv.reader(path.read_text(encoding="utf-8").splitlines()))
    except csv.Error as exc:
        return [Finding(f"invalid CSV in {path}: {exc}")]
    if not rows:
        return [Finding(f"{path} is empty")]
    lowered = [[cell.strip().lower() for cell in row] for row in rows]
    if any("skeleton" in row or "pending" in row for row in lowered):
        return [Finding(f"{path} still contains placeholder rows")]
    return []


def validate_expected_dir(expected: Path) -> list[Finding]:
    if not expected.exists():
        return [Finding(f"missing expected directory: {expected}")]
    findings: list[Finding] = []
    json_files = sorted(expected.glob("*.expected.json"))
    csv_files = sorted(expected.glob("*.expected.csv"))
    if not json_files and not csv_files:
        return [Finding(f"expected directory has no expected files: {expected}")]
    for path in json_files:
        findings.extend(_validate_expected_json(path))
    for path in csv_files:
        findings.extend(_validate_expected_csv(path))
    return findings


def _result_status(mode_record: dict[str, Any]) -> str:
    result = mode_record.get("result")
    if isinstance(result, dict):
        return str(result.get("status") or "MISSING").upper()
    status = mode_record.get("status")
    return str(status or "MISSING").upper()


def _result_sanity(mode_record: dict[str, Any]) -> str:
    result = mode_record.get("result")
    if isinstance(result, dict):
        return str(result.get("sanity") or "NA")
    return str(mode_record.get("sanity") or "NA")


def _validate_e2e_expected(expected: dict[str, Any], actual: dict[str, Any]) -> list[Finding]:
    results = actual.get("results")
    if not isinstance(results, dict):
        return [Finding("actual E2E JSON must contain a results object")]

    findings: list[Finding] = []
    expected_count = expected.get("expected_case_count")
    if isinstance(expected_count, int) and len(results) != expected_count:
        findings.append(Finding(f"expected {expected_count} cases, found {len(results)}"))

    required_modes = expected.get("required_modes") or []
    if not isinstance(required_modes, list):
        required_modes = []
    allowed_statuses = {str(s).upper() for s in expected.get("allowed_statuses", []) if isinstance(s, str)}
    if not allowed_statuses:
        allowed_statuses = {"SAFE", "UNSAFE"}
    allow_inconclusive = bool(expected.get("allow_inconclusive", False))
    require_sanity_ok = bool(expected.get("require_unsafe_sanity_ok", False))
    required_category = expected.get("required_category")

    for spec, rec in sorted(results.items()):
        if not isinstance(rec, dict):
            findings.append(Finding(f"{spec}: result record is not an object"))
            continue
        if required_category and rec.get("category") != required_category:
            findings.append(Finding(f"{spec}: category {rec.get('category')!r} != {required_category!r}"))
        for mode in required_modes:
            mode_rec = rec.get(str(mode))
            if not isinstance(mode_rec, dict):
                findings.append(Finding(f"{spec}: missing mode {mode}"))
                continue
            status = _result_status(mode_rec)
            if status not in allowed_statuses:
                findings.append(Finding(f"{spec}/{mode}: status {status} not in {sorted(allowed_statuses)}"))
            if (not allow_inconclusive) and status in INCONCLUSIVE_STATUSES:
                findings.append(Finding(f"{spec}/{mode}: inconclusive status {status}"))
            if require_sanity_ok and status == "UNSAFE" and _result_sanity(mode_rec) != "OK":
                findings.append(Finding(f"{spec}/{mode}: UNSAFE sanity is {_result_sanity(mode_rec)!r}, not OK"))
    return findings


def _validate_compile_runtime_expected(expected: dict[str, Any], actual: dict[str, Any]) -> list[Finding]:
    cases = actual.get("cases")
    if not isinstance(cases, dict):
        return [Finding("actual compile-runtime JSON must contain a cases object")]
    findings: list[Finding] = []
    expected_count = expected.get("expected_case_count")
    if isinstance(expected_count, int) and len(cases) != expected_count:
        findings.append(Finding(f"expected {expected_count} compile-runtime cases, found {len(cases)}"))
    required_modes = expected.get("required_modes") or []
    if not isinstance(required_modes, list):
        required_modes = []
    for spec, rec in sorted(cases.items()):
        if not isinstance(rec, dict):
            findings.append(Finding(f"{spec}: compile-runtime record is not an object"))
            continue
        for mode in required_modes:
            mode_rec = rec.get(str(mode))
            if not isinstance(mode_rec, dict):
                findings.append(Finding(f"{spec}: missing mode {mode}"))
                continue
            compile_profile = mode_rec.get("compile_profile")
            if not isinstance(compile_profile, dict):
                findings.append(Finding(f"{spec}/{mode}: missing compile_profile"))
                continue
            if compile_profile.get("returncode") != 0:
                findings.append(Finding(f"{spec}/{mode}: compile returncode {compile_profile.get('returncode')}"))
            runtime = mode_rec.get("runtime")
            if not isinstance(runtime, dict):
                findings.append(Finding(f"{spec}/{mode}: missing runtime record"))
                continue
            status = str(runtime.get("status") or "MISSING").upper()
            if status in INCONCLUSIVE_STATUSES:
                findings.append(Finding(f"{spec}/{mode}: inconclusive runtime status {status}"))
    return findings


def _validate_smoke_expected(expected: dict[str, Any], actual: dict[str, Any]) -> list[Finding]:
    findings: list[Finding] = []
    required = expected.get("required")
    if not isinstance(required, dict):
        return [Finding("smoke expected profile must contain a required object")]
    for key, value in sorted(required.items()):
        if actual.get(key) != value:
            findings.append(Finding(f"smoke actual {key}={actual.get(key)!r}, expected {value!r}"))
    solver = actual.get("solver")
    if isinstance(solver, dict):
        status = str(solver.get("status") or "").upper()
        allowed = {str(s).upper() for s in expected.get("allowed_solver_statuses", []) if isinstance(s, str)}
        if allowed and status not in allowed:
            findings.append(Finding(f"smoke solver status {status} not in {sorted(allowed)}"))
    return findings


def validate_actual(expected_file: Path, actual_file: Path) -> list[Finding]:
    findings = _validate_expected_json(expected_file)
    if findings:
        return findings
    expected, exp_findings = _load_json(expected_file)
    actual, act_findings = _load_json(actual_file)
    if exp_findings or act_findings:
        return exp_findings + act_findings
    if not isinstance(expected, dict) or not isinstance(actual, dict):
        return [Finding("expected and actual files must contain JSON objects")]

    profile = _profile_from_expected(expected_file, expected)
    actual_profile = actual.get("profile")
    if actual_profile is not None and actual_profile != profile:
        return [Finding(f"actual profile {actual_profile!r} does not match expected {profile!r}")]

    if profile == "smoke":
        return _validate_smoke_expected(expected, actual)
    if profile in {"core_28", "wraparound_4"}:
        return _validate_e2e_expected(expected, actual)
    if profile == "compile_runtime":
        return _validate_compile_runtime_expected(expected, actual)
    return [Finding(f"no checker implemented for profile {profile!r}")]


def _default_actual_for(expected_file: Path) -> Path:
    profile = _remove_suffix(expected_file.name, ".expected.json")
    return Path(".tmp") / "procurator" / "artifact" / f"{profile}.actual.json"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--expected", type=Path, default=Path("artifact/expected"))
    parser.add_argument("--actual", type=Path, default=None)
    args = parser.parse_args()

    if args.expected.is_dir():
        findings = validate_expected_dir(args.expected)
    else:
        actual = args.actual or _default_actual_for(args.expected)
        findings = validate_actual(args.expected, actual)

    for finding in findings:
        print(finding.message)
    if findings:
        return 1
    print("expected check passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
