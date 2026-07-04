from __future__ import annotations

import importlib.util
import json
import os
import subprocess
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

    def test_artifact_manifest_is_release_facing_not_placeholder(self) -> None:
        data = json.loads((ARTIFACT / "MANIFEST.json").read_text(encoding="utf-8"))
        manifest_text = json.dumps(data).lower()
        for marker in ("skeleton", "pending", "placeholder"):
            self.assertNotIn(marker, manifest_text)

        self.assertEqual("Procurator SIGCOMM26 AE package", data.get("artifact"))
        profile_names = [profile["name"] for profile in data.get("profiles", [])]
        self.assertEqual(["smoke", "core_28", "wraparound_4", "full"], profile_names)
        self.assertIn("artifact/evidence/MANIFEST.json", data.get("evidence_manifest", ""))

        policy = data.get("large_benchmark_policy", "")
        self.assertIn("casewise", policy)
        self.assertIn("run_benchmark_case.sh", policy)
        self.assertIn("run_core_28_casewise.sh", policy)
        self.assertIn("ALLOW_BATCH_CORE_28=1", policy)

    def test_shell_entrypoints_are_not_skeletons(self) -> None:
        for name in (
            "run_benchmark_case.sh",
            "run_core_28_casewise.sh",
            "run_core_28.sh",
            "run_wraparound_4.sh",
            "run_compile_runtime.sh",
        ):
            with self.subTest(script=name):
                text = (ARTIFACT / "scripts" / name).read_text(encoding="utf-8")
                self.assertNotIn("runner skeleton", text)
                if name == "run_benchmark_case.sh":
                    self.assertIn("--bench", text)
                    self.assertIn("validate_benchmark_case.py", text)
                    self.assertNotIn("\n  --resume \\\n", text)
                if name == "run_core_28_casewise.sh":
                    self.assertIn("run_benchmark_case.sh", text)
                    self.assertIn("merge_case_results.py", text)
                    self.assertIn("--timeout \"${TIMEOUT_SECONDS:-3600}\"", text)
                    self.assertIn("--ultimate-xmx-gb \"${ULTIMATE_XMX_GB:-4}\"", text)
                    self.assertNotIn("run_core_28.sh", text)
                if name == "run_core_28.sh":
                    self.assertIn("run_core_28_casewise.sh", text)
                    self.assertIn("ALLOW_BATCH_CORE_28", text)
                if name == "run_wraparound_4.sh":
                    self.assertIn("run_benchmark_case.sh", text)
                    self.assertIn("merge_case_results.py", text)
                    self.assertIn("--profile wraparound_4", text)
                    self.assertNotIn("run_e2e_ablations.py", text)
                if name == "run_compile_runtime.sh":
                    self.assertIn("core_28.casewise.actual.json", text)
                    self.assertIn("run_core_28_casewise.sh", text)

    @unittest.skipIf(sys.platform == "win32", "artifact shell entrypoints require WSL/Linux")
    def test_run_core_28_defaults_to_casewise_dry_run(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            env = os.environ.copy()
            env["OUT_DIR"] = str(Path(td) / "artifact")
            env["PYTHON"] = sys.executable
            env["PYTHONPATH"] = (
                f"{ROOT / 'src'}:{ROOT / 'src' / 'p4b' / 'python'}"
                f"{':' + env['PYTHONPATH'] if env.get('PYTHONPATH') else ''}"
            )

            result = subprocess.run(
                [str(ARTIFACT / "scripts" / "run_core_28.sh"), "--dry-run"],
                cwd=ROOT,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                timeout=60,
                check=False,
            )

        combined = result.stdout + result.stderr
        self.assertEqual(0, result.returncode, combined)
        self.assertIn("run_core_28_casewise.sh", combined)
        self.assertIn("core_28 casewise dry-run", combined)
        self.assertEqual(56, combined.count("[DRY]"), combined)

    def test_artifact_consumers_prefer_casewise_results_when_present(self) -> None:
        for script in ("make_tables.py", "validate_witnesses.py"):
            with self.subTest(script=script):
                mod = _load_script(script)
                with tempfile.TemporaryDirectory() as td:
                    out_dir = Path(td)
                    legacy = out_dir / "core_28.actual.json"
                    casewise = out_dir / "core_28.casewise.actual.json"

                    legacy.write_text(json.dumps({"results": {}}) + "\n", encoding="utf-8")
                    self.assertEqual(legacy, mod._default_results_json(out_dir))

                    casewise.write_text(json.dumps({"results": {}}) + "\n", encoding="utf-8")
                    self.assertEqual(casewise, mod._default_results_json(out_dir))

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

    def test_validate_benchmark_case_accepts_conclusive_nonwraparound_case(self) -> None:
        mod = _load_script("validate_benchmark_case.py")
        actual = {
            "results": {
                "benchmarks/specs/bench/atp_bug.prop": {
                    "category": "implementation",
                    "name": "ATP bound bug",
                    "slicing": {
                        "result": {
                            "status": "UNSAFE",
                            "sanity": "OK",
                            "out_dir": "/tmp/procurator/atp",
                        }
                    },
                }
            }
        }

        findings = mod.validate_case_actual(actual, bench="atp_bug", only="slicing")
        self.assertEqual([], findings)

    def test_validate_benchmark_case_load_json_success_returns_no_findings(self) -> None:
        mod = _load_script("validate_benchmark_case.py")
        with tempfile.TemporaryDirectory() as td:
            path = Path(td) / "case.actual.json"
            path.write_text(json.dumps({"results": {}}) + "\n", encoding="utf-8")

            actual, findings = mod._load_json(path)

        self.assertEqual({"results": {}}, actual)
        self.assertEqual([], findings)

    def test_validate_benchmark_case_rejects_inconclusive_status(self) -> None:
        mod = _load_script("validate_benchmark_case.py")
        actual = {
            "results": {
                "benchmarks/specs/bench/atp_bug.prop": {
                    "category": "implementation",
                    "name": "ATP bound bug",
                    "slicing": {"result": {"status": "TIMEOUT", "sanity": "NA"}},
                }
            }
        }

        findings = mod.validate_case_actual(actual, bench="atp_bug", only="slicing")
        self.assertTrue(any("inconclusive status TIMEOUT" in f.message for f in findings), findings)

    def test_validate_benchmark_case_rejects_safe_wraparound_case(self) -> None:
        mod = _load_script("validate_benchmark_case.py")
        actual = {
            "results": {
                "benchmarks/specs/bench/netchain_wraparound_bug.prop": {
                    "category": "wraparound",
                    "name": "NetChain wrap-around bug",
                    "slicing": {"result": {"status": "SAFE", "sanity": "NA"}},
                }
            }
        }

        findings = mod.validate_case_actual(actual, bench="netchain_wraparound_bug", only="slicing")
        self.assertTrue(any("wraparound status SAFE is not UNSAFE" in f.message for f in findings), findings)

    def test_merge_case_results_combines_casewise_modes(self) -> None:
        mod = _load_script("merge_case_results.py")
        with tempfile.TemporaryDirectory() as td:
            cases = Path(td)
            for mode in ("slicing", "noslicing"):
                (cases / f"alpha_bug.{mode}.actual.json").write_text(
                    json.dumps(
                        {
                            "results": {
                                "benchmarks/specs/bench/alpha_bug.prop": {
                                    "category": "implementation",
                                    "name": "Alpha bug",
                                    mode: {
                                        "cmd": ["verify", "--bench", "alpha_bug", "--only", mode],
                                        "result": {
                                            "status": "UNSAFE",
                                            "sanity": "OK",
                                            "out_dir": f"/tmp/alpha/{mode}",
                                        },
                                    },
                                }
                            }
                        }
                    )
                    + "\n",
                    encoding="utf-8",
                )

            payload, findings = mod.merge_case_actuals(
                cases_dir=cases,
                benches=["alpha_bug"],
                modes=["slicing", "noslicing"],
            )

        self.assertEqual([], findings)
        self.assertEqual("core_28", payload["profile"])
        record = payload["results"]["benchmarks/specs/bench/alpha_bug.prop"]
        self.assertEqual("Alpha bug", record["name"])
        self.assertEqual("UNSAFE", record["slicing"]["result"]["status"])
        self.assertEqual("UNSAFE", record["noslicing"]["result"]["status"])

    def test_merge_case_results_reports_missing_case_file(self) -> None:
        mod = _load_script("merge_case_results.py")
        with tempfile.TemporaryDirectory() as td:
            payload, findings = mod.merge_case_actuals(
                cases_dir=Path(td),
                benches=["alpha_bug"],
                modes=["slicing", "noslicing"],
            )

        self.assertEqual({}, payload["results"])
        self.assertTrue(any("missing case actual" in f.message for f in findings), findings)


if __name__ == "__main__":
    unittest.main()
