#!/usr/bin/env python3
"""Reject files that must not be part of the public release tree."""

from __future__ import annotations

import argparse
import dataclasses
import fnmatch
import glob
import json
import subprocess
import sys
from pathlib import Path
from typing import Iterable


FORBIDDEN_PATTERNS = (
    ".agents",
    ".agents/**",
    ".codex",
    ".codex/**",
    ".gemini",
    ".gemini/**",
    ".vscode",
    ".vscode/**",
    ".tmp",
    ".tmp/**",
    "tmp",
    "tmp/**",
    "workspace",
    "workspace/**",
    "build",
    "build/**",
    ".venv",
    ".venv/**",
    ".venv-wsl",
    ".venv-wsl/**",
    "p4verify_latex",
    "p4verify_latex/**",
    "doc/rebuttal*",
    "doc/rebuttal*/**",
    "doc/Questions.md",
    "doc/*.pdf",
    "*.docx",
    "p4verify_sigcomm26.pdf",
    "p4rt-ovs",
    "p4rt-ovs/**",
    "ubpf",
    "ubpf/**",
    "ARTIFACT.md",
    "CHANGELOG.md",
    "INSTALL.md",
    "REPRODUCE.md",
    "THIRD_PARTY.md",
    "USAGE.md",
    "README_zh.md",
    "README_PROCURATOR_PML.md",
    "AGENTS.md",
    "HARDRULES.md",
    "OPERATE.md",
    "benchmarks/datasets/Blink",
    "benchmarks/datasets/Blink/**",
    "benchmarks/datasets/external_henna",
    "benchmarks/datasets/external_henna/**",
    "benchmarks/datasets/farreach",
    "benchmarks/datasets/farreach/**",
    "benchmarks/datasets/horus-p4",
    "benchmarks/datasets/horus-p4/**",
    "benchmarks/datasets/KDR",
    "benchmarks/datasets/KDR/**",
    "benchmarks/datasets/NetLock-netx",
    "benchmarks/datasets/NetLock-netx/**",
    "benchmarks/datasets/P4DB-bmv2",
    "benchmarks/datasets/P4DB-bmv2/**",
    "benchmarks/datasets/P4DB-src",
    "benchmarks/datasets/P4DB-src/**",
    "benchmarks/datasets/P4DB-system",
    "benchmarks/datasets/P4DB-system/**",
    "benchmarks/datasets/P4-timer-1ms",
    "benchmarks/datasets/P4-timer-1ms/**",
    "benchmarks/datasets/recirc_fanout",
    "benchmarks/datasets/recirc_fanout/**",
    "benchmarks/datasets/switchv2p",
    "benchmarks/datasets/switchv2p/**",
    "benchmarks/datasets/tofinoTest",
    "benchmarks/datasets/tofinoTest/**",
    "benchmarks/datasets/V1modelTest",
    "benchmarks/datasets/V1modelTest/**",
    "docs/superpowers",
    "docs/superpowers/**",
)


@dataclasses.dataclass(frozen=True)
class Finding:
    path: str
    pattern: str
    message: str


def normalize_path(path: str | Path) -> str:
    return str(path).replace("\\", "/").strip("/")


def is_forbidden(path: str | Path) -> str | None:
    normalized = normalize_path(path)
    for pattern in FORBIDDEN_PATTERNS:
        if fnmatch.fnmatchcase(normalized, pattern):
            return pattern
    return None


def find_forbidden_paths(paths: Iterable[str | Path]) -> list[Finding]:
    findings: list[Finding] = []
    for path in paths:
        pattern = is_forbidden(path)
        if pattern is not None:
            normalized = normalize_path(path)
            findings.append(
                Finding(
                    path=normalized,
                    pattern=pattern,
                    message=f"{normalized} matches forbidden release pattern {pattern}",
                )
            )
    return findings


def _matches_globs(path: str, patterns: list[str]) -> bool:
    for pattern in patterns:
        normalized = pattern.rstrip("/")
        if fnmatch.fnmatchcase(path, normalized):
            return True
        if normalized.endswith("/**") and path.startswith(normalized[:-3].rstrip("/") + "/"):
            return True
    return False


def release_manifest_paths(repo: Path) -> list[str]:
    manifest_path = repo / "tools" / "release" / "source_manifest.json"
    if not manifest_path.exists():
        return tracked_files(repo)
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return tracked_files(repo)

    includes = data.get("include", [])
    excludes = data.get("exclude", [])
    if not isinstance(includes, list) or not isinstance(excludes, list):
        return tracked_files(repo)

    paths: set[str] = set()
    for pattern in includes:
        if not isinstance(pattern, str):
            continue
        matches = glob.glob(str(repo / pattern), recursive=True)
        if not matches and not any(ch in pattern for ch in "*?["):
            matches = [str(repo / pattern)]
        for item in matches:
            path = Path(item)
            try:
                if not path.is_file():
                    continue
                rel = normalize_path(path.relative_to(repo))
            except (OSError, ValueError):
                continue
            if _matches_globs(rel, [str(exclude).replace("\\", "/") for exclude in excludes if isinstance(exclude, str)]):
                continue
            paths.add(rel)
    return sorted(paths)


def tracked_files(repo: Path) -> list[str]:
    result = subprocess.run(
        ["git", "ls-files"],
        cwd=repo,
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("paths", nargs="*", help="Optional paths to check instead of the release manifest")
    args = parser.parse_args(argv)

    repo = args.repo.resolve()
    paths = args.paths or release_manifest_paths(repo)
    findings = find_forbidden_paths(paths)
    for finding in findings:
        print(f"{finding.path}: {finding.message}", file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
