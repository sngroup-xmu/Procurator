from __future__ import annotations

import json
import os
import re
import subprocess
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Callable, Dict, List, Optional, Protocol, Sequence, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate, infer_wraparound_candidates
from dslc.compiler import compile_spec_file
from dslc.speclang.parse import parse_model
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text, unroll_mainprocedure_loop_text
from dslc.transform.wraparound_analyze import _infer_deterministic_scheduler_period, _parse_global_var_types
from dslc.transform.wraparound_common import _RE_PROC_SCHED
# NOTE: We intentionally do NOT rewrite quantified array inits in CEGIS.
# See dslc/transform/wraparound_stages.py::_rewrite_forall_bv32_array_inits for the
# performance motivation. In practice, eliminating `forall i :: A[i] == 0` without
# re-establishing *all* semantically relevant indices can make confirm/enable_check
# vacuously SAFE or introduce spurious behavior (e.g., leaf/spine load regs starting
# from unconstrained values). Correctness > micro-optimizations here.
from dslc.transform.wraparound_analyze import _inline_deterministic_round_into_mainprocedure
from dslc.toolchain.ultimate_witness import (
    extract_assumptions_from_graphml,
    find_latest_graphml_witness,
    synthesize_boogie_assumes,
)
from dslc.utils.exec import wrap_resource_limits
from dslc.utils.repo import repo_root


class WraparoundCegisError(RuntimeError):
    pass


_RE_HAVOC = re.compile(r"^\s*havoc\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*;\s*$")
_RE_BV_TYPE = re.compile(r"^bv(?P<w>\d+)$")


def _zero_value_for_boogie_type(typ: str) -> Optional[str]:
    t = typ.strip()
    if t == "bool":
        return "false"
    if t == "int":
        return "0"
    m = _RE_BV_TYPE.match(t)
    if m:
        return f"0bv{m.group('w')}"
    return None


def _collect_env_assigned_vars_from_model(model) -> set[str]:
    """
    Collect dotted variables that appear on the LHS of assignments/decls inside env blocks.
    """

    from lark import Token, Tree

    def dotted_var_to_str(node) -> str:
        if isinstance(node, Token):
            return str(node)
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            if len(node.children) == 1:
                return dotted_var_to_str(node.children[0])
            return ".".join(str(c) for c in node.children)

        cur = ""
        for item in node.children:
            if isinstance(item, Token):
                if item.type == "NAME":
                    cur += str(item) + "."
                elif item.type == "NUMBER":
                    cur = cur.rstrip(".")
                    cur += f"[{item}]."
        return cur.rstrip(".")

    def collect_from_stmts(stmts, out: set[str]) -> None:
        for stmt in stmts:
            if not isinstance(stmt, Tree):
                continue
            tt = str(stmt.data)
            if tt not in {"assignment", "var_decl"}:
                continue
            var_tree = stmt.children[0] if tt == "assignment" else stmt.children[1]
            out.add(dotted_var_to_str(var_tree))

    assigned: set[str] = set()
    for nd in model.nodes.values():
        collect_from_stmts(nd.env_statements, assigned)
    for hd in model.hosts.values():
        collect_from_stmts(hd.env_statements, assigned)
    return assigned


def _synthesize_env_completion_assumes(*, model, base_text: str) -> List[str]:
    """
    Under-approximate the environment by setting *unassigned* injected fields to zero.

    This is used as a refinement when CONFIRM times out on large programs (e.g., DistCache).
    It is sound for bug finding because it only restricts environment nondeterminism.
    """

    assigned = _collect_env_assigned_vars_from_model(model)
    host_names = sorted(model.hosts.keys())
    if not host_names:
        return []

    lines = [ln.rstrip("\n") for ln in base_text.splitlines()]
    var_types = _parse_global_var_types(lines)

    out: List[str] = []
    seen: set[str] = set()
    for ln in lines:
        m = _RE_HAVOC.match(ln)
        if not m:
            continue
        name = m.group("name")
        if not any(name.startswith(f"{hn}_") for hn in host_names):
            continue
        typ = var_types.get(name)
        if not typ:
            continue
        z = _zero_value_for_boogie_type(typ)
        if z is None:
            continue

        # Map "<host>_..." -> "..." for matching env LHS names.
        suffix = name
        for hn in host_names:
            if suffix.startswith(f"{hn}_"):
                suffix = suffix[len(hn) + 1 :]
                break
        if suffix in assigned:
            continue

        expr = f"({name} == {z})"
        if expr not in seen:
            out.append(expr)
            seen.add(expr)

    return sorted(out)


def _collect_env_input_prefixes(model) -> Tuple[str, ...]:
    """
    Compute a conservative set of variable prefixes that correspond to *environment*
    packet/meta inputs.

    We use this to restrict witness-guided refinement to input shapes only, avoiding
    pinning internal scheduler/state variables (e.g., procurator_step/phase) that can
    easily make closure brittle or unsound as a certificate.
    """

    names: set[str] = set()
    # Host actors inject packets through <host>_hdr/meta/standard_metadata globals.
    names.update(model.hosts.keys())
    # EnvThread injects packets directly to nodes marked external_input=true.
    for n, nd in model.nodes.items():
        if nd.external_input is True:
            names.add(n)

    prefixes: List[str] = ["hdr.", "meta.", "standard_metadata."]
    for nm in sorted(names):
        prefixes.extend([f"{nm}_hdr.", f"{nm}_meta.", f"{nm}_standard_metadata."])
    return tuple(prefixes)


def _unroll_confirm_like_mainprocedure(
    *,
    bpl_text: str,
    requested_steps: int,
    deterministic_period: Optional[int],
) -> Tuple[str, int]:
    """
    Unroll `mainProcedure` for a "confirm-like" stage (CONFIRM/ENABLE_CHECK).

    Important subtlety: in the sequential harness with `deterministic_scheduler=true`,
    one logical external input + node processing "round" may require multiple scheduler
    steps (phases). The user's `requested_steps` is specified in *round* units, but
    `unroll_mainprocedure_loop_text()` operates on the low-level scheduler loop body.

    We therefore scale the unroll bound by the inferred deterministic scheduler period
    when available, and opportunistically inline the round-robin dispatcher to reduce
    solver load.
    """

    req = max(1, int(requested_steps))
    steps = req
    if deterministic_period is not None and deterministic_period > 0:
        steps = req * deterministic_period

    txt = unroll_mainprocedure_loop_text(bpl_text=bpl_text, steps=steps)

    # Optional post-processing: inline deterministic phases and eliminate heavy forall inits.
    lines = txt.splitlines(keepends=True)
    no_nl = [ln.rstrip("\n") for ln in lines]
    has_sched_proc = any(_RE_PROC_SCHED.match(ln.strip()) for ln in no_nl)
    if deterministic_period is not None and has_sched_proc:
        try:
            _inline_deterministic_round_into_mainprocedure(lines, period=deterministic_period, steps=steps)
        except Exception:
            # Best-effort: inlining is a performance optimization only.
            pass

    return "".join(lines), steps


class StageRunner(Protocol):
    """
    Runner interface for solver stages.

    This indirection makes the CEGIS loop unit-testable (mockable) without requiring
    Ultimate to be installed/runnable in the test environment.
    """

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> "StageRunResult": ...


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

        return self.returncode in (124, 137)

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


def _extract_result_line(log_text: str) -> Optional[str]:
    lines = log_text.splitlines()

    # Some Ultimate toolchains may time out *after* they already registered results for
    # all error locations (e.g., during post-processing). In that case, the
    # "Registering result ..." lines can be more informative than a final
    # "Ultimate could not prove ... Timeout" summary.
    #
    # IMPORTANT (soundness): a single "Registering result SAFE" line does NOT imply the
    # overall program is SAFE when multiple error locations exist. We only treat this
    # as SAFE when Ultimate indicates that *all* error locations have been resolved,
    # i.e., "(0 of N remaining)".
    any_unsafe = False
    registered_safe_done = False
    re_remaining = re.compile(
        r"Registering result (SAFE|UNSAFE) .*\((?P<rem>\d+) of (?P<tot>\d+) remaining\)"
    )
    for line in lines:
        if "Registering result UNSAFE" in line:
            any_unsafe = True
            return "RESULT: UNSAFE"
        m = re_remaining.search(line)
        if not m:
            continue
        if m.group(1) != "SAFE":
            continue
        if int(m.group("rem")) == 0:
            registered_safe_done = True

    if (not any_unsafe) and registered_safe_done:
        return "RESULT: SAFE"

    # Otherwise, prefer an explicit RESULT line.
    # If multiple RESULT lines exist, keep the last non-timeout one.
    last: Optional[str] = None
    for line in lines:
        if "RESULT:" not in line:
            continue
        cur = line.strip()
        if "could not prove" in cur.lower() and "timeout" in cur.lower():
            # Treat as UNKNOWN unless there's no other RESULT at all.
            if last is None:
                last = cur
            continue
        last = cur
    return last


def _default_toolchain_paths(*, root: Path) -> Tuple[Path, Path, Path, Path, Path, Path]:
    """
    Best-effort defaults that work for both in-repo toolchains and legacy Procurator paths.
    """

    # Toolchains.
    # Default to the reachability-safety toolchains (TraceAbstraction).
    #
    # Important for sound bug finding: some Ultimate toolchains focus on termination
    # or other analyses and can print "proved your program to be correct" even when
    # assertions are not treated as reachability properties under our harness.
    tc_no_witness = (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety.xml").resolve()
    tc_witness = (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml").resolve()
    tc_legacy_witness = (root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml").resolve()

    # IMPORTANT: some Ultimate releases crash in the witness printer when the result is SAFE.
    # We therefore default CEGIS stages to the non-witness toolchain and only re-run with
    # witness enabled when we actually need a witness (i.e., on UNSAFE for refinement).
    toolchain_nowitness = tc_no_witness if tc_no_witness.exists() else tc_legacy_witness
    toolchain_witness = tc_witness if tc_witness.exists() else tc_legacy_witness

    tc_closure = root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-ReachSafety.xml"
    closure_toolchain = tc_closure.resolve() if tc_closure.exists() else toolchain_nowitness

    # Settings.
    #
    # For performance and robustness, we default ENTRY/CLOSURE/CONFIRM to a *non-witness*
    # settings profile. We only enable witness printing when we explicitly re-run CONFIRM
    # for CEGIS refinement.
    # If we're using BuchiAutomizer, we must ensure RCFGBuilder uses an SMT mode
    # compatible with BuchiAutomizer's predicate generation.
    settings_nowitness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-12g.epf"
    if not settings_nowitness.exists():
        settings_nowitness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g.epf"
    if not settings_nowitness.exists():
        settings_nowitness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL.epf"
    settings_nowitness_legacy = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL.epf"
    )
    settings_nowitness = settings_nowitness if settings_nowitness.exists() else settings_nowitness_legacy

    settings_witness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-12g-witness.epf"
    if not settings_witness.exists():
        settings_witness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g-witness.epf"
    if not settings_witness.exists():
        settings_witness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    settings_witness_legacy = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    )
    settings_witness = settings_witness if settings_witness.exists() else settings_witness_legacy

    closure_settings = root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
    closure_settings_legacy = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
    closure_settings = closure_settings if closure_settings.exists() else closure_settings_legacy
    if not closure_settings.exists():
        closure_settings = settings_nowitness

    if not settings_nowitness.exists():
        # This should not happen in-repo, but keep a reasonable fallback to avoid crashing.
        settings_nowitness = settings_witness

    return (
        toolchain_nowitness,
        toolchain_witness,
        closure_toolchain.resolve(),
        settings_nowitness.resolve(),
        settings_witness.resolve(),
        closure_settings.resolve(),
    )


@dataclass(frozen=True)
class CegisAttemptConfig:
    attempt: int
    pump_reg: str
    accel_regs: Tuple[str, ...]
    index_value: int
    index_expr: Optional[str]
    proj_vars: Tuple[str, ...]
    cutpoint_cond: Optional[str]
    step_op: str
    step_delta: int
    # CEGIS-synthesized additional existence/profile constraints (Boogie expressions).
    extra_assumes: Tuple[str, ...] = ()
    notes: Tuple[str, ...] = ()


@dataclass(frozen=True)
class CegisAttemptArtifacts:
    entry_bpl: str
    closure_bpl: str
    confirm_bpl: str
    entry_log: str
    closure_log: str
    confirm_log: str
    # Optional artifacts for the pump-enable (reach `target != MAX`) refinement.
    enable_bpl: str = ""
    enable_log: str = ""


@dataclass(frozen=True)
class CegisAttemptRecord:
    cfg: CegisAttemptConfig
    artifacts: CegisAttemptArtifacts
    entry: Optional[StageRunResult]
    closure: Optional[StageRunResult]
    confirm: Optional[StageRunResult]


@dataclass(frozen=True)
class CegisManifest:
    spec: str
    base_bpl: str
    work_dir: str
    candidate_reason: str
    attempts: List[CegisAttemptRecord]


def _write_manifest(*, out_dir: Path, spec_path: Path, base_bpl: Path, work_dir: Path, cand: WraparoundCandidate, attempts: List[CegisAttemptRecord]) -> Path:
    """
    Write the current CEGIS manifest (incremental).

    We write after each attempt so an interrupted run still leaves a reproducible
    record of what was tried and which artifacts/logs were produced.
    """

    manifest = CegisManifest(
        spec=str(spec_path),
        base_bpl=str(base_bpl),
        work_dir=str(work_dir),
        candidate_reason=cand.reason,
        attempts=attempts,
    )
    manifest_path = out_dir / "wraparound.cegis.manifest.json"
    manifest_path.write_text(json.dumps(asdict(manifest), indent=2, sort_keys=True), encoding="utf-8")
    return manifest_path


class UltimateStageRunner:
    def __init__(self, *, ultimate: Path) -> None:
        self._ultimate = ultimate

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> StageRunResult:
        cmd = [
            str(self._ultimate),
            f"--core.toolchain.timeout.in.seconds={timeout_seconds}",
            "-tc",
            str(toolchain),
            "-s",
            str(settings),
            "-i",
            str(input_bpl),
        ]
        os_timeout = timeout_seconds + 60 if timeout_seconds > 0 else 0
        cmd = wrap_resource_limits(cmd, enable=resource_limits, os_timeout_s=os_timeout)

        ultimate_home.mkdir(parents=True, exist_ok=True)
        env = dict(os.environ)
        env["HOME"] = str(ultimate_home)
        prev_java_opts = env.get("JAVA_TOOL_OPTIONS", "").strip()
        env["JAVA_TOOL_OPTIONS"] = f"{prev_java_opts} -Duser.home={ultimate_home}".strip()

        log_path.parent.mkdir(parents=True, exist_ok=True)
        start = time.time()
        with log_path.open("wb") as f:
            f.write(("[RUN] " + " ".join(cmd) + "\n").encode("utf-8"))
            f.flush()
            proc = subprocess.run(
                cmd,
                stdout=f,
                stderr=subprocess.STDOUT,
                env=env,
                cwd=str(log_path.parent),
            )
        wall = time.time() - start

        txt = log_path.read_text(encoding="utf-8", errors="replace")
        res = _extract_result_line(txt)
        return StageRunResult(stage=stage, returncode=proc.returncode, wall_time_s=wall, result_line=res)


def _is_distcache_like(spec_text: str) -> bool:
    """
    Best-effort classifier for DistCache-style specs.

    We purposely keep this broad: DistCache specs do not necessarily mention
    concrete table names, but they typically mention DistCache-specific meta
    fields (hashval_for_partition / hashval_for_spine_partition) and/or import
    paths containing "distcache".
    """

    lo = spec_text.lower()
    if "distcache" in lo:
        return True
    # Meta fields used in clientTrack/leaf DistCache pipelines.
    if "hashval_for_partition" in spec_text or "hashval_for_spine_partition" in spec_text:
        return True
    # Table names appear in some specs as comments/explanations.
    if ("hash_leaf_partition_tbl" in spec_text) or ("hash_spine_partition_tbl" in spec_text):
        return True
    return False


_RE_PROP_IMPORT_ENTRIES = re.compile(r"\bentries\s+\"([^\"]+)\"\s*;", flags=re.MULTILINE)
_RE_BMV2_TABLE_ADD_RANGE = re.compile(
    r"^\s*table_add\s+(?P<table>\S+)\s+\S+\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<lo>0x[0-9a-fA-F]+)->(?P<hi>0x[0-9a-fA-F]+)\s+=>",
    flags=re.MULTILINE,
)
_RE_BMV2_TABLE_ADD_RANGE_EPORT = re.compile(
    r"^\s*table_add\s+(?P<table>\S+)\s+\S+\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<lo>0x[0-9a-fA-F]+)->(?P<hi>0x[0-9a-fA-F]+)\s+=>\s*(?P<eport>0x[0-9a-fA-F]+)\s*(?:#.*)?$",
    flags=re.MULTILINE,
)


def _infer_distcache_hash_caps(spec_text: str, *, spec_dir: Path) -> Dict[str, int]:
    caps: Dict[str, int] = {}
    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in _RE_BMV2_TABLE_ADD_RANGE.finditer(txt):
            table = m.group("table")
            hi = int(m.group("hi"), 16)
            if "hash_leaf_partition_tbl" in table:
                caps["hashval_for_partition"] = max(caps.get("hashval_for_partition", -1), hi)
            if "hash_spine_partition_tbl" in table:
                caps["hashval_for_spine_partition"] = max(caps.get("hashval_for_spine_partition", -1), hi)
    return {k: v for k, v in caps.items() if v >= 0}


def _infer_distcache_partition_eports(spec_text: str, *, spec_dir: Path) -> Dict[str, int]:
    ports: Dict[str, int] = {}
    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in _RE_BMV2_TABLE_ADD_RANGE_EPORT.finditer(txt):
            table = m.group("table")
            eport = int(m.group("eport"), 16)
            if "hash_leaf_partition_tbl" in table:
                ports["leaf_eport"] = eport
            if "hash_spine_partition_tbl" in table:
                ports["spine_eport"] = eport
    return ports


def _apply_hash_caps_to_bpl(bpl_text: str, *, node_prefixes: Sequence[str], caps: Dict[str, int]) -> str:
    if not caps:
        return bpl_text

    lines = bpl_text.splitlines(keepends=True)
    wanted: List[Tuple[str, int]] = []
    for suffix, cap in caps.items():
        for pref in node_prefixes:
            wanted.append((f"{pref}_meta.{suffix}", cap))

    out_lines: List[str] = []
    havoc_re = re.compile(r"^(?P<indent>\s*)havoc\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*;\s*$")
    for line in lines:
        out_lines.append(line)

        # Constrain havoc'd hash outputs to the configured range-table domain.
        #
        # Motivation (bug-finding, not proof): DistCache models hash as `havoc` in Boogie.
        # If it escapes the configured key domain (e.g., 0..15), downstream range tables
        # may miss and leave indices unconstrained, which can make wraparound CONFIRM
        # spuriously SAFE (the pumped cell never updates, so assertions stay gated off).
        mh = havoc_re.match(line.rstrip("\n"))
        if mh:
            name = mh.group("name")
            for var, cap in wanted:
                if name != var:
                    continue
                indent = mh.group("indent")
                # Use unsigned comparisons consistent with P4B's helpers.
                out_lines.append(f"{indent}assume(buge.bv16({var}, 0bv16));\n")
                out_lines.append(f"{indent}assume(bule.bv16({var}, {cap}bv16));\n")
                break

        stripped = line.strip()
        if not stripped.startswith("assume("):
            continue
        if "buge.bv" not in stripped or "bule.bv" not in stripped:
            continue
        for var, cap in wanted:
            if var not in stripped:
                continue
            m = re.search(r"buge\.bv(\d+)\(", stripped)
            if not m:
                continue
            bv = m.group(1)
            indent = re.match(r"^[ \t]*", line).group(0)  # type: ignore[union-attr]
            out_lines.append(f"{indent}assume(bule.bv{bv}({var}, {cap}bv{bv}));\n")
            break

    return "".join(out_lines)


def _refine_proj_vars_greedy(
    proj_vars: List[str],
    *,
    mandatory: Sequence[str],
    max_drops: int,
) -> List[str]:
    """
    Simple, predictable refinement: drop at most `max_drops` non-mandatory vars.

    This is intentionally conservative; we can upgrade to ddmin later if needed.
    """

    mandatory_set = set(mandatory)

    def _noise_rank(v: str) -> Tuple[int, int]:
        """
        Lower rank = drop earlier.

        Heuristic:
          - Packet-local meta/hash/index values tend to break closure and add SMT noise.
          - Inbox/egress counts are usually meaningful for scheduler/queue stability and
            are kept via `mandatory`.
        """

        low = v.lower()
        noisy = 0
        if "hash" in low:
            noisy = -3
        elif "switchidx" in low or low.endswith("idx") or ".idx" in low:
            noisy = -2
        elif "tmp" in low or "scratch" in low:
            noisy = -1
        # Prefer dropping meta.* over other namespaces.
        ns = 0
        if "_meta." in v or v.startswith("meta."):
            ns = -1
        return (noisy, ns)

    out = list(proj_vars)
    # Choose a deterministic drop order to keep manifests stable.
    candidates = [v for v in out if v not in mandatory_set]
    candidates.sort(key=_noise_rank)

    drops = 0
    for v in candidates:
        if drops >= max_drops:
            break
        try:
            out.remove(v)
        except ValueError:
            continue
        drops += 1
    return out


def _confirm_unroll_schedule(*, base: int, max_unroll: int) -> List[int]:
    """
    Generate a small, deterministic unroll schedule for CONFIRM.

    Motivation: some wraparound bugs require a slightly longer suffix than the
    default bound (e.g., P2C after overflow). We first try the base bound for
    speed, then grow it a few times before giving up on this candidate.
    """

    b = max(1, int(base))
    cap = max(b, int(max_unroll))
    # Multiplicative growth keeps the schedule short.
    out: List[int] = []
    for k in (1, 2, 3, 4):
        v = min(cap, b * k)
        if v not in out:
            out.append(v)
    return out


def run_wraparound_cegis(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Optional[Path],
    ultimate: Path,
    candidate: Optional[WraparoundCandidate] = None,
    timeout_seconds: int = 1200,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    confirm_unroll: int = 3,
    max_confirm_unroll: int = 12,
    max_iters: int = 6,
    # Heuristic refinement: if CONFIRM times out, under-approximate env by zeroing unassigned inputs.
    enable_env_completion_refinement: bool = True,
    # Default order for the standalone wraparound workflow.
    stage_order: str = "entry_confirm_closure",
    # Auto mode policy: require P4B monotone-update meta when inferring candidates from global asserts.
    require_meta_step_for_global_asserts: bool = False,
    runner: Optional[StageRunner] = None,
    # Toolchain selection:
    #   - toolchain_nowitness: used by default for ENTRY/CONFIRM to avoid witness-printer crashes on SAFE.
    #   - toolchain_witness: used only when we need a witness (CEGIS refinement).
    toolchain: Optional[Path] = None,
    witness_toolchain: Optional[Path] = None,
    closure_toolchain: Optional[Path] = None,
    settings: Optional[Path] = None,
    closure_settings: Optional[Path] = None,
) -> Path:
    """
    Iterative wraparound CEGIS loop for sound bug finding.

    We support multiple stage orders:

      - entry_closure_confirm (default): ENTRY -> CLOSURE -> CONFIRM
        Useful when you expect closure to hold and want to gate confirm on a
        proven pump summary.

      - entry_confirm_closure: ENTRY -> CONFIRM -> CLOSURE
        Recommended when integrating wraparound into the main verification
        pipeline: if CONFIRM does not find a bug, CLOSURE is wasted work.

    Refinement (when closure_check is not SAFE):
      - distcache-specific index stabilization (index_expr -> constant eport), if applicable;
      - projection shrinking (drop a few non-mandatory vars per iteration).

    All artifacts and outcomes are recorded into `wraparound.cegis.manifest.json`.
    """

    spec_path = spec_path.resolve()
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    work_dir = out_dir / "work"
    base_bpl = out_dir / f"{spec_path.stem}.base.bpl"

    # 1) Compile base model (sequential harness; deterministic scheduler expected for closure/entry).
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=enable_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=pipeline_two_stage,
    )

    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")

    # 2) P4B meta is an optimization input; tolerate missing meta files.
    meta_by_node: Dict[str, dict] = {}
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            meta_by_node[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue

    # 3) DistCache stabilization: hash caps and constant partition eports.
    partition_ports: Dict[str, int] = {}
    if _is_distcache_like(spec_text):
        caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
        if caps:
            node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
            patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=caps)
            if patched != base_text:
                base_text = patched
                base_bpl.write_text(base_text, encoding="utf-8")
        partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

    # 4) Infer candidates from spec/meta unless caller provided an explicit candidate.
    if candidate is None:
        cands = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=base_text,
            meta_by_node=meta_by_node,
            require_meta_step_for_global_asserts=require_meta_step_for_global_asserts,
        )
        if not cands:
            raise WraparoundCegisError("failed to infer wraparound candidates; pass a spec that exposes a counter update")
        cand = cands[0]
    else:
        cand = candidate

    # 5) Resolve defaults for solver toolchains/settings.
    root = repo_root()
    tc_nowit_def, tc_wit_def, tc_cl_def, st_nowit_def, st_wit_def, st_cl_def = _default_toolchain_paths(root=root)
    toolchain_nowitness = (toolchain or tc_nowit_def).resolve()
    toolchain_witness = (witness_toolchain or tc_wit_def).resolve()
    closure_toolchain = (closure_toolchain or tc_cl_def).resolve()
    settings = (settings or st_nowit_def).resolve()
    witness_settings = st_wit_def.resolve()
    closure_settings = (closure_settings or st_cl_def).resolve()

    runner = runner or UltimateStageRunner(ultimate=ultimate)

    manifest_path = _run_cegis_loop(
        spec_path=spec_path,
        spec_text=spec_text,
        base_bpl=base_bpl,
        base_text=base_text,
        out_dir=out_dir,
        work_dir=work_dir,
        candidate=cand,
        partition_ports=partition_ports,
        timeout_seconds=timeout_seconds,
        resource_limits=resource_limits,
        confirm_unroll=confirm_unroll,
        max_confirm_unroll=max_confirm_unroll,
        max_iters=max_iters,
        enable_env_completion_refinement=enable_env_completion_refinement,
        runner=runner,
        toolchain_nowitness=toolchain_nowitness,
        toolchain_witness=toolchain_witness,
        witness_settings=witness_settings,
        closure_toolchain=closure_toolchain,
        settings=settings,
        closure_settings=closure_settings,
        stage_order=stage_order,
    )
    return manifest_path


def _run_cegis_loop(
    *,
    spec_path: Path,
    spec_text: str,
    base_bpl: Path,
    base_text: str,
    out_dir: Path,
    work_dir: Path,
    candidate: WraparoundCandidate,
    partition_ports: Dict[str, int],
    timeout_seconds: int,
    resource_limits: bool,
    confirm_unroll: int,
    max_confirm_unroll: int,
    max_iters: int,
    enable_env_completion_refinement: bool,
    runner: StageRunner,
    toolchain_nowitness: Path,
    toolchain_witness: Path,
    witness_settings: Path,
    closure_toolchain: Path,
    settings: Path,
    closure_settings: Path,
    stage_order: str,
) -> Path:
    """
    Core iterative loop (unit-testable via a fake StageRunner).
    """

    cand = candidate
    det_period = _infer_deterministic_scheduler_period(base_text.splitlines())

    try:
        spec_model = parse_model(spec_text)
    except Exception:
        # Unit tests may call `_run_cegis_loop` with dummy/empty spec text.
        # Env-completion refinement is optional; fall back to an empty model.
        from dslc.speclang.model import SpecModel

        spec_model = SpecModel()

    pump_reg = cand.pump_reg
    accel_regs = cand.accel_regs

    index_expr = cand.index_expr
    index_value = cand.index_value if cand.index_value is not None else 0
    # Conditional existence/profile assumptions synthesized by CEGIS refinements.
    extra_assumes: List[str] = []
    env_completion_done = False
    witness_profile_done = False

    def _sanitize_local(name: str) -> str:
        # Keep consistent with dslc/transform/wraparound_common.py
        return re.sub(r"[^A-Za-z0-9_]", "_", name)

    def _closure_failed_proc_name(log_text: str) -> Optional[str]:
        """
        Best-effort extraction of which closure assert wrapper failed.

        With per-assert wrappers, Ultimate typically logs lines like:
          "=== Iteration k === Targeting __wraparound_closure_assert_proj_xxxASSERT_VIOLATIONASSERT ==="
        """

        m = re.search(r"Targeting\s+(?P<name>__wraparound_closure_assert_[A-Za-z0-9_]+)", log_text)
        if m:
            return m.group("name")
        # Fallback: some toolchains mention the error location without "Targeting".
        m = re.search(r"(?P<name>__wraparound_closure_assert_[A-Za-z0-9_]+)", log_text)
        if m:
            return m.group("name")
        return None

    def _assume_all_meta_sources_const(*, field: str, bv_value: str) -> None:
        """
        Constrain all meta sources that contain `.<field>` to the same constant.

        This is a pragmatic fix for a recurring DistCache pitfall:
          - We fast-forward reg[cell] based on a meta-derived index (leafswitchidx/spineswitchidx),
          - but the harness may overwrite the node-local meta from host meta (e.g., io_meta.*),
          - so constraining only `<node>_meta.<field>` is not enough in no-slicing builds.

        We only add assumptions for variables that actually exist in the current base Boogie
        text, avoiding "undeclared identifier" errors in sliced builds.
        """

        # Prefixes such that `<prefix>_meta.<field>` appears in the Boogie text.
        prefixes = sorted(set(re.findall(rf"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.{re.escape(field)}\b", base_text)))
        for p in prefixes:
            extra_assumes.append(f"{p}_meta.{field} == {bv_value}")

    if partition_ports and index_expr:
        # If we infer a constant index from DistCache BMv2 entries, also add a
        # matching assumption to reduce solver noise and avoid "pumping a
        # different cell than the P4 action updates" corner cases when meta
        # indices are otherwise unconstrained.
        #
        # This is a *conditional* certificate: if these constraints are too strong,
        # confirm/closure will fail and we will not claim a certified UNSAFE.
        if ("leafload" in pump_reg) and ("leaf_eport" in partition_ports) and ("leafswitchidx" in index_expr):
            index_expr = None
            index_value = partition_ports["leaf_eport"]
            # IMPORTANT: constrain host meta sources too (e.g., io_meta.leafswitchidx), otherwise
            # no-slicing builds may overwrite the constrained node meta and pump a different cell.
            _assume_all_meta_sources_const(field="leafswitchidx", bv_value=f"{index_value}bv16")
        if ("spineload" in pump_reg) and ("spine_eport" in partition_ports) and ("spineswitchidx" in index_expr):
            index_expr = None
            index_value = partition_ports["spine_eport"]
            _assume_all_meta_sources_const(field="spineswitchidx", bv_value=f"{index_value}bv16")
            # DistCache P2C suffixes often need `leafload > 0` to expose the bug.
            # If `leafswitchidx` is left unconstrained, the "make leafload > 0" packet
            # may update a different cell than the subsequent P2C query reads, making the
            # confirm stage spuriously SAFE. Constrain leafswitchidx too when available.
            if "leaf_eport" in partition_ports:
                _assume_all_meta_sources_const(
                    field="leafswitchidx", bv_value=f"{partition_ports['leaf_eport']}bv16"
                )

    proj_vars = list(cand.proj_vars)
    if partition_ports and proj_vars:
        drop_suffixes = (
            ".leafswitchidx",
            ".spineswitchidx",
            ".hashval_for_partition",
            ".hashval_for_spine_partition",
        )
        proj_vars = [v for v in proj_vars if not v.endswith(drop_suffixes)]

    cutpoint_cond = cand.cutpoint_cond
    step_op = cand.step_op
    step_delta = int(cand.step_delta) if cand.step_delta is not None else 1

    mandatory_proj = ["procurator_phase"]
    mandatory_proj.extend([v for v in proj_vars if v.endswith("_inbox_count") or v.endswith("_egress_count")])
    mandatory_proj = sorted(set(mandatory_proj))

    attempts: List[CegisAttemptRecord] = []
    base_proj_set = set(proj_vars)
    base_index_expr = index_expr
    base_index_value = index_value

    for it in range(max_iters):
        notes: List[str] = []
        if it > 0:
            notes.append(f"refine_iter={it}")
        if det_period is not None:
            notes.append(f"deterministic_scheduler_period={det_period}")
        if base_index_expr is not None and index_expr is None:
            notes.append("index_expr=const")
        if int(index_value) != int(base_index_value):
            notes.append(f"index_value={index_value}")
        dropped_proj = sorted(base_proj_set.difference(set(proj_vars)))
        if dropped_proj:
            # Keep it stable and grep-friendly for manifests.
            notes.append("drop_proj_vars=" + ",".join(dropped_proj))

        cfg = CegisAttemptConfig(
            attempt=it,
            pump_reg=pump_reg,
            accel_regs=accel_regs,
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=tuple(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            extra_assumes=tuple(extra_assumes),
            notes=tuple(notes),
        )

        stem = f"{spec_path.stem}.cegis.{it:02d}"
        entry_bpl = out_dir / f"{stem}.entry_check.bpl"
        closure_bpl = out_dir / f"{stem}.closure_check.bpl"
        entry_log = out_dir / f"{stem}.entry_check.log"
        closure_log = out_dir / f"{stem}.closure_check.log"

        entry_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            extra_assumes=extra_assumes,
        )
        entry_bpl.write_text(entry_txt, encoding="utf-8")

        closure_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            extra_assumes=extra_assumes,
        )
        closure_bpl.write_text(closure_txt, encoding="utf-8")

        # Always emit a default CONFIRM instance so that artifacts are well-defined even
        # if we exit early after ENTRY (e.g., ENTRY is SAFE/UNKNOWN).
        #
        # For entry_confirm_closure we may emit additional confirm instances with a larger
        # unroll bound later; those are recorded as separate attempts in the manifest.
        confirm_bpl = out_dir / f"{stem}.confirm.unroll{confirm_unroll}.bpl"
        confirm_log = out_dir / f"{stem}.confirm.unroll{confirm_unroll}.log"
        confirm_txt0 = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CONFIRM,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            extra_assumes=extra_assumes,
        )
        confirm_txt0, _confirm_steps0 = _unroll_confirm_like_mainprocedure(
            bpl_text=confirm_txt0, requested_steps=confirm_unroll, deterministic_period=det_period
        )
        confirm_bpl.write_text(confirm_txt0, encoding="utf-8")

        artifacts = CegisAttemptArtifacts(
            entry_bpl=str(entry_bpl),
            closure_bpl=str(closure_bpl),
            confirm_bpl=str(confirm_bpl),
            entry_log=str(entry_log),
            closure_log=str(closure_log),
            confirm_log=str(confirm_log),
        )

        ultimate_home_root = out_dir / "ultimate-home"

        # ENTRY_CHECK is a pure reachability gate: is the deterministic round executable?
        # We run it with the *non-witness* toolchain to avoid witness-printer crashes on SAFE.
        entry_res = runner.run(
            stage="entry_check",
            input_bpl=entry_bpl,
            log_path=entry_log,
            ultimate_home=ultimate_home_root / stem / "entry",
            toolchain=toolchain_nowitness,
            settings=settings,
            timeout_seconds=timeout_seconds,
            resource_limits=resource_limits,
        )

        if not entry_res.is_unsafe:
            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=None, confirm=None))
            _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)
            break

        if stage_order not in {"entry_closure_confirm", "entry_confirm_closure"}:
            raise WraparoundCegisError(f"unknown stage_order: {stage_order}")

        closure_res: Optional[StageRunResult] = None
        confirm_res: Optional[StageRunResult] = None

        if stage_order == "entry_closure_confirm":
            closure_res = runner.run(
                stage="closure_check",
                input_bpl=closure_bpl,
                log_path=closure_log,
                ultimate_home=ultimate_home_root / stem / "closure",
                toolchain=closure_toolchain,
                settings=closure_settings,
                timeout_seconds=timeout_seconds,
                resource_limits=resource_limits,
            )
            if closure_res.is_safe:
                # Legacy ordering: we already proved closure, so we do not need a witness.
                # Run confirm with the non-witness toolchain to avoid witness printer crashes.
                confirm_res = runner.run(
                    stage="confirm",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / "confirm",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                attempts.append(
                    CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=confirm_res)
                )
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )
                break

            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=None))
            _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)

        else:
            # entry_confirm_closure: run confirm first; only certify with closure if confirm finds a bug.
            #
            # We try a short unroll schedule because some bugs require a slightly longer suffix.
            confirm_found_bug = False
            retry_after_timeout_refine = False
            enable_refine_tried = False
            for unroll in _confirm_unroll_schedule(base=confirm_unroll, max_unroll=max_confirm_unroll):
                confirm_bpl = out_dir / f"{stem}.confirm.unroll{unroll}.bpl"
                confirm_log = out_dir / f"{stem}.confirm.unroll{unroll}.log"

                confirm_txt = instrument_bpl_text(
                    bpl_text=base_text,
                    stage=WraparoundStage.CONFIRM,
                    pump_reg=pump_reg,
                    accel_regs=list(accel_regs),
                    index_value=index_value,
                    index_expr=index_expr,
                    proj_vars=list(proj_vars),
                    cutpoint_cond=cutpoint_cond,
                    step_op=step_op,
                    step_delta=step_delta,
                    extra_assumes=extra_assumes,
                )
                confirm_txt, confirm_steps = _unroll_confirm_like_mainprocedure(
                    bpl_text=confirm_txt, requested_steps=unroll, deterministic_period=det_period
                )
                confirm_bpl.write_text(confirm_txt, encoding="utf-8")

                artifacts = CegisAttemptArtifacts(
                    entry_bpl=str(entry_bpl),
                    closure_bpl=str(closure_bpl),
                    confirm_bpl=str(confirm_bpl),
                    entry_log=str(entry_log),
                    closure_log=str(closure_log),
                    confirm_log=str(confirm_log),
                )

                # Record which unroll we tried for reproducibility.
                cfg_i = CegisAttemptConfig(
                    attempt=cfg.attempt,
                    pump_reg=cfg.pump_reg,
                    accel_regs=cfg.accel_regs,
                    index_value=cfg.index_value,
                    index_expr=cfg.index_expr,
                    proj_vars=cfg.proj_vars,
                    cutpoint_cond=cfg.cutpoint_cond,
                    step_op=cfg.step_op,
                    step_delta=cfg.step_delta,
                    extra_assumes=tuple(extra_assumes),
                    notes=tuple(
                        list(cfg.notes)
                        + [f"confirm_unroll={unroll}"]
                        + ([f"confirm_steps={confirm_steps}"] if confirm_steps != int(unroll) else [])
                    ),
                )

                # First, run confirm with the non-witness toolchain. If this already finds
                # a bug, we run closure and only then (on closure failure) obtain a witness.
                confirm_res = runner.run(
                    stage="confirm",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )

                if confirm_res.is_unknown:
                    # Do not mis-classify UNKNOWN (e.g., timeout) as "no bug"; in practice,
                    # longer unrolls will only make this worse. Record and stop trying this
                    # candidate so the caller can fall back to the full semantics.
                    attempts.append(
                        CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                    )
                    _write_manifest(
                        out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                    )
                    # Refinement: if CONFIRM timed out, try shrinking the environment by
                    # setting unassigned injected inputs to 0. This is a sound under-approx
                    # for bug finding and can drastically reduce branching in large programs.
                    if (
                        enable_env_completion_refinement
                        and (not env_completion_done)
                        and confirm_res.timed_out
                        and (it + 1 < max_iters)
                    ):
                        new_assumes = _synthesize_env_completion_assumes(model=spec_model, base_text=base_text)
                        before = set(extra_assumes)
                        for aexpr in new_assumes:
                            if aexpr not in before:
                                extra_assumes.append(aexpr)
                                before.add(aexpr)
                        env_completion_done = True
                        confirm_found_bug = False
                        retry_after_timeout_refine = True
                        break

                    confirm_found_bug = False
                    break

                if not confirm_res.is_unsafe:
                    # Not a bug under this bound; try a longer suffix.
                    attempts.append(
                        CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                    )
                    _write_manifest(
                        out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                    )

                    # CEGIS pump-enable refinement (key for wraparound bugs):
                    #
                    # CONFIRM can return SAFE simply because the pumped register never
                    # leaves MAX, so all property asserts are gated off. Before we waste
                    # time increasing the suffix, try to synthesize an environment profile
                    # that *enables* the pump update (i.e., reaches target != MAX).
                    if (not enable_refine_tried) and (not witness_profile_done) and (it + 1 < max_iters):
                        enable_refine_tried = True
                        enable_bpl = out_dir / f"{stem}.enable_check.unroll{unroll}.bpl"
                        enable_log = out_dir / f"{stem}.enable_check.unroll{unroll}.log"

                        enable_txt = instrument_bpl_text(
                            bpl_text=base_text,
                            stage=WraparoundStage.ENABLE_CHECK,
                            pump_reg=pump_reg,
                            accel_regs=list(accel_regs),
                            index_value=index_value,
                            index_expr=index_expr,
                            proj_vars=list(proj_vars),
                            cutpoint_cond=cutpoint_cond,
                            step_op=step_op,
                            step_delta=step_delta,
                            extra_assumes=extra_assumes,
                        )
                        enable_txt, _enable_steps = _unroll_confirm_like_mainprocedure(
                            bpl_text=enable_txt, requested_steps=unroll, deterministic_period=det_period
                        )
                        enable_bpl.write_text(enable_txt, encoding="utf-8")

                        enable_res = runner.run(
                            stage=f"enable_check.unroll{unroll}",
                            input_bpl=enable_bpl,
                            log_path=enable_log,
                            ultimate_home=ultimate_home_root / stem / f"enable_check.unroll{unroll}",
                            toolchain=toolchain_nowitness,
                            settings=settings,
                            timeout_seconds=timeout_seconds,
                            resource_limits=resource_limits,
                        )

                        # Update the last record with enable artifacts for reproducibility.
                        last = attempts[-1]
                        attempts[-1] = CegisAttemptRecord(
                            cfg=last.cfg,
                            artifacts=CegisAttemptArtifacts(
                                entry_bpl=last.artifacts.entry_bpl,
                                closure_bpl=last.artifacts.closure_bpl,
                                confirm_bpl=last.artifacts.confirm_bpl,
                                entry_log=last.artifacts.entry_log,
                                closure_log=last.artifacts.closure_log,
                                confirm_log=last.artifacts.confirm_log,
                                enable_bpl=str(enable_bpl),
                                enable_log=str(enable_log),
                            ),
                            entry=last.entry,
                            closure=last.closure,
                            confirm=last.confirm,
                        )
                        _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )

                        # If enable_check is UNSAFE, extract a witness profile and retry
                        # in the next outer iteration (so ENTRY/CONFIRM/CLOSURE align).
                        if enable_res.is_unsafe:
                            # Re-run with witness printing to extract a compact input profile.
                            witness_log = enable_log.with_suffix(enable_log.suffix + ".witness.log")
                            _ = runner.run(
                                stage=f"enable_check.witness.unroll{unroll}",
                                input_bpl=enable_bpl,
                                log_path=witness_log,
                                ultimate_home=ultimate_home_root / stem / f"enable_check.unroll{unroll}.witness",
                                toolchain=toolchain_witness,
                                settings=witness_settings,
                                timeout_seconds=timeout_seconds,
                                resource_limits=resource_limits,
                            )
                            witness = find_latest_graphml_witness(work_dir=out_dir)
                            if witness:
                                try:
                                    wtxt = witness.read_text(encoding="utf-8", errors="replace")
                                    wa = extract_assumptions_from_graphml(wtxt)
                                    new_assumes = synthesize_boogie_assumes(
                                        witness_assumptions=wa,
                                        base_bpl_text=base_text,
                                        allow_prefixes=_collect_env_input_prefixes(spec_model),
                                    )
                                except Exception:
                                    new_assumes = []
                                before = set(extra_assumes)
                                added_any = False
                                for aexpr in new_assumes:
                                    if aexpr not in before:
                                        extra_assumes.append(aexpr)
                                        before.add(aexpr)
                                        added_any = True
                                witness_profile_done = witness_profile_done or added_any
                                if added_any:
                                    confirm_found_bug = False
                                    retry_after_timeout_refine = True
                                    break

                    continue

                # CONFIRM found a bug.
                #
                # Design choice (per our workflow): run CLOSURE *after* CONFIRM, and
                # only attempt closure when we already have evidence the bug exists.
                #
                # If closure is SAFE, we have a certified (sound) accelerated UNSAFE.
                # If closure is not SAFE (UNKNOWN/TIMEOUT/UNSAFE), we may optionally
                # try a witness-guided refinement to pin down the environment, then
                # retry in the next outer iteration.
                confirm_found_bug = True
                closure_res = runner.run(
                    stage="closure_check",
                    input_bpl=closure_bpl,
                    log_path=closure_log,
                    ultimate_home=ultimate_home_root / stem / "closure",
                    toolchain=closure_toolchain,
                    settings=closure_settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )

                attempts.append(
                    CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=confirm_res)
                )
                attempt_idx = len(attempts) - 1
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )

                if closure_res.is_safe:
                    break

                # Closure failed to certify. Optionally try to mine a witness-driven
                # environment profile to make the next closure attempt easier.
                #
                # We only do this if (a) we have iterations left, and (b) we haven't
                # already extracted such a profile.
                added_any = False
                if (not witness_profile_done) and (it + 1 < max_iters):
                    witness_log = confirm_log.with_suffix(confirm_log.suffix + ".witness.log")
                    _ = runner.run(
                        stage=f"confirm.witness.unroll{unroll}",
                        input_bpl=confirm_bpl,
                        log_path=witness_log,
                        ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.witness",
                        toolchain=toolchain_witness,
                        settings=witness_settings,
                        timeout_seconds=timeout_seconds,
                        resource_limits=resource_limits,
                    )
                    witness = find_latest_graphml_witness(work_dir=out_dir)
                    if witness:
                        try:
                            wtxt = witness.read_text(encoding="utf-8", errors="replace")
                            wa = extract_assumptions_from_graphml(wtxt)
                            new_assumes = synthesize_boogie_assumes(
                                witness_assumptions=wa,
                                base_bpl_text=base_text,
                                allow_prefixes=_collect_env_input_prefixes(spec_model),
                            )
                        except Exception:
                            new_assumes = []
                        before = set(extra_assumes)
                        for aexpr in new_assumes:
                            if aexpr not in before:
                                extra_assumes.append(aexpr)
                                before.add(aexpr)
                                added_any = True
                        witness_profile_done = witness_profile_done or added_any

                if added_any:
                    # Retry in next outer iteration so ENTRY/CONFIRM/CLOSURE align
                    # under the refined profile (certificate remains sound).
                    confirm_found_bug = False
                    retry_after_timeout_refine = True
                    break

                if closure_res.is_unsafe:
                    # CEGAR-style refinement: if closure fails on a projection equality,
                    # drop that variable and retry in the next outer iteration.
                    try:
                        clog = closure_log.read_text(encoding="utf-8", errors="replace")
                    except Exception:
                        clog = ""
                    failed = _closure_failed_proc_name(clog)
                    if failed and failed.startswith("__wraparound_closure_assert_proj_"):
                        # Map proc back to a proj var (sanitized name match).
                        for v in list(proj_vars):
                            if v in mandatory_proj:
                                continue
                            if failed == f"__wraparound_closure_assert_proj_{_sanitize_local(v)}":
                                proj_vars = [x for x in proj_vars if x != v]
                                break
                break  # end unroll schedule; proceed to next outer iteration

            if confirm_found_bug:
                # We ran closure (recorded above); only accept if closure is SAFE.
                if closure_res is not None and closure_res.is_safe:  # type: ignore[truthy-bool]
                    break
            else:
                # No confirm UNSAFE even after unroll growth: don't waste time refining closure/projection.
                if retry_after_timeout_refine:
                    continue
                break

        if index_expr is not None and cand.index_value is not None:
            index_expr = None
            index_value = int(cand.index_value)
            continue

        # Projection refinement fallback: progressively drop more non-mandatory vars.
        #
        # If closure_check timed out/was unknown, we cannot reliably pinpoint a culprit,
        # so we use a greedy shrink to reduce the proof burden in subsequent iterations.
        max_drops = min(len([v for v in proj_vars if v not in set(mandatory_proj)]), 2 + it * 3)
        if max_drops <= 0:
            # Nothing left to drop; keep iterating to allow index stabilization, etc.
            continue
        proj_vars = _refine_proj_vars_greedy(proj_vars, mandatory=mandatory_proj, max_drops=max_drops)

    return _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)


def run_wraparound_cegis_multi(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Optional[Path],
    ultimate: Path,
    timeout_seconds: int = 1200,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    confirm_unroll: int = 3,
    max_confirm_unroll: int = 12,
    max_iters: int = 6,
    stage_order: str = "entry_confirm_closure",
    max_targets: int = 8,
    require_meta_step_for_global_asserts: bool = False,
) -> List[Path]:
    """
    Run wraparound CEGIS for multiple candidates (best-effort).

    This is intended for integration into the main verification pipeline:
      - try a coarse "group" first (when candidates are compatible),
      - then fall back to per-register candidates.

    Returns a list of manifest paths (one per attempted target), in order.
    """

    spec_path = spec_path.resolve()
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    # Compile once and infer candidates.
    work_dir = out_dir / "work"
    base_bpl = out_dir / f"{spec_path.stem}.base.bpl"
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=enable_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=pipeline_two_stage,
    )
    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")

    meta_by_node: Dict[str, dict] = {}
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            meta_by_node[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue

    partition_ports: Dict[str, int] = {}
    if _is_distcache_like(spec_text):
        caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
        if caps:
            node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
            patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=caps)
            if patched != base_text:
                base_text = patched
                base_bpl.write_text(base_text, encoding="utf-8")
        partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

    cands = infer_wraparound_candidates(
        spec_text=spec_text,
        bpl_text=base_text,
        meta_by_node=meta_by_node,
        require_meta_step_for_global_asserts=require_meta_step_for_global_asserts,
    )
    if not cands:
        return []

    # Deterministic target ordering for reproducibility.
    cands = sorted(cands, key=lambda c: (c.pump_reg, str(c.index_value), str(c.index_expr)))

    # If multiple wraparound candidates exist, prefer the one that matches the
    # benchmark's intent. This matters for DistCache where both leafload/spineload
    # are monotone counters but a given .prop is usually written to target one of them.
    stem_lower = spec_path.stem.lower()
    prefer_token: Optional[str] = None
    if "spineload" in stem_lower:
        prefer_token = "spineload"
    elif "leafload" in stem_lower:
        prefer_token = "leafload"
    if prefer_token is not None and len(cands) > 1:
        def _pref_key(c: WraparoundCandidate) -> tuple[int, str, str, str]:
            hit = 0 if (prefer_token in c.pump_reg.lower() or prefer_token in c.reason.lower()) else 1
            return (hit, c.pump_reg, str(c.index_value), str(c.index_expr))

        cands = sorted(cands, key=_pref_key)
        # If the preferred token matches at least one candidate, drop the rest.
        # This keeps `--wraparound auto` aligned with the benchmark's intent and
        # avoids spending time on irrelevant counters.
        preferred = [
            c
            for c in cands
            if (prefer_token in c.pump_reg.lower() or prefer_token in c.reason.lower())
        ]
        if preferred:
            cands = preferred
    cands = cands[: max(1, int(max_targets))]

    roots: List[WraparoundCandidate] = []

    # Try a coarse group if (step_op, step_delta, cutpoint) align.
    if cands:
        base0 = cands[0]
        compatible = all(
            (c.step_op == base0.step_op)
            and (int(c.step_delta or 1) == int(base0.step_delta or 1))
            and (str(c.cutpoint_cond) == str(base0.cutpoint_cond))
            for c in cands
        )
        same_index = all((c.index_value == base0.index_value) and (c.index_expr == base0.index_expr) for c in cands)
        if compatible and same_index and len(cands) > 1:
            regs: List[str] = []
            for c in cands:
                regs.append(c.pump_reg)
                regs.extend(list(c.accel_regs))
            seen = set()
            uniq_regs: List[str] = []
            for r in regs:
                if r not in seen:
                    seen.add(r)
                    uniq_regs.append(r)
            proj: List[str] = []
            for c in cands:
                proj.extend(list(c.proj_vars))
            roots.append(
                WraparoundCandidate(
                    pump_reg=base0.pump_reg,
                    accel_regs=tuple(sorted(set(uniq_regs))),
                    index_value=base0.index_value,
                    index_expr=base0.index_expr,
                    proj_vars=tuple(sorted(set(proj))),
                    cutpoint_cond=base0.cutpoint_cond,
                    reason="group0(all_regs): " + "; ".join(sorted(set(c.reason for c in cands))),
                    step_op=base0.step_op,
                    step_delta=base0.step_delta,
                )
            )

    # Then try each candidate individually.
    roots.extend(cands)

    # Run CEGIS per root candidate, in isolated subdirectories (reuse the compiled base model).
    manifests: List[Path] = []
    root = repo_root()
    tc_nowit_def, tc_wit_def, tc_cl_def, st_nowit_def, st_wit_def, st_cl_def = _default_toolchain_paths(root=root)
    runner = UltimateStageRunner(ultimate=ultimate)

    for i, cand in enumerate(roots):
        subdir = out_dir / f"target.{i:02d}.{cand.pump_reg}"
        subdir.mkdir(parents=True, exist_ok=True)
        mpath = _run_cegis_loop(
            spec_path=spec_path,
            spec_text=spec_text,
            base_bpl=base_bpl,
            base_text=base_text,
            out_dir=subdir,
            work_dir=work_dir,
            candidate=cand,
            partition_ports=partition_ports,
            timeout_seconds=timeout_seconds,
            resource_limits=resource_limits,
            confirm_unroll=confirm_unroll,
            max_confirm_unroll=max_confirm_unroll,
            max_iters=max_iters,
            enable_env_completion_refinement=True,
            runner=runner,
            toolchain_nowitness=tc_nowit_def,
            toolchain_witness=tc_wit_def,
            witness_settings=st_wit_def,
            closure_toolchain=tc_cl_def,
            settings=st_nowit_def,
            closure_settings=st_cl_def,
            stage_order=stage_order,
        )
        manifests.append(mpath)
    return manifests
