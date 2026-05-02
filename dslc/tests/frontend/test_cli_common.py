import unittest
from pathlib import Path
from unittest import mock

from dslc.cli import compile as compile_cli
from dslc.cli import gemcutter as verify_cli
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

    def test_step_bounds_are_explicit_optional_cli_options(self) -> None:
        for mod in (compile_cli, verify_cli):
            with self.subTest(module=mod.__name__):
                with mock.patch("sys.stdout") as stdout:
                    with self.assertRaises(SystemExit) as cm:
                        mod.main(["--help"])
                self.assertEqual(cm.exception.code, 0)
                help_text = "".join(str(call.args[0]) for call in stdout.write.call_args_list if call.args)
                self.assertIn("--max-steps", help_text)
                self.assertIn("--use-spec-max-steps", help_text)
