import unittest

from dslc.speclang import SemanticAnalyzer, SemanticError, parse_tree


class TestSemantics(unittest.TestCase):
    def test_semantics_ok_basic(self) -> None:
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  int X = 0;
  X = 1;
}
global { }
"""
        tree = parse_tree(spec)
        SemanticAnalyzer().analyze(tree)

    def test_semantics_reject_double_decl(self) -> None:
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  int X = 0;
  int X = 1;
}
global { }
"""
        tree = parse_tree(spec)
        with self.assertRaises(SemanticError):
            SemanticAnalyzer().analyze(tree)

    def test_semantics_reject_use_before_decl_for_dsl_local(self) -> None:
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  X = 1;
}
global { }
"""
        tree = parse_tree(spec)
        with self.assertRaises(SemanticError):
            SemanticAnalyzer().analyze(tree)

    def test_semantics_allow_unknown_lowercase_vars(self) -> None:
        # Lowercase var is treated as "likely external/P4 var" (best-effort),
        # so we don't error out even though it's undeclared in DSL.
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  reg3 = 1;
}
global { }
"""
        tree = parse_tree(spec)
        SemanticAnalyzer().analyze(tree)

    def test_semantics_reject_type_mismatch(self) -> None:
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  int X = true;
}
global { }
"""
        tree = parse_tree(spec)
        with self.assertRaises(SemanticError):
            SemanticAnalyzer().analyze(tree)

    def test_semantics_typecheck_assert_bool_block(self) -> None:
        # assert expects boolean expressions; `1 + 2` is int and should be rejected.
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  assert { 1 + 2; };
}
global { }
"""
        tree = parse_tree(spec)
        with self.assertRaises(SemanticError):
            SemanticAnalyzer().analyze(tree)

    def test_semantics_ignore_directives(self) -> None:
        spec = """
import s1 from "/tmp/s1.bpl";
topology { }
node s1 {
  external_input = true;
}
global {
  queue_capacity = 5;
}
"""
        tree = parse_tree(spec)
        SemanticAnalyzer().analyze(tree)


if __name__ == "__main__":
    unittest.main()
