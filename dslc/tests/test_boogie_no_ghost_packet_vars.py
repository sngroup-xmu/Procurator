import re
import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieNoGhostPacketVars(unittest.TestCase):
    def test_env_var_resolves_to_declared_suffix_variant(self) -> None:
        """
        Regression/soundness: do not auto-declare "ghost" packet vars.

        If the imported Boogie program declares only a suffixed packet var
        (e.g., `hdr.ipv4.dstAddr_0`), then spec-level references to
        `hdr.ipv4.dstAddr` must resolve to the declared variant instead of
        synthesizing a new global `hdr.ipv4.dstAddr`.
        """

        raw_bpl = """
var hdr.ipv4.dstAddr_0: bv32;
var standard_metadata.egress_port: bv16;

procedure mainProcedure() returns()
  modifies hdr.ipv4.dstAddr_0, standard_metadata.egress_port;
{
  // minimal stub
  return;
}
"""

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            bpl_path = td_path / "in.bpl"
            bpl_path.write_text(raw_bpl, encoding="utf-8")

            spec = f"""
import s1 from "{bpl_path.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  env {{
    hdr.ipv4.dstAddr = 1;
  }}
}}
global {{
  queue_capacity = 1;
  assert {{ true; }};
}}
"""
            out_bpl = td_path / "out.bpl"
            outp = compile_spec_text(spec_text=spec, backend="boogie", out=out_bpl, boogie_harness="concurrent")
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")

        # The suffixed var must exist (and be referenced), and the unsuffixed one must NOT be introduced.
        self.assertRegex(text, r"\bvar\s+s1_hdr\.ipv4\.dstAddr_0\s*:\s*bv32;")
        self.assertNotRegex(text, r"\bvar\s+s1_hdr\.ipv4\.dstAddr\s*:\s*bv32;")
        self.assertIn("s1_hdr.ipv4.dstAddr_0 := 1bv32;", text)


if __name__ == "__main__":
    unittest.main()

