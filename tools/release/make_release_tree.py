#!/usr/bin/env python3
"""Create a release tree from source_manifest.json."""

from __future__ import annotations

import argparse
import fnmatch
import glob
import json
import shutil
import sys
from pathlib import Path


def load_manifest(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def normalize(path: str | Path) -> str:
    return str(path).replace("\\", "/").strip("/")


def _os_path(path: Path) -> Path:
    resolved = path.resolve()
    text = str(resolved)
    if sys.platform == "win32" and not text.startswith("\\\\?\\"):
        return Path("\\\\?\\" + text)
    return resolved


def matches_globs(path: str, patterns: list[str]) -> bool:
    for pattern in patterns:
        normalized = pattern.rstrip("/")
        if fnmatch.fnmatchcase(path, normalized):
            return True
        if normalized.endswith("/**") and path.startswith(normalized[:-3].rstrip("/") + "/"):
            return True
    return False


def iter_manifest_files(repo: Path, manifest: dict) -> list[Path]:
    includes = manifest.get("include", [])
    excludes = manifest.get("exclude", [])
    if not isinstance(includes, list) or not isinstance(excludes, list):
        raise ValueError("manifest must contain include and exclude arrays")

    exclude_patterns = [normalize(item) for item in excludes if isinstance(item, str)]
    files: set[Path] = set()
    for pattern in includes:
        if not isinstance(pattern, str):
            continue
        pattern = normalize(pattern)
        matches = glob.glob(str(repo / pattern), recursive=True)
        if not matches and not any(ch in pattern for ch in "*?["):
            matches = [str(repo / pattern)]
        for match in matches:
            path = Path(match)
            try:
                if not path.is_file():
                    continue
                rel = normalize(path.relative_to(repo))
            except (OSError, ValueError):
                continue
            if matches_globs(rel, exclude_patterns):
                continue
            files.add(path)
    return sorted(files, key=lambda p: normalize(p.relative_to(repo)))


def create_release_tree(repo: Path, manifest_path: Path, out: Path, *, force: bool = False) -> list[str]:
    repo = repo.resolve()
    manifest_path = manifest_path.resolve()
    out = out.resolve()
    manifest = load_manifest(manifest_path)

    if out.exists():
        if not force:
            raise FileExistsError(f"output directory already exists: {out}")
        shutil.rmtree(_os_path(out))
    out.mkdir(parents=True)

    copied: list[str] = []
    for source in iter_manifest_files(repo, manifest):
        rel = Path(normalize(source.relative_to(repo)))
        dest = out / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(_os_path(source), _os_path(dest))
        copied.append(rel.as_posix())

    (out / "SOURCE_MANIFEST.json").write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    return copied


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--manifest", type=Path, default=Path("tools/release/source_manifest.json"))
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--force", action="store_true", help="Remove an existing output directory before copying.")
    args = parser.parse_args(argv)

    repo = args.repo.resolve()
    manifest = args.manifest
    if not manifest.is_absolute():
        manifest = repo / manifest
    try:
        copied = create_release_tree(repo, manifest, args.out, force=args.force)
    except Exception as exc:
        print(f"release tree creation failed: {exc}", file=sys.stderr)
        return 1
    print(f"Copied {len(copied)} files to {args.out}")
    print(f"Wrote {args.out / 'SOURCE_MANIFEST.json'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
