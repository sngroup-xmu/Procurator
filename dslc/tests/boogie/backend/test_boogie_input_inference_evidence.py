import json
import os
import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


class TestBoogieInputInferenceEvidence(unittest.TestCase):
    def test_compile_profile_records_keep_havoc_and_skipped_outputs(self) -> None:
        raw_bpl = """\
var hdr.keep: bv8;
var hdr.assume_only: bv8;
var hdr.unused: bv8;
var standard_metadata.egress_spec: bv9;
var standard_metadata.egress_port: bv9;

procedure mainProcedure() returns()
  modifies hdr.keep, standard_metadata.egress_spec;
{
  if (hdr.keep == 1bv8) {
    standard_metadata.egress_spec := 1bv9;
  }
}
"""

        with tempfile.TemporaryDirectory() as td:
            td_path = Path(td)
            bpl_path = td_path / "in.bpl"
            bpl_path.write_text(raw_bpl, encoding="utf-8")
            profile_path = td_path / "profile.jsonl"
            old_profile = os.environ.get("PROCURATOR_COMPILE_PROFILE_JSON")
            os.environ["PROCURATOR_COMPILE_PROFILE_JSON"] = str(profile_path)
            try:
                spec = f"""
import s1 from "{bpl_path.as_posix()}";
topology {{ }}
node s1 {{
  external_input = true;
  assume {{ hdr.assume_only == 7; }};
}}
global {{
  queue_capacity = 1;
  assert {{ s1_hdr.keep == s1_hdr.keep; }};
}}
"""
                compile_spec_text(
                    spec_text=spec,
                    backend="boogie",
                    out=td_path / "out.bpl",
                    boogie_harness="sequential",
                    pipeline_two_stage=False,
                    enable_slicing=True,
                    prune_env_inputs=True,
                )
            finally:
                if old_profile is None:
                    os.environ.pop("PROCURATOR_COMPILE_PROFILE_JSON", None)
                else:
                    os.environ["PROCURATOR_COMPILE_PROFILE_JSON"] = old_profile

            lines = [json.loads(line) for line in profile_path.read_text(encoding="utf-8").splitlines() if line]

        self.assertEqual(len(lines), 1)
        node_record = lines[0]["nodes"]["s1"]
        evidence = node_record["input_inference"]
        self.assertIn("hdr.keep", evidence["slicing_vars"])
        self.assertNotIn("hdr.assume_only", evidence["slicing_vars"])
        self.assertIn("hdr.assume_only", evidence["required_packet_vars"])
        self.assertIn("hdr.keep", evidence["raw_input_vars"])
        self.assertIn("hdr.assume_only", evidence["raw_input_vars"])
        self.assertIn("hdr.unused", evidence["raw_input_vars"])
        self.assertIn("hdr.keep", evidence["havoc_input_vars"])
        self.assertIn("hdr.assume_only", evidence["havoc_input_vars"])
        self.assertNotIn("hdr.unused", evidence["havoc_input_vars"])
        self.assertIn("hdr.assume_only", evidence["force_keep_input_vars"])
        self.assertIn("hdr.unused", evidence["pruned_input_vars"])
        self.assertIn("standard_metadata.egress_spec", evidence["skipped_control_outputs"])
        self.assertIn("standard_metadata.egress_port", evidence["skipped_control_outputs"])


if __name__ == "__main__":
    unittest.main()
