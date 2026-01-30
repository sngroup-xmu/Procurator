from __future__ import annotations

import re
from pathlib import Path
from typing import List

from .wraparound_analyze import _is_mainprocedure_loop_header
from .wraparound_common import WraparoundTransformError, _RE_PROC_MAIN

def unroll_mainprocedure_loop_text(*, bpl_text: str, steps: int) -> str:
    if steps <= 0:
        return bpl_text

    lines = bpl_text.splitlines(keepends=True)
    no_nl_lines = [ln.rstrip("\n") for ln in lines]

    proc_idx = None
    for i, ln in enumerate(no_nl_lines):
        if _RE_PROC_MAIN.match(ln.strip()):
            proc_idx = i
            break
    if proc_idx is None:
        raise WraparoundTransformError("mainProcedure not found for unroll")

    body_open_idx = None
    for i in range(proc_idx, len(no_nl_lines)):
        if "{" in no_nl_lines[i]:
            body_open_idx = i
            break
    if body_open_idx is None:
        raise WraparoundTransformError("mainProcedure body not found for unroll")

    while_idx = None
    for i in range(body_open_idx + 1, len(no_nl_lines)):
        if _is_mainprocedure_loop_header(no_nl_lines[i]):
            while_idx = i
            break
    if while_idx is None:
        raise WraparoundTransformError(
            "mainProcedure loop not found for unroll (expected while(true) or while (procurator_step < ...))"
        )

    open_idx = None
    if "{" in no_nl_lines[while_idx]:
        open_idx = while_idx
    else:
        for i in range(while_idx + 1, len(no_nl_lines)):
            if "{" in no_nl_lines[i]:
                open_idx = i
                break
    if open_idx is None:
        raise WraparoundTransformError("failed to locate loop body start for unroll")

    depth = 0
    close_idx = None
    for i in range(open_idx, len(no_nl_lines)):
        for ch in no_nl_lines[i]:
            if ch == "{":
                depth += 1
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    close_idx = i
                    break
        if close_idx is not None:
            break
    if close_idx is None:
        raise WraparoundTransformError("failed to locate loop body end for unroll")

    body = lines[open_idx + 1 : close_idx]
    indent = re.match(r"^(\s*)", lines[while_idx]).group(1)  # type: ignore[union-attr]
    replacement: List[str] = [f"{indent}// UNROLLED {steps} steps (wraparound)\n"]
    replacement.extend(body * steps)

    lines[while_idx : close_idx + 1] = replacement
    return "".join(lines)


def unroll_mainprocedure_loop_file(*, in_path: Path, out_path: Path, steps: int) -> None:
    text = in_path.read_text(encoding="utf-8", errors="replace")
    out = unroll_mainprocedure_loop_text(bpl_text=text, steps=steps)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    if out_path.exists():
        old = out_path.read_text(encoding="utf-8", errors="replace")
        if old == out:
            return
    out_path.write_text(out, encoding="utf-8")
