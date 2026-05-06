import unittest

from dslc.backends.boogie_harness_dsl import BoogieHarnessDslMixin
from dslc.speclang.parse import parse_tree


class _DummyDsl(BoogieHarnessDslMixin):
    def __init__(self) -> None:
        # Minimal fields used by _infer_bv_width_for_node.
        self._host_to_node = {}
        self._meta_sizes = {}
        self._meta_var_types = {}
        self._node_var_types = {}
        self._node_type_defs = {}
        self._spec = type("_Spec", (), {"imports": {"sw": object()}})()
        self._dsl_node_vars = {}
        self._dsl_host_vars = {}
        self._dsl_global_vars = {}
        self._node_declared_vars = {"sw": set()}
        self._host_declared_vars = {}
        self._node_register_arrays = {}
        self._emit_reg_debug = False

    def _get_declared_vars(self, name: str) -> set[str]:
        if name in self._host_declared_vars:
            return self._host_declared_vars.get(name, set())
        return self._node_declared_vars.get(name, set())


class TestBoogieHarnessDslArrayTypedefs(unittest.TestCase):
    def test_infer_width_from_meta_array_typedef(self) -> None:
        d = _DummyDsl()
        d._meta_var_types = {"sw": {"reg": "[bv32]pair"}}
        d._node_type_defs = {"sw": {"pair": "bv64"}}
        self.assertEqual(d._infer_bv_width_for_node("sw", "reg"), 64)

    def test_infer_width_from_bpl_array_typedef(self) -> None:
        d = _DummyDsl()
        d._node_var_types = {"sw": {"reg": "[bv32]pair"}}
        d._node_type_defs = {"sw": {"pair": "bv64"}}
        self.assertEqual(d._infer_bv_width_for_node("sw", "reg"), 64)

    def test_infer_width_from_bpl_array_with_typedef_index(self) -> None:
        d = _DummyDsl()
        d._node_var_types = {"sw": {"reg": "[sw_lid_t]bv8"}}
        d._node_type_defs = {"sw": {"sw_lid_t": "bv32"}}
        self.assertEqual(d._infer_bv_width_for_node("sw", "reg"), 8)

    def test_infer_width_from_meta_array_with_typedef_index(self) -> None:
        d = _DummyDsl()
        d._meta_var_types = {"sw": {"reg": "[sw_lid_t]bv8"}}
        d._node_type_defs = {"sw": {"sw_lid_t": "bv32"}}
        self.assertEqual(d._infer_bv_width_for_node("sw", "reg"), 8)

    def test_bit_slice_comparison_renders_bv_literal(self) -> None:
        d = _DummyDsl()
        tree = parse_tree(
            """
import sw from "dummy.p4";
topology { }
node sw { external_input = true; }
global { assert { sw_reg__last_value[64:32] == 0; }; }
"""
        )
        expr = next(tree.find_data("eq"))
        self.assertEqual(d._expr_to_boogie(expr, current_node="sw"), "(sw_reg__last_value[64:32] == 0bv32)")

    def test_bit_slice_reverse_comparison_renders_bv_literal(self) -> None:
        d = _DummyDsl()
        tree = parse_tree(
            """
import sw from "dummy.p4";
topology { }
node sw { external_input = true; }
global { assert { 0 == sw_reg__last_value[16:8]; }; }
"""
        )
        expr = next(tree.find_data("eq"))
        self.assertEqual(d._expr_to_boogie(expr, current_node="sw"), "(0bv8 == sw_reg__last_value[16:8])")

    def test_bit_slice_unsigned_comparison_uses_slice_width(self) -> None:
        d = _DummyDsl()
        tree = parse_tree(
            """
import sw from "dummy.p4";
topology { }
node sw { external_input = true; }
global { assert { sw_reg__last_value[64:32] > 0; }; }
"""
        )
        expr = next(tree.find_data("greater"))
        self.assertEqual(
            d._expr_to_boogie(expr, current_node="sw"),
            "(bvule.bv32$builtin(0bv32, sw_reg__last_value[64:32]) && (sw_reg__last_value[64:32] != 0bv32))",
        )
