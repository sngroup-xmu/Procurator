from __future__ import annotations

import os
import re
import subprocess
from pathlib import Path
from typing import List, Optional, Sequence

from .boogie_errors import P4BTranslatorError


class P4BTranslator:
    """
    Wrapper for a P4->Boogie translator (e.g., external P4B-Translator).

    IMPORTANT: The translator invoked here MUST output Boogie (.bpl).
    """

    def __init__(self, p4b_bin: str, *, include_paths: Optional[Sequence[str]] = None):
        self._p4b_bin = p4b_bin
        self._include_paths = _default_p4c_include_paths(p4b_bin) if include_paths is None else list(include_paths)

    def compile_to_bpl(
        self,
        p4_path: str,
        out_bpl: str,
        entries_path: Optional[str],
        out_meta: Optional[str] = None,
        slicing_vars: Optional[Sequence[str]] = None,
        disable_slicing: bool = False,
        keep_control_seeds: bool = True,
    ) -> None:
        def run(cmd: List[str]) -> None:
            try:
                subprocess.run(cmd, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            except FileNotFoundError as e:
                raise P4BTranslatorError(f"translator binary not found: {self._p4b_bin}") from e
            except subprocess.CalledProcessError as e:
                raise P4BTranslatorError(
                    "translation failed:\n"
                    f"cmd: {' '.join(cmd)}\n"
                    f"exit: {e.returncode}\n"
                    f"out:\n{e.stdout}"
                ) from e

        def build_cmd(*, use_goto: bool) -> List[str]:
            # NOTE: p4c-style compilers require -I paths to appear before the input file.
            cmd: List[str] = [self._p4b_bin]
            for inc in self._include_paths:
                cmd.extend(["-I", inc])
            if use_goto:
                cmd.extend(["--goto"])
            if disable_slicing:
                cmd.append("--no-slicing")
            elif not keep_control_seeds:
                # Let the caller (dslc) decide which control variables matter for the property/topology.
                cmd.append("--no-slicing-control-seeds")
            if p4_path.endswith(".json"):
                cmd.extend(["--fromJSON", p4_path])
            else:
                cmd.append(p4_path)
            cmd.extend(["-o", out_bpl])
            if out_meta:
                cmd.extend(["--meta-out", out_meta])
            if entries_path:
                cmd.extend(["--bmv2cmds", entries_path])
            if slicing_vars and not disable_slicing:
                cmd.append("--slicing-vars=" + ",".join(slicing_vars))
            return cmd

        cmd = build_cmd(use_goto=True)
        run(cmd)

        # Correctness guardrail: sliced Boogie must be well-formed.
        #
        # If slicing keeps a `.read/.write` call, the corresponding register var
        # and helper decls must also be present. Otherwise downstream tools fail
        # with confusing type errors. We treat this as a translator bug and fail
        # fast (no silent fallback to unsliced programs).
        if not disable_slicing:
            bad = _detect_missing_read_write_decls(Path(out_bpl))
            if bad:
                raise P4BTranslatorError(
                    "P4B slicing produced invalid Boogie (dangling `.read/.write` without decls).\n"
                    "This indicates a translator/slicer bug; refusing to continue.\n"
                    f"missing bases: {', '.join(bad)}\n"
                    f"out_bpl: {out_bpl}\n"
                    "You may temporarily re-run with `disable_slicing=True` to debug, but\n"
                    "the recommended fix is to repair the translator so slicing preserves\n"
                    "the required register declarations."
                )


def _default_p4c_include_paths(p4b_bin: str) -> List[str]:
    """
    Determine a best-effort list of include directories for p4c-style preprocessors.

    Sources (in priority order):
      1) $P4C_INCLUDE_PATH (split by os.pathsep)
      2) Auto-detect a `p4include/` directory by walking up from the p4b_bin path.
    """
    out: List[str] = []

    env = os.getenv("P4C_INCLUDE_PATH", "")
    if env:
        for p in env.split(os.pathsep):
            p = p.strip()
            if not p:
                continue
            if Path(p).is_dir():
                out.append(str(Path(p)))

    bin_path = Path(p4b_bin).expanduser().resolve()
    for parent in [bin_path.parent, *bin_path.parents]:
        cand = parent / "p4include"
        if cand.is_dir():
            out.append(str(cand))
            break

    seen = set()
    dedup: List[str] = []
    for p in out:
        if p not in seen:
            seen.add(p)
            dedup.append(p)
    return dedup


_RE_READ_CALL = re.compile(r"\b(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.read\(\s*(?P=base)\s*,")
_RE_WRITE_CALL = re.compile(r"\bcall\s+(?P<base>[A-Za-z_][A-Za-z0-9_]*)\.write\(")
_RE_VAR_DECL = re.compile(r"^\s*var\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s*:", re.MULTILINE)
_RE_FUNC_DECL = re.compile(r"^\s*function\b.*\b(?P<name>[A-Za-z_][A-Za-z0-9_]*)\.read\b", re.MULTILINE)
# Allow optional Boogie attributes between `procedure` and the name, e.g.:
#   procedure {:inline 1} sequence_reg.write(...)
_RE_PROC_DECL = re.compile(
    r"^\s*procedure(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\.write\b",
    re.MULTILINE,
)


def _detect_missing_read_write_decls(bpl_path: Path) -> List[str]:
    """
    Heuristic sanity check for sliced Boogie output.

    Returns a list of base names that appear in `.read/.write` calls but do not
    have corresponding declarations in the file.
    """
    try:
        text = bpl_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return []

    bases: set[str] = set()
    bases.update(m.group("base") for m in _RE_READ_CALL.finditer(text))
    bases.update(m.group("base") for m in _RE_WRITE_CALL.finditer(text))
    if not bases:
        return []

    declared_vars = {m.group("name") for m in _RE_VAR_DECL.finditer(text)}
    declared_reads = {m.group("name") for m in _RE_FUNC_DECL.finditer(text)}
    declared_writes = {m.group("name") for m in _RE_PROC_DECL.finditer(text)}

    missing: List[str] = []
    for b in sorted(bases):
        # Most `.read` calls are on arrays; require both the array var and its helper decls.
        if b not in declared_vars or b not in declared_reads or b not in declared_writes:
            missing.append(b)
    return missing
