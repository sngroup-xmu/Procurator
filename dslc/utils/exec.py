from __future__ import annotations


def wrap_resource_limits(cmd: list[str], *, enable: bool, os_timeout_s: int) -> list[str]:
    """
    Best-effort safety wrapper for WSL: lower CPU/IO priority, pin to 1 core,
    and optionally apply an OS-level timeout.
    """

    if not enable:
        return cmd

    wrapped = ["taskset", "-c", "0", "nice", "-n", "19", "ionice", "-c", "3"]
    if os_timeout_s > 0:
        wrapped.extend(["timeout", str(os_timeout_s)])
    wrapped.extend(cmd)
    return wrapped

