#!/usr/bin/env python3
"""
Run end-to-end (E2E) bug-finding + slicing/no-slicing ablations for a curated
set of Procurator benchmarks, then write a markdown table to USAGE.md.

Design goals:
  - No cache: each run writes to a fresh .tmp/procurator/... directory.
  - Reproducible reporting: capture walltime + final RESULT line.
  - Minimal policy: the benchmark list is explicit and lives here (so "what we
    tested" is auditable in git).
"""

from __future__ import annotations

import argparse
import datetime as _dt
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional


RE_RESULT = re.compile(r"^\[RESULT\]\s+RESULT:\s*(.*)$")


@dataclass(frozen=True)
class RunCfg:
    name: str
    args: list[str]


@dataclass
class RunResult:
    status: str  # UNSAFE / SAFE / TIMEOUT / OOM / ERROR / UNKNOWN
    wall_s: float
    out_dir: Optional[str]
    log_path: Optional[str]


def _repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def _find_default_ultimate(root: Path) -> Optional[Path]:
    # Keep in sync with USAGE.md "Common Ultimate settings".
    candidates = [
        root / ".tmp" / "orphan-worktree-20260129-005608" / "UGemCutter-linux" / "Ultimate",
        root / "UGemCutter-linux" / "Ultimate",
    ]
    for p in candidates:
        if p.exists():
            return p
    return None


def _run(cmd: list[str], *, cwd: Path) -> tuple[int, str]:
    proc = subprocess.run(
        cmd,
        cwd=str(cwd),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
    )
    return proc.returncode, proc.stdout


def _classify(stdout: str, rc: int) -> str:
    # Prefer explicit RESULT line from procurator CLI.
    # For wraparound multi-stage runs, summarize as "closure_check SAFE; confirm UNSAFE".
    stage = ""
    stage_results: list[tuple[str, str]] = []
    for ln in stdout.splitlines():
        ln = ln.rstrip()
        if ln.startswith("[STAGE] "):
            stage = ln.split("[STAGE] ", 1)[1].split(" ", 1)[0].strip()
            continue
        m = RE_RESULT.match(ln.strip())
        if m:
            msg = m.group(1).strip()
            st = stage or "verify"
            stage_results.append((st, msg))

    if stage_results:
        # If we have both closure_check and confirm, format them explicitly.
        seen = {s: m for s, m in stage_results}
        if "closure_check" in seen and "confirm" in seen:
            def _short(msg: str) -> str:
                lo = msg.lower()
                if "proved your program to be incorrect" in lo:
                    return "UNSAFE"
                if "proved your program to be correct" in lo:
                    return "SAFE"
                if "timeout" in lo:
                    return "TIMEOUT"
                if "incorrect syntax" in lo:
                    return "ERROR"
                return "UNKNOWN"

            return f"closure_check {_short(seen['closure_check'])}; confirm {_short(seen['confirm'])}"

        # Otherwise fall back to last stage result.
        _, last_msg = stage_results[-1]
        lo = last_msg.lower()
        if "proved your program to be incorrect" in lo:
            return "UNSAFE"
        if "proved your program to be correct" in lo:
            return "SAFE"
        if "timeout" in lo:
            return "TIMEOUT"
        if "incorrect syntax" in lo:
            return "ERROR"
        return "UNKNOWN"
    if "out of memory" in stdout.lower():
        return "OOM"
    if rc != 0:
        return "ERROR"
    return "UNKNOWN"


def _extract_paths(stdout: str) -> tuple[Optional[str], Optional[str]]:
    out_dir = None
    log_path = None
    for ln in stdout.splitlines():
        if ln.startswith("[OK] bpl: "):
            # verify
            p = ln.split("[OK] bpl: ", 1)[1].strip()
            out_dir = str(Path(p).parent)
        if ln.startswith("[OK] base bpl: "):
            # wraparound
            p = ln.split("[OK] base bpl: ", 1)[1].strip()
            out_dir = str(Path(p).parent)
        if ln.startswith("[LOG] "):
            log_path = ln.split("[LOG] ", 1)[1].strip()
    return out_dir, log_path


def _fmt_s(x: float) -> str:
    return f"{x:.1f}"


def _md_escape(s: str) -> str:
    return s.replace("|", "\\|")


def _table(rows: Iterable[list[str]]) -> str:
    out = []
    for i, r in enumerate(rows):
        if i == 0:
            out.append("| " + " | ".join(r) + " |")
            out.append("|" + "|".join(["---"] * len(r)) + "|")
        else:
            out.append("| " + " | ".join(r) + " |")
    return "\n".join(out) + "\n"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ultimate", default="", help="Path to Ultimate (default: auto-detect)")
    ap.add_argument("--timeout", type=int, default=600, help="Timeout per Ultimate run (seconds)")
    ap.add_argument("--wraparound-timeout", type=int, default=1200, help="Timeout per wraparound stage (seconds)")
    ap.add_argument(
        "--confirm-unroll",
        type=int,
        default=9,
        help=(
            "Default unroll bound for wraparound confirm stage. "
            "Some specs override this internally (e.g., DistCache P2C spineload needs 9 steps)."
        ),
    )
    ap.add_argument("--update-usage", action="store_true", help="Update USAGE.md in-place")
    ap.add_argument("--only", choices=["all", "verify", "wraparound"], default="all", help="Subset to run")
    ap.add_argument("--dry-run", action="store_true", help="Print commands but do not execute")
    ns = ap.parse_args(argv)

    root = _repo_root()
    ultimate = Path(ns.ultimate) if ns.ultimate else _find_default_ultimate(root)
    if not ultimate or not ultimate.exists():
        print("error: Ultimate not found; pass --ultimate", file=sys.stderr)
        return 2

    # Shared Ultimate settings for bug-finding (witness on for UNSAFE).
    verify_toolchain = "dslc/toolchain/ultimate/ReachSafety-Witness.xml"
    verify_settings = "dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf"

    wrap_confirm_toolchain = "dslc/toolchain/ultimate/ReachSafety-Witness.xml"
    wrap_confirm_settings = "dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf"
    wrap_closure_toolchain = "dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml"
    wrap_closure_settings = "dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf"

    # Curated regression list for NSDI-style bug-finding (functional, reproducible).
    #
    # NOTE: Some older `.prop` files are "wraparound demos" that assert `reg[idx] != 0`;
    # we do not include them here because they don't capture functional correctness.
    specs_verify = [
        ("Netchain fast-forward", "Procurator/argo/code/spec/bench/netchain_bug_s1s2_fastforward.prop"),
        ("ATP bound bug", "Procurator/argo/code/spec/bench/atp_bug.prop"),
        ("DistCache leaf pktloss clone/drop", "Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop"),
        ("DistCache CM3/CM4 write wiring", "Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop"),
        ("DistCache spine cache_frequency idx", "Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop"),
    ]
    # (title, spec, confirm_unroll_override)
    specs_wrap = [
        ("DistCache P2C wrong-choice after leafload overflow", "Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop", 6),
        ("DistCache P2C wrong-choice after spineload overflow", "Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop", 9),
    ]

    cfgs_verify = [
        RunCfg(
            name="opt",
            args=[
                "./bin/procurator",
                "verify",
                "--env",
                "spec",
                "--use-spec-max-steps",
                "--ultimate",
                str(ultimate),
                "--toolchain",
                verify_toolchain,
                "--settings",
                verify_settings,
                "--ultimate-timeout-seconds",
                str(ns.timeout),
                "--no-resource-limits",
            ],
        ),
        RunCfg(
            name="base",
            args=[
                "./bin/procurator",
                "verify",
                "--env",
                "spec",
                "--use-spec-max-steps",
                "--no-slicing",
                "--no-env-prune",
                "--ultimate",
                str(ultimate),
                "--toolchain",
                verify_toolchain,
                "--settings",
                verify_settings,
                "--ultimate-timeout-seconds",
                str(ns.timeout),
                "--no-resource-limits",
            ],
        ),
    ]

    cfgs_wrap = [
        RunCfg(
            name="opt",
            args=[
                "./bin/procurator",
                "wraparound",
                "--ultimate",
                str(ultimate),
                "--stages",
                "closure_check,confirm",
                "--soundness",
                "closure",
                "--timeout-seconds",
                str(ns.wraparound_timeout),
                "--toolchain",
                wrap_confirm_toolchain,
                "--settings",
                wrap_confirm_settings,
                "--closure-toolchain",
                wrap_closure_toolchain,
                "--closure-settings",
                wrap_closure_settings,
                "--no-resource-limits",
            ],
        ),
        RunCfg(
            name="base",
            args=[
                "./bin/procurator",
                "wraparound",
                "--ultimate",
                str(ultimate),
                "--stages",
                "closure_check,confirm",
                "--soundness",
                "closure",
                "--timeout-seconds",
                str(ns.wraparound_timeout),
                "--no-slicing",
                "--no-two-stage",
                "--toolchain",
                wrap_confirm_toolchain,
                "--settings",
                wrap_confirm_settings,
                "--closure-toolchain",
                wrap_closure_toolchain,
                "--closure-settings",
                wrap_closure_settings,
                "--no-resource-limits",
            ],
        ),
    ]

    rows = [
        [
            "bug / benchmark",
            "spec",
            "opt cmd",
            "opt time (s)",
            "opt result",
            "base cmd",
            "base time (s)",
            "base result",
            "notes",
        ]
    ]

    def run_one(spec: str, cfg: RunCfg, extra_args: Optional[list[str]] = None) -> RunResult:
        cmd = cfg.args + (extra_args or []) + ["--spec", spec]
        if ns.dry_run:
            print("[DRY]", " ".join(cmd))
            return RunResult(status="DRY", wall_s=0.0, out_dir=None, log_path=None)
        t0 = time.monotonic()
        rc, out = _run(cmd, cwd=root)
        wall = time.monotonic() - t0
        status = _classify(out, rc)
        out_dir, log_path = _extract_paths(out)
        # Store the raw stdout alongside the log to help later debugging.
        if out_dir:
            try:
                Path(out_dir, f"{Path(spec).stem}.{cfg.name}.procurator.stdout.txt").write_text(out)
            except OSError:
                pass
        return RunResult(status=status, wall_s=wall, out_dir=out_dir, log_path=log_path)

    if ns.only in {"all", "verify"}:
        # Verify-style bugs.
        for title, spec in specs_verify:
            spec_path = root / spec
            if not spec_path.exists():
                print(f"[SKIP] missing spec: {spec}", file=sys.stderr)
                continue
            opt = run_one(spec, cfgs_verify[0])
            base = run_one(spec, cfgs_verify[1])
            rows.append(
                [
                    _md_escape(title),
                    f"`{spec}`",
                    "`verify (slicing)`",
                    _fmt_s(opt.wall_s),
                    opt.status,
                    "`verify --no-slicing --no-env-prune`",
                    _fmt_s(base.wall_s),
                    base.status,
                    "see per-run dirs under `.tmp/procurator/verify/`",
                ]
            )

    if ns.only in {"all", "wraparound"}:
        # Wraparound bugs.
        for title, spec, confirm_unroll in specs_wrap:
            spec_path = root / spec
            if not spec_path.exists():
                print(f"[SKIP] missing spec: {spec}", file=sys.stderr)
                continue
            extra = ["--confirm-unroll", str(confirm_unroll)]
            opt = run_one(spec, cfgs_wrap[0], extra_args=extra)
            base = run_one(spec, cfgs_wrap[1], extra_args=extra)
            rows.append(
                [
                    _md_escape(title),
                    f"`{spec}`",
                    "`wraparound (slicing)`",
                    _fmt_s(opt.wall_s),
                    opt.status,
                    "`wraparound --no-slicing --no-two-stage`",
                    _fmt_s(base.wall_s),
                    base.status,
                    "UNSAFE is sound only when closure_check is SAFE (enforced by --soundness closure)",
                ]
            )

    md = []
    md.append("## E2E Ablations (Auto-Generated)\n")
    md.append(
        f"Generated on {_dt.datetime.now().strftime('%Y-%m-%d %H:%M:%S')} using Ultimate `{ultimate}`.\n"
    )
    md.append(_table(rows))
    block = "\n".join(md)

    if ns.update_usage:
        usage = root / "USAGE.md"
        txt = usage.read_text(encoding="utf-8", errors="replace")
        start = "<!-- E2E_ABLATIONS_START -->"
        end = "<!-- E2E_ABLATIONS_END -->"
        if start not in txt or end not in txt:
            raise SystemExit("USAGE.md missing E2E_ABLATIONS markers")
        pre, rest = txt.split(start, 1)
        _, post = rest.split(end, 1)
        new_txt = pre + start + "\n\n" + block + "\n\n" + end + post
        usage.write_text(new_txt, encoding="utf-8")
        print(f"[OK] updated {usage}")
    else:
        print(block)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
