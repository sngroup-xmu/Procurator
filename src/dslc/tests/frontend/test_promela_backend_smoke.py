import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestPromelaBackendSmoke(unittest.TestCase):
    def test_promela_smoke_with_direct_pml_imports(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            pml = td_path / "s1.pml"
            pml.write_text(
                "proctype s1_mainProcedure() { skip; }\n",
                encoding="utf-8",
            )

            spec = f"""
import s1 from "{pml.as_posix()}";
topology {{ }}
node s1 {{ external_input = true; }}
global {{ queue_capacity = 3; }}
"""
            out_dir = td_path / "out"
            outp = compile_spec_text(
                spec_text=spec,
                backend="promela",
                out=out_dir,
                p4c_translator_bin=None,  # not needed for .pml imports
            )

            main_model = outp.artifacts["main_model"]
            self.assertTrue(main_model.exists())
            text = main_model.read_text(encoding="utf-8", errors="replace")
            self.assertIn("#define MAX_BUF_SIZE 3", text)
            self.assertIn("chan s1_chan", text)
            self.assertIn("run s1_mainProcedure()", text)

            # Also ensure a minimal headers typedef exists.
            self.assertTrue((out_dir / "hdr_info" / "global_channel.pml").exists())


if __name__ == "__main__":
    unittest.main()
