import unittest
from pathlib import Path

from dslc.cli.common import find_default_p4b_bin
from dslc.utils.repo import repo_root


class TestCliCommon(unittest.TestCase):
    def test_find_default_p4b_bin_prefers_verify_backend(self) -> None:
        root = repo_root()
        prefer = root / "P4B-Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        vendored = root / "Procurator" / "argo" / "code" / "Translator" / "build-host" / "backends" / "verify" / "p4c-translator"
        legacy = root / "P4B-Translator" / "build-host" / "p4c-translator"
        vendored_legacy = root / "Procurator" / "argo" / "code" / "Translator" / "build-host" / "p4c-translator"

        p = find_default_p4b_bin()
        if prefer.exists():
            self.assertEqual(p, prefer)
            return
        if vendored.exists():
            self.assertEqual(p, vendored)
            return
        if legacy.exists():
            self.assertEqual(p, legacy)
            return
        if vendored_legacy.exists():
            self.assertEqual(p, vendored_legacy)
            return

        # If the host build isn't present, accept the docker wrapper (or None).
        docker = root / "dslc" / "toolchain" / "p4b_docker.sh"
        if docker.exists():
            self.assertIn(p, (docker, None))
        else:
            self.assertIsNone(p)


if __name__ == "__main__":
    unittest.main()
