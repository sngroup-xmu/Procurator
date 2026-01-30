from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Optional

from dslc.utils.exec import wrap_resource_limits


@dataclass(frozen=True)
class UltimateRunResult:
    returncode: int
    log_path: Path
    result_line: Optional[str]
    pid: Optional[int] = None


def extract_result_line(log_text: str) -> Optional[str]:
    for line in log_text.splitlines():
        if "RESULT:" in line:
            return line.strip()
    return None


def run_ultimate(
    *,
    ultimate: Path,
    toolchain: Path,
    settings: Path,
    input_bpl: Path,
    log_path: Path,
    ultimate_home: Path,
    toolchain_timeout_seconds: Optional[int] = None,
    os_timeout_seconds: int = 0,
    data_dir: Optional[Path] = None,
    cwd: Optional[Path] = None,
    async_run: bool = False,
    resource_limits: bool = True,
) -> UltimateRunResult:
    """
    Run Ultimate on a single Boogie input, writing output to `log_path`.

    - Uses a per-run HOME + `-Duser.home=...` to keep Ultimate caches isolated.
    - Optionally applies CPU/IO niceness and an OS-level timeout (WSL safety).
    - Optionally starts Ultimate in the background (async_run=True).
    """

    if not ultimate.exists():
        raise FileNotFoundError(f"Ultimate executable not found: {ultimate}")
    if not toolchain.exists():
        raise FileNotFoundError(f"Ultimate toolchain not found: {toolchain}")
    if not settings.exists():
        raise FileNotFoundError(f"Ultimate settings not found: {settings}")
    if not input_bpl.exists():
        raise FileNotFoundError(f"Ultimate input not found: {input_bpl}")

    cmd: list[str] = [str(ultimate)]
    if data_dir is not None:
        cmd.extend(["-data", str(data_dir)])
    if toolchain_timeout_seconds is not None:
        cmd.append(f"--core.toolchain.timeout.in.seconds={toolchain_timeout_seconds}")
    cmd.extend(["-tc", str(toolchain), "-s", str(settings), "-i", str(input_bpl)])

    cmd = wrap_resource_limits(cmd, enable=resource_limits, os_timeout_s=os_timeout_seconds)

    ultimate_home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HOME"] = str(ultimate_home)
    prev_java_opts = env.get("JAVA_TOOL_OPTIONS", "").strip()
    user_home_opt = f"-Duser.home={ultimate_home}"
    env["JAVA_TOOL_OPTIONS"] = f"{prev_java_opts} {user_home_opt}".strip()

    log_path.parent.mkdir(parents=True, exist_ok=True)
    run_header = "[RUN] " + " ".join(cmd) + "\n"

    if async_run:
        with log_path.open("w", encoding="utf-8") as log_file:
            log_file.write(run_header)
            log_file.flush()
            proc = subprocess.Popen(
                cmd,
                stdout=log_file,
                stderr=subprocess.STDOUT,
                text=True,
                env=env,
                cwd=str(cwd) if cwd else None,
            )
        return UltimateRunResult(returncode=0, log_path=log_path, result_line=None, pid=proc.pid)

    with log_path.open("wb") as log_file:
        log_file.write(run_header.encode("utf-8"))
        log_file.flush()
        proc = subprocess.run(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            env=env,
            cwd=str(cwd) if cwd else None,
        )

    txt = log_path.read_text(encoding="utf-8", errors="replace")
    res = extract_result_line(txt)
    return UltimateRunResult(returncode=proc.returncode, log_path=log_path, result_line=res, pid=None)

