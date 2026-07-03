from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


def _read_tail_text(path: Path, *, max_bytes: int = 1_000_000) -> str:
    """
    Read the last `max_bytes` bytes of a text file (best-effort).

    Rationale: Ultimate logs can be large. For early-stop monitoring we only need
    the most recent lines that contain RESULT / "Registering result ..." markers.
    """

    try:
        with path.open("rb") as f:
            try:
                f.seek(-max(1, int(max_bytes)), os.SEEK_END)
            except OSError:
                f.seek(0)
            data = f.read()
    except FileNotFoundError:
        return ""
    return data.decode("utf-8", errors="replace")


def _toolchain_has_witnessprinter(toolchain: Path) -> bool:
    """
    Best-effort detection for whether a toolchain XML enables witness printing.

    We use this to avoid a redundant second CONFIRM run:
      - if CONFIRM already runs with a witness-enabled toolchain, we reuse its witness.
      - otherwise, we may re-run with a witness toolchain when we explicitly need one.
    """

    try:
        txt = toolchain.read_text(encoding="utf-8", errors="ignore").lower()
    except Exception:
        return False
    return "ultimate.witnessprinter" in txt


@dataclass(frozen=True)
class StageRunResult:
    stage: str
    returncode: int
    wall_time_s: float
    result_line: Optional[str]

    @property
    def is_unknown(self) -> bool:
        """
        True when we could not classify the run as SAFE/UNSAFE.

        Typical causes:
          - Ultimate timed out / crashed (no RESULT line),
          - toolchain printed no recognizable result marker.
        """

        return (not self.is_safe) and (not self.is_unsafe)

    @property
    def timed_out(self) -> bool:
        """
        Best-effort timeout detection.

        We commonly run Ultimate under the external `timeout` wrapper, which
        returns 124 on timeout and 137 if killed (SIGKILL).
        """

        if self.returncode in (124, 137):
            return True
        # Ultimate can also exit with 0 but still report a timeout in its RESULT line.
        # We treat this as a timeout for refinement/certification logic.
        if self.result_line and "timeout" in self.result_line.lower():
            return True
        return False

    @property
    def is_safe(self) -> bool:
        if not self.result_line:
            return False
        s = self.result_line.lower()
        return ("result: safe" in s) or ("proved your program to be correct" in s)

    @property
    def is_unsafe(self) -> bool:
        if not self.result_line:
            return False
        s = self.result_line.lower()
        return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)


def _select_stage_result_line(
    *,
    killed_early: bool,
    observed_result_line: Optional[str],
    final_result_line: Optional[str],
) -> Optional[str]:
    """
    Choose a stable semantic stage result line.

    Rationale:
    - Some Ultimate toolchains can keep running (post-processing) after reaching SAFE/UNSAFE.
    - When we early-stop, Ultimate may log a synthetic Timeout/Cancel RESULT line due to SIGTERM.
      In that case the "observed" SAFE/UNSAFE is the semantic result we intentionally stopped on.
    """

    if killed_early and observed_result_line:
        return observed_result_line
    return final_result_line


def _extract_result_line(log_text: str) -> Optional[str]:
    lines = log_text.splitlines()

    # Prefer explicit top-level RESULT markers when available.
    #
    # Rationale: Ultimate may emit intermediate "Registering result SAFE ..." lines for
    # error locations but still end the run with an explicit Timeout/Unknown. Treating
    # such runs as SAFE is unsafe for regression tracking (it can hide real bugs).
    last_result: Optional[str] = None
    for line in lines:
        if "RESULT:" in line:
            last_result = line.strip()

    # UNSAFE always wins (even if later timeouts happen).
    re_remaining = re.compile(
        r"Registering result (SAFE|UNSAFE) .*\((?P<rem>\d+) of (?P<tot>\d+) remaining\)"
    )
    for line in lines:
        if "Registering result UNSAFE" in line:
            return "RESULT: UNSAFE"

    # If Ultimate printed a RESULT marker, trust it.
    if last_result is not None:
        return last_result

    # Otherwise, fall back to SAFE when all error locations are resolved.
    #
    # IMPORTANT: safe registration is only meaningful when Ultimate indicates
    # "(0 of N remaining)".
    for line in lines:
        m = re_remaining.search(line)
        if not m:
            continue
        if m.group(1) != "SAFE":
            continue
        if int(m.group("rem")) == 0:
            return "RESULT: SAFE"

    return None
