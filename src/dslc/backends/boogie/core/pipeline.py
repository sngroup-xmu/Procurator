from __future__ import annotations

import re
from dataclasses import dataclass
from typing import List, Optional


@dataclass(frozen=True)
class PipelineStages:
    ingress_lines: List[str]
    egress_lines: List[str]


_CALL_RE = re.compile(r"^\s*call\s+(?:[^:]*:=\s*)?([A-Za-z0-9_\.\$]+)\s*\(")


def _extract_call_target(line: str) -> Optional[str]:
    m = _CALL_RE.match(line)
    if not m:
        return None
    return m.group(1)


def _extract_procedure_body_lines(bpl: str, proc_name: str) -> Optional[List[str]]:
    proc_re = re.compile(
        rf"^\s*procedure(?:\s*\{{:[^}}]+\}}\s*)*\s+{re.escape(proc_name)}\b",
        re.MULTILINE,
    )
    m = proc_re.search(bpl)
    if not m:
        return None
    brace_start = bpl.find("{", m.end())
    if brace_start == -1:
        return None
    depth = 0
    body_start = None
    body_end = None
    for idx in range(brace_start, len(bpl)):
        ch = bpl[idx]
        if ch == "{":
            depth += 1
            if depth == 1:
                body_start = idx + 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                body_end = idx
                break
    if body_start is None or body_end is None:
        return None
    body = bpl[body_start:body_end]
    return body.splitlines()


def _normalize_body_lines(lines: List[str]) -> List[str]:
    if not lines:
        return []
    while lines and not lines[0].strip():
        lines.pop(0)
    while lines and not lines[-1].strip():
        lines.pop()
    if not lines:
        return []
    min_indent = None
    for line in lines:
        if not line.strip():
            continue
        indent = len(line) - len(line.lstrip(" "))
        if min_indent is None or indent < min_indent:
            min_indent = indent
    if min_indent is None:
        return lines
    return [line[min_indent:] if len(line) >= min_indent else line for line in lines]


def _first_egress_call_index(lines: List[str]) -> Optional[int]:
    for idx, line in enumerate(lines):
        callee = _extract_call_target(line)
        if not callee:
            continue
        if re.search(r"egress", callee, re.IGNORECASE):
            return idx
    return None


def split_pipeline_stages(prefixed_bpl: str, alias: str) -> Optional[PipelineStages]:
    main_name = f"{alias}_main"
    main_body = _extract_procedure_body_lines(prefixed_bpl, main_name)
    if not main_body:
        return None

    pipe_call_idx: Optional[int] = None
    pipe_callee: Optional[str] = None
    for idx, line in enumerate(main_body):
        callee = _extract_call_target(line)
        if not callee:
            continue
        if callee.startswith(f"{alias}_pipe"):
            pipe_call_idx = idx
            pipe_callee = callee
            break

    if pipe_callee:
        pipe_body = _extract_procedure_body_lines(prefixed_bpl, pipe_callee)
        if not pipe_body:
            return None
        split_idx = _first_egress_call_index(pipe_body)
        if split_idx is None:
            return None
        ingress_lines = list(main_body[:pipe_call_idx]) + list(pipe_body[:split_idx])
        egress_lines = list(pipe_body[split_idx:]) + list(main_body[pipe_call_idx + 1 :])
    else:
        split_idx = _first_egress_call_index(main_body)
        if split_idx is None:
            return None
        ingress_lines = list(main_body[:split_idx])
        egress_lines = list(main_body[split_idx:])

    ingress_lines = _normalize_body_lines(ingress_lines)
    egress_lines = _normalize_body_lines(egress_lines)
    if not ingress_lines and not egress_lines:
        return None
    return PipelineStages(ingress_lines=ingress_lines, egress_lines=egress_lines)
