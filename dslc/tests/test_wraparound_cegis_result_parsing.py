import unittest


class TestWraparoundCegisResultParsing(unittest.TestCase):
    def test_registering_safe_done_does_not_override_timeout(self) -> None:
        # Ultimate may print intermediate "Registering result SAFE ..." lines but still end
        # with an explicit Timeout RESULT. We must not misclassify this as SAFE.
        from dslc.workflows.wraparound_cegis import _extract_result_line

        log = "\n".join(
            [
                "foo",
                "Registering result SAFE for location ERR (0 of 1 remaining)",
                "RESULT: Ultimate could not prove your program: Timeout",
            ]
        )
        self.assertIn("Timeout", _extract_result_line(log) or "")

    def test_registering_safe_not_done_does_not_imply_safe(self) -> None:
        from dslc.workflows.wraparound_cegis import _extract_result_line

        log = "\n".join(
            [
                "Registering result SAFE for location ERR0 (1 of 2 remaining)",
                "RESULT: Ultimate could not prove your program: Timeout",
            ]
        )
        # Not DONE => keep RESULT timeout (UNKNOWN).
        self.assertIn("Timeout", _extract_result_line(log) or "")

    def test_registering_unsafe_beats_timeout(self) -> None:
        from dslc.workflows.wraparound_cegis import _extract_result_line

        log = "\n".join(
            [
                "Registering result UNSAFE for location ERR (0 of 1 remaining)",
                "RESULT: Ultimate could not prove your program: Timeout",
            ]
        )
        self.assertEqual(_extract_result_line(log), "RESULT: UNSAFE")

    def test_early_stop_prefers_observed_safe_over_cancel_timeout(self) -> None:
        from dslc.workflows.wraparound_cegis import _select_stage_result_line

        # When we SIGTERM Ultimate after observing SAFE/UNSAFE, it may append a synthetic
        # Timeout/Cancel RESULT line. The observed result is the intended semantic result.
        self.assertEqual(
            _select_stage_result_line(
                killed_early=True,
                observed_result_line="RESULT: SAFE",
                final_result_line="RESULT: Ultimate could not prove your program: Timeout",
            ),
            "RESULT: SAFE",
        )


if __name__ == "__main__":
    unittest.main()
