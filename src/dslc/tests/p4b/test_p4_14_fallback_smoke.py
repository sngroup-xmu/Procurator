import tempfile
import unittest
from pathlib import Path
from dslc.tests.helpers import repo_root_from_test

from dslc.compiler import compile_spec_file


class TestP414FallbackSmoke(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "third_party" / "p4c" / "source" / "build-host" / "p4c-translator",
        ]
        for p in candidates:
            if p.exists():
                return p
        return candidates[0]

    def test_p4_14_router_compiles_via_std_fallback(self) -> None:
        repo_root = repo_root_from_test(Path(__file__))
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("p4c translator not built (missing build-host/p4c-translator)")

        spec_path = (
            repo_root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "bench"
            / "p4db_router_send_frame_bug.prop"
        )
        if not spec_path.exists():
            self.skipTest("missing P4DB router spec")

        with tempfile.TemporaryDirectory() as td:
            out_bpl = Path(td) / "out.bpl"
            _ = compile_spec_file(
                spec_path=spec_path,
                backend="boogie",
                out=out_bpl,
                p4b_bin=p4b_bin,
                boogie_harness="sequential",
                pipeline_two_stage=False,
            )


if __name__ == "__main__":
    unittest.main()
