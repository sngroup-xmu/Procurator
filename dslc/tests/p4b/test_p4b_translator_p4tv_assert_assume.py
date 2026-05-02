import subprocess
import tempfile
import unittest
from pathlib import Path


class TestP4BTranslatorP4TVAssertAssume(unittest.TestCase):
    def _p4b_bin(self, repo_root: Path) -> Path:
        candidates = [
            repo_root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator",
            repo_root / "P4B-Translator" / "build-host" / "p4c-translator",
        ]
        for p in candidates:
            if p.exists():
                return p
        return candidates[0]

    def test_bracket_assert_assume_emits_boogie(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4include.is_dir():
            self.skipTest("missing p4include")

        # Minimal v1model program exercising p4tv-style bracket annotations.
        p4_text = """\
#include <core.p4>
#include <v1model.p4>

header H { bit<8> f; }
struct Headers { H h; }
struct Metadata { bool b; }

parser P(packet_in packet, out Headers hdr, inout Metadata meta, inout standard_metadata_t sm) {
  state start { transition accept; }
}

control MyVerifyChecksum(inout Headers hdr, inout Metadata meta) { apply { } }
control MyComputeChecksum(inout Headers hdr, inout Metadata meta) { apply { } }
control MyEgress(inout Headers hdr, inout Metadata meta, inout standard_metadata_t sm) { apply { } }
control MyDeparser(packet_out packet, in Headers hdr) { apply { } }

control MyIngress(inout Headers hdr, inout Metadata meta, inout standard_metadata_t sm) {
  apply {
    @assume[meta.b] {}
    @assert[false] {}
  }
}

V1Switch(P(), MyVerifyChecksum(), MyIngress(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
"""

        with tempfile.TemporaryDirectory() as td:
            p4 = Path(td) / "p4tv_assert_assume.p4"
            out_bpl = Path(td) / "out.bpl"
            p4.write_text(p4_text, encoding="utf-8")

            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)

            bpl = out_bpl.read_text(encoding="utf-8", errors="replace")

            # Ensure the translator no longer drops p4tv-style assertions/assumptions
            # (previously leading to vacuous SAFE results).
            self.assertRegex(bpl, r"\bassume\b\s+meta\.b\s*;")
            self.assertRegex(bpl, r"\bassert\b\s*\(?\s*false\s*\)?\s*;")

    def test_bracket_assert_in_quoted_include_is_sanitized_outside_source_tree(self) -> None:
        repo_root = next(p for p in Path(__file__).resolve().parents if (p / "Procurator").exists())
        p4b_bin = self._p4b_bin(repo_root)
        if not p4b_bin.exists():
            self.skipTest("P4B-Translator not built (missing build-host/p4c-translator)")

        p4include = repo_root / "P4B-Translator" / "p4include"
        if not p4include.is_dir():
            self.skipTest("missing p4include")

        with tempfile.TemporaryDirectory() as td:
            root = Path(td)
            inc_dir = root / "inc"
            inc_dir.mkdir()
            included = inc_dir / "assertion.p4"
            included.write_text(
                """\
control Included(inout Headers hdr, inout Metadata meta, inout standard_metadata_t sm) {
  apply {
    @assert[meta.b] {}
  }
}
""",
                encoding="utf-8",
            )
            p4 = root / "main.p4"
            out_bpl = root / "out.bpl"
            p4.write_text(
                """\
#include <core.p4>
#include <v1model.p4>

header H { bit<8> f; }
struct Headers { H h; }
struct Metadata { bool b; }

#include "inc/assertion.p4"

parser P(packet_in packet, out Headers hdr, inout Metadata meta, inout standard_metadata_t sm) {
  state start { transition accept; }
}

control MyVerifyChecksum(inout Headers hdr, inout Metadata meta) { apply { } }
control MyComputeChecksum(inout Headers hdr, inout Metadata meta) { apply { } }
control MyEgress(inout Headers hdr, inout Metadata meta, inout standard_metadata_t sm) { apply { } }
control MyDeparser(packet_out packet, in Headers hdr) { apply { } }
V1Switch(P(), MyVerifyChecksum(), Included(), MyEgress(), MyComputeChecksum(), MyDeparser()) main;
""",
                encoding="utf-8",
            )

            before = set(root.rglob(".p4b_sanitized_*.p4"))
            cmd = [
                str(p4b_bin),
                "-I",
                str(p4include),
                "--goto",
                "-o",
                str(out_bpl),
                str(p4),
            ]
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            after = set(root.rglob(".p4b_sanitized_*.p4"))
            bpl = out_bpl.read_text(encoding="utf-8", errors="replace")

            self.assertEqual(after, before)
            self.assertRegex(bpl, r"\bassert\b\s+meta\.b\s*;")
