from __future__ import annotations

import os
import re
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
    """
    Extract a coarse SAFE/UNSAFE result marker from an Ultimate log.

    Notes:
    - Some Ultimate toolchains may time out *after* they already registered results for
      all error locations (e.g. during post-processing). In that case, the
      "Registering result ..." lines can be more informative than a final RESULT line.
    - We only treat SAFE as final when Ultimate indicates "(0 of N remaining)" *and*
      there is no explicit final `RESULT:` marker contradicting it (e.g. Timeout).
    """

    lines = log_text.splitlines()

    # 0) Prefer explicit final RESULT markers when available.
    #
    # Rationale: Ultimate sometimes logs intermediate "Registering result SAFE ..."
    # lines for error locations but still ends with a top-level Timeout/Unknown.
    # For our regression pipeline we must not misclassify those runs as SAFE.
    last_result: Optional[str] = None
    for line in lines:
        if "RESULT:" in line:
            last_result = line.strip()

    # 1) Fast path: any UNSAFE registration wins (even if later timeouts happen).
    for line in lines:
        if "Registering result UNSAFE" in line:
            return "RESULT: UNSAFE"

    # 2) If Ultimate printed a RESULT marker, trust it.
    if last_result is not None:
        return last_result

    # 3) SAFE when all error locations have been resolved (only when no RESULT exists).
    re_remaining = re.compile(
        r"Registering result (SAFE|UNSAFE) .*\((?P<rem>\d+) of (?P<tot>\d+) remaining\)"
    )
    for line in lines:
        m = re_remaining.search(line)
        if not m:
            continue
        if m.group(1) != "SAFE":
            continue
        if int(m.group("rem")) == 0:
            return "RESULT: SAFE"

    return None


def write_launcher_ini(
    *,
    ultimate: Path,
    out_ini: Path,
    xmx_gb: int,
    xms_mb: int = 512,
) -> Path:
    """
    Create a launcher .ini for the Eclipse-based Ultimate binary with a bounded JVM heap.

    Rationale: Ultimate ships with an `Ultimate.ini` that often sets `-Xmx12G`. On WSL
    this can reserve too much memory and freeze the system. Passing `--launcher.ini`
    with a per-run ini keeps memory usage predictable and isolates changes from the
    vendored Ultimate distribution.
    """

    xmx_gb_i = max(1, int(xmx_gb))
    xms_mb_i = max(16, int(xms_mb))

    src_ini = ultimate.with_suffix(".ini")
    if src_ini.exists():
        lines = src_ini.read_text(encoding="utf-8", errors="replace").splitlines()
    else:
        # Minimal Eclipse launcher ini that matches common Ultimate distributions.
        lines = [
            "--launcher.suppressErrors",
            "-nosplash",
            "-consoleLog",
            "--console",
            "-data",
            "@user.home/.ultimate",
            "-vm",
            "/usr/bin/java",
            "-vmargs",
        ]

    out: list[str] = []
    saw_vmargs = False
    saw_xmx = False
    saw_xms = False

    for ln in lines:
        s = ln.strip()
        if s == "-vmargs":
            saw_vmargs = True
            out.append(ln)
            continue
        if re.match(r"^-Xmx\d+[KMG]$", s, flags=re.IGNORECASE):
            out.append(f"-Xmx{xmx_gb_i}G")
            saw_xmx = True
            continue
        if re.match(r"^-Xms\d+[KMG]$", s, flags=re.IGNORECASE):
            out.append(f"-Xms{xms_mb_i}M")
            saw_xms = True
            continue
        out.append(ln)

    if not saw_vmargs:
        out.append("-vmargs")
        saw_vmargs = True

    if not saw_xmx:
        out.append(f"-Xmx{xmx_gb_i}G")
    if not saw_xms:
        out.append(f"-Xms{xms_mb_i}M")

    out_ini.parent.mkdir(parents=True, exist_ok=True)
    out_ini.write_text("\n".join(out) + "\n", encoding="utf-8")
    return out_ini


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
    launcher_xmx_gb: Optional[int] = None,
    launcher_xms_mb: int = 512,
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
    if launcher_xmx_gb is not None:
        launcher_ini = write_launcher_ini(
            ultimate=ultimate,
            out_ini=ultimate_home / "Ultimate.launcher.ini",
            xmx_gb=int(launcher_xmx_gb),
            xms_mb=int(launcher_xms_mb),
        )
        # Eclipse launcher supports overriding the ini path via `--launcher.ini`.
        cmd.extend(["--launcher.ini", str(launcher_ini)])
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
                # Make it safe to terminate the whole Ultimate process tree (WSL safety).
                start_new_session=True,
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
            # Isolate as its own process group so callers can safely kill it (WSL safety).
            start_new_session=True,
        )

    txt = log_path.read_text(encoding="utf-8", errors="replace")
    res = extract_result_line(txt)
    return UltimateRunResult(returncode=proc.returncode, log_path=log_path, result_line=res, pid=None)
