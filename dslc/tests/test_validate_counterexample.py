import unittest


class TestValidateCounterexample(unittest.TestCase):
    def test_witness_summary_matches_dsl_guard_line(self) -> None:
        from dslc.bench.validate_counterexample import _extract_dsl_guard_lines

        bpl = """
procedure main()
{
  // Global assertions (accumulated into procurator_bad)
  if (!((x == 0bv8))) { procurator_bad := true; }
  assert !procurator_bad;
}
"""
        guards = _extract_dsl_guard_lines(bpl)
        self.assertEqual(guards, ["if (!((x == 0bv8))) { procurator_bad := true; }"])

    def test_summarize_witness_accepts_normalized_procurator_bad_assignment(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            (out_dir / "toy.bpl").write_text(
                "procedure main(){ if (!((x==0bv8))) { procurator_bad := true; } assert !procurator_bad; }",
                encoding="utf-8",
            )
            (out_dir / "toy.bpl-witness.graphml").write_text(
                "<graphml><graph><node><data key=\"sourcecode\">[procurator_bad := true;]</data></node></graph></graphml>",
                encoding="utf-8",
            )

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok)
            self.assertEqual(s.kind, "dsl_assert")

    def test_summarize_witness_accepts_direct_global_assert(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            (out_dir / "toy.bpl").write_text(
                "\n".join(
                    [
                        "procedure main(){",
                        "  // DSL assertions",
                        "  assert ((x == 0bv8));",
                        "}",
                    ]
                ),
                encoding="utf-8",
            )
            (out_dir / "toy.bpl-witness.graphml").write_text(
                "<graphml><graph><node><data key=\"sourcecode\">assert x == 0bv8;</data></node></graph></graphml>",
                encoding="utf-8",
            )

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok)
            self.assertEqual(s.kind, "dsl_assert")

    def test_summarize_witness_accepts_wraparound_assert_call(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        # Wraparound stages rewrite assertions as `call __wraparound_assert(<expr>);` and
        # Ultimate's witness printer tends to normalize away redundant parentheses.
        bpl = "\n".join(
            [
                "procedure main(){",
                "  // Global assertions",
                "  call __wraparound_assert((!((x && (y == z))) || (r != 0bv32) || (s == 1bv1)));",
                "}",
            ]
        )
        # Mimic GraphML witness XML escaping of "&&" as "&amp;&amp;" and fewer parentheses.
        witness = (
            "<graphml><graph><node><data key=\"sourcecode\">"
            "call __wraparound_assert(!(x &amp;&amp; y == z) || r != 0bv32 || s == 1bv1);"
            "</data></node></graph></graphml>"
        )

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            (out_dir / "toy.bpl").write_text(bpl, encoding="utf-8")
            (out_dir / "toy.bpl-witness.graphml").write_text(witness, encoding="utf-8")

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok, msg=s.details)
            self.assertEqual(s.kind, "dsl_assert")

    def test_summarize_witness_uses_programfile_when_multiple_bpl(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.validate_counterexample import summarize_witness

        # Simulate a wraparound run directory with multiple stage BPLs where the
        # newest `.bpl` is not the one that produced the newest witness.
        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            confirm_bpl = out_dir / "toy.confirm.bpl"
            closure_bpl = out_dir / "toy.closure.bpl"

            confirm_bpl.write_text(
                "\n".join(
                    [
                        "procedure main(){",
                        "  // Global assertions",
                        "  call __wraparound_assert((x == 0bv8));",
                        "}",
                    ]
                ),
                encoding="utf-8",
            )
            # Write a newer BPL with no assertion section; previously this could confuse
            # the witness summary if we picked the newest `.bpl` by mtime.
            closure_bpl.write_text("procedure main() { return; }", encoding="utf-8")

            witness_text = (
                "<graphml><graph>"
                f"<data key=\"programfile\">{confirm_bpl.as_posix()}</data>"
                "<node><data key=\"sourcecode\">call __wraparound_assert(x == 0bv8);</data></node>"
                "</graph></graphml>"
            )
            (out_dir / "toy.bpl-witness.graphml").write_text(witness_text, encoding="utf-8")

            s = summarize_witness(out_dir=out_dir)
            self.assertTrue(s.ok, msg=s.details)
            self.assertEqual(s.kind, "dsl_assert")


if __name__ == "__main__":
    unittest.main()
