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
    toolchain = tc_no_witness if tc_no_witness.exists() else (tc_witness if tc_witness.exists() else tc_legacy)

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
    # Cheap classifier: DistCache benchmarks and entries commonly mention these tables/fields.
    return ("hash_leaf_partition_tbl" in spec_text) or ("hash_spine_partition_tbl" in spec_text)


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
    out = list(proj_vars)
    drops = 0
    # Drop from the end: later vars are usually derived meta/hash fields.
    i = len(out) - 1
    while i >= 0 and drops < max_drops:
        v = out[i]
        if v not in mandatory_set:
            out.pop(i)
            drops += 1
        i -= 1
    return out


def run_wraparound_cegis(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Path,
    ultimate: Path,
    timeout_seconds: int = 1200,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    confirm_unroll: int = 3,
    max_iters: int = 6,
    runner: Optional[StageRunner] = None,
    toolchain: Optional[Path] = None,
    closure_toolchain: Optional[Path] = None,
    settings: Optional[Path] = None,
    closure_settings: Optional[Path] = None,
) -> Path:
    """
    Iterative CEGIS loop for wraparound sound bug finding.

    Pipeline per attempt:
      ENTRY_CHECK  -> must be UNSAFE (non-vacuous reachability)
      CLOSURE_CHECK -> must be SAFE  (closed +1 summary under the chosen projection)
      CONFIRM       -> expected UNSAFE (functional bug)

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

    # 4) Infer candidates from spec/meta.
    cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=base_text, meta_by_node=meta_by_node)
    if not cands:
        raise WraparoundCegisError("failed to infer wraparound candidates; pass a spec that exposes a counter update")

    cand = cands[0]

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
        max_iters=max_iters,
        runner=runner,
        toolchain=toolchain,
        closure_toolchain=closure_toolchain,
        settings=settings,
        closure_settings=closure_settings,
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
    max_iters: int,
    runner: StageRunner,
    toolchain: Path,
    closure_toolchain: Path,
    settings: Path,
    closure_settings: Path,
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

    for it in range(max_iters):
        notes: List[str] = []
        if it > 0:
            notes.append(f"refine_iter={it}")

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
        confirm_bpl = out_dir / f"{stem}.confirm.bpl"

        entry_log = out_dir / f"{stem}.entry_check.log"
        closure_log = out_dir / f"{stem}.closure_check.log"
        confirm_log = out_dir / f"{stem}.confirm.log"

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
        )
        closure_bpl.write_text(closure_txt, encoding="utf-8")

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
        )
        confirm_txt = unroll_mainprocedure_loop_text(bpl_text=confirm_txt, steps=confirm_unroll)
        confirm_bpl.write_text(confirm_txt, encoding="utf-8")

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
            toolchain=closure_toolchain,
            settings=closure_settings,
            timeout_seconds=timeout_seconds,
            resource_limits=resource_limits,
        )

        if not entry_res.is_unsafe:
            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=None, confirm=None))
            break

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
            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=confirm_res))
            break

        attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=None))

        if index_expr is not None and cand.index_value is not None:
            index_expr = None
            index_value = int(cand.index_value)
            continue

        proj_vars = _refine_proj_vars_greedy(proj_vars, mandatory=mandatory_proj, max_drops=2)

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
