import unittest

from dslc.backends.boogie_bpl import assert_no_missing_type_decls, find_missing_type_decls


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


if __name__ == "__main__":
    unittest.main()

