#!/usr/bin/env python3
"""Merge per-benchmark casewise E2E actual JSON files.

This keeps the open-source artifact workflow fail-closed while avoiding a
single long "run all 28" solver invocation. Each input file is produced by
`run_benchmark_case.sh --bench <bench> --only <mode>`.
"""

from __future__ import annotations

import argparse
import dataclasses
import json
from pathlib import Path
from typing import Any


DEFAULT_MODES = ("slicing", "noslicing")


@dataclasses.dataclass(frozen=True)
class Finding:
    message: str


def _load_json(path: Path) -> tuple[Any | None, list[Finding]]:
    if not path.exists():
        return None, [Finding(f"missing case actual: {path}")]
    try:
        return json.loads(path.read_text(encoding="utf-8")), []
    except json.JSONDecodeError as exc:
        return None, [Finding(f"invalid JSON in {path}: {exc}")]


def _case_path(cases_dir: Path, bench: str, mode: str) -> Path:
    return cases_dir / f"{bench}.{mode}.actual.json"


def _empty_payload(*, profile: str, cases_dir: Path, modes: list[str]) -> dict[str, Any]:
    return {
        "profile": profile,
        "meta": {
            "source": "merged from per-benchmark casewise actual JSON files",
            "cases_dir": str(cases_dir),
            "required_modes": modes,
        },
        "results": {},
    }


def merge_case_actuals(
    *,
    cases_dir: Path,
    benches: list[str],
    modes: list[str] | None = None,
    profile: str = "core_28",
) -> tuple[dict[str, Any], list[Finding]]:
    required_modes = list(modes or DEFAULT_MODES)
    payload = _empty_payload(profile=profile, cases_dir=cases_dir, modes=required_modes)
    findings: list[Finding] = []
    results = payload["results"]

    for bench in benches:
        for mode in required_modes:
            path = _case_path(cases_dir, bench, mode)
            data, load_findings = _load_json(path)
            if load_findings:
                findings.extend(load_findings)
                continue
            if not isinstance(data, dict):
                findings.append(Finding(f"{path}: case actual must contain a JSON object"))
                continue

            case_results = data.get("results")
            if not isinstance(case_results, dict):
                findings.append(Finding(f"{path}: missing results object"))
                continue
            if len(case_results) != 1:
                findings.append(Finding(f"{path}: expected one benchmark result, found {len(case_results)}"))
                continue

            spec, rec = next(iter(case_results.items()))
            if not isinstance(rec, dict):
                findings.append(Finding(f"{path}: benchmark record for {spec} is not an object"))
                continue
            mode_record = rec.get(mode)
            if not isinstance(mode_record, dict):
                findings.append(Finding(f"{path}: missing mode {mode}"))
                continue

            dst = results.setdefault(
                spec,
                {
                    "name": rec.get("name"),
                    "spec": rec.get("spec", spec),
                    "category": rec.get("category"),
                },
            )
            if not isinstance(dst, dict):
                findings.append(Finding(f"{path}: merged record for {spec} is not an object"))
                continue
            if mode in dst:
                findings.append(Finding(f"{path}: duplicate merged mode {spec}/{mode}"))
                continue
            for key in ("name", "spec", "category"):
                if dst.get(key) != (rec.get(key) if key != "spec" else rec.get("spec", spec)):
                    findings.append(Finding(f"{path}: inconsistent {key} for {spec}"))
                    break
            else:
                dst[mode] = mode_record

    for spec, rec in sorted(results.items()):
        if not isinstance(rec, dict):
            continue
        for mode in required_modes:
            if mode not in rec:
                findings.append(Finding(f"{spec}: missing merged mode {mode}"))

    return payload, findings


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cases-dir", type=Path, default=Path(".tmp/procurator/artifact/cases"))
    parser.add_argument("--out", type=Path, default=Path(".tmp/procurator/artifact/core_28.casewise.actual.json"))
    parser.add_argument("--profile", default="core_28")
    parser.add_argument("--bench", action="append", default=[], help="Benchmark slug to merge; repeatable")
    parser.add_argument("--mode", action="append", default=[], help="Mode to require; default: slicing,noslicing")
    args = parser.parse_args()

    if not args.bench:
        print("at least one --bench is required")
        return 2

    modes = args.mode or list(DEFAULT_MODES)
    payload, findings = merge_case_actuals(
        cases_dir=args.cases_dir,
        benches=args.bench,
        modes=modes,
        profile=args.profile,
    )
    for finding in findings:
        print(finding.message)
    if findings:
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"merged casewise actual: {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
