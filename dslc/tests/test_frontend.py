import unittest

from dslc.speclang import parse_model


class TestFrontendParseModel(unittest.TestCase):
    def test_parse_model_directives_and_links(self) -> None:
        spec = """
import s1 from "/tmp/s1.bpl";

topology {
  link s1 -> s1 1;
}

node s1 {
  external_input = true;
  assume { true; };
}

global {
  queue_capacity = 7;
  reachability(s1, s1);
}
"""
        m = parse_model(spec)
        self.assertIn("s1", m.imports)
        self.assertEqual(m.imports["s1"].path, "/tmp/s1.bpl")
        self.assertIn("s1", m.nodes)
        self.assertTrue(m.nodes["s1"].external_input)
        self.assertEqual(m.global_decl.queue_capacity, 7)
        self.assertEqual(len(m.links), 1)
        self.assertEqual(m.links[0].src, "s1")
        self.assertEqual(m.links[0].dst, "s1")
        self.assertEqual(m.links[0].port, "1")
        self.assertEqual(m.global_decl.reachability, [("s1", "s1")])


if __name__ == "__main__":
    unittest.main()
