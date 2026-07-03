import unittest


class TestRunE2EAblationsClassify(unittest.TestCase):
    def test_classify_unsafe_simple(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(_classify("[RESULT] RESULT: UNSAFE", rc=1), "UNSAFE")

    def test_classify_unsafe_witness_rerun(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(_classify("[RESULT] RESULT: UNSAFE (witness rerun)", rc=1), "UNSAFE")

    def test_classify_bounded_dsl_replay_cex_without_result(self) -> None:
        from dslc.bench.run_e2e_ablations import _classify

        self.assertEqual(
            _classify(
                "[CEX] bounded_dsl_replay_under_approx: /tmp/case.bounded-dsl-replay.unsafe.json",
                rc=1,
            ),
            "UNSAFE",
        )

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

    def test_find_default_ultimate_accepts_setup_gemcutter_install_path(self) -> None:
        import tempfile
        from pathlib import Path

        from dslc.bench.run_e2e_ablations import _find_default_ultimate

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            ultimate = (
                root
                / ".tmp"
                / "orphan-worktree-20260703-gemcutter"
                / "UGemCutter-linux"
                / "Ultimate"
            )
            ultimate.parent.mkdir(parents=True)
            ultimate.write_text("#!/bin/sh\n", encoding="utf-8")

            self.assertEqual(ultimate, _find_default_ultimate(root))

    def test_repo_root_resolves_release_tree_root_after_src_move(self) -> None:
        from pathlib import Path

        from dslc.bench.run_e2e_ablations import _repo_root

        self.assertEqual(Path(__file__).resolve().parents[4], _repo_root())

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

    def test_sanity_check_accepts_bounded_dsl_replay_marker(self) -> None:
        import hashlib
        import json
        import tempfile
        from pathlib import Path

        from dslc.bench.run_e2e_ablations import _sanity_check

        with tempfile.TemporaryDirectory() as td:
            out_dir = Path(td)
            bpl = out_dir / "toy.bpl"
            bpl.write_text("procedure mainProcedure() returns() { assert !procurator_bad; }\n", encoding="utf-8")
            log = out_dir / "toy.bounded-dsl-replay.textual.log"
            log.write_text("RESULT: UNSAFE\nCounterExampleResult [Line: 1]\n", encoding="utf-8")
            marker = out_dir / "toy.bounded-dsl-replay.unsafe.json"
            marker.write_text(
                json.dumps(
                    {
                        "kind": "bounded_dsl_replay_under_approx",
                        "result_line": "RESULT: UNSAFE",
                        "source_bpl": str(bpl),
                        "bpl": str(bpl),
                        "log": str(log),
                        "source_bpl_sha256": hashlib.sha256(bpl.read_bytes()).hexdigest(),
                        "focused_bpl_sha256": hashlib.sha256(bpl.read_bytes()).hexdigest(),
                    }
                )
                + "\n",
                encoding="utf-8",
            )

            self.assertEqual(_sanity_check(root=out_dir, out_dir=str(out_dir)), "OK")

    def test_gecko_bug3_dry_run_uses_opt_smallblocks_profile(self) -> None:
        import io
        from contextlib import redirect_stdout
        from pathlib import Path
        from unittest import mock

        from dslc.bench import run_e2e_ablations

        ultimate = Path("/tmp/fake-ultimate")
        with mock.patch.object(Path, "exists", return_value=True):
            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = run_e2e_ablations.main(
                    [
                        "--ultimate",
                        str(ultimate),
                        "--only",
                        "slicing",
                        "--bench",
                        "gecko_bug3",
                        "--dry-run",
                    ]
                )

        self.assertEqual(rc, 0)
        out = buf.getvalue()
        dry_line = next(line for line in out.splitlines() if line.startswith("[DRY]"))
        self.assertIn(
            "--settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
            dry_line,
        )

    def test_gecko_bug2_dry_run_uses_opt_smallblocks_profile(self) -> None:
        import io
        from contextlib import redirect_stdout
        from pathlib import Path
        from unittest import mock

        from dslc.bench import run_e2e_ablations

        ultimate = Path("/tmp/fake-ultimate")
        with mock.patch.object(Path, "exists", return_value=True):
            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = run_e2e_ablations.main(
                    [
                        "--ultimate",
                        str(ultimate),
                        "--only",
                        "slicing",
                        "--bench",
                        "gecko_bug2",
                        "--dry-run",
                    ]
                )

        self.assertEqual(rc, 0)
        out = buf.getvalue()
        dry_line = next(line for line in out.splitlines() if line.startswith("[DRY]"))
        self.assertIn(
            "--settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
            dry_line,
        )

    def test_ddosd_dry_run_uses_opt_smallblocks_profile(self) -> None:
        import io
        from contextlib import redirect_stdout
        from pathlib import Path
        from unittest import mock

        from dslc.bench import run_e2e_ablations

        ultimate = Path("/tmp/fake-ultimate")
        with mock.patch.object(Path, "exists", return_value=True):
            buf = io.StringIO()
            with redirect_stdout(buf):
                rc = run_e2e_ablations.main(
                    [
                        "--ultimate",
                        str(ultimate),
                        "--only",
                        "slicing",
                        "--bench",
                        "ddosd",
                        "--dry-run",
                    ]
                )

        self.assertEqual(rc, 0)
        out = buf.getvalue()
        dry_line = next(line for line in out.splitlines() if line.startswith("[DRY]"))
        self.assertIn(
            "--settings src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
            dry_line,
        )
