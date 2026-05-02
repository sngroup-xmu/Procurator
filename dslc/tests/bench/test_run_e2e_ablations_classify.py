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
