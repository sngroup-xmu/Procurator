from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from dslc.cli.gemcutter import (
    _ComposeJob,
    _run_one,
)


class _FakeRes:
    def __init__(self, result_line: str, returncode: int = 0):
        self.result_line = result_line
        self.returncode = returncode


class TestGemcutterResultRc(unittest.TestCase):
    def _mk_job(self, tmp: Path) -> _ComposeJob:
        return _ComposeJob(
            spec_path=tmp / "case.prop",
            out_bpl=tmp / "out" / "case.bpl",
            work_dir=tmp / "work",
            log_path=tmp / "logs" / "case.log",
            ultimate_home=tmp / "ultimate-home",
        )

    def test_timeout_result_maps_to_nonzero_rc(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tmp = Path(td)
            job = self._mk_job(tmp)
            job.spec_path.parent.mkdir(parents=True, exist_ok=True)
            job.spec_path.write_text("dummy", encoding="utf-8")

            import dslc.cli.gemcutter as gemcutter

            orig_compile = gemcutter.compile_spec_file
            orig_run = gemcutter.run_ultimate
            try:
                def fake_compile_spec_file(**kwargs):
                    out = Path(kwargs["out"])
                    out.parent.mkdir(parents=True, exist_ok=True)
                    out.write_text("procedure main() {}\n", encoding="utf-8")

                def fake_run_ultimate(**_kwargs):
                    return _FakeRes("RESULT: Ultimate could not prove your program: Timeout", returncode=0)

                gemcutter.compile_spec_file = fake_compile_spec_file
                gemcutter.run_ultimate = fake_run_ultimate

                rc = _run_one(
                    job=job,
                    p4b_bin=None,
                    max_env_inputs=False,
                    enable_slicing=True,
                    prune_env_inputs=True,
                    keep_control_seeds=True,
                    por_enabled=False,
                    por_guard_enabled=True,
                    boogie_harness="sequential",
                    pipeline_two_stage=False,
                    max_steps=None,
                    honor_spec_max_steps=False,
                    emit_reg_debug=False,
                    skip_duplicated_fail_fast_global_asserts=False,
                    ultimate=tmp / "Ultimate",
                    toolchain=tmp / "ReachSafety.xml",
                    witness_toolchain=None,
                    settings=tmp / "settings.epf",
                    ultimate_async=False,
                    ultimate_timeout_seconds=5,
                    resource_limits=False,
                    ultimate_xmx_gb=1,
                    witness_rerun=False,
                    focused_direct="off",
                )
            finally:
                gemcutter.compile_spec_file = orig_compile
                gemcutter.run_ultimate = orig_run

            self.assertEqual(rc, 2)


if __name__ == "__main__":
    unittest.main()
