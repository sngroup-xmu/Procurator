import unittest

from dslc.backends.boogie_harness_dsl import BoogieHarnessDslMixin


class _DummyDsl(BoogieHarnessDslMixin):
    def __init__(self) -> None:
        # Minimal fields used by _infer_bv_width_for_node.
        self._host_to_node = {}
        self._meta_sizes = {}
        self._meta_var_types = {}
        self._node_var_types = {}
        self._node_type_defs = {}


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
