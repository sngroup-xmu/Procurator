from __future__ import annotations

import importlib.util
import json
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
ARTIFACT = ROOT / "artifact"


def _load_script(name: str):
    path = ARTIFACT / "scripts" / name
    spec = importlib.util.spec_from_file_location(name.replace(".", "_"), path)
    assert spec is not None and spec.loader is not None
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


class ArtifactEntrypointTests(unittest.TestCase):
    def test_expected_profiles_are_checkable_not_placeholders(self) -> None:
        for path in sorted((ARTIFACT / "expected").glob("*.expected.json")):
            with self.subTest(path=path.name):
                data = json.loads(path.read_text(encoding="utf-8"))
                self.assertNotIn(data.get("status"), {"pending", "skeleton"})
                self.assertEqual(data.get("profile"), path.name.removesuffix(".expected.json"))

    def test_shell_entrypoints_are_not_skeletons(self) -> None:
        for name in ("run_core_28.sh", "run_wraparound_4.sh", "run_compile_runtime.sh"):
            with self.subTest(script=name):
                text = (ARTIFACT / "scripts" / name).read_text(encoding="utf-8")
                self.assertNotIn("runner skeleton", text)
                self.assertNotIn("exit 2", text)

    def test_check_expected_rejects_pending_profiles(self) -> None:
        mod = _load_script("check_expected.py")
        with tempfile.TemporaryDirectory() as td:
            expected = Path(td) / "expected"
            expected.mkdir()
            (expected / "core_28.expected.json").write_text(
                json.dumps({"profile": "core_28", "status": "pending"}) + "\n",
                encoding="utf-8",
            )
            findings = mod.validate_expected_dir(expected)
            self.assertTrue(any("placeholder" in f.message for f in findings), findings)

    def test_check_expected_accepts_minimal_smoke_actual(self) -> None:
        mod = _load_script("check_expected.py")
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            expected = root / "smoke.expected.json"
            actual = root / "smoke.actual.json"
            expected.write_text(
                json.dumps(
                    {
                        "profile": "smoke",
                        "status": "checkable",
                        "required": {
                            "cli_help": "ok",
                            "compile": "ok",
                        },
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            actual.write_text(
                json.dumps(
                    {
                        "profile": "smoke",
                        "cli_help": "ok",
                        "compile": "ok",
                        "solver": {"status": "TIMEOUT", "classification": "inconclusive"},
                    }
                )
                + "\n",
                encoding="utf-8",
            )
            findings = mod.validate_actual(expected, actual)
            self.assertEqual([], findings)


if __name__ == "__main__":
    unittest.main()
