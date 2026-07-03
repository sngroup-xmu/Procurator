from __future__ import annotations

import json
import re
import hashlib
import copy
from pathlib import Path
from typing import Callable, Dict, List, Optional, Sequence, Tuple

from dslc.analysis.boogie_bv_eval import BvValue, bv_width, eval_bv_expr
from dslc.toolchain.ultimate_runner import UltimateRunResult, run_ultimate
from dslc.transform.focused_direct import find_focused_direct_assert_lines, focus_dynamic_index0_register_assert
from dslc.transform.wraparound_analyze import _is_mainprocedure_loop_header
from dslc.transform.wraparound_unroll import unroll_mainprocedure_loop_text


UltimateRunner = Callable[..., UltimateRunResult]
Optimizer = Callable[[Path], None]
Emitter = Callable[[str], None]
_FOCUSED_REPLAY_MAX_DEPTH = 128
_FOCUSED_REPLAY_MAX_STEPS = 1000000


_RE_PROC_MAIN = re.compile(r"^\s*procedure(?:\s*\{[^}]*\}\s*)?\s+mainProcedure\s*\(")
_RE_PROC_DECL = re.compile(r"^\s*procedure(?:\s*\{[^}]*\}\s*)?\s+(?P<name>[^\s(]+)\s*\(")
_RE_PROC_SIGNATURE = re.compile(
    r"^\s*procedure(?:\s*\{[^}]*\}\s*)?\s+(?P<name>[^\s(]+)\s*"
    r"\((?P<params>[^)]*)\)\s*(?:returns\s*\((?P<returns>[^)]*)\))?"
)
_RE_PROC_SCHED_PHASE = re.compile(r"\bprocurator_phase\s*==\s*(\d+)\b")
_RE_CALL_STMT = re.compile(r"\bcall\s+([^\s(;]+)\s*\(")
_RE_ATTR = re.compile(r"\{:[^}]*\}")
_RE_ASSUME_EQ = re.compile(
    r"^\s*assume\s*\(\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>[^)]+)\)\s*;\s*$"
)
_RE_HAVOC = re.compile(r"^(?P<indent>\s*)havoc\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_WSL_MNT = re.compile(r"^/mnt/(?P<drive>[a-zA-Z])/(?P<rest>.*)$")
_RE_WIN_DRIVE = re.compile(r"^(?P<drive>[a-zA-Z]):[\\/](?P<rest>.*)$")
_RE_VAR_DECL = re.compile(r"^\s*var\s+(?P<name>\S+)\s*:\s*(?P<type>[^;]+);\s*$")
_RE_TYPE_ALIAS = re.compile(
    r"^\s*type(?:\s*\{[^}]*\}\s*)?\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*=\s*(?P<type>[^;]+);\s*$"
)
_RE_ARRAY_TYPE = re.compile(r"^\[(?P<idx>[^\]]+)\](?P<val>.+)$")
_RE_REG_ARRAY_TYPE = re.compile(r"^\[(?P<idx>bv\d+)\](?P<val>bv\d+)$")
_RE_SLOT_INIT = re.compile(
    r"^\s*assume\s+(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<slot>\d+bv\d+)\]\s*==\s*(?P<value>\d+bv\d+)\s*;\s*$"
)
_RE_FORALL_ZERO_INIT = re.compile(
    r"^\s*assume\s*\(\s*forall\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s*bv\d+\s*::\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\s*\[\s*[A-Za-z_][A-Za-z0-9_]*\s*\]\s*==\s*(?P<value>\d+bv\d+)\s*\)\s*;\s*$"
)
_RE_SLOT_READ = re.compile(
    r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<slot>\d+bv\d+)\]\s*;\s*$"
)
_RE_EXTERN_READ_ASSIGN = re.compile(
    r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*"
    r"(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\.read\s*\(\s*(?P<reg_arg>[A-Za-z_][A-Za-z0-9_.]*)\s*,\s*(?P<idx>.+)\)\s*;\s*$"
)
_RE_SLOT_WRITE = re.compile(
    r"^\s*(?P<reg>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<slot>\d+bv\d+)\]\s*:=\s*(?P<rhs>.+)\s*;\s*$"
)
_RE_PROCURATOR_BAD_LATCH = re.compile(
    r"^\s*if\s*\(!\((?P<expr>.+)\)\)\s*\{\s*procurator_bad\s*:=\s*true\s*;\s*\}\s*$"
)
_RE_LATCH_TRUE = re.compile(r"^\s*if\s*\(!\(false\)\)\s*\{\s*procurator_focused_underapprox_hit\s*:=\s*true\s*;\s*\}\s*$")
_RE_LATCH_COND = re.compile(
    r"^\s*if\s*\(!\((?P<expr>.+)\)\)\s*\{\s*procurator_focused_underapprox_hit\s*:=\s*true\s*;\s*\}\s*$"
)
_RE_BV_LIT = re.compile(r"^(?P<value>\d+)bv(?P<width>\d+)$")
_RE_CALL_VOID = re.compile(r"^\s*call\s+(?P<callee>[A-Za-z_][A-Za-z0-9_.]*)\s*\((?P<args>[^;]*)\)\s*;\s*$")
_RE_CALL_ASSIGN = re.compile(
    r"^\s*call\s+(?P<lhs>.+?)\s*:=\s*(?P<callee>[A-Za-z_][A-Za-z0-9_.]*)\s*\((?P<args>[^;]*)\)\s*;\s*$"
)
_RE_GOTO = re.compile(r"^\s*goto\s+(?P<labels>[^;]+)\s*;\s*$")
_RE_LABEL = re.compile(r"^\s*[A-Za-z_][A-Za-z0-9_.$]*\s*:\s*$")
_RE_SIMPLE_ASSIGN = re.compile(
    r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>.+)\s*;\s*$"
)
_RE_BOOL_ASSIGN = re.compile(
    r"^\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*:=\s*(?P<rhs>true|false)\s*;\s*$"
)
_RE_ASSUME = re.compile(r"^\s*assume\b\s*(?P<expr>.+)\s*;\s*$")
_RE_ASSERT = re.compile(r"^\s*assert\b\s*(?P<expr>.+)\s*;\s*$")


def _resolve_artifact_path(path_str: str, *, base_dir: Path) -> Optional[Path]:
    raw = str(path_str or "").strip()
    if not raw:
        return None

    cand = Path(raw)
    if cand.is_absolute() and cand.exists():
        return cand

    if not cand.is_absolute():
        rel = (base_dir / cand).resolve()
        if rel.exists():
            return rel

    m_wsl = _RE_WSL_MNT.match(raw.replace("\\", "/"))
    if m_wsl:
        drive = m_wsl.group("drive").upper()
        rest = m_wsl.group("rest")
        win_cand = Path(f"{drive}:/{rest}")
        if win_cand.exists():
            return win_cand

    m_win = _RE_WIN_DRIVE.match(raw)
    if m_win:
        drive = m_win.group("drive").lower()
        rest = m_win.group("rest").replace("\\", "/")
        wsl_cand = Path(f"/mnt/{drive}/{rest}")
        if wsl_cand.exists():
            return wsl_cand

    return None


def _extract_phase0_eq_assumes_from_near_wrap_bpl(text: str) -> List[str]:
    """
    Extract equality assumptions from the inlined `phase 0` env-injection block.

    These assumptions are replay hints (UNSAFE-only under-approximation) and are
    therefore intentionally syntactic and conservative.
    """

    out: List[str] = []
    seen: set[str] = set()
    in_phase0 = False
    for raw in text.splitlines():
        s = raw.strip()
        if "wraparound inlined phase 0" in s:
            in_phase0 = True
            continue
        if in_phase0 and "wraparound inlined phase 1" in s:
            break
        if not in_phase0:
            continue
        m = _RE_ASSUME_EQ.match(raw)
        if not m:
            continue
        expr = f"{m.group('lhs')} == {m.group('rhs').strip()}"
        if expr in seen:
            continue
        seen.add(expr)
        out.append(expr)
        # Keep replay hints compact to avoid over-constraining to accidental noise.
        if len(out) >= 96:
            break
    return out


def _near_wrap_unsafe_confirm_bpl_from_manifest(*, manifest_path: Path, pump_reg: str) -> Optional[Path]:
    try:
        data = json.loads(manifest_path.read_text(encoding="utf-8"))
    except Exception:
        return None

    cand = data.get("candidate") or {}
    if str(cand.get("pump_reg") or "") != str(pump_reg or ""):
        return None

    attempts = data.get("attempts") or []
    if not isinstance(attempts, list):
        return None

    for attempt in attempts:
        if not isinstance(attempt, dict):
            continue
        near = attempt.get("near_wrap") or attempt.get("confirm") or {}
        if not isinstance(near, dict):
            continue
        line = str(near.get("result_line") or "").lower()
        if "unsafe" not in line and "incorrect" not in line:
            continue
        artifacts = attempt.get("artifacts") or {}
        if not isinstance(artifacts, dict):
            continue
        confirm_bpl = artifacts.get("confirm_bpl")
        if not isinstance(confirm_bpl, str):
            continue
        resolved = _resolve_artifact_path(confirm_bpl, base_dir=manifest_path.parent)
        if resolved is not None and resolved.exists():
            return resolved
    return None


def _collect_replay_assumes_from_recent_manifests(
    *,
    spec_runs_dir: Path,
    current_run_dir: Path,
    pump_reg: str,
) -> Tuple[List[str], Optional[Path]]:
    """
    Mine replay assumptions from recent near-wrap UNSAFE artifacts for the same pump reg.

    Returns (`assumes`, `manifest_path_used`).
    """

    try:
        run_dirs = [p for p in spec_runs_dir.iterdir() if p.is_dir()]
    except Exception:
        return ([], None)

    run_dirs.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    cur_resolved = current_run_dir.resolve()

    for run_dir in run_dirs:
        try:
            if run_dir.resolve() == cur_resolved:
                continue
        except Exception:
            continue
        manifest_paths = sorted(run_dir.glob("wraparound/target.*/wraparound.cegis.manifest.json"))
        for manifest_path in manifest_paths:
            confirm_bpl = _near_wrap_unsafe_confirm_bpl_from_manifest(
                manifest_path=manifest_path,
                pump_reg=pump_reg,
            )
            if confirm_bpl is None:
                continue
            try:
                txt = confirm_bpl.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue
            assumes = _extract_phase0_eq_assumes_from_near_wrap_bpl(txt)
            if assumes:
                return (assumes, manifest_path)
    return ([], None)


def _inject_replay_assumes_after_havoc(*, bpl_text: str, assumes: Sequence[str]) -> Tuple[str, int]:
    """
    Inject replay assumptions immediately after matching `havoc` statements.

    Soundness note: this is an under-approximation used only for UNSAFE bug finding.
    SAFE/UNKNOWN/TIMEOUT outcomes always fall back to the original model.
    """

    # Keep one equality per variable to avoid accidental contradictions.
    per_var: dict[str, str] = {}
    for a in assumes:
        m = _RE_ASSUME_EQ.match(f"assume ({a});")
        if not m:
            continue
        lhs = m.group("lhs").strip()
        rhs = m.group("rhs").strip()
        if lhs not in per_var:
            per_var[lhs] = f"{lhs} == {rhs}"
    if not per_var:
        return (bpl_text, 0)

    out: List[str] = []
    injected = 0
    for raw in bpl_text.splitlines(keepends=True):
        out.append(raw)
        m = _RE_HAVOC.match(raw.rstrip("\n"))
        if not m:
            continue
        indent = m.group("indent")
        vars_part = m.group("vars")
        vars_list = [v.strip() for v in vars_part.split(",") if v.strip()]
        for v in vars_list:
            expr = per_var.get(v)
            if not expr:
                continue
            out.append(f"{indent}assume ({expr});\n")
            injected += 1
    return ("".join(out), injected)


def _parse_bv_width(lit: Optional[str]) -> Optional[int]:
    if not lit:
        return None
    m = re.fullmatch(r"\d+bv(\d+)", lit.strip())
    if not m:
        return None
    try:
        width = int(m.group(1))
    except Exception:
        return None
    return width if width > 0 else None


def _infer_scheduler_period_from_text(text: str) -> int:
    phases: set[int] = set()
    for m in _RE_PROC_SCHED_PHASE.finditer(text):
        try:
            phases.add(int(m.group(1)))
        except Exception:
            continue
    if not phases:
        return 1
    return max(1, max(phases) + 1)


def _find_mainprocedure_span(lines: Sequence[str]) -> Optional[Tuple[int, int]]:
    proc_idx: Optional[int] = None
    for i, raw in enumerate(lines):
        if _RE_PROC_MAIN.match(raw):
            proc_idx = i
            break
    if proc_idx is None:
        return None

    body_open_idx: Optional[int] = None
    for i in range(proc_idx, len(lines)):
        if "{" in _RE_ATTR.sub("", lines[i]):
            body_open_idx = i
            break
    if body_open_idx is None:
        return None

    depth = 0
    close_idx: Optional[int] = None
    for i in range(body_open_idx, len(lines)):
        line = _RE_ATTR.sub("", lines[i])
        for ch in line:
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
        return None
    return body_open_idx, close_idx


def _mainprocedure_has_scheduler_loop(lines: Sequence[str]) -> bool:
    span = _find_mainprocedure_span(lines)
    if span is None:
        return False
    body_open_idx, close_idx = span
    for i in range(body_open_idx + 1, close_idx):
        if _is_mainprocedure_loop_header(lines[i]):
            return True
    return False


def _collect_procedure_definitions(lines: Sequence[str]) -> List[Tuple[str, int, int, int]]:
    defs: List[Tuple[str, int, int, int]] = []
    i = 0
    n = len(lines)
    while i < n:
        m = _RE_PROC_DECL.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group(1)

        body_open_idx: Optional[int] = None
        j = i
        while j < n:
            line = lines[j]
            line_wo_attr = _RE_ATTR.sub("", line)
            if "{" in line_wo_attr:
                body_open_idx = j
                break
            if j > i and (
                _RE_PROC_DECL.match(line)
                or line.lstrip().startswith("function ")
                or line.lstrip().startswith("axiom ")
            ):
                break
            j += 1
        if body_open_idx is None:
            i += 1
            continue

        depth = 0
        body_close_idx: Optional[int] = None
        j = body_open_idx
        while j < n:
            line = _RE_ATTR.sub("", lines[j])
            for ch in line:
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        body_close_idx = j
                        break
            if body_close_idx is not None:
                break
            j += 1
        if body_close_idx is None:
            break

        defs.append((name, i, body_open_idx, body_close_idx))
        i = body_close_idx + 1
    return defs


def _procedure_for_body_line(
    defs: Sequence[Tuple[str, int, int, int]],
    line_idx0: int,
) -> Optional[str]:
    for name, _start, body_open, body_close in defs:
        if body_open <= line_idx0 <= body_close:
            return name
    return None


def _collect_procedure_calls(
    lines: Sequence[str],
    defs: Sequence[Tuple[str, int, int, int]],
) -> dict[str, set[str]]:
    call_map: dict[str, set[str]] = {}
    for name, _start, body_open, body_close in defs:
        callees: set[str] = set()
        for i in range(body_open + 1, body_close):
            for m in _RE_CALL_STMT.finditer(lines[i]):
                callee = m.group(1).strip()
                if callee:
                    callees.add(callee)
        call_map[name] = callees
    return call_map


def _expand_modifies_targets_with_callers(
    targets: Sequence[str],
    call_map: dict[str, set[str]],
) -> set[str]:
    wanted = {t for t in targets if t}
    if not wanted:
        return set()

    reverse: dict[str, set[str]] = {}
    for caller, callees in call_map.items():
        for callee in callees:
            reverse.setdefault(callee, set()).add(caller)

    queue = list(wanted)
    while queue:
        cur = queue.pop(0)
        for caller in reverse.get(cur, set()):
            if caller not in wanted:
                wanted.add(caller)
                queue.append(caller)
    return wanted


def _ensure_var_in_modifies_for_procedures(
    *,
    text: str,
    var_name: str,
    procedure_names: Sequence[str],
) -> str:
    targets = {p for p in procedure_names if p}
    if not targets:
        return text

    lines = text.splitlines(keepends=True)
    defs = _collect_procedure_definitions([ln.rstrip("\n") for ln in lines])
    if not defs:
        return text

    for name, start, body_open, _body_close in reversed(defs):
        if name not in targets:
            continue

        modify_start: Optional[int] = None
        for i in range(start, body_open + 1):
            if re.search(r"\bmodifies\b", lines[i]):
                modify_start = i
                break

        if modify_start is None:
            lines.insert(body_open, f"  modifies {var_name};\n")
            continue

        modify_end: Optional[int] = None
        for j in range(modify_start, body_open + 1):
            if ";" in lines[j]:
                modify_end = j
                break
        if modify_end is None:
            continue

        seg = "".join(lines[modify_start : modify_end + 1])
        if re.search(rf"(?<![\w$.]){re.escape(var_name)}(?![\w$.])", seg):
            continue
        lines[modify_end] = lines[modify_end].replace(";", f", {var_name};", 1)

    return "".join(lines)


def _inject_focus_latch_and_unroll(
    *,
    focused_text: str,
    assert_lines: Sequence[int],
    steps: int,
    target_reg: Optional[str] = None,
    target_value: Optional[str] = None,
    slot_literal: Optional[str] = None,
    target_old_value: Optional[str] = None,
) -> Optional[str]:
    lines = focused_text.splitlines(keepends=True)
    if not lines:
        return None

    focus_var = "procurator_focused_underapprox_hit"
    for i, raw in enumerate(lines):
        if raw.strip().startswith(f"var {focus_var}:"):
            focus_var = f"{focus_var}_1"
            break

    # Replace focused failure sites with a latch assignment.
    # This keeps UNSAFE witnesses sound: whenever the latch becomes true, the
    # original program would have hit an `assert false;` at that point.
    line_set = {int(v) for v in assert_lines if int(v) > 0}
    if not line_set:
        return None
    touched_procs: set[str] = set()
    defs = _collect_procedure_definitions([ln.rstrip("\n") for ln in lines])
    max_idx = len(lines)
    replaced = 0
    out: List[str] = []
    i = 1
    while i <= max_idx:
        raw = lines[i - 1]
        stripped = raw.strip()
        if i in line_set and stripped.startswith("assert ") and stripped.endswith(";"):
            indent = raw[: len(raw) - len(raw.lstrip())]
            expr = stripped[len("assert ") : -1].strip()
            if not expr:
                return None
            if (
                expr == "false"
                and target_reg is not None
                and target_value is not None
                and slot_literal is not None
            ):
                parts = [
                    f"{target_reg}__wrote_any",
                    f"{target_reg}__last_index == {slot_literal}",
                ]
                if target_old_value is not None:
                    parts.append(f"{target_reg}__last_old_value == {target_old_value}")
                parts.append(f"{target_reg}__last_value == {target_value}")
                expr = "!(" + " && ".join(parts) + ")"
            out.append(f"{indent}if (!({expr})) {{ {focus_var} := true; }}\n")
            proc_name = _procedure_for_body_line(defs, i - 1)
            if proc_name:
                touched_procs.add(proc_name)
            replaced += 1
            # Old focused prepass sites may keep `assume false` immediately after
            # an injected `assert false;`. Skip that postcondition once the site is
            # rewritten into a latch assignment.
            if i < max_idx and lines[i].strip() == "assume false;":
                i += 2
                continue
        else:
            out.append(raw)
        i += 1
    if replaced <= 0:
        return None
    lines = out

    # Declare the latch variable before procedures/functions/axioms.
    insert_decl_idx = None
    for idx, raw in enumerate(lines):
        stripped = raw.strip()
        if stripped.startswith("procedure ") or stripped.startswith("function ") or stripped.startswith("axiom "):
            insert_decl_idx = idx
            break
    if insert_decl_idx is None:
        return None
    lines.insert(insert_decl_idx, f"var {focus_var}: bool;\n")

    # Initialize latch at mainProcedure entry.
    span = _find_mainprocedure_span([ln.rstrip("\n") for ln in lines])
    if span is None:
        return None
    body_open_idx, _ = span
    lines.insert(body_open_idx + 1, f"  {focus_var} := false;\n")
    touched_procs.add("mainProcedure")
    txt = "".join(lines)

    # Unroll into a bounded acyclic body so the focused probe can hit long
    # prefixes without requiring loop invariants. Some callers already compile
    # a bounded/unrolled mainProcedure via `--max-steps`; in that case, keep the
    # existing acyclic body and only add the latch assertion below.
    try:
        txt = unroll_mainprocedure_loop_text(bpl_text=txt, steps=max(1, int(steps)))
    except Exception:
        no_nl = [ln.rstrip("\n") for ln in txt.splitlines()]
        if _find_mainprocedure_span(no_nl) is None or _mainprocedure_has_scheduler_loop(no_nl):
            return None

    lines = txt.splitlines(keepends=True)
    span = _find_mainprocedure_span([ln.rstrip("\n") for ln in lines])
    if span is None:
        return None
    _, close_idx = span
    lines.insert(close_idx, f"  assert !{focus_var};\n")
    txt = "".join(lines)
    lines_no_nl = [ln.rstrip("\n") for ln in txt.splitlines()]
    defs = _collect_procedure_definitions(lines_no_nl)
    call_map = _collect_procedure_calls(lines_no_nl, defs)
    closure_targets = _expand_modifies_targets_with_callers(tuple(sorted(touched_procs)), call_map)
    txt = _ensure_var_in_modifies_for_procedures(
        text=txt,
        var_name=focus_var,
        procedure_names=tuple(sorted(closure_targets)),
    )
    return txt


def _find_focus_latch_assert_line(text: str) -> Optional[int]:
    for i, raw in enumerate(text.splitlines(), start=1):
        if re.fullmatch(r"assert !procurator_focused_underapprox_hit(?:_\d+)?;", raw.strip()):
            return i
    return None


def _resolve_type_alias(typ: str, aliases: Dict[str, str]) -> str:
    typ = typ.strip()
    m_array = _RE_ARRAY_TYPE.match(typ)
    if m_array:
        idx = _resolve_type_alias(m_array.group("idx"), aliases)
        val = _resolve_type_alias(m_array.group("val"), aliases)
        return f"[{idx}]{val}"

    seen: set[str] = set()
    while typ in aliases and typ not in seen:
        seen.add(typ)
        typ = aliases[typ].strip()
    return typ


def _parse_typed_decl_list(decls: str, aliases: Dict[str, str]) -> List[Tuple[str, str]]:
    out: List[Tuple[str, str]] = []
    for part in _split_args_top(decls or "") or []:
        clean = _RE_ATTR.sub("", part).strip()
        if not clean or ":" not in clean:
            continue
        name, typ = clean.split(":", 1)
        name = name.strip()
        if not name:
            continue
        out.append((name, _resolve_type_alias(typ, aliases)))
    return out


def _parse_type_aliases(text: str) -> Dict[str, str]:
    aliases: Dict[str, str] = {}
    for raw in text.splitlines():
        m = _RE_TYPE_ALIAS.match(raw)
        if m:
            aliases[m.group("name")] = _resolve_type_alias(m.group("type"), aliases)
    return aliases


def _parse_var_types(text: str) -> Dict[str, str]:
    aliases = _parse_type_aliases(text)
    out: Dict[str, str] = {}
    for raw in text.splitlines():
        m = _RE_VAR_DECL.match(raw)
        if m:
            out[m.group("name")] = _resolve_type_alias(m.group("type"), aliases)
            continue
        m_proc = _RE_PROC_SIGNATURE.match(raw)
        if m_proc:
            for name, typ in _parse_typed_decl_list(m_proc.group("params") or "", aliases):
                out.setdefault(name, typ)
            for name, typ in _parse_typed_decl_list(m_proc.group("returns") or "", aliases):
                out.setdefault(name, typ)
    return out


def _procedure_signatures(text: str) -> Dict[str, Tuple[Tuple[str, ...], Tuple[str, ...]]]:
    aliases = _parse_type_aliases(text)
    out: Dict[str, Tuple[Tuple[str, ...], Tuple[str, ...]]] = {}
    for raw in text.splitlines():
        m = _RE_PROC_SIGNATURE.match(raw)
        if not m:
            continue
        params = tuple(name for name, _typ in _parse_typed_decl_list(m.group("params") or "", aliases))
        returns = tuple(name for name, _typ in _parse_typed_decl_list(m.group("returns") or "", aliases))
        out[m.group("name")] = (params, returns)
    return out


def _procedure_type_scopes(text: str) -> Dict[str, Dict[str, str]]:
    aliases = _parse_type_aliases(text)
    out: Dict[str, Dict[str, str]] = {}
    for raw in text.splitlines():
        m = _RE_PROC_SIGNATURE.match(raw)
        if not m:
            continue
        scope = out.setdefault(m.group("name"), {})
        for name, typ in _parse_typed_decl_list(m.group("params") or "", aliases):
            scope[name] = typ
        for name, typ in _parse_typed_decl_list(m.group("returns") or "", aliases):
            scope[name] = typ

    for name, body in _procedure_bodies(text).items():
        scope = out.setdefault(name, {})
        for raw in body:
            m = _RE_VAR_DECL.match(raw)
            if m:
                scope[m.group("name")] = _resolve_type_alias(m.group("type"), aliases)
    return out


def _bv_literal_value(lit: str) -> Optional[BvValue]:
    m = _RE_BV_LIT.match(lit.strip())
    if not m:
        return None
    return BvValue(int(m.group("value")), int(m.group("width"))).masked()


def _procedure_bodies(text: str) -> Dict[str, List[str]]:
    lines = text.splitlines()
    out: Dict[str, List[str]] = {}
    i = 0
    while i < len(lines):
        m = _RE_PROC_DECL.match(lines[i])
        if not m:
            i += 1
            continue
        name = m.group("name")
        open_idx: Optional[int] = None
        j = i
        while j < len(lines):
            if "{" in _RE_ATTR.sub("", lines[j]):
                open_idx = j
                break
            if j > i and _RE_PROC_DECL.match(lines[j]):
                break
            j += 1
        if open_idx is None:
            i += 1
            continue
        depth = 0
        close_idx: Optional[int] = None
        for j in range(open_idx, len(lines)):
            for ch in _RE_ATTR.sub("", lines[j]):
                if ch == "{":
                    depth += 1
                elif ch == "}":
                    depth -= 1
                    if depth == 0:
                        close_idx = j
                        break
            if close_idx is not None:
                break
        if close_idx is None:
            break
        out[name] = lines[open_idx + 1 : close_idx]
        i = close_idx + 1
    return out


def _strip_inline_attributes(line: str) -> str:
    return _RE_ATTR.sub("", line)


def _split_block_lines_with_tail(lines: Sequence[str], start: int) -> Tuple[List[str], int, str]:
    body: List[str] = []
    depth = 0
    opened = False
    i = start
    while i < len(lines):
        raw = lines[i]
        clean = _strip_inline_attributes(raw)
        line_body = raw
        if not opened:
            brace = clean.find("{")
            if brace < 0:
                i += 1
                continue
            opened = True
            depth = 1
            raw_brace = raw.find("{")
            line_body = raw[raw_brace + 1 :]
        j = 0
        segment = ""
        while j < len(line_body):
            ch = line_body[j]
            if ch == "{":
                depth += 1
                segment += ch
            elif ch == "}":
                depth -= 1
                if depth == 0:
                    if segment.strip():
                        body.append(segment)
                    return body, i + 1, line_body[j + 1 :].strip()
                segment += ch
            else:
                segment += ch
            j += 1
        if segment.strip():
            body.append(segment)
        i += 1
    return body, len(lines), ""


def _split_block_lines(lines: Sequence[str], start: int) -> Tuple[List[str], int]:
    body, next_i, _tail = _split_block_lines_with_tail(lines, start)
    return body, next_i


def _else_chain_branches(
    lines: Sequence[str],
    *,
    next_i: int,
    inline_tail: str,
) -> Tuple[List[Tuple[Optional[str], List[str]]], int]:
    branches: List[Tuple[Optional[str], List[str]]] = []
    idx = next_i
    header = inline_tail.strip()

    while True:
        if not header:
            if idx >= len(lines):
                break
            stripped = lines[idx].strip()
            if not stripped.startswith("else"):
                break
            header = stripped
            idx += 1

        if not header.startswith("else"):
            break

        cond: Optional[str] = None
        block_header = header
        if header.startswith("else if"):
            block_header = header[len("else ") :].strip()
            cond = _parse_if_header(block_header)
            if cond is None:
                break
        elif header.startswith("else"):
            cond = None
        else:
            break

        pseudo = [block_header] + list(lines[idx:])
        body, pseudo_next, tail = _split_block_lines_with_tail(pseudo, 0)
        if pseudo_next <= 0:
            break
        idx = idx + pseudo_next - 1
        branches.append((cond, body))
        header = tail.strip()
        if cond is None:
            break

    return branches, idx


def _parse_if_header(line: str) -> Optional[str]:
    stripped = line.strip()
    if not stripped.startswith("if"):
        return None
    open_paren = stripped.find("(")
    if open_paren < 0:
        return None
    depth = 0
    for idx in range(open_paren, len(stripped)):
        ch = stripped[idx]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                return stripped[open_paren + 1 : idx]
    return None


def _strip_balanced_parens(expr: str) -> str:
    cur = expr.strip()
    while cur.startswith("(") and cur.endswith(")"):
        depth = 0
        balanced_outer = True
        for i, ch in enumerate(cur):
            if ch == "(":
                depth += 1
            elif ch == ")":
                depth -= 1
                if depth == 0 and i != len(cur) - 1:
                    balanced_outer = False
                    break
        if not balanced_outer:
            break
        cur = cur[1:-1].strip()
    return cur


def _is_forward_drop_guard_noop(cond: str, then_body: Sequence[str], else_chain: Sequence[Tuple[Optional[str], List[str]]]) -> bool:
    if else_chain:
        return False
    cond_norm = _strip_balanced_parens(cond).replace(" ", "")
    if cond_norm not in {"sw_forward==false", "false==sw_forward"}:
        return False
    for raw in then_body:
        stripped = raw.strip()
        if not stripped or stripped.startswith("//") or _RE_LABEL.match(stripped):
            continue
        m_bool = _RE_BOOL_ASSIGN.match(stripped)
        if not m_bool or m_bool.group("lhs") != "sw_drop":
            return False
    return True


def _body_is_only_return(body: Sequence[str]) -> bool:
    for raw in body:
        stripped = raw.strip()
        if not stripped or stripped.startswith("//") or _RE_LABEL.match(stripped):
            continue
        if stripped != "return;":
            return False
    return True


def _is_forward_return_guard_noop(
    cond: str,
    then_body: Sequence[str],
    else_chain: Sequence[Tuple[Optional[str], List[str]]],
) -> bool:
    if else_chain:
        return False
    cond_norm = _strip_balanced_parens(cond).replace(" ", "")
    return cond_norm in {
        "sw_eg_intr_md.egress_port==0bv9",
        "0bv9==sw_eg_intr_md.egress_port",
    } and _body_is_only_return(then_body)


def _is_ipv4_route_tail_noop(
    cond: str,
    then_body: Sequence[str],
    else_chain: Sequence[Tuple[Optional[str], List[str]]],
) -> bool:
    if else_chain:
        return False
    cond_norm = _strip_balanced_parens(cond).replace(" ", "")
    if not all(
        part in cond_norm
        for part in (
            "sw_isValid[sw_hdr.nlk_hdr]",
            "sw_ig_md.routed==0bv1",
            "sw_ig_md.recirced==0bv2",
        )
    ):
        return False
    for raw in then_body:
        stripped = raw.strip()
        if not stripped or stripped.startswith("//") or _RE_LABEL.match(stripped):
            continue
        m_call = _RE_CALL_VOID.match(stripped)
        if not m_call or m_call.group("callee") != "sw_SwitchIngress_ipv4_route_table.apply":
            return False
    return True


def _split_bool_top(expr: str, op: str) -> Optional[Tuple[str, str]]:
    depth = 0
    i = 0
    while i <= len(expr) - len(op):
        ch = expr[i]
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif depth == 0 and expr.startswith(op, i):
            return expr[:i], expr[i + len(op) :]
        i += 1
    return None


def _int_expr_value(expr: str, *, int_eq: Dict[str, int]) -> Optional[int]:
    stripped = _strip_balanced_parens(expr)
    if re.fullmatch(r"-?\d+", stripped):
        return int(stripped)
    if stripped in int_eq:
        return int_eq[stripped]
    for op in ("+", "-"):
        split = _split_bool_top(stripped, op)
        if split is None:
            continue
        lhs = _int_expr_value(split[0], int_eq=int_eq)
        rhs = _int_expr_value(split[1], int_eq=int_eq)
        if lhs is None or rhs is None:
            return None
        return lhs + rhs if op == "+" else lhs - rhs
    return None


def _split_args_top(args: str) -> Optional[List[str]]:
    out: List[str] = []
    depth = 0
    start = 0
    for i, ch in enumerate(args):
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        elif ch == "," and depth == 0:
            out.append(args[start:i].strip())
            start = i + 1
    tail = args[start:].strip()
    if tail:
        out.append(tail)
    return out


def _bool_call_value(expr: str, *, const_eq: Dict[str, int], var_types: Dict[str, str]) -> Optional[bool]:
    m = re.fullmatch(
        r"(?P<op>bugt|buge|bult|bule|bvugt|bvuge|bvult|bvule)\.bv(?P<w>\d+)(?:\$builtin)?\((?P<args>.*)\)",
        expr.strip(),
    )
    if not m:
        return None
    args = _split_args_top(m.group("args"))
    if args is None or len(args) != 2:
        return None
    lhs = eval_bv_expr(args[0], const_eq=const_eq, var_types=var_types)
    rhs = eval_bv_expr(args[1], const_eq=const_eq, var_types=var_types)
    width = int(m.group("w"))
    if lhs is None or rhs is None or lhs.width != width or rhs.width != width:
        return None
    op = m.group("op")
    if op in {"bugt", "bvugt"}:
        return lhs.value > rhs.value
    if op in {"buge", "bvuge"}:
        return lhs.value >= rhs.value
    if op in {"bult", "bvult"}:
        return lhs.value < rhs.value
    if op in {"bule", "bvule"}:
        return lhs.value <= rhs.value
    return None


def _bool_atom_value(
    expr: str,
    *,
    const_eq: Dict[str, int],
    bool_eq: Dict[str, bool],
    var_types: Dict[str, str],
) -> Optional[bool]:
    stripped = _strip_balanced_parens(expr)
    if stripped == "true":
        return True
    if stripped == "false":
        return False
    if stripped in bool_eq:
        return bool_eq[stripped]
    return _bool_call_value(stripped, const_eq=const_eq, var_types=var_types)


def _bool_expr_value(
    expr: str,
    *,
    const_eq: Dict[str, int],
    bool_eq: Dict[str, bool],
    int_eq: Optional[Dict[str, int]] = None,
    var_types: Dict[str, str],
) -> Optional[bool]:
    int_eq = int_eq or {}
    stripped = _strip_balanced_parens(expr)
    if stripped == "true":
        return True
    if stripped == "false":
        return False
    if stripped in bool_eq:
        return bool_eq[stripped]
    atom = _bool_atom_value(stripped, const_eq=const_eq, bool_eq=bool_eq, var_types=var_types)
    if atom is not None:
        return atom
    if stripped.startswith("!"):
        inner = _bool_expr_value(
            stripped[1:],
            const_eq=const_eq,
            bool_eq=bool_eq,
            int_eq=int_eq,
            var_types=var_types,
        )
        return None if inner is None else not inner
    for op, combiner in (("||", "or"), ("&&", "and")):
        split = _split_bool_top(stripped, op)
        if split is None:
            continue
        lhs = _bool_expr_value(split[0], const_eq=const_eq, bool_eq=bool_eq, int_eq=int_eq, var_types=var_types)
        rhs = _bool_expr_value(split[1], const_eq=const_eq, bool_eq=bool_eq, int_eq=int_eq, var_types=var_types)
        if combiner == "or":
            if lhs is True or rhs is True:
                return True
            if lhs is False and rhs is False:
                return False
        else:
            if lhs is False or rhs is False:
                return False
            if lhs is True and rhs is True:
                return True
        return None
    for op in ("==", "!=", "<=", ">=", "<", ">"):
        split = _split_bool_top(stripped, op)
        if split is None:
            continue
        lhs_b = _bool_atom_value(split[0], const_eq=const_eq, bool_eq=bool_eq, var_types=var_types)
        rhs_b = _bool_atom_value(split[1], const_eq=const_eq, bool_eq=bool_eq, var_types=var_types)
        if lhs_b is not None and rhs_b is not None:
            if op == "==":
                return lhs_b == rhs_b
            if op == "!=":
                return lhs_b != rhs_b
            return None
        lhs_i = _int_expr_value(split[0], int_eq=int_eq)
        rhs_i = _int_expr_value(split[1], int_eq=int_eq)
        if lhs_i is not None and rhs_i is not None:
            if op == "==":
                return lhs_i == rhs_i
            if op == "!=":
                return lhs_i != rhs_i
            if op == "<=":
                return lhs_i <= rhs_i
            if op == ">=":
                return lhs_i >= rhs_i
            if op == "<":
                return lhs_i < rhs_i
            if op == ">":
                return lhs_i > rhs_i
        lhs_v = eval_bv_expr(split[0].strip(), const_eq=const_eq, var_types=var_types)
        rhs_v = eval_bv_expr(split[1].strip(), const_eq=const_eq, var_types=var_types)
        if op not in {"==", "!="} or lhs_v is None or rhs_v is None or lhs_v.width != rhs_v.width:
            return None
        same = lhs_v.value == rhs_v.value
        return same if op == "==" else not same
    return None


def _bool_expr_known_false(
    expr: str,
    *,
    const_eq: Dict[str, int],
    bool_eq: Optional[Dict[str, bool]] = None,
    int_eq: Optional[Dict[str, int]] = None,
    var_types: Dict[str, str],
) -> bool:
    return (
        _bool_expr_value(expr, const_eq=const_eq, bool_eq=bool_eq or {}, int_eq=int_eq or {}, var_types=var_types)
        is False
    )


_RE_DIRECT_ARRAY_READ = re.compile(
    r"(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\[(?P<idx>[^\[\]]+)\]"
)


def _replace_known_array_reads(
    expr: str,
    *,
    arrays: Dict[str, Dict[Tuple[int, int], BvValue]],
    array_default: Dict[str, BvValue],
    const_eq: Dict[str, int],
    var_types: Dict[str, str],
) -> str:
    def repl(match: re.Match[str]) -> str:
        name = match.group("name")
        reg_decl = _RE_REG_ARRAY_TYPE.match(var_types.get(name, ""))
        if reg_decl is None:
            return match.group(0)
        index = eval_bv_expr(match.group("idx").strip(), const_eq=const_eq, var_types=var_types)
        expected_index_width = bv_width(reg_decl.group("idx"))
        if index is None or expected_index_width != index.width:
            return match.group(0)
        value = arrays.get(name, {}).get((index.width, index.value), array_default.get(name))
        if value is None:
            return match.group(0)
        return f"{value.value}bv{value.width}"

    return _RE_DIRECT_ARRAY_READ.sub(repl, expr)


class _FocusedTextualReplay:
    def __init__(
        self,
        *,
        procedure_map: Dict[str, List[str]],
        var_types: Dict[str, str],
        target_reg: str,
        slot_literal: str,
        value_width: int,
    ) -> None:
        self.procedure_map = procedure_map
        self.var_types = var_types
        self.target_reg = target_reg
        self.slot_literal = slot_literal
        self.value_width = value_width
        self.reg_value: Optional[BvValue] = None
        self.const_eq: Dict[str, int] = {}
        self.bool_eq: Dict[str, bool] = {}
        self.int_eq: Dict[str, int] = {}
        self.visited_steps = 0
        self.unsupported = False
        self.path_found = False
        self.stop_current = False
        self._body_stack: List[Sequence[str]] = []
        self.last_target_write_literal = False

    def run_procedure(self, name: str, *, args: Optional[Sequence[str]] = None, depth: int = 0) -> bool:
        if depth > _FOCUSED_REPLAY_MAX_DEPTH:
            self.unsupported = True
            return False
        body = self.procedure_map.get(name)
        if body is None:
            return self._run_known_external(name, args or ())
        prev_stop = self.stop_current
        self.stop_current = False
        self._body_stack.append(body)
        try:
            result = self.run_lines(body, depth=depth)
        finally:
            self._body_stack.pop()
            self.stop_current = prev_stop
        return result

    def run_lines(self, lines: Sequence[str], *, depth: int = 0) -> bool:
        if depth > _FOCUSED_REPLAY_MAX_DEPTH:
            self.unsupported = True
            return False
        return self._run_lines_from(lines, 0, depth=depth)

    def _snapshot(self):
        return (
            copy.deepcopy(self.reg_value),
            dict(self.const_eq),
            dict(self.bool_eq),
            dict(self.int_eq),
            self.visited_steps,
            self.unsupported,
            self.path_found,
            self.stop_current,
            list(self._body_stack),
            self.last_target_write_literal,
        )

    def _restore(self, snapshot) -> None:
        (
            self.reg_value,
            self.const_eq,
            self.bool_eq,
            self.int_eq,
            self.visited_steps,
            self.unsupported,
            self.path_found,
            self.stop_current,
            body_stack,
            self.last_target_write_literal,
        ) = snapshot
        self._body_stack = list(body_stack)

    def _run_branch(self, branch: Sequence[str], *, depth: int) -> Tuple[bool, bool, object]:
        snapshot = self._snapshot()
        self.unsupported = False
        self.stop_current = False
        result = self.run_lines(branch, depth=depth + 1)
        branch_supported = not self.unsupported
        branch_state = self._snapshot()
        self._restore(snapshot)
        return result, branch_supported, branch_state

    def _run_lines_from(self, lines: Sequence[str], start: int, *, depth: int = 0) -> bool:
        i = start
        while i < len(lines):
            raw = lines[i]
            cond = _parse_if_header(raw)
            if cond is not None and "{" in raw:
                then_body, next_i, tail = _split_block_lines_with_tail(lines, i)
                else_chain, after_else = _else_chain_branches(lines, next_i=next_i, inline_tail=tail)
                cond_value = _bool_expr_value(
                    cond,
                    const_eq=self.const_eq,
                    bool_eq=self.bool_eq,
                    int_eq=self.int_eq,
                    var_types=self.var_types,
                )
                selected: Optional[List[str]] = None
                if cond_value is True:
                    selected = then_body
                elif cond_value is False:
                    for else_cond, else_body in else_chain:
                        if else_cond is None:
                            selected = else_body
                            break
                        else_value = _bool_expr_value(
                            else_cond,
                            const_eq=self.const_eq,
                            bool_eq=self.bool_eq,
                            int_eq=self.int_eq,
                            var_types=self.var_types,
                        )
                        if else_value is True:
                            selected = else_body
                            break
                        if else_value is None:
                            self.unsupported = True
                            return False
                else:
                    self.unsupported = True
                    return False
                if selected and self.run_lines(selected, depth=depth + 1):
                    return True
                if self.unsupported:
                    return False
                i = after_else
                continue
            if self.step(raw.strip(), depth=depth):
                return True
            if self.unsupported:
                return False
            if self.stop_current:
                self.stop_current = False
                return False
            i += 1
        return False

    def step(self, stripped: str, *, depth: int = 0) -> bool:
        self.visited_steps += 1
        if self.visited_steps > _FOCUSED_REPLAY_MAX_STEPS:
            self.unsupported = True
            return False
        if not stripped or stripped.startswith("//"):
            return False
        if _RE_LABEL.match(stripped):
            return False

        m_forall = _RE_FORALL_ZERO_INIT.match(stripped)
        if m_forall and m_forall.group("reg") == self.target_reg:
            self._set_reg_literal(m_forall.group("value"))
            return False

        m_slot_init = _RE_SLOT_INIT.match(stripped)
        if (
            m_slot_init
            and m_slot_init.group("reg") == self.target_reg
            and m_slot_init.group("slot") == self.slot_literal
        ):
            self._set_reg_literal(m_slot_init.group("value"))
            return False

        m_read = _RE_SLOT_READ.match(stripped)
        if (
            m_read
            and m_read.group("reg") == self.target_reg
            and m_read.group("slot") == self.slot_literal
        ):
            self._assign_reg_to_var(m_read.group("lhs"))
            return False

        m_write = _RE_SLOT_WRITE.match(stripped)
        if (
            m_write
            and m_write.group("reg") == self.target_reg
            and m_write.group("slot") == self.slot_literal
        ):
            self._write_reg_expr(m_write.group("rhs").strip())
            return False

        m_latch = _RE_LATCH_COND.match(stripped)
        if m_latch:
            if not self.last_target_write_literal and _bool_expr_known_false(
                m_latch.group("expr"),
                const_eq=self.const_eq,
                bool_eq=self.bool_eq,
                int_eq=self.int_eq,
                var_types=self.var_types,
            ):
                self.path_found = True
                return True
            return False

        if _RE_LATCH_TRUE.match(stripped):
            return False

        m_call = _RE_CALL_VOID.match(stripped)
        if m_call:
            args = _split_args_top(m_call.group("args")) or []
            return self.run_procedure(m_call.group("callee"), args=args, depth=depth + 1)

        m_goto = _RE_GOTO.match(stripped)
        if m_goto:
            return self._run_goto_targets(m_goto.group("labels"), depth=depth)

        m_assume = _RE_ASSUME.match(stripped)
        if m_assume:
            self._apply_assume(m_assume.group("expr"))
            return False

        m_assert = _RE_ASSERT.match(stripped)
        if m_assert:
            value = _bool_expr_value(
                m_assert.group("expr"),
                const_eq=self.const_eq,
                bool_eq=self.bool_eq,
                int_eq=self.int_eq,
                var_types=self.var_types,
            )
            if value is False:
                self.path_found = True
                return True
            if value is None:
                self.unsupported = True
            return False

        if stripped.startswith("havoc "):
            for name in [p.strip() for p in stripped[len("havoc ") :].rstrip(";").split(",")]:
                self.const_eq.pop(name, None)
                self.bool_eq.pop(name, None)
                self.int_eq.pop(name, None)
                prefix = f"{name}["
                for key in list(self.bool_eq):
                    if key.startswith(prefix):
                        self.bool_eq.pop(key, None)
            return False

        m_bool = _RE_BOOL_ASSIGN.match(stripped)
        if m_bool:
            self.const_eq.pop(m_bool.group("lhs"), None)
            self.int_eq.pop(m_bool.group("lhs"), None)
            self.bool_eq[m_bool.group("lhs")] = m_bool.group("rhs") == "true"
            return False

        m_assign = _RE_SIMPLE_ASSIGN.match(stripped)
        if m_assign:
            lhs = m_assign.group("lhs")
            lhs_width = bv_width(self.var_types.get(lhs))
            if lhs_width is None:
                self._assign_non_bv(lhs, m_assign.group("rhs").strip())
                return False
            value = eval_bv_expr(m_assign.group("rhs").strip(), const_eq=self.const_eq, var_types=self.var_types)
            if value is None or value.width != lhs_width:
                self.const_eq.pop(lhs, None)
            else:
                self.const_eq[lhs] = value.value
            self.bool_eq.pop(lhs, None)
            self.int_eq.pop(lhs, None)
            return False

        return False

    def _apply_assume(self, expr: str) -> None:
        changed = False
        value = _bool_expr_value(
            expr,
            const_eq=self.const_eq,
            bool_eq=self.bool_eq,
            int_eq=self.int_eq,
            var_types=self.var_types,
        )
        if value is False:
            self.unsupported = True
            return False
        if value is True:
            return True
        stripped = _strip_balanced_parens(expr)
        if stripped.startswith("!"):
            atom = _strip_balanced_parens(stripped[1:])
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*(?:\[[^\]]+\])?", atom):
                self.bool_eq[atom] = False
                return True
            return False
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*(?:\[[^\]]+\])?", stripped):
            self.bool_eq[stripped] = True
            return True
        split = _split_bool_top(stripped, "==")
        negate = False
        if split is None:
            split = _split_bool_top(stripped, "!=")
            negate = split is not None
        if split is None:
            return False
        lhs, rhs = split[0].strip(), split[1].strip()
        lhs_bool = _bool_atom_value(lhs, const_eq=self.const_eq, bool_eq=self.bool_eq, var_types=self.var_types)
        rhs_bool = _bool_atom_value(rhs, const_eq=self.const_eq, bool_eq=self.bool_eq, var_types=self.var_types)
        if lhs_bool is None and rhs_bool is not None:
            self.bool_eq[lhs] = (not rhs_bool) if negate else rhs_bool
            return True
        if rhs_bool is None and lhs_bool is not None:
            self.bool_eq[rhs] = (not lhs_bool) if negate else lhs_bool
            return True
        if negate:
            return False
        lhs_width = bv_width(self.var_types.get(lhs))
        rhs_width = bv_width(self.var_types.get(rhs))
        lhs_bv = eval_bv_expr(lhs, const_eq=self.const_eq, var_types=self.var_types)
        rhs_bv = eval_bv_expr(rhs, const_eq=self.const_eq, var_types=self.var_types)
        if lhs_width is not None and rhs_bv is not None and lhs_width == rhs_bv.width:
            self.const_eq[lhs] = rhs_bv.value
            return True
        if rhs_width is not None and lhs_bv is not None and rhs_width == lhs_bv.width:
            self.const_eq[rhs] = lhs_bv.value
            return True
        lhs_i = _int_expr_value(lhs, int_eq=self.int_eq)
        rhs_i = _int_expr_value(rhs, int_eq=self.int_eq)
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", lhs) and rhs_i is not None:
            self.int_eq[lhs] = rhs_i
            changed = True
        elif re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", rhs) and lhs_i is not None:
            self.int_eq[rhs] = lhs_i
            changed = True
        return changed

    def _assign_non_bv(self, lhs: str, rhs: str) -> None:
        bool_value = _bool_expr_value(
            rhs,
            const_eq=self.const_eq,
            bool_eq=self.bool_eq,
            int_eq=self.int_eq,
            var_types=self.var_types,
        )
        int_value = _int_expr_value(rhs, int_eq=self.int_eq)
        self.const_eq.pop(lhs, None)
        self.bool_eq.pop(lhs, None)
        self.int_eq.pop(lhs, None)
        if bool_value is not None:
            self.bool_eq[lhs] = bool_value
        elif int_value is not None:
            self.int_eq[lhs] = int_value

    def _run_known_external(self, name: str, args: Sequence[str]) -> bool:
        # P4B emits uninterpreted extern declarations for header validity ops.
        # For textual replay, model only the boolean validity side effect needed
        # to reach a concrete UNSAFE latch; all other externs fail closed.
        if name.endswith(".advance") or name.endswith(".emit"):
            return False
        if name.endswith("packet_in.extract"):
            if args:
                self.bool_eq[f"{args[0]}.__extract"] = True
                self.bool_eq[f"{self._valid_key(args[0])}"] = True
            return False
        if name.endswith("setValid") or name.endswith("setInvalid"):
            if args:
                self.bool_eq[self._valid_key(args[0])] = name.endswith("setValid")
            return False
        self.unsupported = True
        return False

    def _valid_key(self, header: str) -> str:
        return f"{self._valid_array_prefix()}[{header.strip()}]"

    def _valid_array_prefix(self) -> str:
        parts = self.target_reg.split("_", 1)
        if parts:
            cand = f"{parts[0]}_isValid"
            if cand in self.var_types:
                return cand
        for name, typ in self.var_types.items():
            if name.endswith("_isValid") and typ.startswith("[") and typ.endswith("]bool"):
                return name
        return "isValid"

    def _run_goto_targets(self, labels: str, *, depth: int) -> bool:
        if depth > _FOCUSED_REPLAY_MAX_DEPTH:
            self.unsupported = True
            return False
        target_names = [p.strip() for p in labels.split(",") if p.strip()]
        if not target_names:
            return False
        first_supported_state = None
        if not self._body_stack:
            self.unsupported = True
            return False
        body = self._body_stack[-1]
        label_to_idx = {
            raw.strip()[:-1]: idx
            for idx, raw in enumerate(body)
            if _RE_LABEL.match(raw.strip())
        }
        for name in target_names:
            idx = label_to_idx.get(name)
            if idx is None:
                continue
            result, supported, branch_state = self._run_branch(body[idx + 1 :], depth=depth)
            if result:
                self._restore(branch_state)
                return True
            if supported and first_supported_state is None:
                first_supported_state = branch_state
        if first_supported_state is not None:
            self._restore(first_supported_state)
            self.stop_current = True
            return False
        self.unsupported = True
        return False

    def _set_reg_literal(self, lit: str) -> None:
        val = _bv_literal_value(lit)
        if val is not None and val.width == self.value_width:
            self.reg_value = val
        else:
            self.reg_value = None

    def _assign_reg_to_var(self, lhs: str) -> None:
        if self.reg_value is not None and bv_width(self.var_types.get(lhs)) == self.value_width:
            self.const_eq[lhs] = self.reg_value.value
        else:
            self.const_eq.pop(lhs, None)

    def _write_reg_expr(self, rhs: str) -> None:
        self.last_target_write_literal = _bv_literal_value(rhs) is not None
        value = eval_bv_expr(rhs, const_eq=self.const_eq, var_types=self.var_types)
        if value is None or value.width != self.value_width:
            self.reg_value = None
        else:
            self.reg_value = value


class _BoundedDslTextualReplay:
    def __init__(
        self,
        *,
        procedure_map: Dict[str, List[str]],
        var_types: Dict[str, str],
        procedure_sigs: Optional[Dict[str, Tuple[Tuple[str, ...], Tuple[str, ...]]]] = None,
        procedure_type_scopes: Optional[Dict[str, Dict[str, str]]] = None,
        bad_guard_exprs: Optional[Sequence[str]] = None,
    ) -> None:
        self.procedure_map = procedure_map
        self.var_types = var_types
        self.procedure_sigs = procedure_sigs or {}
        self.procedure_type_scopes = procedure_type_scopes or {}
        self.bad_guard_exprs = tuple(bad_guard_exprs or ())
        self.arrays: Dict[str, Dict[Tuple[int, int], BvValue]] = {}
        self.array_default: Dict[str, BvValue] = {}
        self.const_eq: Dict[str, int] = {}
        self.bool_eq: Dict[str, bool] = {}
        self.int_eq: Dict[str, int] = {}
        self.visited_steps = 0
        self.unsupported = False
        self.path_found = False
        self.stop_current = False
        self._body_stack: List[Sequence[str]] = []

    def run_procedure(self, name: str, *, args: Optional[Sequence[str]] = None, depth: int = 0) -> bool:
        if depth > _FOCUSED_REPLAY_MAX_DEPTH:
            self.unsupported = True
            return False
        body = self.procedure_map.get(name)
        if body is None:
            return self._run_known_external(name, args or ())
        params, returns = self.procedure_sigs.get(name, ((), ()))
        type_scope = self.procedure_type_scopes.get(name, {})
        old_types: Dict[str, Optional[str]] = {}
        for var, typ in type_scope.items():
            old_types[var] = self.var_types.get(var)
            self.var_types[var] = typ
        call_args = tuple(args or ())
        if call_args:
            if len(call_args) != len(params):
                self.unsupported = True
                for var, old in old_types.items():
                    if old is None:
                        self.var_types.pop(var, None)
                    else:
                        self.var_types[var] = old
                return False
            for param, arg in zip(params, call_args):
                self._assign(param, arg)
        for ret in returns:
            self.const_eq.pop(ret, None)
            self.bool_eq.pop(ret, None)
            self.int_eq.pop(ret, None)
        prev_stop = self.stop_current
        self.stop_current = False
        self._body_stack.append(body)
        try:
            result = self.run_lines(body, depth=depth)
        finally:
            self._body_stack.pop()
            self.stop_current = prev_stop
            for var, old in old_types.items():
                if old is None:
                    self.var_types.pop(var, None)
                else:
                    self.var_types[var] = old
        return result

    def _expr_with_known_array_reads(self, expr: str) -> str:
        return _replace_known_array_reads(
            expr,
            arrays=self.arrays,
            array_default=self.array_default,
            const_eq=self.const_eq,
            var_types=self.var_types,
        )

    def _bool_expr_value(self, expr: str) -> Optional[bool]:
        return _bool_expr_value(
            self._expr_with_known_array_reads(expr),
            const_eq=self.const_eq,
            bool_eq=self.bool_eq,
            int_eq=self.int_eq,
            var_types=self.var_types,
        )

    def _bool_expr_known_false(self, expr: str) -> bool:
        return self._bool_expr_value(expr) is False

    def run_lines(self, lines: Sequence[str], *, depth: int = 0) -> bool:
        if depth > _FOCUSED_REPLAY_MAX_DEPTH:
            self.unsupported = True
            return False
        return self._run_lines_from(lines, 0, depth=depth)

    def _snapshot(self):
        return (
            copy.deepcopy(self.arrays),
            copy.deepcopy(self.array_default),
            dict(self.const_eq),
            dict(self.bool_eq),
            dict(self.int_eq),
            self.visited_steps,
            self.unsupported,
            self.path_found,
            self.stop_current,
            list(self._body_stack),
        )

    def _restore(self, snapshot) -> None:
        (
            self.arrays,
            self.array_default,
            self.const_eq,
            self.bool_eq,
            self.int_eq,
            self.visited_steps,
            self.unsupported,
            self.path_found,
            self.stop_current,
            body_stack,
        ) = snapshot
        self._body_stack = list(body_stack)

    def _run_branch(self, branch: Sequence[str], *, depth: int) -> Tuple[bool, bool, object]:
        snapshot = self._snapshot()
        self.unsupported = False
        self.stop_current = False
        result = self.run_lines(branch, depth=depth + 1)
        branch_supported = not self.unsupported
        branch_state = self._snapshot()
        self._restore(snapshot)
        return result, branch_supported, branch_state

    def _run_lines_from(self, lines: Sequence[str], start: int, *, depth: int = 0) -> bool:
        i = start
        while i < len(lines):
            raw = lines[i]
            cond = _parse_if_header(raw)
            if cond is not None and "{" in raw:
                then_body, next_i, tail = _split_block_lines_with_tail(lines, i)
                else_chain, after_else = _else_chain_branches(lines, next_i=next_i, inline_tail=tail)
                cond_value = self._bool_expr_value(cond)
                selected: Optional[List[str]] = None
                if cond_value is True:
                    selected = then_body
                elif cond_value is False:
                    for else_cond, else_body in else_chain:
                        if else_cond is None:
                            selected = else_body
                            break
                        else_value = self._bool_expr_value(else_cond)
                        if else_value is True:
                            selected = else_body
                            break
                        if else_value is None:
                            if self._accept_known_bad_guard():
                                return True
                            self.unsupported = True
                            return False
                else:
                    if _is_forward_drop_guard_noop(cond, then_body, else_chain) or _is_forward_return_guard_noop(
                        cond, then_body, else_chain
                    ) or _is_ipv4_route_tail_noop(
                        cond, then_body, else_chain
                    ):
                        i = after_else
                        continue
                    if self._accept_known_bad_guard():
                        return True
                    self.unsupported = True
                    return False
                if selected and self.run_lines(selected, depth=depth + 1):
                    return True
                if self.unsupported:
                    return False
                i = after_else
                continue
            if self.step(raw.strip(), depth=depth):
                return True
            if self.unsupported:
                return False
            if self.stop_current:
                self.stop_current = False
                return False
            i += 1
        return False

    def step(self, stripped: str, *, depth: int = 0) -> bool:
        self.visited_steps += 1
        if self.visited_steps > _FOCUSED_REPLAY_MAX_STEPS:
            self.unsupported = True
            return False
        if not stripped or stripped.startswith("//"):
            return False
        if _RE_LABEL.match(stripped):
            return False

        m_forall = _RE_FORALL_ZERO_INIT.match(stripped)
        if m_forall:
            self._set_array_default_literal(m_forall.group("reg"), m_forall.group("value"))
            return False

        m_slot_init = _RE_SLOT_INIT.match(stripped)
        if m_slot_init:
            self._set_array_literal(
                m_slot_init.group("reg"),
                m_slot_init.group("slot"),
                m_slot_init.group("value"),
            )
            return False

        m_latch = _RE_PROCURATOR_BAD_LATCH.match(stripped)
        if m_latch:
            if self._bool_expr_known_false(m_latch.group("expr")):
                self.bool_eq["procurator_bad"] = True
            return False

        m_ext_read = _RE_EXTERN_READ_ASSIGN.match(stripped)
        if m_ext_read and m_ext_read.group("reg") == m_ext_read.group("reg_arg"):
            self._assign_array_read(m_ext_read.group("lhs"), m_ext_read.group("reg"), m_ext_read.group("idx"))
            return False

        m_slot_read = _RE_SLOT_READ.match(stripped)
        if m_slot_read:
            self._assign_array_read(m_slot_read.group("lhs"), m_slot_read.group("reg"), m_slot_read.group("slot"))
            return False

        m_slot_write = _RE_SLOT_WRITE.match(stripped)
        if m_slot_write:
            self._write_array_expr(m_slot_write.group("reg"), m_slot_write.group("slot"), m_slot_write.group("rhs"))
            return False

        m_call_assign = _RE_CALL_ASSIGN.match(stripped)
        if m_call_assign:
            callee = m_call_assign.group("callee")
            args = _split_args_top(m_call_assign.group("args")) or []
            lhs_names = tuple(_split_args_top(m_call_assign.group("lhs")) or ())
            _params, returns = self.procedure_sigs.get(callee, ((), ()))
            if not returns or len(lhs_names) != len(returns):
                self.unsupported = True
                return False
            if self.run_procedure(callee, args=args, depth=depth + 1):
                return True
            if self.unsupported:
                return False
            callee_types = self.procedure_type_scopes.get(callee, {})
            old_return_types: Dict[str, Optional[str]] = {}
            for ret in returns:
                if ret in callee_types:
                    old_return_types[ret] = self.var_types.get(ret)
                    self.var_types[ret] = callee_types[ret]
            for lhs, ret in zip(lhs_names, returns):
                self._assign(lhs, ret)
            for ret, old in old_return_types.items():
                if old is None:
                    self.var_types.pop(ret, None)
                else:
                    self.var_types[ret] = old
            return False

        m_call = _RE_CALL_VOID.match(stripped)
        if m_call:
            callee = m_call.group("callee")
            args = _split_args_top(m_call.group("args")) or []
            if callee.endswith(".write"):
                reg = callee[: -len(".write")]
                if len(args) != 2:
                    self.unsupported = True
                    return False
                self._write_array_expr(reg, args[0], args[1])
                return False
            return self.run_procedure(callee, args=args, depth=depth + 1)

        m_goto = _RE_GOTO.match(stripped)
        if m_goto:
            return self._run_goto_targets(m_goto.group("labels"), depth=depth)

        m_assume = _RE_ASSUME.match(stripped)
        if m_assume:
            self._apply_assume(m_assume.group("expr"))
            return False

        m_assert = _RE_ASSERT.match(stripped)
        if m_assert:
            value = self._bool_expr_value(m_assert.group("expr"))
            if value is False:
                self.path_found = True
                return True
            if value is None:
                if self._accept_known_bad_guard():
                    return True
                self.unsupported = True
            return False

        if stripped.startswith("havoc "):
            for name in [p.strip() for p in stripped[len("havoc ") :].rstrip(";").split(",")]:
                self.const_eq.pop(name, None)
                self.bool_eq.pop(name, None)
                self.int_eq.pop(name, None)
                self.arrays.pop(name, None)
                self.array_default.pop(name, None)
                prefix = f"{name}["
                for key in list(self.bool_eq):
                    if key.startswith(prefix):
                        self.bool_eq.pop(key, None)
            return False

        m_bool = _RE_BOOL_ASSIGN.match(stripped)
        if m_bool:
            self.const_eq.pop(m_bool.group("lhs"), None)
            self.int_eq.pop(m_bool.group("lhs"), None)
            self.bool_eq[m_bool.group("lhs")] = m_bool.group("rhs") == "true"
            return False

        m_assign = _RE_SIMPLE_ASSIGN.match(stripped)
        if m_assign:
            self._assign(m_assign.group("lhs"), m_assign.group("rhs").strip())
            return False

        return False

    def _apply_assume(self, expr: str) -> bool:
        value = self._bool_expr_value(expr)
        if value is False:
            self.unsupported = True
            return False
        if value is True:
            return True
        stripped = _strip_balanced_parens(expr)
        if stripped.startswith("!"):
            atom = _strip_balanced_parens(stripped[1:])
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*(?:\[[^\]]+\])?", atom):
                self.bool_eq[atom] = False
                return True
            return False
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*(?:\[[^\]]+\])?", stripped):
            self.bool_eq[stripped] = True
            return True
        split = _split_bool_top(stripped, "==")
        negate = False
        if split is None:
            split = _split_bool_top(stripped, "!=")
            negate = split is not None
        if split is None:
            return False
        lhs, rhs = split[0].strip(), split[1].strip()
        lhs_bool = _bool_atom_value(lhs, const_eq=self.const_eq, bool_eq=self.bool_eq, var_types=self.var_types)
        rhs_bool = _bool_atom_value(rhs, const_eq=self.const_eq, bool_eq=self.bool_eq, var_types=self.var_types)
        if lhs_bool is None and rhs_bool is not None:
            self.bool_eq[lhs] = (not rhs_bool) if negate else rhs_bool
            return True
        if rhs_bool is None and lhs_bool is not None:
            self.bool_eq[rhs] = (not lhs_bool) if negate else lhs_bool
            return True
        if negate:
            return False
        lhs_bv = eval_bv_expr(lhs, const_eq=self.const_eq, var_types=self.var_types)
        rhs_bv = eval_bv_expr(rhs, const_eq=self.const_eq, var_types=self.var_types)
        lhs_width = bv_width(self.var_types.get(lhs))
        rhs_width = bv_width(self.var_types.get(rhs))
        if lhs_width is not None and rhs_bv is not None and lhs_width == rhs_bv.width:
            self.const_eq[lhs] = rhs_bv.value
            self.bool_eq.pop(lhs, None)
            self.int_eq.pop(lhs, None)
            return True
        if rhs_width is not None and lhs_bv is not None and rhs_width == lhs_bv.width:
            self.const_eq[rhs] = lhs_bv.value
            self.bool_eq.pop(rhs, None)
            self.int_eq.pop(rhs, None)
            return True
        lhs_i = _int_expr_value(lhs, int_eq=self.int_eq)
        rhs_i = _int_expr_value(rhs, int_eq=self.int_eq)
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", lhs) and rhs_i is not None:
            self.int_eq[lhs] = rhs_i
            return True
        if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_.]*", rhs) and lhs_i is not None:
            self.int_eq[rhs] = lhs_i
            return True
        return False

    def _assign(self, lhs: str, rhs: str) -> None:
        lhs_width = bv_width(self.var_types.get(lhs))
        if lhs_width is not None:
            value = eval_bv_expr(rhs, const_eq=self.const_eq, var_types=self.var_types)
            self.const_eq.pop(lhs, None)
            self.bool_eq.pop(lhs, None)
            self.int_eq.pop(lhs, None)
            if value is not None and value.width == lhs_width:
                self.const_eq[lhs] = value.value
            return
        bool_value = self._bool_expr_value(rhs)
        int_value = _int_expr_value(rhs, int_eq=self.int_eq)
        self.const_eq.pop(lhs, None)
        self.bool_eq.pop(lhs, None)
        self.int_eq.pop(lhs, None)
        if bool_value is not None:
            self.bool_eq[lhs] = bool_value
            return
        if int_value is not None:
            self.int_eq[lhs] = int_value

    def _run_known_external(self, name: str, args: Sequence[str]) -> bool:
        if name.endswith(".advance") or name.endswith(".emit"):
            return False
        if name.endswith("packet_in.extract"):
            if args:
                self.bool_eq[f"{args[0]}.__extract"] = True
                self.bool_eq[f"{self._valid_key(args[0])}"] = True
            return False
        if name.endswith("setValid") or name.endswith("setInvalid"):
            if args:
                self.bool_eq[self._valid_key(args[0])] = name.endswith("setValid")
            return False
        self.unsupported = True
        return False

    def _valid_key(self, header: str) -> str:
        return f"{self._valid_array_prefix(header.strip())}[{header.strip()}]"

    def _valid_array_prefix(self, header: str) -> str:
        if "_" in header:
            cand = f"{header.split('_', 1)[0]}_isValid"
            if cand in self.var_types:
                return cand
        for name, typ in self.var_types.items():
            if name.endswith("_isValid") and typ.startswith("[") and typ.endswith("]bool"):
                return name
        return "isValid"

    def _run_goto_targets(self, labels: str, *, depth: int) -> bool:
        if depth > _FOCUSED_REPLAY_MAX_DEPTH:
            self.unsupported = True
            return False
        target_names = [p.strip() for p in labels.split(",") if p.strip()]
        if not target_names or not self._body_stack:
            self.unsupported = True
            return False
        body = self._body_stack[-1]
        label_to_idx = {raw.strip()[:-1]: idx for idx, raw in enumerate(body) if _RE_LABEL.match(raw.strip())}
        first_supported_state = None
        for name in target_names:
            idx = label_to_idx.get(name)
            if idx is None:
                continue
            result, supported, branch_state = self._run_branch(body[idx + 1 :], depth=depth)
            if result:
                self._restore(branch_state)
                return True
            if supported and first_supported_state is None:
                first_supported_state = branch_state
        if first_supported_state is not None:
            self._restore(first_supported_state)
            self.stop_current = True
            return False
        self.unsupported = True
        return False

    def _set_array_default_literal(self, reg: str, lit: str) -> None:
        value = _bv_literal_value(lit)
        if value is not None:
            self.array_default[reg] = value

    def _set_array_literal(self, reg: str, slot_lit: str, value_lit: str) -> None:
        slot = _bv_literal_value(slot_lit)
        value = _bv_literal_value(value_lit)
        if slot is None or value is None:
            return
        self.arrays.setdefault(reg, {})[(slot.width, slot.value)] = value

    def _assign_array_read(self, lhs: str, reg: str, idx_expr: str) -> None:
        self.const_eq.pop(lhs, None)
        index = eval_bv_expr(idx_expr.strip(), const_eq=self.const_eq, var_types=self.var_types)
        if index is None:
            return
        value = self.arrays.get(reg, {}).get((index.width, index.value), self.array_default.get(reg))
        lhs_width = bv_width(self.var_types.get(lhs))
        if value is not None and lhs_width == value.width:
            self.const_eq[lhs] = value.value

    def _write_array_expr(self, reg: str, idx_expr: str, rhs: str) -> None:
        index = eval_bv_expr(idx_expr.strip(), const_eq=self.const_eq, var_types=self.var_types)
        value = eval_bv_expr(rhs.strip(), const_eq=self.const_eq, var_types=self.var_types)
        if index is None or value is None:
            self._forget_array_write(reg, index=index)
            return
        self.arrays.setdefault(reg, {})[(index.width, index.value)] = value
        self._assign(f"{reg}__last_index", f"{index.value}bv{index.width}")
        self._assign(f"{reg}__last_value", f"{value.value}bv{value.width}")
        self._assign(f"{reg}__wrote_any", "true")
        if index.value == 0 and f"{reg}__last0_value" in self.var_types:
            self._assign(f"{reg}__wrote_index0", "true")
            self._assign(f"{reg}__last0_value", f"{value.value}bv{value.width}")

    def _accept_known_bad_guard(self) -> bool:
        for expr in self.bad_guard_exprs:
            if self._bool_expr_known_false(expr):
                self.bool_eq["procurator_bad"] = True
                self.path_found = True
                return True
        return False

    def _forget_array_write(self, reg: str, *, index: Optional[BvValue]) -> None:
        if index is None:
            self.arrays.pop(reg, None)
            self.array_default.pop(reg, None)
        else:
            self.arrays.get(reg, {}).pop((index.width, index.value), None)
        for suffix in (
            "__last_index",
            "__last_value",
            "__last_old_value",
            "__wrote_any",
            "__wrote_index0",
            "__last0_old_value",
            "__last0_value",
            "__next_write_site",
            "__last_write_site",
        ):
            name = f"{reg}{suffix}"
            self.const_eq.pop(name, None)
            self.bool_eq.pop(name, None)
            self.int_eq.pop(name, None)


def _focused_bounded_textual_latch_witness(
    *,
    text: str,
    target_reg: Optional[str],
    slot_literal: Optional[str],
) -> bool:
    """
    Recognize a narrow deterministic focused-bounded witness.

    This is an UNSAFE-only shortcut for focused direct probing. It only accepts
    a concrete slot whose initial value is explicit and whose repeated writes
    deterministically set the focused latch. Failure means "fall back", never
    SAFE.
    """

    if not target_reg or not slot_literal or "procurator_focused_underapprox_hit := true" not in text:
        return False
    slot = _bv_literal_value(slot_literal)
    if slot is None:
        return False

    var_types = _parse_var_types(text)
    reg_type = var_types.get(target_reg, "")
    reg_decl = _RE_REG_ARRAY_TYPE.match(reg_type)
    if not reg_decl or bv_width(reg_decl.group("idx")) != slot.width:
        return False
    value_width = bv_width(reg_decl.group("val"))
    if value_width is None:
        return False

    procedure_map = _procedure_bodies(text)
    replay = _FocusedTextualReplay(
        procedure_map=procedure_map,
        var_types=var_types,
        target_reg=target_reg,
        slot_literal=slot_literal,
        value_width=value_width,
    )
    if "mainProcedure" in procedure_map:
        result = replay.run_procedure("mainProcedure")
        return result and not replay.unsupported
    for raw in text.splitlines():
        if replay.step(raw.strip()):
            return not replay.unsupported
        if replay.unsupported:
            return False
    return False


def _find_assert_line(text: str, needle: str) -> Optional[int]:
    for i, raw in enumerate(text.splitlines(), start=1):
        if needle in raw:
            return i
    return None


def _collect_procurator_bad_guard_exprs(text: str) -> List[str]:
    exprs: List[str] = []
    seen: set[str] = set()
    for raw in text.splitlines():
        m = _RE_PROCURATOR_BAD_LATCH.match(raw.strip())
        if not m:
            continue
        expr = m.group("expr").strip()
        if expr and expr not in seen:
            seen.add(expr)
            exprs.append(expr)
    return exprs


def run_bounded_dsl_replay_prepass(
    *,
    bpl_path: Path,
    log_dir: Path,
    emit: Emitter = print,
) -> int:
    """
    UNSAFE-only deterministic replay for bounded DSL guard harnesses.

    This accepts only a concrete replay that reaches `assert !procurator_bad`
    with `procurator_bad == true`. Unsupported statements, nondeterministic
    branches, missing hashes, or non-violating paths return 0 so the normal
    solver continues.
    """

    try:
        text = bpl_path.read_text(encoding="utf-8", errors="replace")
    except Exception as e:
        emit(f"[FOCUS] bounded DSL replay skipped (read failed: {type(e).__name__}: {e})")
        return 0
    if "procurator_bad := true" not in text or "assert !procurator_bad" not in text:
        return 0
    var_types = _parse_var_types(text)
    procedure_map = _procedure_bodies(text)
    if "mainProcedure" not in procedure_map:
        return 0
    replay = _BoundedDslTextualReplay(
        procedure_map=procedure_map,
        var_types=var_types,
        procedure_sigs=_procedure_signatures(text),
        procedure_type_scopes=_procedure_type_scopes(text),
        bad_guard_exprs=_collect_procurator_bad_guard_exprs(text),
    )
    if not replay.run_procedure("mainProcedure") or replay.unsupported:
        return 0
    assert_line = _find_assert_line(text, "assert !procurator_bad")
    if assert_line is None:
        return 0
    marker = log_dir / f"{bpl_path.stem}.bounded-dsl-replay.unsafe.json"
    synthetic_log = log_dir / f"{bpl_path.stem}.bounded-dsl-replay.textual.log"
    try:
        marker.parent.mkdir(parents=True, exist_ok=True)
        synthetic_log.write_text(
            "RESULT: UNSAFE\n"
            f"CounterExampleResult [Line: {assert_line}]\n"
            "Bounded DSL deterministic textual replay witness.\n",
            encoding="utf-8",
        )
        _write_bounded_dsl_replay_marker(
            marker_path=marker,
            result_line="RESULT: UNSAFE",
            source_bpl=bpl_path,
            log_path=synthetic_log,
            assert_line=assert_line,
            note=(
                "UNSAFE by deterministic bounded DSL replay of procurator_bad. "
                "This is an UNSAFE-only under-approximation; unsupported, SAFE, "
                "UNKNOWN, TIMEOUT, or missing replay evidence falls back to the solver."
            ),
        )
    except Exception as e:
        emit(f"[FOCUS] bounded DSL replay marker skipped ({type(e).__name__}: {e})")
        return 0
    emit("[FOCUS] bounded DSL replay found deterministic procurator_bad violation; original run skipped.")
    return 1


def _write_focused_marker(
    *,
    marker_path: Path,
    kind: str,
    result_line: str,
    bpl_path: Path,
    log_path: Path,
    source_bpl: Path,
    focused_target_reg: Optional[str],
    focused_idx_var: Optional[str],
    focused_zero: Optional[str],
    focused_target_old_value: Optional[str],
    focused_target_value: Optional[str],
    focused_target_slice: Optional[Tuple[int, int]],
    assert_lines: Sequence[int],
    note: str,
) -> None:
    marker_path.write_text(
        json.dumps(
            {
                "kind": kind,
                "result_line": result_line,
                "bpl": str(bpl_path),
                "log": str(log_path),
                "source_bpl": str(source_bpl),
                "source_bpl_sha256": _sha256_file(source_bpl),
                "focused_bpl_sha256": _sha256_file(bpl_path),
                "target_reg": focused_target_reg,
                "idx_var": focused_idx_var,
                "zero": focused_zero,
                "target_old_value": focused_target_old_value,
                "target_value": focused_target_value,
                "target_slice": list(focused_target_slice) if focused_target_slice is not None else None,
                "assert_line": int(assert_lines[0]) if assert_lines else None,
                "assert_lines": [int(v) for v in assert_lines],
                "note": note,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def _write_bounded_dsl_replay_marker(
    *,
    marker_path: Path,
    result_line: str,
    source_bpl: Path,
    log_path: Path,
    assert_line: int,
    note: str,
) -> None:
    marker_path.write_text(
        json.dumps(
            {
                "kind": "bounded_dsl_replay_under_approx",
                "result_line": result_line,
                "bpl": str(source_bpl),
                "log": str(log_path),
                "source_bpl": str(source_bpl),
                "source_bpl_sha256": _sha256_file(source_bpl),
                "focused_bpl_sha256": _sha256_file(source_bpl),
                "assert_line": int(assert_line),
                "assert_lines": [int(assert_line)],
                "note": note,
            },
            indent=2,
            sort_keys=True,
        )
        + "\n",
        encoding="utf-8",
    )


def result_line_is_unsafe(result_line: Optional[str]) -> bool:
    if not result_line:
        return False
    s = result_line.lower()
    return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)


def result_line_is_timeout_or_unknown(result_line: Optional[str]) -> bool:
    if not result_line:
        return False
    s = result_line.lower()
    return ("timeout" in s) or ("unknown" in s) or ("could not prove your program" in s)


def _focused_result_should_try_bounded(res: UltimateRunResult) -> bool:
    if result_line_is_timeout_or_unknown(res.result_line):
        return True
    # OS-level timeout may kill Ultimate before it prints a RESULT line.  Since
    # focused-direct is UNSAFE-only, a missing result should continue to the
    # bounded focused probes instead of starving them.
    if res.result_line is None and res.returncode != 0:
        return True
    return False


def _focused_prepass_timeout(user_timeout_seconds: int) -> int:
    """
    Focused direct is an UNSAFE-only hint before the real direct solver.

    Keep it short so difficult focused queries cannot consume the whole user
    timeout and starve the full model.
    """

    if int(user_timeout_seconds) <= 0:
        return 60
    return max(5, min(int(user_timeout_seconds), 60))


def counterexample_line_from_log(log_path: Path) -> Optional[int]:
    try:
        text = log_path.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return None
    matches = re.findall(r"CounterExampleResult\s+\[Line:\s*(\d+)\]", text)
    if len(matches) != 1:
        return None
    try:
        return int(matches[0])
    except ValueError:
        return None


def focused_unsafe_marker_for_bpl(*, out_dir: Path, bpl_path: Path) -> Optional[Path]:
    marker = out_dir / f"{bpl_path.stem}.focused-index0.unsafe.json"
    if not marker.exists():
        return None
    try:
        data = json.loads(marker.read_text(encoding="utf-8"))
    except Exception:
        return None
    kind = data.get("kind")
    if kind not in {"focused_under_approx", "focused_under_approx_bounded"}:
        return None
    if data.get("source_bpl_sha256") != _sha256_file(bpl_path):
        return None
    focused_bpl = data.get("bpl")
    if not isinstance(focused_bpl, str):
        return None
    if kind == "focused_under_approx":
        if not focused_bpl.endswith(f"{bpl_path.stem}.focused-index0.bpl"):
            return None
    else:
        if not re.search(rf"{re.escape(bpl_path.stem)}\.focused-index0\.bounded\d+\.bpl$", focused_bpl):
            return None
    if not isinstance(focused_bpl, str):
        return None
    focus_path = Path(focused_bpl)
    if not focus_path.is_absolute():
        focus_path = marker.parent / focus_path
    if not focus_path.exists():
        return None
    if data.get("focused_bpl_sha256") != _sha256_file(focus_path):
        return None
    return marker


def bounded_dsl_replay_marker_for_bpl(*, out_dir: Path, bpl_path: Path) -> Optional[Path]:
    marker = out_dir / f"{bpl_path.stem}.bounded-dsl-replay.unsafe.json"
    if not marker.exists():
        return None
    try:
        data = json.loads(marker.read_text(encoding="utf-8"))
    except Exception:
        return None
    if data.get("kind") != "bounded_dsl_replay_under_approx":
        return None
    if data.get("result_line") != "RESULT: UNSAFE":
        return None
    if data.get("source_bpl_sha256") != _sha256_file(bpl_path):
        return None
    if data.get("focused_bpl_sha256") != _sha256_file(bpl_path):
        return None
    bpl = data.get("bpl")
    if not isinstance(bpl, str):
        return None
    replay_bpl = _resolve_marker_artifact_path(bpl, base_dir=marker.parent)
    try:
        if replay_bpl is None or replay_bpl.resolve() != bpl_path.resolve():
            return None
    except Exception:
        return None
    log_path = data.get("log")
    if not isinstance(log_path, str):
        return None
    replay_log = _resolve_marker_artifact_path(log_path, base_dir=marker.parent)
    if replay_log is None or not replay_log.exists():
        return None
    return marker


def _resolve_marker_artifact_path(path_str: str, *, base_dir: Path) -> Optional[Path]:
    path = Path(path_str)
    if path.is_absolute():
        return path if path.exists() else None
    try:
        cwd_path = path.resolve()
        if cwd_path.exists():
            return cwd_path
    except Exception:
        pass
    base_path = base_dir / path
    return base_path if base_path.exists() else None


def _sha256_file(path: Path) -> Optional[str]:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except Exception:
        return None


def run_focused_direct_prepass(
    *,
    bpl_path: Path,
    log_dir: Path,
    ultimate: Path,
    toolchain: Path,
    settings: Path,
    ultimate_home: Path,
    ultimate_timeout_seconds: int,
    resource_limits: bool,
    ultimate_xmx_gb: int,
    optimize_bpl: Optional[Optimizer] = None,
    ultimate_runner: UltimateRunner = run_ultimate,
    emit: Emitter = print,
) -> int:
    """
    Try a small under-approx direct bug-finding probe before the full run.

    This is deliberately UNSAFE-only.  SAFE, UNKNOWN, ERROR, TIMEOUT, stale line
    mappings, and counterexamples outside the focused assertion all fall back to
    the original BPL.
    """

    try:
        src = bpl_path.read_text(encoding="utf-8", errors="replace")
        focused = focus_dynamic_index0_register_assert(src)
    except Exception as e:
        emit(f"[FOCUS] skip: focused direct prepass failed ({type(e).__name__}: {e})")
        return 0

    if not focused.changed:
        return 0

    # Optional UNSAFE-only replay prepass:
    # mine near-wrap witness shape assumptions from recent runs and inject them
    # into the base model before focused slicing. This is an under-approximation
    # used only for bug finding; SAFE/UNKNOWN/TIMEOUT still fall back.
    try:
        pump_reg = str(focused.target_reg or "").strip()
        run_dir = log_dir.resolve()
        spec_runs_dir = run_dir.parent
        replay_assumes, replay_manifest = _collect_replay_assumes_from_recent_manifests(
            spec_runs_dir=spec_runs_dir,
            current_run_dir=run_dir,
            pump_reg=pump_reg,
        )
        if replay_assumes:
            patched_text, injected_n = _inject_replay_assumes_after_havoc(
                bpl_text=src,
                assumes=replay_assumes,
            )
            if injected_n > 0 and patched_text != src:
                src = patched_text
                focused = focus_dynamic_index0_register_assert(src)
                if focused.changed:
                    emit(
                        "[FOCUS] replay prepass: injected "
                        f"{injected_n} near-wrap witness assumptions from {replay_manifest}"
                    )
                else:
                    emit(
                        "[FOCUS] replay prepass: focused transform no longer applicable after "
                        f"{injected_n} injected assumptions; falling back to original focused flow."
                    )
    except Exception as e:
        emit(f"[FOCUS] replay prepass skipped ({type(e).__name__}: {e})")

    if not focused.changed:
        return 0

    focus_bpl = log_dir / f"{bpl_path.stem}.focused-index0.bpl"
    focus_log = log_dir / f"{bpl_path.stem}.focused-index0.log"
    marker = log_dir / f"{bpl_path.stem}.focused-index0.unsafe.json"
    try:
        focus_bpl.parent.mkdir(parents=True, exist_ok=True)
        focus_bpl.write_text(focused.text, encoding="utf-8")
    except Exception as e:
        emit(f"[FOCUS] skip: could not write focused BPL ({type(e).__name__}: {e})")
        return 0

    if optimize_bpl is not None:
        optimize_bpl(focus_bpl)

    expected_lines = tuple(focused.assert_lines or ((focused.assert_line,) if focused.assert_line is not None else ()))
    refresh_failed = False
    try:
        optimized_focused_text = focus_bpl.read_text(encoding="utf-8", errors="replace")
        if focused.target_reg and focused.target_value:
            refreshed_lines = find_focused_direct_assert_lines(
                optimized_focused_text,
                focused.target_reg,
                focused.target_value,
                focused.target_slice,
                focused.zero,
                focused.target_old_value,
            )
            if refreshed_lines:
                expected_lines = refreshed_lines
            else:
                refresh_failed = True
    except Exception:
        refresh_failed = True

    focus_timeout = _focused_prepass_timeout(int(ultimate_timeout_seconds))
    emit(f"[FOCUS] direct prepass: {focused.reason}")
    res = ultimate_runner(
        ultimate=ultimate,
        toolchain=toolchain,
        settings=settings,
        input_bpl=focus_bpl,
        log_path=focus_log,
        ultimate_home=ultimate_home,
        toolchain_timeout_seconds=focus_timeout,
        os_timeout_seconds=focus_timeout + 60,
        cwd=log_dir,
        async_run=False,
        resource_limits=resource_limits,
        launcher_xmx_gb=max(1, int(ultimate_xmx_gb)),
    )
    if res.result_line:
        emit(f"[FOCUS] {res.result_line}")
    emit(f"[FOCUS] log: {focus_log}")

    if result_line_is_unsafe(res.result_line):
        if refresh_failed:
            emit("[FOCUS] could not refresh focused assertion lines after BPL optimization; falling back to original BPL.")
            return 0

        hit_line = counterexample_line_from_log(focus_log)
        if hit_line not in expected_lines:
            emit(
                "[FOCUS] UNSAFE did not hit the focused direct assertion "
                f"(hit={hit_line}, expected={expected_lines}); falling back to original BPL."
            )
            return 0

        try:
            _write_focused_marker(
                marker_path=marker,
                kind="focused_under_approx",
                result_line=res.result_line or "RESULT: UNSAFE",
                bpl_path=focus_bpl,
                log_path=focus_log,
                source_bpl=bpl_path,
                focused_target_reg=focused.target_reg,
                focused_idx_var=focused.idx_var,
                focused_zero=focused.zero,
                focused_target_old_value=focused.target_old_value,
                focused_target_value=focused.target_value,
                focused_target_slice=focused.target_slice,
                assert_lines=expected_lines,
                note=(
                    "UNSAFE in a focused constant-slot under-approximation. "
                    "This is a direct bug witness only; it is not a wraparound closure certificate."
                ),
            )
        except Exception:
            pass
        emit("[FOCUS] UNSAFE witness found in focused under-approximation; original run skipped.")
        return 1

    # Stage 2: only when the focused query timed out/unknown, run bounded
    # under-approx probes with a latch assertion. These are UNSAFE-only hints.
    if not _focused_result_should_try_bounded(res):
        return 0
    if refresh_failed:
        return 0

    value_width = _parse_bv_width(focused.target_value)
    slot_width = _parse_bv_width(focused.zero)
    sched_period = _infer_scheduler_period_from_text(focused.text)
    # Keep this short and deterministic; the goal is to surface easy long-prefix
    # witnesses before the full direct run, not to replace it.
    bounded_steps: List[int] = []
    if value_width is not None and value_width <= 8:
        # 8-bit counters often need close to 256 updates to wrap.
        for base in (32, 64, 128, 256):
            if base not in bounded_steps:
                bounded_steps.append(base)
    elif value_width is not None and value_width <= 16:
        for base in (32, 64, 128):
            if base not in bounded_steps:
                bounded_steps.append(base)
    elif slot_width is not None and slot_width <= 8:
        # Fallback: if value width is unknown, index width<=8 usually indicates
        # tiny tables/regs where a deeper bounded probe is still cheap.
        for base in (64, 128, 192, 256):
            if base not in bounded_steps:
                bounded_steps.append(base)
    else:
        for base in (64, 128):
            if base not in bounded_steps:
                bounded_steps.append(base)

    if not bounded_steps:
        return 0

    focus_src_for_bounded = focus_bpl.read_text(encoding="utf-8", errors="replace")
    per_probe_timeout = max(15, min(focus_timeout, 45))
    bounded_jobs: List[Tuple[int, int, Path, Path, int]] = []
    for steps in bounded_steps:
        # Convert logical rounds to scheduler steps.
        step_budget = max(1, int(steps)) * max(1, int(sched_period))
        bounded_text = _inject_focus_latch_and_unroll(
            focused_text=focus_src_for_bounded,
            assert_lines=expected_lines,
            steps=step_budget,
            target_reg=focused.target_reg,
            target_value=focused.target_value,
            slot_literal=focused.zero,
            target_old_value=focused.target_old_value,
        )
        if bounded_text is None:
            continue
        bounded_bpl = log_dir / f"{bpl_path.stem}.focused-index0.bounded{steps}.bpl"
        bounded_log = log_dir / f"{bpl_path.stem}.focused-index0.bounded{steps}.log"
        bounded_bpl.write_text(bounded_text, encoding="utf-8")
        if optimize_bpl is not None:
            optimize_bpl(bounded_bpl)
        bounded_after_opt = bounded_bpl.read_text(encoding="utf-8", errors="replace")
        latch_assert_line = _find_focus_latch_assert_line(bounded_after_opt)
        if latch_assert_line is None:
            continue
        if _focused_bounded_textual_latch_witness(
            text=bounded_after_opt,
            target_reg=focused.target_reg,
            slot_literal=focused.zero,
        ):
            synthetic_log = bounded_log.with_suffix(".textual.log")
            synthetic_log.write_text(
                "RESULT: UNSAFE\n"
                "CounterExampleResult [Line: "
                f"{latch_assert_line}]\n"
                "Focused bounded textual latch witness.\n",
                encoding="utf-8",
            )
            try:
                _write_focused_marker(
                    marker_path=marker,
                    kind="focused_under_approx_bounded",
                    result_line="RESULT: UNSAFE",
                    bpl_path=bounded_bpl,
                    log_path=synthetic_log,
                    source_bpl=bpl_path,
                    focused_target_reg=focused.target_reg,
                    focused_idx_var=focused.idx_var,
                    focused_zero=focused.zero,
                    focused_target_old_value=focused.target_old_value,
                    focused_target_value=focused.target_value,
                    focused_target_slice=focused.target_slice,
                    assert_lines=(latch_assert_line,),
                    note=(
                        "UNSAFE in a bounded focused constant-slot under-approximation "
                        "by deterministic textual latch replay. This witness is valid "
                        "for bug finding only; it is not a wraparound closure certificate."
                    ),
                )
            except Exception:
                pass
            emit(
                "[FOCUS] textual bounded latch witness found "
                f"(steps={steps}, scheduler_steps={step_budget}); original run skipped."
            )
            return 1
        bounded_jobs.append((steps, step_budget, bounded_bpl, bounded_log, latch_assert_line))

    for steps, step_budget, bounded_bpl, bounded_log, latch_assert_line in bounded_jobs:
        emit(
            f"[FOCUS] bounded under-approx probe: steps={steps} (scheduler_steps={step_budget}, timeout={per_probe_timeout}s)"
        )
        bounded_res = ultimate_runner(
            ultimate=ultimate,
            toolchain=toolchain,
            settings=settings,
            input_bpl=bounded_bpl,
            log_path=bounded_log,
            ultimate_home=ultimate_home / f"bounded-{steps}",
            toolchain_timeout_seconds=per_probe_timeout,
            os_timeout_seconds=per_probe_timeout + 60,
            cwd=log_dir,
            async_run=False,
            resource_limits=resource_limits,
            launcher_xmx_gb=max(1, int(ultimate_xmx_gb)),
        )
        if bounded_res.result_line:
            emit(f"[FOCUS] {bounded_res.result_line}")
        emit(f"[FOCUS] log: {bounded_log}")
        if not result_line_is_unsafe(bounded_res.result_line):
            continue
        hit = counterexample_line_from_log(bounded_log)
        if hit != latch_assert_line:
            emit(
                "[FOCUS] bounded UNSAFE did not hit focused latch assertion "
                f"(hit={hit}, expected={latch_assert_line}); continuing."
            )
            continue
        try:
            _write_focused_marker(
                marker_path=marker,
                kind="focused_under_approx_bounded",
                result_line=bounded_res.result_line or "RESULT: UNSAFE",
                bpl_path=bounded_bpl,
                log_path=bounded_log,
                source_bpl=bpl_path,
                focused_target_reg=focused.target_reg,
                focused_idx_var=focused.idx_var,
                focused_zero=focused.zero,
                focused_target_old_value=focused.target_old_value,
                focused_target_value=focused.target_value,
                focused_target_slice=focused.target_slice,
                assert_lines=(latch_assert_line,),
                note=(
                    "UNSAFE in a bounded focused constant-slot under-approximation. "
                    "This witness is valid for bug finding only; SAFE/UNKNOWN/TIMEOUT still fall back."
                ),
            )
        except Exception:
            pass
        emit("[FOCUS] UNSAFE witness found in bounded focused under-approximation; original run skipped.")
        return 1
    return 0
