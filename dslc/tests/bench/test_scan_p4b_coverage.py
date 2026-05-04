import tempfile
import unittest
from pathlib import Path

from dslc.bench.scan_p4b_coverage import _classify_failure, _include_paths, _markdown, _target_kind, discover_candidates


class TestScanP4BCoverage(unittest.TestCase):
    def test_target_kind_detects_psa_and_tna(self) -> None:
        self.assertEqual(_target_kind('#include <psa.p4>\nPSA_Switch(ip, pre, ep, bq) main;'), "psa")
        self.assertEqual(_target_kind('#include <t2na.p4>\nSwitch(pipe) main;'), "tna")

    def test_target_kind_prefers_explicit_v1model_over_stray_tna_include(self) -> None:
        text = """
            #include <core.p4>
            #include <tna.p4>
            control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t sm) { apply {} }
            V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
        """

        self.assertEqual(_target_kind(text), "v1model")

    def test_classify_frontend_internal_and_hyphen_type_error(self) -> None:
        self.assertEqual(
            _classify_failure("Compiler Bug: frontends/p4/functionsInlining.cpp:41: Null stat", 1),
            "frontend_internal",
        )
        self.assertEqual(_classify_failure("[--Werror=type-error] error: cast not supported", 1), "frontend_type")

    def test_classify_source_type_mismatch(self) -> None:
        self.assertEqual(
            _classify_failure("Actual error: ig_tm_md: No argument supplied for parameter", 1),
            "source_type",
        )
        self.assertEqual(
            _classify_failure("Cannot unify type 'bit<32>' with type 'MsgType_t'", 1),
            "source_type",
        )

    def test_discover_candidates_accepts_multiple_roots(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            one = root / "one"
            two = root / "two"
            one.mkdir()
            two.mkdir()
            (one / "a.p4").write_text('#include <v1model.p4>\nV1Switch(p, vc, ig, eg, cc, dp) main;\n', encoding="utf-8")
            (two / "b.p4").write_text('#include <psa.p4>\nPSA_Switch(ip, pre, ep, bq) main;\n', encoding="utf-8")

            found = discover_candidates(root, [one, two], include_sanitized=False, include_modules=False)

        self.assertEqual([c.target for c in found], ["v1model", "psa"])
        self.assertEqual([c.rel for c in found], ["one/a.p4", "two/b.p4"])

    def test_include_paths_prefer_external_checkout_p4include(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            checkout = root / "external_p4c"
            sample_dir = checkout / "testdata" / "p4_16_samples"
            sample_dir.mkdir(parents=True)
            (checkout / "p4include").mkdir()
            p4 = sample_dir / "pna-sample.p4"
            p4.write_text('#include <pna.p4>\n', encoding="utf-8")

            paths = _include_paths(root, p4)

        self.assertEqual(paths[0].name, "p4include")

    def test_explicit_tmp_scan_root_is_not_skipped(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scan_root = root / ".tmp" / "upstream"
            scan_root.mkdir(parents=True)
            (scan_root / "pna-example.p4").write_text(
                '#include <pna.p4>\nPNA_NIC(p, m, d, c, dep) main;\n',
                encoding="utf-8",
            )

            found = discover_candidates(root, [scan_root], include_sanitized=False, include_modules=False)

        self.assertEqual([c.rel for c in found], [".tmp/upstream/pna-example.p4"])

    def test_markdown_treats_discovered_as_success(self) -> None:
        md = _markdown(
            {
                "generated_at": "now",
                "p4b_bin": "/p4b",
                "scan_roots": ["samples"],
                "with_slicing": False,
                "semantic_audit": True,
                "timeout_s": 1,
                "offset": 5,
                "limit": 10,
                "max_wall_seconds": 30.0,
                "stopped_reason": "max-wall-seconds 30s reached",
                "candidate_count_before_batch": 25,
                "candidate_count_in_batch": 10,
                "next_offset": 6,
                "records": [
                    {
                        "path": "sample.p4",
                        "target": "psa",
                        "status": "DISCOVERED",
                        "category": "not_run",
                        "semantic_status": "SKIP",
                        "wall_s": 0.0,
                        "error_tail": "",
                    }
                ],
            }
        )

        self.assertIn("| ok | 1 |", md)
        self.assertIn("| fail | 0 |", md)
        self.assertIn("### By Semantic Status", md)
        self.assertIn("| `SKIP` | 1 |", md)
        self.assertIn("Batch: `offset=5, limit=10, max_wall_seconds=30.0`", md)
        self.assertIn("Batch counts: `before_batch=25, in_batch=10, recorded=1, next_offset=6`", md)
        self.assertIn("Stopped early: `max-wall-seconds 30s reached`", md)


if __name__ == "__main__":
    unittest.main()
