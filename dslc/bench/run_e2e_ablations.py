#!/usr/bin/env python3
"""
Run end-to-end (E2E) bug-finding + slicing/no-slicing ablations for a curated
set of Procurator (NSDI-style) benchmarks, then write a markdown table to USAGE.md.

Key policy:
  - Use ONLY `procurator verify` (wraparound is integrated; no legacy `procurator wraparound`).
  - Always use witness-enabled toolchain to make UNSAFE auditable (pseudo-CEX guard).
  - For wraparound UNSAFE, require a certified manifest: (ENTRY UNSAFE, CONFIRM UNSAFE, CLOSURE SAFE).
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Optional, Union

try:
    from dslc.bench.validate_counterexample import summarize_witness, validate_wraparound_manifest
except ModuleNotFoundError:
    # Allow running directly as a script:
    #   python3 dslc/bench/run_e2e_ablations.py ...
    from validate_counterexample import summarize_witness, validate_wraparound_manifest


RE_RESULT = re.compile(r"^\[RESULT\]\s+RESULT:\s*(.*)$")


@dataclass(frozen=True)
class RunCfg:
    name: str
    args: list[str]


@dataclass(frozen=True)
class Bench:
    name: str
    spec: str
    category: str
    env: str  # spec/max
    wraparound: str  # off/auto/force
    timeout_s: int
    use_spec_max_steps: bool
    extra_args: list[str]
    notes: str
    # Optional override for the base (`--no-slicing --no-env-prune`) run.
    # This is useful when the default low-memory Z3 profile (2GB) OOMs on
    # very large unsliced programs during CFG/RCFG construction.
    base_settings: str = ""


@dataclass
class RunResult:
    status: str  # UNSAFE / SAFE / TIMEOUT / OOM / ERROR / UNKNOWN
    wall_s: float
    out_dir: Optional[str]
    log_path: Optional[str]
    sanity: str  # OK / FAIL / NA


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
    # Legacy helper; kept for unit tests / dry-run style invocations.
    proc = subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace")
    return proc.returncode, proc.stdout


def _classify(stdout: str, rc: int) -> str:
    # Prefer explicit RESULT line from procurator CLI.
    last_result: Optional[str] = None
    for ln in stdout.splitlines():
        m = RE_RESULT.match(ln.strip())
        if m:
            last_result = m.group(1).strip()

    if last_result is not None:
        lo = last_result.lower()
        if "unsafe" in lo or "proved your program to be incorrect" in lo:
            return "UNSAFE"
        # "UNSAFE" contains "safe" as a substring; check UNSAFE first.
        if ("safe" in lo or "proved your program to be correct" in lo) and ("unsafe" not in lo):
            return "SAFE"
        if "timeout" in lo:
            return "TIMEOUT"
        if "out of memory" in lo or "oom" in lo:
            return "OOM"
        if "toolchain returned no result" in lo:
            return "ERROR"
        if "incorrect syntax" in lo or "error" in lo or "exception" in lo:
            return "ERROR"
        if "unknown" in lo:
            return "UNKNOWN"
        return "UNKNOWN"

    if "out of memory" in stdout.lower():
        return "OOM"
    if rc != 0:
        return "ERROR"
    return "UNKNOWN"


def _read_text_tail(path: Path, *, max_bytes: int = 250_000) -> str:
    try:
        with path.open("rb") as f:
            f.seek(0, os.SEEK_END)
            size = f.tell()
            f.seek(max(0, size - max_bytes), os.SEEK_SET)
            data = f.read()
        return data.decode("utf-8", errors="replace")
    except OSError:
        return ""


def _refine_error_from_log(*, status: str, log_path: Optional[str]) -> str:
    """
    `procurator verify` sometimes only reports "Toolchain returned no result" even when
    the Ultimate log tail clearly indicates a root cause such as Z3 OOM.

    Refine ERROR into OOM/TIMEOUT when the log contains evidence.
    """
    if status != "ERROR" or not log_path:
        return status
    txt = _read_text_tail(Path(log_path))
    if not txt:
        return status

    lo = txt.lower()
    if "out of memory" in lo or "outofmemoryerror" in lo:
        return "OOM"
    if "result: ultimate could not prove your program: timeout" in lo:
        return "TIMEOUT"
    return status


def _extract_paths(stdout: str) -> tuple[Optional[str], Optional[str]]:
    out_dir = None
    log_path = None
    for ln in stdout.splitlines():
        if ln.startswith("[OK] bpl: "):
            p = ln.split("[OK] bpl: ", 1)[1].strip()
            out_dir = str(Path(p).parent)
        if ln.startswith("[LOG] "):
            log_path = ln.split("[LOG] ", 1)[1].strip()
    return out_dir, log_path


def _run_streaming(
    *,
    cmd: list[str],
    cwd: Path,
    tag: str,
    stdout_path: Path,
) -> tuple[int, str, Optional[str], Optional[str]]:
    """
    Run a long `procurator verify` command while:
      - streaming key progress lines to our stdout (so WSL runs are observable),
      - tee-ing full stdout to a file for debugging,
      - extracting (out_dir, log_path, result_line) incrementally.
    """

    stdout_path.parent.mkdir(parents=True, exist_ok=True)
    out_dir: Optional[str] = None
    log_path: Optional[str] = None
    last_result: str = ""
    wrap_manifest: Optional[str] = None

    proc = subprocess.Popen(
        cmd,
        cwd=str(cwd),
        env={**os.environ, "PYTHONUNBUFFERED": "1"},
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        errors="replace",
        bufsize=1,
    )
    assert proc.stdout is not None

    # Always stream something upfront so it's obvious which benchmark is running.
    print(f"[{tag}] [CMD] {' '.join(cmd)}", flush=True)

    with stdout_path.open("w", encoding="utf-8") as f:
        for line in proc.stdout:
            f.write(line)

            s = line.rstrip("\n")
            if s.startswith("[OK] bpl: "):
                p = s.split("[OK] bpl: ", 1)[1].strip()
                out_dir = str(Path(p).parent)
                print(f"[{tag}] {s}", flush=True)
                continue
            if s.startswith("[WRAP]"):
                # Keep wraparound progress visible.
                if s.startswith("[WRAP] CERTIFIED UNSAFE:"):
                    wrap_manifest = s.split("[WRAP] CERTIFIED UNSAFE:", 1)[1].strip()
                    try:
                        mp = Path(wrap_manifest)
                        out_dir = str(mp.resolve().parents[2])
                    except Exception:
                        # Best-effort only.
                        pass
                print(f"[{tag}] {s}", flush=True)
                continue
            if s.startswith("[RESULT]"):
                last_result = s
                print(f"[{tag}] {s}", flush=True)
                continue
            if s.startswith("[LOG]"):
                log_path = s.split("[LOG] ", 1)[1].strip()
                print(f"[{tag}] {s}", flush=True)
                continue
            if s.startswith(("[ERR]", "[FAIL]", "[CEX-WARN]")):
                print(f"[{tag}] {s}", flush=True)
                continue

    rc = proc.wait()

    # Some runs print only a wraparound certificate and exit with rc=1.
    # Keep the most informative "result-like" line we saw.
    if not last_result:
        try:
            txt = stdout_path.read_text(encoding="utf-8", errors="replace")
        except OSError:
            txt = ""
        for ln in txt.splitlines():
            if ln.startswith("[RESULT]"):
                last_result = ln.strip()
        # Wraparound early exit.
        if "[WRAP] CERTIFIED UNSAFE:" in txt:
            last_result = "[RESULT] RESULT: Ultimate proved your program to be incorrect!"

    return rc, last_result, out_dir, log_path


def _fmt_s(x: float) -> str:
    return f"{x:.1f}"


def _md_escape(s: str) -> str:
    return s.replace("|", "\\|")


def _table(rows: Iterable[list[str]]) -> str:
    out: list[str] = []
    for i, r in enumerate(rows):
        if i == 0:
            out.append("| " + " | ".join(r) + " |")
            out.append("|" + "|".join(["---"] * len(r)) + "|")
        else:
            out.append("| " + " | ".join(r) + " |")
    return "\n".join(out) + "\n"


def _sanity_check(*, root: Path, out_dir: str) -> str:
    """
    Validate UNSAFE runs:
      - normal verify: witness must correspond to DSL global assert (or at least be classifiable)
      - wraparound: manifest must be certified (entry unsafe, confirm unsafe, closure safe)
    """
    od = Path(out_dir)
    focused = sorted(od.glob("*.focused-index0.unsafe.json"), key=lambda p: p.stat().st_mtime, reverse=True)
    if focused:
        s = summarize_witness(out_dir=od)
        return "OK" if s.ok else f"FAIL({s.kind})"

    witness = list(od.glob("*.bpl-witness.graphml"))
    if witness:
        s = summarize_witness(out_dir=od)
        return "OK" if s.ok else f"FAIL({s.kind})"

    # Wraparound CEGIS writes one manifest per attempted target under:
    #   <out_dir>/wraparound/target.*/wraparound.cegis.manifest.json
    mpaths = sorted((od / "wraparound").glob("target.*/wraparound.cegis.manifest.json"))
    if mpaths:
        for mp in mpaths:
            ok, _ = validate_wraparound_manifest(mp)
            if ok:
                return "OK"
        return "FAIL(wraparound)"

    return "NA"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ultimate", default="", help="Path to Ultimate (default: auto-detect)")
    ap.add_argument("--timeout", type=int, default=900, help="Default timeout per Ultimate run (seconds)")
    ap.add_argument(
        "--ultimate-xmx-gb",
        type=int,
        default=4,
        help="Max Java heap for Ultimate (WSL safety; default: 4).",
    )
    ap.add_argument(
        "--results-json",
        default="",
        help="Write intermediate results to JSON (default: .tmp/procurator/e2e_ablations_results.json).",
    )
    ap.add_argument(
        "--resume",
        action="store_true",
        help="Resume from --results-json (skip runs already recorded with the same cmd).",
    )
    ap.add_argument(
        "--report-only",
        action="store_true",
        help="Do not execute; render a table from --results-json (if any).",
    )
    ap.add_argument(
        "--max-new-benches",
        type=int,
        default=0,
        help="Stop after executing this many new benches (0 = no limit).",
    )
    ap.add_argument("--update-usage", action="store_true", help="Update USAGE.md in-place")
    ap.add_argument("--only", choices=["all", "slicing", "noslicing"], default="all", help="Subset to run")
    ap.add_argument(
        "--bench",
        action="append",
        default=[],
        help="Run only benchmarks whose name/spec contains this substring (repeatable).",
    )
    ap.add_argument("--list", action="store_true", help="List available benchmarks and exit")
    ap.add_argument("--dry-run", action="store_true", help="Print commands but do not execute")
    ns = ap.parse_args(argv)

    root = _repo_root()
    ultimate = Path(ns.ultimate) if ns.ultimate else _find_default_ultimate(root)
    if not ultimate or not ultimate.exists():
        print("error: Ultimate not found; pass --ultimate", file=sys.stderr)
        return 2

    # Default to the non-witness toolchain for robustness.
    #
    # Some Ultimate releases crash in the witness printer even when the program is SAFE
    # (see `dslc/workflows/wraparound_cegis.py:_default_toolchain_paths`). For E2E
    # regressions we want a stable result classification; we re-run UNSAFE cases with
    # witness enabled for auditability.
    verify_toolchain = "dslc/toolchain/ultimate/ReachSafety.xml"
    # WSL safety: prefer the low-memory (~2GB Z3) profiles by default.
    verify_settings = "dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL.epf"

    witness_toolchain = "dslc/toolchain/ultimate/ReachSafety-Witness.xml"

    cfgs: list[RunCfg] = [
        RunCfg(
            name="slicing",
            args=[
                "./bin/procurator",
                "verify",
                "--boogie-harness",
                "sequential",
                "--no-two-stage",
                "--ultimate",
                str(ultimate),
                "--toolchain",
                verify_toolchain,
                "--settings",
                verify_settings,
            ],
        ),
        RunCfg(
            name="noslicing",
            args=[
                "./bin/procurator",
                "verify",
                "--no-slicing",
                "--no-env-prune",
                "--boogie-harness",
                "sequential",
                "--no-two-stage",
                "--ultimate",
                str(ultimate),
                "--toolchain",
                verify_toolchain,
                "--settings",
                verify_settings,
            ],
        ),
    ]

    # Curated regression list (aligned with the NSDI evaluation narrative).
    #
    # NOTE:
    # - Wraparound uses a fixed stage order: ENTRY -> CONFIRM -> CLOSURE.
    # - ENTRY/CONFIRM are existence checks and must be run once (no progressive unroll growth).
    #   We keep `--wraparound-confirm-unroll 3 --wraparound-max-confirm-unroll 0` for reproducibility.
    wraparound_args = [
        "--wraparound-stage-order",
        "entry_confirm_closure",
        "--wraparound-max-targets",
        "1",
        "--wraparound-confirm-unroll",
        "3",
        "--wraparound-max-confirm-unroll",
        "0",
        "--wraparound-closure-timeout-cap",
        "0",
    ]
    benches: list[Bench] = [
        # Wraparound-class bugs (certified by ENTRY/CONFIRM UNSAFE + CLOSURE SAFE).
        Bench(
            name="NetChain wrap-around bug (NSDI)",
            spec="Procurator/argo/code/spec/bench/netchain_wraparound_bug.prop",
            category="wraparound",
            env="spec",
            wraparound="auto",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=wraparound_args + ["--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="DistCache P2C spineload wrap-around bug",
            spec="Procurator/argo/code/spec/bench/distcache_p2c_spineload_wraparound_bug.prop",
            category="wraparound",
            env="spec",
            wraparound="auto",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=wraparound_args,
            notes="",
        ),
        Bench(
            name="DistCache P2C wrong-choice after overflow",
            spec="Procurator/argo/code/spec/bench/distcache_p2c_wraparound_bug.prop",
            category="wraparound",
            env="spec",
            wraparound="auto",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=wraparound_args + ["--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="FissLock: premature TRANSFER after notification_cnt wrap-around",
            spec="Procurator/argo/code/spec/bench/fisslock_notification_cnt_wraparound_bug.prop",
            category="wraparound",
            env="spec",
            wraparound="auto",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            # Disable per-pass register snapshot debug vars for faster wraparound
            # stages; bug predicate does not depend on __dbg snapshots.
            extra_args=wraparound_args + ["--no-slicing-control-seeds", "--no-reg-debug"],
            notes="",
        ),
        # Non-wraparound NSDI and new-system bugs.
        Bench(
            name="ATP bound bug",
            spec="Procurator/argo/code/spec/bench/atp_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 300),
            use_spec_max_steps=False,
            # This bug does not depend on clone/recirc control seeds. Disabling
            # implicit control seeds shrinks sliced state space and improves
            # slicing-side convergence in repeated runs.
            extra_args=["--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="ATP count mismatch bug",
            spec="Procurator/argo/code/spec/bench/atp_count_mismatch_bug.prop",
            category="functional",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            # Case-specific pruning: this spec is single-node and does not rely on
            # clone/recirc control seeds. Disabling implicit control seeds shrinks
            # the sliced model and consistently improves wall time.
            extra_args=["--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="DistCache leaf pktloss clone/drop",
            spec="Procurator/argo/code/spec/bench/distcache_leaf_pktloss_clone_drop_bug.prop",
            category="functional",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
            # The unsliced program can OOM in Z3 during CFG/RCFG construction even with larger memory limits.
            # Prefer the internal SMTInterpol profile (POR off) for WSL stability.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-internal-no-por.epf",
        ),
        Bench(
            name="DistCache CM3/CM4 write wiring",
            spec="Procurator/argo/code/spec/bench/distcache_cm34_write_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            # Drop per-pass register snapshot vars; this case's bug predicate only
            # depends on __wrote_any flags, so debug snapshots are pure overhead.
            # Also disable implicit control seeds: this single-node table wiring bug
            # does not depend on recirc/clone control predicates.
            extra_args=["--no-reg-debug", "--no-slicing-control-seeds"],
            notes="",
            # Base side converges better with Z3 small-blocks than internal SMTInterpol.
            # Using 8GB + small-block profile avoids long timeout tails on WSL.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
        ),
        Bench(
            name="DistCache spine cache_frequency idx",
            spec="Procurator/argo/code/spec/bench/distcache_spine_cache_frequency_idx_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 900),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
            # Base run is unstable under internal-no-por (frequent timeout after step-bound fix);
            # use 8GB + small-block profile to keep base side runnable on WSL.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
        ),
        Bench(
            name="DDOSD: window label collision (NSDI)",
            spec="Procurator/argo/code/spec/bench/ddosd_window_label_collision_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=["--no-reg-debug"],
            notes="",
            # Base run can OOM under the low-memory Z3 profiles; use the 8GB small-block profile.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
        ),
        Bench(
            name="FRR bug1: unexpected mirror (NSDI)",
            spec="Procurator/argo/code/spec/bench/frr_bug1_unexpected_mirror.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=["--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="FRR bug2: state inconsistency (NSDI)",
            spec="Procurator/argo/code/spec/bench/frr_bug2_state_inconsistency.prop",
            category="interleaving",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
        ),
        Bench(
            name="P4NIS bug1: forwarding sequence desync (NSDI)",
            spec="Procurator/argo/code/spec/bench/p4nis_bug1_forwarding_sequence_desync.prop",
            category="interleaving",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
        ),
        Bench(
            name="P4NIS bug2: tunnel state leakage (NSDI)",
            spec="Procurator/argo/code/spec/bench/p4nis_bug2_tunnel_state_leakage.prop",
            category="functional",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
        ),
        Bench(
            name="Gecko bug1: Timer Loss (NSDI)",
            spec="Procurator/argo/code/spec/bench/gecko_bug1_timer_loss.prop",
            category="functional",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 900),
            use_spec_max_steps=True,
            # Gecko is large enough to OOM or stall during CFG construction under the low-memory
            # (~2GB) Z3 profile. Also disable per-pass register snapshot variables which can bloat
            # SMT queries significantly.
            extra_args=[
                "--no-reg-debug",
                "--settings",
                "dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
            ],
            notes="",
        ),
        Bench(
            name="Gecko bug2: Limited Concurrency Handling (NSDI)",
            spec="Procurator/argo/code/spec/bench/gecko_bug2_concurrency.prop",
            category="interleaving",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 900),
            use_spec_max_steps=True,
            extra_args=["--no-reg-debug"],
            notes="",
        ),
        Bench(
            name="Gecko bug3: Improper Timer Initialization (NSDI)",
            spec="Procurator/argo/code/spec/bench/gecko_bug3_timer_init.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=["--no-reg-debug"],
            notes="",
        ),
        Bench(
            name="P4xos: register access safety (NSDI)",
            spec="Procurator/argo/code/spec/bench/p4xos_bug.prop",
            category="implementation",
            env="max",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=[],
            notes="",
            # Base run can OOM under the 2GB/4GB Z3 profiles; prefer the 8GB profile first.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g.epf",
        ),
        Bench(
            name="P4xos: forwarding correctness drop_flag (NSDI, old)",
            spec="Procurator/argo/code/spec/bench/p4xos_dropflag_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=True,
            extra_args=["--no-reg-debug"],
            notes="",
        ),
        Bench(
            name="P4xos: majority quorum (NSDI)",
            spec="Procurator/argo/code/spec/bench/p4xos_majority_quorum_bug.prop",
            category="interleaving",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 900),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
        ),
        Bench(
            name="Cheetah: slot index collision (NSDI)",
            spec="Procurator/argo/code/spec/bench/cheetah_slot_index_collision_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 1800),
            use_spec_max_steps=True,
            extra_args=[],
            notes="",
        ),
        Bench(
            name="NetLock: pkt_type domain",
            spec="Procurator/argo/code/spec/bench/netlock_pkt_type_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=["--no-slicing-control-seeds"],
            notes="",
            # Base run tends to OOM under the 2GB/4GB Z3 profiles; prefer the 8GB profile first.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g.epf",
        ),
        Bench(
            name="NetLock: push_back length_in_server underflow",
            spec="Procurator/argo/code/spec/bench/netlock_pushback_length_in_server_underflow_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=["--max-steps", "3", "--no-slicing-control-seeds"],
            notes="",
            # Base run OOMs on low-memory profile; 8GB small-blocks is required for stable UNSAFE witness.
            base_settings="dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
        ),
        Bench(
            name="NetLock: release counter underflow",
            spec="Procurator/argo/code/spec/bench/netlock_release_counter_underflow_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=["--max-steps", "3", "--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="NetLock: release empty-queue head corruption",
            spec="Procurator/argo/code/spec/bench/netlock_release_empty_queue_head_bug.prop",
            category="functional",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=["--max-steps", "3", "--no-slicing-control-seeds"],
            notes="",
        ),
        Bench(
            name="NetLock: release empty_slots overflow",
            spec="Procurator/argo/code/spec/bench/netlock_release_empty_slots_overflow_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=[
                "--max-steps",
                "3",
                "--no-slicing-control-seeds",
                "--no-reg-debug",
                "--settings",
                "dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-8g-smallblocks.epf",
            ],
            notes="",
        ),
        Bench(
            name="P4DB router: TTL expiry",
            spec="Procurator/argo/code/spec/bench/p4db_router_ttl_expiry_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=[
                "--max-steps",
                "3",
                "--no-slicing-control-seeds",
                "--no-reg-debug",
            ],
            notes="",
        ),
        Bench(
            name="P4DB router+damper: threshold off-by-one",
            spec="Procurator/argo/code/spec/bench/p4db_damper_threshold_off_by_one_bug.prop",
            category="implementation",
            env="spec",
            wraparound="off",
            timeout_s=max(ns.timeout, 600),
            use_spec_max_steps=False,
            extra_args=[
                "--max-steps",
                "3",
                "--no-slicing-control-seeds",
                "--no-reg-debug",
            ],
            notes="",
        ),
    ]

    if ns.list:
        for b in benches:
            print(f"- {b.name} ({b.spec})")
        return 0

    if ns.bench:
        pats = [p.lower() for p in ns.bench]

        def _match(b: Bench) -> bool:
            s = (b.name + " " + b.spec).lower()
            return any(p in s for p in pats)

        benches = [b for b in benches if _match(b)]
        if not benches:
            print("[ERR] no benchmarks matched --bench filters", file=sys.stderr)
            return 2

    if ns.update_usage and (ns.bench or int(ns.max_new_benches) > 0):
        print("[ERR] --update-usage requires running the full benchmark set (no --bench/--max-new-benches).", file=sys.stderr)
        return 2

    results_path = (
        Path(ns.results_json)
        if ns.results_json
        else (root / ".tmp" / "procurator" / "e2e_ablations_results.json")
    )
    checkpoint: dict[str, object] = {"meta": {}, "results": {}}

    def _load_checkpoint() -> dict[str, object]:
        # Always load an existing results JSON (if any) to avoid accidentally
        # clobbering long-running experiment records when re-running a subset.
        # `--resume` only controls whether we *skip* already-recorded runs.
        if not results_path.exists():
            return {"meta": {}, "results": {}}
        try:
            j = json.loads(results_path.read_text(encoding="utf-8", errors="replace"))
        except Exception:
            return {"meta": {}, "results": {}}
        if not isinstance(j, dict):
            return {"meta": {}, "results": {}}
        meta = j.get("meta")
        results = j.get("results")
        return {
            "meta": meta if isinstance(meta, dict) else {},
            "results": results if isinstance(results, dict) else {},
        }

    checkpoint = _load_checkpoint()
    if not isinstance(checkpoint.get("results"), dict):
        checkpoint["results"] = {}

    def _save_checkpoint() -> None:
        results_path.parent.mkdir(parents=True, exist_ok=True)
        tmp = results_path.with_suffix(results_path.suffix + ".tmp")
        meta = {
            "updated_at": _dt.datetime.now().isoformat(timespec="seconds"),
            "ultimate": str(ultimate),
            "default_timeout_s": int(ns.timeout),
            "ultimate_xmx_gb": int(ns.ultimate_xmx_gb),
        }
        payload = {"meta": meta, "results": checkpoint.get("results", {})}
        tmp.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        tmp.replace(results_path)

    rows: list[list[str]] = [
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
            "category",
        ]
    ]

    def _cmd_fragment(b: Bench, *, base: bool) -> str:
        parts: list[str] = ["verify"]
        if b.env != "spec":
            parts += ["--env", b.env]
        parts += ["--wraparound", b.wraparound]
        if b.use_spec_max_steps:
            parts.append("--use-spec-max-steps")
        parts += list(b.extra_args)
        if base:
            parts += ["--no-slicing", "--no-env-prune"]
            if b.base_settings:
                parts += ["--settings", b.base_settings]
        return " ".join(parts)

    def _find_latest_witness(p: Path) -> Optional[Path]:
        w = sorted(p.glob("*.bpl-witness.graphml"), key=lambda q: q.stat().st_mtime, reverse=True)
        return w[0] if w else None

    def _rel(p: Union[str, Path]) -> str:
        try:
            pp = Path(p).resolve()
            return str(pp.relative_to(root))
        except Exception:
            return str(p)

    def _wraparound_certified_summary(out_dir: Path) -> Optional[dict]:
        """
        Return a dict containing:
          - manifest (path)
          - entry_s/confirm_s/closure_s (floats)
          - confirm_witness (path; best-effort)
        Only for certified wraparound attempts.
        """
        wrap = out_dir / "wraparound"
        if not wrap.is_dir():
            return None

        manifests = sorted(wrap.glob("target.*/wraparound.cegis.manifest.json"))
        for mp in manifests:
            ok, _msg = validate_wraparound_manifest(mp)
            if not ok:
                continue
            try:
                j = json.loads(mp.read_text(encoding="utf-8", errors="replace"))
            except Exception:
                continue
            for a in j.get("attempts", []):
                e = a.get("entry") or {}
                c = a.get("confirm") or {}
                cl = a.get("closure") or {}
                el = str(e.get("result_line") or "").lower()
                cll = str(cl.get("result_line") or "").lower()
                col = str(c.get("result_line") or "").lower()
                if ("unsafe" in el) and ("unsafe" in col) and ("safe" in cll):
                    target_dir = mp.parent
                    cw = sorted(target_dir.glob("*.confirm.*.bpl-witness.graphml"))
                    return {
                        "manifest": str(mp),
                        "entry_s": float(e.get("wall_time_s") or 0.0),
                        "confirm_s": float(c.get("wall_time_s") or 0.0),
                        "closure_s": float(cl.get("wall_time_s") or 0.0),
                        "confirm_witness": str(cw[0]) if cw else "",
                    }
            continue

        return None

    def _cmd_for(b: Bench, cfg: RunCfg) -> list[str]:
        cmd = cfg.args + [
            "--env",
            b.env,
            "--wraparound",
            b.wraparound,
            "--ultimate-timeout-seconds",
            str(b.timeout_s),
            "--ultimate-xmx-gb",
            str(max(1, int(ns.ultimate_xmx_gb))),
        ]
        if cfg.name == "noslicing" and b.base_settings:
            cmd += ["--settings", b.base_settings]
        cmd += list(b.extra_args) + ["--spec", b.spec]
        if b.use_spec_max_steps:
            cmd.insert(len(cfg.args), "--use-spec-max-steps")
        return cmd

    def _rr_to_json(r: RunResult) -> dict:
        return {
            "status": r.status,
            "wall_s": r.wall_s,
            "out_dir": r.out_dir,
            "log_path": r.log_path,
            "sanity": r.sanity,
        }

    def _rr_from_json(d: dict) -> RunResult:
        return RunResult(
            status=str(d.get("status") or "UNKNOWN"),
            wall_s=float(d.get("wall_s") or 0.0),
            out_dir=d.get("out_dir") or None,
            log_path=d.get("log_path") or None,
            sanity=str(d.get("sanity") or "NA"),
        )

    def _stored_ok(stored: object, cmd: list[str]) -> bool:
        if not isinstance(stored, dict):
            return False
        if stored.get("cmd") != cmd:
            return False
        res = stored.get("result")
        if not isinstance(res, dict):
            return False
        od = res.get("out_dir")
        if od and (not Path(str(od)).exists()):
            return False
        return True

    def run_one(b: Bench, cfg: RunCfg) -> RunResult:
        cmd = _cmd_for(b, cfg)
        if ns.dry_run:
            print("[DRY]", " ".join(cmd))
            return RunResult(status="DRY", wall_s=0.0, out_dir=None, log_path=None, sanity="NA")
        t0 = time.monotonic()
        stem = Path(b.spec).stem
        stdout_path = root / ".tmp" / "procurator" / "ablation-stdout" / f"{stem}.{cfg.name}.stdout.txt"
        rc, last_result, out_dir, log_path = _run_streaming(
            cmd=cmd, cwd=root, tag=f"{stem}/{cfg.name}", stdout_path=stdout_path
        )
        wall = time.monotonic() - t0
        status = _classify(last_result, rc)
        status = _refine_error_from_log(status=status, log_path=log_path)

        if out_dir:
            try:
                # Preserve the full stdout in the per-run output dir for debugging.
                Path(out_dir, f"{Path(b.spec).stem}.{cfg.name}.procurator.stdout.txt").write_text(
                    stdout_path.read_text(encoding="utf-8", errors="replace"), encoding="utf-8"
                )
            except OSError:
                pass

        sanity = "NA"
        if status == "UNSAFE" and out_dir:
            sanity = _sanity_check(root=root, out_dir=out_dir)

        # Audit UNSAFE with a witness run if needed.
        #
        # The default toolchain does not print a witness. For regression purposes we
        # want UNSAFE to be auditable (non-spurious), so re-run the same command with
        # witness printing enabled when we cannot validate the counterexample.
        if status == "UNSAFE" and (sanity != "OK"):
            cmd2 = cmd + ["--toolchain", witness_toolchain]
            t1 = time.monotonic()
            stdout_path2 = root / ".tmp" / "procurator" / "ablation-stdout" / f"{stem}.{cfg.name}.witness.stdout.txt"
            rc2, last_result2, out_dir2, log_path2 = _run_streaming(
                cmd=cmd2,
                cwd=root,
                tag=f"{stem}/{cfg.name}/witness",
                stdout_path=stdout_path2,
            )
            wall += time.monotonic() - t1
            status2 = _classify(last_result2, rc2)
            if status2 == "UNSAFE" and out_dir2:
                sanity2 = _sanity_check(root=root, out_dir=out_dir2)
                # Prefer audited artifacts in the final record.
                out_dir, log_path, sanity = out_dir2, log_path2, sanity2

        return RunResult(status=status, wall_s=wall, out_dir=out_dir, log_path=log_path, sanity=sanity)

    new_benches_executed = 0

    for b in benches:
        spec_path = root / b.spec
        if not spec_path.exists():
            print(f"[SKIP] missing spec: {b.spec}", file=sys.stderr)
            continue

        r_opt: Optional[RunResult] = None
        r_base: Optional[RunResult] = None
        ran_any = False

        if ns.only in {"all", "slicing"}:
            cfg_opt = next(c for c in cfgs if c.name == "slicing")
            cmd_opt = _cmd_for(b, cfg_opt)
            results = checkpoint["results"]
            assert isinstance(results, dict)
            brec = results.setdefault(
                b.spec,
                {
                    "name": b.name,
                    "spec": b.spec,
                    "category": b.category,
                },
            )
            if (ns.resume or ns.report_only) and _stored_ok(brec.get(cfg_opt.name), cmd_opt):
                r_opt = _rr_from_json(brec[cfg_opt.name]["result"])
            elif ns.report_only:
                r_opt = None
            else:
                r_opt = run_one(b, cfg_opt)
                # Dry-run should never mutate persisted checkpoints.
                if not ns.dry_run:
                    brec[cfg_opt.name] = {"cmd": cmd_opt, "result": _rr_to_json(r_opt)}
                    _save_checkpoint()
                    ran_any = True
        if ns.only in {"all", "noslicing"}:
            cfg_base = next(c for c in cfgs if c.name == "noslicing")
            cmd_base = _cmd_for(b, cfg_base)
            results = checkpoint["results"]
            assert isinstance(results, dict)
            brec = results.setdefault(
                b.spec,
                {
                    "name": b.name,
                    "spec": b.spec,
                    "category": b.category,
                },
            )
            if (ns.resume or ns.report_only) and _stored_ok(brec.get(cfg_base.name), cmd_base):
                r_base = _rr_from_json(brec[cfg_base.name]["result"])
            elif ns.report_only:
                r_base = None
            else:
                r_base = run_one(b, cfg_base)
                # Dry-run should never mutate persisted checkpoints.
                if not ns.dry_run:
                    brec[cfg_base.name] = {"cmd": cmd_base, "result": _rr_to_json(r_base)}
                    _save_checkpoint()
                    ran_any = True

        opt_cmd = f"`{_md_escape(_cmd_fragment(b, base=False))}`"
        base_cmd = f"`{_md_escape(_cmd_fragment(b, base=True))}`"

        opt_time = "-"
        opt_res = "N/A"
        base_time = "-"
        base_res = "N/A"

        notes: list[str] = []
        if b.notes:
            notes.append(b.notes.strip())

        if r_opt is not None:
            opt_time = _fmt_s(r_opt.wall_s)
            opt_res = r_opt.status
            if r_opt.out_dir:
                od = Path(r_opt.out_dir)
                run_id = od.name
                wrap = _wraparound_certified_summary(od)
                if wrap:
                    total = float(wrap["entry_s"]) + float(wrap["confirm_s"]) + float(wrap["closure_s"])
                    opt_time = _fmt_s(total)
                    opt_res = "entry UNSAFE; confirm UNSAFE; closure SAFE"
                    notes.append(
                        f"opt run_id `{run_id}`; stage times: entry {_fmt_s(wrap['entry_s'])}s / confirm {_fmt_s(wrap['confirm_s'])}s / closure {_fmt_s(wrap['closure_s'])}s; manifest: `{_rel(wrap['manifest'])}`"
                    )
                    if wrap.get("confirm_witness"):
                        notes.append(f"opt confirm witness: `{_rel(wrap['confirm_witness'])}`")
                else:
                    w = _find_latest_witness(od)
                    if w:
                        notes.append(f"opt run_id `{run_id}`; witness: `{_rel(w)}`")
                    else:
                        notes.append(f"opt run_id `{run_id}`; out: `{_rel(od)}`")
                if r_opt.sanity != "OK" and r_opt.sanity != "NA":
                    notes.append(f"opt sanity={r_opt.sanity}")

        if r_base is not None:
            base_time = _fmt_s(r_base.wall_s)
            base_res = r_base.status
            if b.base_settings:
                notes.append(f"base settings override: `{_rel(b.base_settings)}`")
            if r_base.out_dir:
                od = Path(r_base.out_dir)
                run_id = od.name
                wrap = _wraparound_certified_summary(od)
                if wrap:
                    total = float(wrap["entry_s"]) + float(wrap["confirm_s"]) + float(wrap["closure_s"])
                    base_time = _fmt_s(total)
                    base_res = "entry UNSAFE; confirm UNSAFE; closure SAFE"
                    notes.append(
                        f"base run_id `{run_id}`; stage times: entry {_fmt_s(wrap['entry_s'])}s / confirm {_fmt_s(wrap['confirm_s'])}s / closure {_fmt_s(wrap['closure_s'])}s; manifest: `{_rel(wrap['manifest'])}`"
                    )
                    if wrap.get("confirm_witness"):
                        notes.append(f"base confirm witness: `{_rel(wrap['confirm_witness'])}`")
                else:
                    w = _find_latest_witness(od)
                    if w:
                        notes.append(f"base run_id `{run_id}`; witness: `{_rel(w)}`")
                    else:
                        notes.append(f"base run_id `{run_id}`; out: `{_rel(od)}`")
                if r_base.sanity != "OK" and r_base.sanity != "NA":
                    notes.append(f"base sanity={r_base.sanity}")

        notes_cell = _md_escape("; ".join([n for n in notes if n]))
        rows.append(
            [
                _md_escape(b.name),
                f"`{b.spec}`",
                opt_cmd,
                opt_time,
                opt_res,
                base_cmd,
                base_time,
                base_res,
                notes_cell,
                b.category,
            ]
        )

        if ran_any:
            new_benches_executed += 1
            if int(ns.max_new_benches) > 0 and new_benches_executed >= int(ns.max_new_benches):
                break

    md: list[str] = []
    md.append("## E2E Ablations (Auto-Generated)\n")
    md.append(
        f"Updated on {_dt.datetime.now().strftime('%Y-%m-%d')} with the latest E2E runs using Ultimate `{ultimate}`.\n"
    )
    md.append("Category legend:\n")
    md.append("- `functional`: 功能类（功能/一致性性质被违反）\n")
    md.append("- `implementation`: 实现类（实现细节/边界处理错误；包含因缺少 guard/clamp 导致的溢出/下溢）\n")
    md.append("- `wraparound`: 变量翻转类（需要 wraparound 加速/证书的溢出相关 bug：ENTRY/CONFIRM=UNSAFE 且 CLOSURE=SAFE）\n")
    md.append("- `interleaving`: 交错类（并发/交错导致性质被违反）\n")
    md.append("- Note: 单步算术溢出/下溢（bitvector wrap）可在很短前缀内出现，通常不需要 wraparound 管线；此类按实现类统计。\n")
    md.append("\n")
    md.append(_table(rows))
    block = "".join(md)

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
