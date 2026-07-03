import unittest

from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text


class TestClosureRegisterActionSimplify(unittest.TestCase):
    def test_identity_registeraction_writeback_keeps_mirrors_without_array_store(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_program(identity=True),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="pump_reg",
            accel_regs=["pump_reg"],
            index_value=0,
        )

        body = _proc_body(out, "Read_result")
        self.assertIn("result_reg__last_old_value := result_reg[idx];", body)
        self.assertIn("result_reg__last_index := idx;", body)
        self.assertIn("result_reg__last_value := ra_val;", body)
        self.assertIn("result_reg__last_write_site := result_reg__next_write_site;", body)
        self.assertIn("result_reg__wrote_any := true;", body)
        self.assertIn("result_reg__last0_value := ra_val;", body)
        self.assertIn("out_value := ra_ret;", body)
        self.assertNotIn("call result_reg.write(idx, ra_val);", body)
        self.assertNotIn("result_reg[idx] := ra_val;", body)

    def test_non_identity_registeraction_writeback_keeps_array_store_after_expansion(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_program(identity=False),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="pump_reg",
            accel_regs=["pump_reg"],
            index_value=0,
        )

        body = _proc_body(out, "Read_result")
        self.assertNotIn("call result_reg.write(idx, ra_val);", body)
        self.assertIn("result_reg[idx] := ra_val;", body)
        self.assertIn("result_reg__last_value := ra_val;", body)

    def test_plain_register_write_call_is_expanded_in_closure_task(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_plain_write_program(),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="pump_reg",
            accel_regs=["pump_reg"],
            index_value=0,
        )

        body = _proc_body(out, "Do_write")
        self.assertNotIn("call result_reg.write(idx, in_value);", body)
        self.assertIn("result_reg__last_old_value := result_reg[idx];", body)
        self.assertIn("result_reg[idx] := in_value;", body)
        self.assertLess(
            body.index("result_reg__last_old_value := result_reg[idx];"),
            body.index("result_reg[idx] := in_value;"),
        )
        self.assertIn("result_reg__last_index := idx;", body)
        self.assertIn("result_reg__last_value := in_value;", body)
        self.assertIn("result_reg__last_write_site := result_reg__next_write_site;", body)
        self.assertIn("result_reg__wrote_any := true;", body)
        self.assertIn("result_reg__last0_value := in_value;", body)

    def test_alias_index_register_write_call_is_expanded_in_closure_task(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_alias_index_write_program(),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="pump_reg",
            accel_regs=["pump_reg"],
            index_value=0,
        )

        body = _proc_body(out, "Do_alias_write")
        self.assertNotIn("call alias_reg.write(idx_alias, in_value);", body)
        self.assertIn("alias_reg__last_old_value := alias_reg[idx_alias];", body)
        self.assertIn("alias_reg[idx_alias] := in_value;", body)
        self.assertIn("alias_reg__last_index := idx_alias;", body)
        self.assertIn("alias_reg__last_value := in_value;", body)
        self.assertIn("alias_reg__wrote_any := true;", body)
        self.assertIn("if (idx_alias == 0bv32) {", body)
        self.assertIn("alias_reg__last0_value := in_value;", body)

    def test_simple_action_helper_call_substitutes_formals_in_closure_task(self) -> None:
        out = instrument_bpl_text(
            bpl_text=_simple_action_program(),
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg="pump_reg",
            accel_regs=["pump_reg"],
            index_value=0,
        )

        body = _proc_body(out, "Caller")
        self.assertNotIn("call Do_action(action_arg);", body)
        self.assertIn("meta_field := action_arg;", body)
        self.assertNotIn("action_param", body)


def _program(*, identity: bool) -> str:
    apply_update = "  read_out := value;\n" if identity else "  value := add.bv8(value, 1bv8);\n  read_out := value;\n"
    return (
        """
var procurator_phase: int;
var idx: bv16;
var out_value: bv8;
var ra_val: bv8;
var ra_ret: bv8;
var result_reg:[bv16]bv8;
var result_reg__last_old_value:bv8;
var result_reg__last_index:bv16;
var result_reg__last_value:bv8;
var result_reg__last_write_site:int;
var result_reg__next_write_site:int;
var result_reg__wrote_any:bool;
var result_reg__wrote_index0:bool;
var result_reg__last0_old_value:bv8;
var result_reg__last0_value:bv8;
var pump_reg:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);
function {:inline true} result_reg.read(reg:[bv16]bv8, i:bv16) returns (bv8) { reg[i] }

procedure {:inline 1} result_reg.write(i:bv16, v:bv8)
  modifies result_reg, result_reg__last_old_value, result_reg__last_index, result_reg__last_value,
           result_reg__last_write_site, result_reg__wrote_any, result_reg__wrote_index0,
           result_reg__last0_old_value, result_reg__last0_value;
{
  result_reg__last_old_value := result_reg[i];
  result_reg[i] := v;
  result_reg__last_index := i;
  result_reg__last_value := v;
  result_reg__last_write_site := result_reg__next_write_site;
  result_reg__wrote_any := true;
  if (i == 0bv16) {
    result_reg__wrote_index0 := true;
    result_reg__last0_old_value := result_reg__last_old_value;
    result_reg__last0_value := v;
  }
}

procedure {:inline 1} ReadAction.apply(value_in:bv8, read_in:bv8) returns (value_out:bv8, read_out:bv8)
{
  var value:bv8;
  value := value_in;
__APPLY_UPDATE__
  value_out := value;
}

procedure {:inline 1} Read_result()
  modifies result_reg, result_reg__last_old_value, result_reg__last_index, result_reg__last_value,
           result_reg__last_write_site, result_reg__next_write_site, result_reg__wrote_any,
           result_reg__wrote_index0, result_reg__last0_old_value, result_reg__last0_value, out_value;
{
  ra_val := result_reg.read(result_reg, idx);
  call ra_val, ra_ret := ReadAction.apply(ra_val, ra_ret);
  result_reg__next_write_site := 1;
  call result_reg.write(idx, ra_val);
  out_value := ra_ret;
}

procedure main() returns()
  modifies procurator_phase, pump_reg, result_reg, result_reg__last_old_value, result_reg__last_index,
           result_reg__last_value, result_reg__last_write_site, result_reg__next_write_site,
           result_reg__wrote_any, result_reg__wrote_index0, result_reg__last0_old_value,
           result_reg__last0_value, out_value;
{
  if (procurator_phase == 0) {
    call Read_result();
    pump_reg[0bv32] := add.bv8(pump_reg[0bv32], 1bv8);
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, pump_reg, result_reg, result_reg__last_old_value, result_reg__last_index,
           result_reg__last_value, result_reg__last_write_site, result_reg__next_write_site,
           result_reg__wrote_any, result_reg__wrote_index0, result_reg__last0_old_value,
           result_reg__last0_value, out_value;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
        .replace("__APPLY_UPDATE__", apply_update.rstrip())
    )


def _plain_write_program() -> str:
    return (
        """
var procurator_phase: int;
var idx: bv16;
var in_value: bv8;
var result_reg:[bv16]bv8;
var result_reg__last_old_value:bv8;
var result_reg__last_index:bv16;
var result_reg__last_value:bv8;
var result_reg__last_write_site:int;
var result_reg__next_write_site:int;
var result_reg__wrote_any:bool;
var result_reg__wrote_index0:bool;
var result_reg__last0_old_value:bv8;
var result_reg__last0_value:bv8;
var pump_reg:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);
function {:inline true} result_reg.read(reg:[bv16]bv8, i:bv16) returns (bv8) { reg[i] }

procedure {:inline 1} result_reg.write(i:bv16, v:bv8)
  modifies result_reg, result_reg__last_old_value, result_reg__last_index, result_reg__last_value,
           result_reg__last_write_site, result_reg__wrote_any, result_reg__wrote_index0,
           result_reg__last0_old_value, result_reg__last0_value;
{
  result_reg__last_old_value := result_reg[i];
  result_reg[i] := v;
  result_reg__last_index := i;
  result_reg__last_value := v;
  result_reg__last_write_site := result_reg__next_write_site;
  result_reg__wrote_any := true;
  if (i == 0bv16) {
    result_reg__wrote_index0 := true;
    result_reg__last0_old_value := result_reg__last_old_value;
    result_reg__last0_value := v;
  }
}

procedure {:inline 1} Do_write()
  modifies result_reg, result_reg__last_old_value, result_reg__last_index, result_reg__last_value,
           result_reg__last_write_site, result_reg__next_write_site, result_reg__wrote_any,
           result_reg__wrote_index0, result_reg__last0_old_value, result_reg__last0_value;
{
  result_reg__next_write_site := 1;
  call result_reg.write(idx, in_value);
}

procedure main() returns()
  modifies procurator_phase, pump_reg, result_reg, result_reg__last_old_value, result_reg__last_index,
           result_reg__last_value, result_reg__last_write_site, result_reg__next_write_site,
           result_reg__wrote_any, result_reg__wrote_index0, result_reg__last0_old_value,
           result_reg__last0_value;
{
  if (procurator_phase == 0) {
    call Do_write();
    pump_reg[0bv32] := add.bv8(pump_reg[0bv32], 1bv8);
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, pump_reg, result_reg, result_reg__last_old_value, result_reg__last_index,
           result_reg__last_value, result_reg__last_write_site, result_reg__next_write_site,
           result_reg__wrote_any, result_reg__wrote_index0, result_reg__last0_old_value,
           result_reg__last0_value;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
    )


def _alias_index_write_program() -> str:
    return (
        """
type lid_t = bv32;
var procurator_phase: int;
var idx_alias: lid_t;
var in_value: bv8;
var alias_reg:[lid_t]bv8;
var alias_reg__last_old_value:bv8;
var alias_reg__last_index:lid_t;
var alias_reg__last_value:bv8;
var alias_reg__last_write_site:int;
var alias_reg__next_write_site:int;
var alias_reg__wrote_any:bool;
var alias_reg__wrote_index0:bool;
var alias_reg__last0_old_value:bv8;
var alias_reg__last0_value:bv8;
var pump_reg:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);

procedure {:inline 1} alias_reg.write(i:lid_t, v:bv8)
  modifies alias_reg, alias_reg__last_old_value, alias_reg__last_index, alias_reg__last_value,
           alias_reg__last_write_site, alias_reg__wrote_any, alias_reg__wrote_index0,
           alias_reg__last0_old_value, alias_reg__last0_value;
{
  alias_reg__last_old_value := alias_reg[i];
  alias_reg[i] := v;
  alias_reg__last_index := i;
  alias_reg__last_value := v;
  alias_reg__last_write_site := alias_reg__next_write_site;
  alias_reg__wrote_any := true;
  if (i == 0bv32) {
    alias_reg__wrote_index0 := true;
    alias_reg__last0_old_value := alias_reg__last_old_value;
    alias_reg__last0_value := v;
  }
}

procedure {:inline 1} Do_alias_write()
  modifies alias_reg, alias_reg__last_old_value, alias_reg__last_index, alias_reg__last_value,
           alias_reg__last_write_site, alias_reg__next_write_site, alias_reg__wrote_any,
           alias_reg__wrote_index0, alias_reg__last0_old_value, alias_reg__last0_value;
{
  alias_reg__next_write_site := 1;
  call alias_reg.write(idx_alias, in_value);
}

procedure main() returns()
  modifies procurator_phase, pump_reg, alias_reg, alias_reg__last_old_value, alias_reg__last_index,
           alias_reg__last_value, alias_reg__last_write_site, alias_reg__next_write_site,
           alias_reg__wrote_any, alias_reg__wrote_index0, alias_reg__last0_old_value,
           alias_reg__last0_value;
{
  if (procurator_phase == 0) {
    call Do_alias_write();
    pump_reg[0bv32] := add.bv8(pump_reg[0bv32], 1bv8);
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, pump_reg, alias_reg, alias_reg__last_old_value, alias_reg__last_index,
           alias_reg__last_value, alias_reg__last_write_site, alias_reg__next_write_site,
           alias_reg__wrote_any, alias_reg__wrote_index0, alias_reg__last0_old_value,
           alias_reg__last0_value;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
    )


def _simple_action_program() -> str:
    return (
        """
var procurator_phase: int;
var action_arg: bv16;
var meta_field: bv16;
var pump_reg:[bv32]bv8;

function add.bv8(x:bv8, y:bv8) returns (bv8);

procedure {:inline 1} Do_action(action_param:bv16)
  modifies meta_field;
{
  meta_field := action_param;
}

procedure {:inline 1} Caller()
  modifies meta_field;
{
  call Do_action(action_arg);
}

procedure main() returns()
  modifies procurator_phase, pump_reg, meta_field;
{
  if (procurator_phase == 0) {
    call Caller();
    pump_reg[0bv32] := add.bv8(pump_reg[0bv32], 1bv8);
  }
  if (procurator_phase == 0) {
    procurator_phase := 0;
  } else {
    procurator_phase := procurator_phase + 1;
  }
}

procedure mainProcedure() returns()
  modifies procurator_phase, pump_reg, meta_field;
{
  procurator_phase := 0;
  while (true) {
    call main();
  }
}
"""
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
