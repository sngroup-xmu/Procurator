import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text


class TestClosureTableSpecialization(unittest.TestCase):
    def test_closure_specializes_fixed_table_action_branch(self) -> None:
        src = _table_program()
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
            extra_assumes=["tbl.action_run == tbl.action.noaction"],
        )

        table_body = _proc_body(out, "tbl.apply")
        self.assertIn("tbl.hit := false;", table_body)
        self.assertIn("call noaction();", table_body)
        self.assertNotIn("goto action_set, action_noaction;", table_body)
        self.assertNotIn("call set_result", table_body)
        self.assertNotIn("tbl.action_run == tbl.action.noaction", table_body)

    def test_closure_specializes_table_action_fixed_by_unrolled_env_phase(self) -> None:
        src = _table_program(phase0_extra="    assume tbl.action_run == tbl.action.noaction;\n")
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
        )

        table_body = _proc_body(out, "tbl.apply")
        self.assertIn("call noaction();", table_body)
        self.assertNotIn("goto action_set, action_noaction;", table_body)
        self.assertNotIn("call set_result", table_body)

    def test_closure_does_not_specialize_when_table_prefix_writes_action_run(self) -> None:
        src = _table_program(prefix_action_write="  tbl.action_run := tbl.action.set;\n")
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
            extra_assumes=["tbl.action_run == tbl.action.noaction"],
        )

        table_body = _proc_body(out, "tbl.apply")
        self.assertIn("goto action_set, action_noaction;", table_body)
        self.assertIn("call set_result", table_body)
        self.assertIn("call noaction();", table_body)

    def test_closure_does_not_specialize_unfixed_table(self) -> None:
        src = _table_program()
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
        )

        table_body = _proc_body(out, "tbl.apply")
        self.assertIn("goto action_set, action_noaction;", table_body)
        self.assertIn("call set_result", table_body)
        self.assertIn("call noaction();", table_body)

    def test_closure_keeps_table_body_when_fixed_value_has_no_branch(self) -> None:
        src = _table_program()
        out = instrument_bpl_text(
            bpl_text=src,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="r",
            accel_regs=["r"],
            index_value=0,
            extra_assumes=["tbl.action_run == tbl.action.other"],
        )

        table_body = _proc_body(out, "tbl.apply")
        self.assertIn("goto action_set, action_noaction;", table_body)
        self.assertIn("call set_result", table_body)
        self.assertIn("call noaction();", table_body)


def _table_program(*, phase0_extra: str = "", prefix_action_write: str = "") -> str:
    return (
        """
type tbl.action;
const unique tbl.action.set: tbl.action;
const unique tbl.action.noaction: tbl.action;
const unique tbl.action.other: tbl.action;
var tbl.action_run: tbl.action;
var tbl.hit: bool;
var result: bv8;
var procurator_phase: int;
var r:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);

procedure {:inline 1} set_result(v:bv8)
  modifies result;
{
  result := v;
}

procedure {:inline 1} noaction()
{
}

procedure {:inline 1} tbl.apply()
  modifies tbl.action_run, tbl.hit, result;
{
  tbl.hit := false;
__PREFIX_ACTION_WRITE__
  goto action_set, action_noaction;

  action_set:
  assume tbl.action_run == tbl.action.set;
  call set_result(7bv8);
  goto exit;

  action_noaction:
  assume tbl.action_run == tbl.action.noaction;
  call noaction();
  goto exit;

  exit:
}

procedure main() returns()
  modifies procurator_phase, r, tbl.action_run, tbl.hit, result;
{
  if (procurator_phase == 0) {
__PHASE0_EXTRA__
    call tbl.apply();
    r[0bv32] := add.bv8(r[0bv32], 1bv8);
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, r, tbl.action_run, tbl.hit, result;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        .replace("__PREFIX_ACTION_WRITE__", prefix_action_write.rstrip())
        .replace("__PHASE0_EXTRA__", phase0_extra.rstrip())
    )


def _proc_body(text: str, proc_name: str) -> str:
    marker = f"procedure {{:inline 1}} {proc_name}()"
    start = text.index(marker)
    body_start = text.index("\n{", start) + 1
    depth = 0
    for idx in range(body_start, len(text)):
        if text[idx] == "{":
            depth += 1
        elif text[idx] == "}":
            depth -= 1
            if depth == 0:
                return text[body_start + 1 : idx]
    raise AssertionError(f"procedure body not found: {proc_name}")


if __name__ == "__main__":
    unittest.main()
