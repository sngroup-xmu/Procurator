from __future__ import annotations

import json
import re
import hashlib
from pathlib import Path
from typing import Callable, Optional

from dslc.toolchain.ultimate_runner import UltimateRunResult, run_ultimate
from dslc.transform.focused_direct import find_focused_direct_assert_lines, focus_dynamic_index0_register_assert


UltimateRunner = Callable[..., UltimateRunResult]
Optimizer = Callable[[Path], None]
Emitter = Callable[[str], None]


def result_line_is_unsafe(result_line: Optional[str]) -> bool:
    if not result_line:
        return False
    s = result_line.lower()
    return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)


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
    if data.get("kind") != "focused_under_approx":
        return None
    if data.get("source_bpl_sha256") != _sha256_file(bpl_path):
        return None
    focused_bpl = data.get("bpl")
    if not isinstance(focused_bpl, str) or not focused_bpl.endswith(f"{bpl_path.stem}.focused-index0.bpl"):
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

    focus_bpl = log_dir / f"{bpl_path.stem}.focused-index0.bpl"
    focus_log = log_dir / f"{bpl_path.stem}.focused-index0.log"
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

    if not result_line_is_unsafe(res.result_line):
        return 0

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

    marker = log_dir / f"{bpl_path.stem}.focused-index0.unsafe.json"
    try:
        marker.write_text(
            json.dumps(
                {
                    "kind": "focused_under_approx",
                    "result_line": res.result_line,
                    "bpl": str(focus_bpl),
                    "log": str(focus_log),
                    "source_bpl": str(bpl_path),
                    "source_bpl_sha256": _sha256_file(bpl_path),
                    "focused_bpl_sha256": _sha256_file(focus_bpl),
                    "target_reg": focused.target_reg,
                    "idx_var": focused.idx_var,
                    "zero": focused.zero,
                    "target_value": focused.target_value,
                    "assert_line": expected_lines[0] if expected_lines else focused.assert_line,
                    "assert_lines": list(expected_lines),
                    "note": (
                        "UNSAFE in a slot-0 focused under-approximation. "
                        "This is a direct bug witness only; it is not a wraparound closure certificate."
                    ),
                },
                indent=2,
                sort_keys=True,
            )
            + "\n",
            encoding="utf-8",
        )
    except Exception:
        pass
    emit("[FOCUS] UNSAFE witness found in focused under-approximation; original run skipped.")
    return 1
