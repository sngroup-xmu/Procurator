#!/usr/bin/env python3
"""Find references to the pre-release repository layout."""

from __future__ import annotations

import argparse
import dataclasses
import fnmatch
import json
import re
import sys
from pathlib import Path


OLD_LITERAL_PATTERNS = (
    "P4B-Translator/",
    "P4B-Translator\\",
    "Procurator/argo/code/spec/",
    "Procurator\\argo\\code\\spec\\",
    "Procurator/argo/code/dataset/",
    "Procurator\\argo\\code\\dataset\\",
    "third_party/legacy-translator/source/",
    "third_party\\legacy-translator\\source\\",
    "third_party/p4c/source/",
    "third_party\\p4c\\source\\",
)

OLD_REGEX_PATTERNS = (
    ("bin/procurator", re.compile(r"(?<!src/)bin/procurator")),
    ("bin\\procurator", re.compile(r"(?<!src\\)bin\\procurator")),
)

SKIP_DIR_PARTS = {
    ".git",
    ".venv",
    ".venv-wsl",
    ".tmp",
    "build",
    "workspace",
    "__pycache__",
}

SKIP_PREFIXES = (
    "third_party/ultimate/source/",
    "third_party/legacy-translator/source/",
    "artifact/evidence/logs/",
    "artifact/evidence/witnesses/",
    "artifact/evidence/manifests/",
)

SELF_SKIP_FILES = {
    "tools/release/check_source_paths.py",
}

SELF_SKIP_PREFIXES = (
    "tools/release/tests/",
)

TEXT_SUFFIXES = {
    "",
    ".bib",
    ".cfg",
    ".cmake",
    ".conf",
    ".csv",
    ".json",
    ".md",
    ".prop",
    ".py",
    ".sh",
    ".txt",
    ".xml",
    ".yaml",
    ".yml",
}


@dataclasses.dataclass(frozen=True)
class Finding:
    path: str
    line: int
    pattern: str
    text: str
    message: str


def normalize(path: Path) -> str:
    return path.as_posix()


def should_skip(path: Path, root: Path) -> bool:
    rel_path = path.relative_to(root)
    rel = normalize(rel_path)
    if rel in SELF_SKIP_FILES or rel.startswith(SELF_SKIP_PREFIXES):
        return True
    if any(part in SKIP_DIR_PARTS for part in rel_path.parts):
        return True
    if rel.startswith(SKIP_PREFIXES):
        return True
    if path.suffix.lower() not in TEXT_SUFFIXES:
        return True
    return False


def should_skip_dir(path: Path, root: Path) -> bool:
    try:
        rel_path = path.relative_to(root)
    except ValueError:
        return False
    rel = normalize(rel_path)
    if rel.startswith(SELF_SKIP_PREFIXES):
        return True
    if any(part in SKIP_DIR_PARTS for part in rel_path.parts):
        return True
    if rel.startswith(SKIP_PREFIXES):
        return True
    return False


def iter_files(root: Path):
    stack = [root]
    while stack:
        current = stack.pop()
        try:
            entries = list(current.iterdir())
        except OSError:
            continue
        for path in entries:
            try:
                if path.is_dir():
                    if not should_skip_dir(path, root):
                        stack.append(path)
                elif path.is_file():
                    yield path
            except OSError:
                continue


def _load_manifest_scope(root: Path) -> tuple[list[str], list[str]]:
    manifest_path = root / "tools" / "release" / "source_manifest.json"
    if not manifest_path.exists():
        return [], []
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return [], []
    includes = data.get("include", [])
    excludes = data.get("exclude", [])
    if not isinstance(includes, list) or not isinstance(excludes, list):
        return [], []
    return [str(item).replace("\\", "/") for item in includes], [str(item).replace("\\", "/") for item in excludes]


def _matches_globs(path: str, patterns: list[str]) -> bool:
    for pattern in patterns:
        normalized = pattern.rstrip("/")
        if fnmatch.fnmatchcase(path, normalized):
            return True
        if normalized.endswith("/**") and path.startswith(normalized[:-3].rstrip("/") + "/"):
            return True
    return False


def find_old_path_references(root: Path) -> list[Finding]:
    root = root.resolve()
    includes, excludes = _load_manifest_scope(root)
    findings: list[Finding] = []
    for path in iter_files(root):
        if should_skip(path, root):
            continue
        rel = normalize(path.relative_to(root))
        if includes and not _matches_globs(rel, includes):
            continue
        if excludes and _matches_globs(rel, excludes):
            continue
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for line_no, line in enumerate(lines, start=1):
            for pattern in OLD_LITERAL_PATTERNS:
                if pattern in line:
                    findings.append(
                        Finding(
                            path=rel,
                            line=line_no,
                            pattern=pattern,
                            text=line.strip(),
                            message=f"{rel}:{line_no} references old layout path {pattern}",
                        )
                    )
            for pattern, regex in OLD_REGEX_PATTERNS:
                if regex.search(line):
                    findings.append(
                        Finding(
                            path=rel,
                            line=line_no,
                            pattern=pattern,
                            text=line.strip(),
                            message=f"{rel}:{line_no} references old layout path {pattern}",
                        )
                    )
    return findings


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    args = parser.parse_args(argv)

    findings = find_old_path_references(args.repo)
    for finding in findings:
        print(f"{finding.message}: {finding.text}", file=sys.stderr)
    return 1 if findings else 0


if __name__ == "__main__":
    raise SystemExit(main())
