import tempfile
import unittest
from pathlib import Path

from dslc.compiler import compile_spec_text


_BPL_BASE = """
type Ref;

var hdr: Ref;
var hdr.fanout: Ref;
var hdr.fanout.valid: bool;
var hdr.fanout.pass: bv1;
var hdr.fanout.write_id: bv1;

var meta.do_recirculate: bv1;

var standard_metadata.egress_spec: bv9;
var standard_metadata.egress_port: bv9;

var p4b_recirculate: bool;
var p4b_clone_i2e: bool;
var p4b_clone_e2e: bool;
var p4b_clone_i2i: bool;

procedure MyParser() { }
procedure MyVerifyChecksum() { }
procedure MyIngress() { }
procedure MyEgress() { }
procedure MyComputeChecksum() { }

procedure main()
  modifies hdr.fanout.valid, hdr.fanout.pass, hdr.fanout.write_id, meta.do_recirculate, standard_metadata.egress_spec,
    standard_metadata.egress_port, p4b_recirculate;
{
  call MyParser();
  call MyVerifyChecksum();
  call MyIngress();
  call MyEgress();
  call MyComputeChecksum();
}

procedure mainProcedure()
  modifies p4b_recirculate, p4b_clone_i2e, p4b_clone_e2e, p4b_clone_i2i, hdr.fanout.valid, hdr.fanout.pass,
    hdr.fanout.write_id, meta.do_recirculate, standard_metadata.egress_spec, standard_metadata.egress_port;
{
  p4b_recirculate := false;
  p4b_clone_i2i := false;
  p4b_clone_e2e := false;
  p4b_clone_i2e := false;
  call main();
}
""".lstrip()


class TestBoogieTwoStageInference(unittest.TestCase):
    def test_pipeline_two_stage_only_for_eventful_nodes(self) -> None:
        with tempfile.TemporaryDirectory() as td:
            tdpath = Path(td)
            t_bpl = tdpath / "t.bpl"
            s1_bpl = tdpath / "s1.bpl"

            # "Eventful" node: sets p4b_recirculate := true somewhere in the program.
            t_bpl.write_text(
                _BPL_BASE.replace(
                    "procedure MyEgress() { }\n",
                    "procedure MyEgress() modifies p4b_recirculate; { p4b_recirculate := true; }\n",
                )
            )
            # "Non-eventful" node: has the flag but never sets it to true.
            s1_bpl.write_text(_BPL_BASE)

            spec = f"""
import t from "{t_bpl.as_posix()}";
import s1 from "{s1_bpl.as_posix()}";

topology {{
  link t -> s1 1;
}}

node t {{
  external_input = true;
}}

node s1 {{ }}

global {{
  queue_capacity = 2;
  max_steps = 3;
  assert {{ true; }};
}}
"""
            out_bpl = tdpath / "out.bpl"
            outp = compile_spec_text(
                spec_text=spec,
                backend="boogie",
                out=out_bpl,
                boogie_harness="concurrent",
                pipeline_two_stage=True,
            )
            text = outp.artifacts["bpl"].read_text(encoding="utf-8", errors="replace")
            self.assertIn("var t_egress_count: int;", text)
            self.assertNotIn("var s1_egress_count: int;", text)
