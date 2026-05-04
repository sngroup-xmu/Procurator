import unittest


class TestRunE2EAblationsClassify(unittest.TestCase):
    def test_classify_unsafe_simple(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(_classify("[RESULT] RESULT: UNSAFE", rc=1), "UNSAFE")

    def test_classify_unsafe_witness_rerun(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(_classify("[RESULT] RESULT: UNSAFE (witness rerun)", rc=1), "UNSAFE")

    def test_classify_safe_simple(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(_classify("[RESULT] RESULT: SAFE", rc=0), "SAFE")

    def test_classify_ultimate_phrase_incorrect(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(
            _classify("[RESULT] RESULT: Ultimate proved your program to be incorrect!", rc=0),
            "UNSAFE",
        )

    def test_classify_ultimate_phrase_correct(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(
            _classify("[RESULT] RESULT: Ultimate proved your program to be correct!", rc=0),
            "SAFE",
        )

    def test_classify_timeout(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(_classify("[RESULT] RESULT: TIMEOUT", rc=124), "TIMEOUT")

    def test_classify_toolchain_no_result(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(
            _classify(
                "[RESULT] RESULT: Ultimate could not prove your program: Toolchain returned no result.",
                rc=0,
            ),
            "ERROR",
        )

    def test_sanity_check_accepts_fresh_focused_marker(self) -> None:
        import hashlib
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.run_e2e_ablations import _sanity_check

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            bpl = out_dir / "case.bpl"
            focused = out_dir / "case.focused-index0.bpl"
            bpl.write_text("procedure main() {}\n", encoding="utf-8")
            focused.write_text("procedure main() {}\n", encoding="utf-8")
            (out_dir / "case.focused-index0.unsafe.json").write_text(
                json.dumps(
                    {
                        "kind": "focused_under_approx",
                        "source_bpl": str(bpl),
                        "bpl": str(focused),
                        "source_bpl_sha256": hashlib.sha256(bpl.read_bytes()).hexdigest(),
                        "focused_bpl_sha256": hashlib.sha256(focused.read_bytes()).hexdigest(),
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            self.assertEqual(_sanity_check(root=out_dir, out_dir=str(out_dir)), "OK")
