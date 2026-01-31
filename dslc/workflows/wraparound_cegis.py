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
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text, unroll_mainprocedure_loop_text
from dslc.toolchain.ultimate_witness import (
    extract_assumptions_from_graphml,
    find_latest_graphml_witness,
    synthesize_boogie_assumes,
)
from dslc.utils.exec import wrap_resource_limits
from dslc.utils.repo import repo_root


class WraparoundCegisError(RuntimeError):
    pass


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
    for line in log_text.splitlines():
        if "RESULT:" in line:
            return line.strip()
    return None


def _default_toolchain_paths(*, root: Path) -> Tuple[Path, Path, Path, Path]:
    """
    Best-effort defaults that work for both in-repo toolchains and legacy Procurator paths.
    """

    # Toolchains.
    tc_no_witness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety.xml"
    tc_witness = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml"
    tc_legacy = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml"
    # Prefer the witness toolchain for bug finding; closure_check uses its own
    # witness-free toolchain to avoid Ultimate crashes on some SAFE tasks.
    toolchain = tc_witness if tc_witness.exists() else (tc_no_witness if tc_no_witness.exists() else tc_legacy)

    tc_closure = root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-ReachSafety.xml"
    closure_toolchain = tc_closure if tc_closure.exists() else toolchain

    # Settings.
    settings = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    settings_legacy = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    settings = settings if settings.exists() else settings_legacy

    closure_settings = root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
    closure_settings_legacy = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
    closure_settings = closure_settings if closure_settings.exists() else closure_settings_legacy
    if not closure_settings.exists():
        closure_settings = settings

    return toolchain.resolve(), closure_toolchain.resolve(), settings.resolve(), closure_settings.resolve()


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
    notes: Tuple[str, ...] = ()


@dataclass(frozen=True)
class CegisAttemptArtifacts:
    entry_bpl: str
    closure_bpl: str
    confirm_bpl: str
    entry_log: str
    closure_log: str
    confirm_log: str


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
    for line in lines:
        out_lines.append(line)
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
    # Default order for the standalone wraparound workflow.
    stage_order: str = "entry_closure_confirm",
    runner: Optional[StageRunner] = None,
    toolchain: Optional[Path] = None,
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
        cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=base_text, meta_by_node=meta_by_node)
        if not cands:
            raise WraparoundCegisError("failed to infer wraparound candidates; pass a spec that exposes a counter update")
        cand = cands[0]
    else:
        cand = candidate

    # 5) Resolve defaults for solver toolchains/settings.
    root = repo_root()
    tc_def, tc_cl_def, st_def, st_cl_def = _default_toolchain_paths(root=root)
    toolchain = (toolchain or tc_def).resolve()
    closure_toolchain = (closure_toolchain or tc_cl_def).resolve()
    settings = (settings or st_def).resolve()
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
        runner=runner,
        toolchain=toolchain,
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
    runner: StageRunner,
    toolchain: Path,
    closure_toolchain: Path,
    settings: Path,
    closure_settings: Path,
    stage_order: str,
) -> Path:
    """
    Core iterative loop (unit-testable via a fake StageRunner).
    """

    cand = candidate

    pump_reg = cand.pump_reg
    accel_regs = cand.accel_regs

    index_expr = cand.index_expr
    index_value = cand.index_value if cand.index_value is not None else 0

    if partition_ports and index_expr:
        if ("leafload" in pump_reg) and ("leaf_eport" in partition_ports) and ("leafswitchidx" in index_expr):
            index_expr = None
            index_value = partition_ports["leaf_eport"]
        if ("spineload" in pump_reg) and ("spine_eport" in partition_ports) and ("spineswitchidx" in index_expr):
            index_expr = None
            index_value = partition_ports["spine_eport"]

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
    extra_assumes: List[str] = []

    for it in range(max_iters):
        notes: List[str] = []
        if it > 0:
            notes.append(f"refine_iter={it}")
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
        confirm_txt0 = unroll_mainprocedure_loop_text(bpl_text=confirm_txt0, steps=confirm_unroll)
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

        entry_res = runner.run(
            stage="entry_check",
            input_bpl=entry_bpl,
            log_path=entry_log,
            ultimate_home=ultimate_home_root / stem / "entry",
            # ENTRY_CHECK is a pure reachability sanity gate (is the deterministic
            # round executable). Using the closure toolchain here can be
            # surprisingly slow and, depending on the settings, may yield UNKNOWN.
            toolchain=toolchain,
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
                # Use the default unroll bound for legacy ordering.
                confirm_res = runner.run(
                    stage="confirm",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / "confirm",
                    toolchain=toolchain,
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
                confirm_txt = unroll_mainprocedure_loop_text(bpl_text=confirm_txt, steps=unroll)
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
                    notes=tuple(list(cfg.notes) + [f"confirm_unroll={unroll}"]),
                )

                confirm_res = runner.run(
                    stage="confirm",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}",
                    toolchain=toolchain,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )

                if not confirm_res.is_unsafe:
                    # Not a bug under this bound; try a longer suffix.
                    attempts.append(
                        CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                    )
                    _write_manifest(
                        out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                    )
                    continue

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
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )
                # If closure is SAFE, we have a certified UNSAFE. Otherwise, try to
                # synthesize extra existence constraints from the confirm witness and refine.
                if closure_res.is_safe:
                    break

                # CEGIS refinement: extract a lightweight "input/profile" from the confirm witness.
                witness = find_latest_graphml_witness(work_dir=out_dir)
                if witness:
                    try:
                        wtxt = witness.read_text(encoding="utf-8", errors="replace")
                        wa = extract_assumptions_from_graphml(wtxt)
                        new_assumes = synthesize_boogie_assumes(witness_assumptions=wa, base_bpl_text=base_text)
                    except Exception:
                        new_assumes = []
                    before = set(extra_assumes)
                    for aexpr in new_assumes:
                        if aexpr not in before:
                            extra_assumes.append(aexpr)
                            before.add(aexpr)

                break  # end unroll schedule; proceed to next outer iteration

            if confirm_found_bug:
                # We ran closure (recorded above); only accept if closure is SAFE.
                if closure_res is not None and closure_res.is_safe:  # type: ignore[truthy-bool]
                    break
            else:
                # No confirm UNSAFE even after unroll growth: don't waste time refining closure/projection.
                break

        if index_expr is not None and cand.index_value is not None:
            index_expr = None
            index_value = int(cand.index_value)
            continue

        # Projection refinement: progressively drop more non-mandatory vars. This is intentionally
        # solver-agnostic (we use closure_check itself as the refinement oracle across iterations).
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

    cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=base_text, meta_by_node=meta_by_node)
    if not cands:
        return []

    # Deterministic target ordering for reproducibility.
    cands = sorted(cands, key=lambda c: (c.pump_reg, str(c.index_value), str(c.index_expr)))
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
    tc_def, tc_cl_def, st_def, st_cl_def = _default_toolchain_paths(root=root)
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
            runner=runner,
            toolchain=tc_def,
            closure_toolchain=tc_cl_def,
            settings=st_def,
            closure_settings=st_cl_def,
            stage_order=stage_order,
        )
        manifests.append(mpath)
    return manifests
