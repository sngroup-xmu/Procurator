import unittest

from dslc.backends.boogie_bpl import assert_no_missing_type_decls, find_missing_type_decls
from dslc.backends.boogie_prefix import BoogiePrefixer


class TestBoogieBplMissingTypeDecls(unittest.TestCase):
    def test_find_missing_type_decl(self) -> None:
        raw = (
            "// ===== BEGIN PREAMBLE =====\n"
            "type Ref;\n"
            "// ===== END PREAMBLE =====\n"
            "\n"
            "var x:break_list;\n"
        )
        self.assertEqual(find_missing_type_decls(raw), ["break_list"])

    def test_assert_raises_on_missing_type_decl(self) -> None:
        raw = "var x:break_list;\n"
        with self.assertRaises(ValueError):
            assert_no_missing_type_decls(raw)

    def test_builtin_types_not_flagged(self) -> None:
        raw = "var x:bv16;\nvar y:int;\nvar z:bool;\n"
        self.assertEqual(find_missing_type_decls(raw), [])
        assert_no_missing_type_decls(raw)

    def test_declared_uninterpreted_type_not_flagged(self) -> None:
        raw = "type break_list;\nvar x:break_list;\n"
        self.assertEqual(find_missing_type_decls(raw), [])
        assert_no_missing_type_decls(raw)

    def test_function_return_type_is_checked(self) -> None:
        raw = "type Ref;\nfunction packet.emit(arg0:Ref) returns(ethernet_t);\n"
        self.assertEqual(find_missing_type_decls(raw), ["ethernet_t"])
        with self.assertRaises(ValueError):
            assert_no_missing_type_decls(raw)

    def test_procedure_parameter_type_is_checked(self) -> None:
        raw = "type Ref;\nprocedure p(x:packet_meta) returns(y:bool);\n"
        self.assertEqual(find_missing_type_decls(raw), ["packet_meta"])
        with self.assertRaises(ValueError):
            assert_no_missing_type_decls(raw)

    def test_prefixer_preserves_then_keyword(self) -> None:
        raw = "function f(x:bool) returns(bv1){ if x then 1bv1 else 0bv1 }\n"
        prefixed = BoogiePrefixer("ann").prefix_content(raw)
        self.assertIn(" then ", prefixed)
        self.assertNotIn("ann_then", prefixed)


if __name__ == "__main__":
    unittest.main()
