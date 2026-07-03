import unittest

from dslc.backends.boogie_harness_render import BoogieHarnessRenderMixin


class _DummyRender(BoogieHarnessRenderMixin):
    def __init__(self) -> None:
        # Raw (unprefixed) typedefs extracted from a node's raw Boogie.
        self._node_type_defs = {
            "sw": {
                "pair": "bv64",
                "PortId_t": "bv9",
            }
        }


class TestBoogieHarnessRenderTypedefs(unittest.TestCase):
    def test_render_value_zero_resolves_node_typedef(self) -> None:
        d = _DummyRender()
        self.assertEqual(d._render_value_zero("sw_pair"), "0bv64")

    def test_render_index_zero_resolves_node_typedef(self) -> None:
        d = _DummyRender()
        self.assertEqual(d._render_index_zero("sw_PortId_t"), "0bv9")

    def test_render_typed_int_resolves_node_typedef(self) -> None:
        d = _DummyRender()
        self.assertEqual(d._render_typed_int("sw_pair", 5), "5bv64")
