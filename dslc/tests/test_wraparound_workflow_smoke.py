import json
import tempfile
import unittest
from pathlib import Path

from dslc.workflows.wraparound import generate_wraparound_tasks


class TestWraparoundWorkflowSmoke(unittest.TestCase):
    def test_generates_manifest_and_stage_bpls(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            out_dir = root / "out"
            base_bpl = root / "base.bpl"
            spec = root / "spec.prop"

            base_bpl.write_text(
                """
var procurator_step: int;
var procurator_phase: int;
var s1_inbox_count: int;
var s2_inbox_count: int;
var s1_sequence_reg:[bv32]bv16;

procedure {:inline 1} s1_sequence_reg.write(i:bv32, v:bv16)
  modifies s1_sequence_reg;
{
  s1_sequence_reg[i] := v;
}

procedure main() returns()
  modifies procurator_phase, s1_sequence_reg;
{
  if (procurator_phase == 0) {
    call s1_sequence_reg.write(0bv32, add.bv16(s1_sequence_reg[0bv32], 1bv16));
  }
  if (procurator_phase == 2) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, procurator_step, s1_sequence_reg, s1_inbox_count, s2_inbox_count;
{
  s1_inbox_count := 0;
  s2_inbox_count := 0;
  procurator_step := 0;
  procurator_phase := 0;
  while (true) {
    call main();
    procurator_step := procurator_step + 1;
  }
}
""".lstrip(),
                encoding="utf-8",
            )

            spec.write_text(
                f"""
import s1 from "{base_bpl}";

topology {{}}

node s1 {{}}

global {{
  assert {{
    s1_sequence_reg_0[0] >= s1_sequence_reg_0[0];
  }};
}}
""".lstrip(),
                encoding="utf-8",
            )

            manifest_path = generate_wraparound_tasks(spec_path=spec, out_dir=out_dir, base_bpl=base_bpl)
            self.assertTrue(manifest_path.exists())

            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            self.assertEqual(manifest["spec"], str(spec.resolve()))
            self.assertEqual(manifest["base_bpl"], str(base_bpl.resolve()))
            self.assertTrue(manifest["candidates"])

            cand0 = manifest["candidates"][0]
            confirm_bpl = Path(cand0["bpl"]["confirm"])
            self.assertTrue(confirm_bpl.exists())
            confirm_text = confirm_bpl.read_text(encoding="utf-8", errors="replace")
            self.assertIn("call s1_sequence_reg.write(0bv32, 65535bv16);", confirm_text)
