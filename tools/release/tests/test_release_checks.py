import importlib.util
import json
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
TOOLS_DIR = REPO_ROOT / "tools" / "release"


def load_script(name: str):
    path = TOOLS_DIR / name
    spec = importlib.util.spec_from_file_location(name.removesuffix(".py"), path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def test_private_path_checker_flags_forbidden_release_inputs():
    checker = load_script("check_no_private_files.py")

    findings = checker.find_forbidden_paths(
        [
            "src/dslc/compiler.py",
            "AGENTS.md",
            "ARTIFACT.md",
            "doc/rebuttal_answer.pdf",
            ".tmp/procurator/run.log",
            "p4rt-ovs/README.md",
            "benchmarks/datasets/Blink/p4src/old.p4",
        ]
    )

    assert {finding.path for finding in findings} == {
        "AGENTS.md",
        "ARTIFACT.md",
        "doc/rebuttal_answer.pdf",
        ".tmp/procurator/run.log",
        "p4rt-ovs/README.md",
        "benchmarks/datasets/Blink/p4src/old.p4",
    }


def test_private_path_checker_uses_release_manifest_scope(tmp_path):
    checker = load_script("check_no_private_files.py")

    (tmp_path / "tools" / "release").mkdir(parents=True)
    (tmp_path / "README.md").write_text("public\n", encoding="utf-8")
    (tmp_path / "AGENTS.md").write_text("internal\n", encoding="utf-8")
    (tmp_path / "tools" / "release" / "source_manifest.json").write_text(
        json.dumps({"include": ["README.md"], "exclude": ["AGENTS.md"]}),
        encoding="utf-8",
    )

    assert checker.release_manifest_paths(tmp_path) == ["README.md"]
    assert checker.find_forbidden_paths(checker.release_manifest_paths(tmp_path)) == []


def test_source_path_checker_reports_old_layout_references(tmp_path):
    checker = load_script("check_source_paths.py")

    good = tmp_path / "README.md"
    bad = tmp_path / "src" / "dslc" / "cli.py"
    skipped = tmp_path / "third_party" / "p4c" / "source" / "README.md"
    bad.parent.mkdir(parents=True)
    skipped.parent.mkdir(parents=True)
    good.write_text("Use benchmarks/specs/smoke/boogie_smoke.prop\n", encoding="utf-8")
    bad.write_text("Use P4B-Translator/build-host/p4c-translator\n", encoding="utf-8")
    skipped.write_text("Historical P4B-Translator text in vendored p4c docs\n", encoding="utf-8")

    findings = checker.find_old_path_references(tmp_path)

    assert len(findings) == 1
    assert findings[0].path == "src/dslc/cli.py"
    assert findings[0].pattern == "P4B-Translator/"


def test_source_path_checker_allows_new_src_bin_entrypoint(tmp_path):
    checker = load_script("check_source_paths.py")

    readme = tmp_path / "README.md"
    readme.write_text(
        "Run ./src/bin/procurator, not the old ./bin/procurator entrypoint.\n",
        encoding="utf-8",
    )

    findings = checker.find_old_path_references(tmp_path)

    assert len(findings) == 1
    assert findings[0].pattern == "bin/procurator"


def test_source_path_checker_skips_existing_excluded_work_dirs(tmp_path):
    checker = load_script("check_source_paths.py")

    tmp_dir = tmp_path / ".tmp" / "run"
    tmp_dir.mkdir(parents=True)
    (tmp_dir / "old.txt").write_text("P4B-Translator/build-host/p4c-translator\n", encoding="utf-8")

    findings = checker.find_old_path_references(tmp_path)

    assert findings == []


def test_source_path_checker_uses_release_manifest_scope(tmp_path):
    checker = load_script("check_source_paths.py")

    (tmp_path / "tools" / "release").mkdir(parents=True)
    (tmp_path / "README.md").write_text("Use P4B-Translator/build-host/p4c-translator\n", encoding="utf-8")
    (tmp_path / "OPERATE.md").write_text("Use P4B-Translator/build-host/p4c-translator\n", encoding="utf-8")
    (tmp_path / "tools" / "release" / "source_manifest.json").write_text(
        json.dumps({"include": ["README.md"], "exclude": ["OPERATE.md"]}),
        encoding="utf-8",
    )

    findings = checker.find_old_path_references(tmp_path)

    assert [finding.path for finding in findings] == ["README.md"]


def test_source_path_checker_reports_release_excluded_legacy_references(tmp_path):
    checker = load_script("check_source_paths.py")

    (tmp_path / "tools" / "release").mkdir(parents=True)
    included = tmp_path / "src" / "dslc" / "tests" / "test_fixture.py"
    included.parent.mkdir(parents=True)
    included.write_text(
        'FIXTURE = "third_party/legacy-translator/source/feature-testcases/bool/out.bpl"\n',
        encoding="utf-8",
    )
    (tmp_path / "tools" / "release" / "source_manifest.json").write_text(
        json.dumps(
            {
                "include": ["src/**"],
                "exclude": ["third_party/legacy-translator/**"],
            }
        ),
        encoding="utf-8",
    )

    findings = checker.find_old_path_references(tmp_path)

    assert [finding.path for finding in findings] == ["src/dslc/tests/test_fixture.py"]
    assert findings[0].pattern == "third_party/legacy-translator/source/"


def test_source_path_checker_reports_old_third_party_p4b_source_references(tmp_path):
    checker = load_script("check_source_paths.py")

    (tmp_path / "tools" / "release").mkdir(parents=True)
    included = tmp_path / "README.md"
    included.write_text(
        "Build P4B from third_party/p4c/source/build-host.\n",
        encoding="utf-8",
    )
    (tmp_path / "tools" / "release" / "source_manifest.json").write_text(
        json.dumps({"include": ["README.md"], "exclude": []}),
        encoding="utf-8",
    )

    findings = checker.find_old_path_references(tmp_path)

    assert [finding.path for finding in findings] == ["README.md"]
    assert findings[0].pattern == "third_party/p4c/source/"


def test_license_manifest_requires_core_third_party_entries(tmp_path):
    checker = load_script("check_license_manifest.py")

    third_party = tmp_path / "third_party"
    third_party.mkdir()
    manifest = third_party / "MANIFEST.json"
    license_notes = third_party / "LICENSES.md"
    manifest.write_text(
        json.dumps(
            {
                "dependencies": [
                    {
                        "name": "p4c",
                        "path": "third_party/p4c/source",
                        "license": "Apache-2.0",
                        "provenance": "pinned local fork",
                    },
                    {
                        "name": "ultimate",
                        "path": "third_party/ultimate/source",
                        "license": "LGPL-3.0-or-later",
                        "provenance": "pinned local fork",
                    },
                ]
            }
        ),
        encoding="utf-8",
    )
    license_notes.write_text("p4c\nUltimate\n", encoding="utf-8")

    findings = checker.validate_license_manifest(tmp_path)

    assert any("z3" in finding.message for finding in findings)


def test_license_manifest_does_not_require_p4b_as_third_party(tmp_path):
    checker = load_script("check_license_manifest.py")

    third_party = tmp_path / "third_party"
    third_party.mkdir()
    (third_party / "MANIFEST.json").write_text(
        json.dumps(
            {
                "dependencies": [
                    {
                        "name": "ultimate",
                        "path": "third_party/ultimate",
                        "license": "LGPL-3.0-or-later",
                        "provenance": "pinned local fork",
                    },
                    {
                        "name": "z3",
                        "path": "third_party/z3",
                        "license": "MIT",
                        "provenance": "artifact-provided dependency",
                    },
                ]
            }
        ),
        encoding="utf-8",
    )
    (third_party / "LICENSES.md").write_text("Ultimate\nZ3\n", encoding="utf-8")

    findings = checker.validate_license_manifest(tmp_path)

    assert not any("p4c" in finding.message.lower() for finding in findings)


def test_make_release_tree_copies_manifest_inputs_and_excludes(tmp_path):
    maker = load_script("make_release_tree.py")

    repo = tmp_path / "repo"
    out = tmp_path / "out"
    (repo / "src" / "bin").mkdir(parents=True)
    (repo / "tools" / "release").mkdir(parents=True)
    (repo / "src" / "bin" / "procurator").write_text("#!/usr/bin/env python3\n", encoding="utf-8")
    (repo / "AGENTS.md").write_text("internal\n", encoding="utf-8")
    manifest = repo / "tools" / "release" / "source_manifest.json"
    manifest.write_text(
        json.dumps({"include": ["src/**", "AGENTS.md"], "exclude": ["AGENTS.md"]}),
        encoding="utf-8",
    )

    copied = maker.create_release_tree(repo, manifest, out, force=False)

    assert copied == ["src/bin/procurator"]
    assert (out / "src" / "bin" / "procurator").is_file()
    assert not (out / "AGENTS.md").exists()
    assert (out / "SOURCE_MANIFEST.json").is_file()
