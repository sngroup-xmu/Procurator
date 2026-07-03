#!/usr/bin/env python3
"""Validate third-party dependency provenance metadata."""

from __future__ import annotations

import argparse
import dataclasses
import json
import sys
from pathlib import Path
from typing import Any


REQUIRED_DEPENDENCIES = ("ultimate", "z3")
REQUIRED_FIELDS = ("name", "path", "license", "provenance")


@dataclasses.dataclass(frozen=True)
class Finding:
    message: str


def _load_json(path: Path) -> tuple[dict[str, Any] | None, list[Finding]]:
    if not path.exists():
        return None, [Finding(f"missing third-party manifest: {path}")]
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return None, [Finding(f"invalid JSON in {path}: {exc}")]
    if not isinstance(data, dict):
        return None, [Finding(f"{path} must contain a JSON object")]
    return data, []


def validate_license_manifest(repo: Path) -> list[Finding]:
    repo = repo.resolve()
    manifest_path = repo / "third_party" / "MANIFEST.json"
    third_party_doc = repo / "THIRD_PARTY.md"
    data, findings = _load_json(manifest_path)
    if data is None:
        return findings

    dependencies = data.get("dependencies")
    if not isinstance(dependencies, list):
        findings.append(Finding("third_party/MANIFEST.json must contain a dependencies array"))
        dependencies = []

    by_name: dict[str, dict[str, Any]] = {}
    for index, entry in enumerate(dependencies):
        if not isinstance(entry, dict):
            findings.append(Finding(f"dependencies[{index}] must be an object"))
            continue
        name = entry.get("name")
        if isinstance(name, str):
            by_name[name.lower()] = entry
        for field in REQUIRED_FIELDS:
            value = entry.get(field)
            if not isinstance(value, str) or not value.strip():
                findings.append(Finding(f"dependency {name or index} missing non-empty field {field}"))

    for required in REQUIRED_DEPENDENCIES:
        if required not in by_name:
            findings.append(Finding(f"missing required third-party dependency entry: {required}"))

    if not third_party_doc.exists():
        findings.append(Finding("missing THIRD_PARTY.md"))
    else:
        doc_text = third_party_doc.read_text(encoding="utf-8", errors="replace").lower()
        for required in REQUIRED_DEPENDENCIES:
            if required not in doc_text:
                findings.append(Finding(f"THIRD_PARTY.md does not mention {required}"))

    return findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)

    findings = validate_license_manifest(args.repo)
    for finding in findings:
        print(finding.message, file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
