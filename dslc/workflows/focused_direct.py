from __future__ import annotations

import json
import re
import hashlib
from pathlib import Path
from typing import Callable, List, Optional, Sequence, Tuple

from dslc.toolchain.ultimate_runner import UltimateRunResult, run_ultimate
from dslc.transform.focused_direct import find_focused_direct_assert_lines, focus_dynamic_index0_register_assert
from dslc.transform.wraparound_analyze import _is_mainprocedure_loop_header
from dslc.transform.wraparound_unroll import unroll_mainprocedure_loop_text


UltimateRunner = Callable[..., UltimateRunResult]
Optimizer = Callable[[Path], None]
Emitter = Callable[[str], None]


_RE_PROC_MAIN = re.compile(r"^\s*procedure(?:\s*\{[^}]*\}\s*)?\s+mainProcedure\s*\(")
_RE_PROC_DECL = re.compile(r"^\s*procedure(?:\s*\{[^}]*\}\s*)?\s+([^\s(]+)\s*\(")
_RE_PROC_SCHED_PHASE = re.compile(r"\bprocurator_phase\s*==\s*(\d+)\b")
_RE_CALL_STMT = re.compile(r"\bcall\s+([^\s(;]+)\s*\(")
_RE_ATTR = re.compile(r"\{:[^}]*\}")
_RE_ASSUME_EQ = re.compile(
    r"^\s*assume\s*\(\s*(?P<lhs>[A-Za-z_][A-Za-z0-9_.]*)\s*==\s*(?P<rhs>[^)]+)\)\s*;\s*$"
)
_RE_HAVOC = re.compile(r"^(?P<indent>\s*)havoc\s+(?P<vars>[^;]+)\s*;\s*$")
_RE_WSL_MNT = re.compile(r"^/mnt/(?P<drive>[a-zA-Z])/(?P<rest>.*)$")
_RE_WIN_DRIVE = re.compile(r"^(?P<drive>[a-zA-Z]):[\\/](?P<rest>.*)$")


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
            )
            if refreshed_lines:
                expected_lines = refreshed_lines
            else:
                refresh_failed = True
    except Exception:
        refresh_failed = True

    focus_timeout = int(ultimate_timeout_seconds) if int(ultimate_timeout_seconds) > 0 else 120
    emit(f"[FOCUS] direct prepass: {focused.reason}")
    res = ultimate_runner(
        ultimate=ultimate,
        toolchain=toolchain,
        settings=settings,
        input_bpl=focus_bpl,
        log_path=focus_log,
        ultimate_home=ultimate_home,
        toolchain_timeout_seconds=focus_timeout,
        os_timeout_seconds=focus_timeout + 300,
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
                focused_target_value=focused.target_value,
                focused_target_slice=focused.target_slice,
                assert_lines=expected_lines,
                note=(
                    "UNSAFE in a slot-0 focused under-approximation. "
                    "This is a direct bug witness only; it is not a wraparound closure certificate."
                ),
            )
        except Exception:
            pass
        emit("[FOCUS] UNSAFE witness found in focused under-approximation; original run skipped.")
        return 1

    # Stage 2: only when the focused query timed out/unknown, run bounded
    # under-approx probes with a latch assertion. These are UNSAFE-only hints.
    if not result_line_is_timeout_or_unknown(res.result_line):
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
    per_probe_timeout = max(60, min(focus_timeout, 150))
    for steps in bounded_steps:
        # Convert logical rounds to scheduler steps.
        step_budget = max(1, int(steps)) * max(1, int(sched_period))
        bounded_text = _inject_focus_latch_and_unroll(
            focused_text=focus_src_for_bounded,
            assert_lines=expected_lines,
            steps=step_budget,
        )
        if bounded_text is None:
            continue
        bounded_bpl = log_dir / f"{bpl_path.stem}.focused-index0.bounded{steps}.bpl"
        bounded_log = log_dir / f"{bpl_path.stem}.focused-index0.bounded{steps}.log"
        bounded_bpl.write_text(bounded_text, encoding="utf-8")
        if optimize_bpl is not None:
            optimize_bpl(bounded_bpl)
        latch_assert_line = _find_focus_latch_assert_line(
            bounded_bpl.read_text(encoding="utf-8", errors="replace")
        )
        if latch_assert_line is None:
            continue
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
            os_timeout_seconds=per_probe_timeout + 180,
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
                focused_target_value=focused.target_value,
                focused_target_slice=focused.target_slice,
                assert_lines=(latch_assert_line,),
                note=(
                    "UNSAFE in a bounded slot-0 focused under-approximation. "
                    "This witness is valid for bug finding only; SAFE/UNKNOWN/TIMEOUT still fall back."
                ),
            )
        except Exception:
            pass
        emit("[FOCUS] UNSAFE witness found in bounded focused under-approximation; original run skipped.")
        return 1
    return 0
