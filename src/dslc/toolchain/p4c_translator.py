from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional


class P4CTranslatorError(RuntimeError):
    pass


@dataclass(frozen=True)
class P4CTranslatorResult:
    pml_path: Path
    type_pml_path: Path
    headers_json_path: Path
    field_mapping_path: Path


class P4CTranslator:
    """
    Wrapper for the repo-local p4c-translator (P4/JSON -> Promela).
    """

    def __init__(self, translator_bin: Path):
        self._bin = translator_bin

    def compile_to_promela(
        self,
        *,
        alias: str,
        input_path: Path,
        entries_path: Optional[Path],
        port_dst: Dict[str, str],
        out_dir: Path,
    ) -> P4CTranslatorResult:
        out_dir.mkdir(parents=True, exist_ok=True)
        pml_path = out_dir / f"{alias}.pml"

        empty_entries = out_dir / "empty_entries.txt"
        if entries_path is None:
            empty_entries.write_text("", encoding="utf-8")
            entries_path = empty_entries

        port_str = ",".join(f"{k}:{v}" for k, v in port_dst.items())
        from_json = ["--fromJSON"] if input_path.suffix == ".json" else []

        cmd = [
            str(self._bin),
            *from_json,
            str(input_path),
            "--switchID",
            alias,
            "--bmv2cmds",
            str(entries_path),
            "--port_dst",
            port_str if port_str else f"ALL:{alias}",
            "-o",
            str(pml_path),
        ]

        try:
            subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
        except FileNotFoundError as e:
            raise P4CTranslatorError(f"p4c-translator not found: {self._bin}") from e
        except subprocess.CalledProcessError as e:
            raise P4CTranslatorError(
                "p4c-translator failed:\n"
                f"cmd: {' '.join(cmd)}\n"
                f"exit: {e.returncode}\n"
                f"out:\n{e.stdout}"
            ) from e

        type_pml_path = out_dir / f"{alias}_type.pml"
        headers_json_path = out_dir / "headers.json"
        field_mapping_path = out_dir / "field_mapping.csv"
        return P4CTranslatorResult(
            pml_path=pml_path,
            type_pml_path=type_pml_path,
            headers_json_path=headers_json_path,
            field_mapping_path=field_mapping_path,
        )
