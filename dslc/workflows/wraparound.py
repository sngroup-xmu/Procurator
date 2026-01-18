from __future__ import annotations

import argparse
import json
import re
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, List, Optional, Sequence

from ..analysis.wraparound_candidates import WraparoundCandidate, infer_wraparound_candidates
from ..compiler import compile_spec_file
from ..speclang import parse_model
from ..transform.wraparound import WraparoundStage, instrument_bpl_file


class WraparoundWorkflowError(RuntimeError):
    pass


def _repo_root() -> Path:
    here = Path(__file__).resolve()
    return here.parents[2]  # .../dslc/workflows -> repo root


def _sanitize_tag(tag: str) -> str:
    tag = tag.strip()
    if not tag:
        return "cand"
    return re.sub(r"[^A-Za-z0-9_]+", "_", tag)


def _candidate_tag(cand: WraparoundCandidate) -> str:
    parts = [cand.pump_reg]
    if cand.index_value is not None:
        parts.append(f"idx{cand.index_value}")
    elif cand.index_expr is not None:
        parts.append("idxexpr")
    parts.append(cand.reason)
    return ".".join(parts)


def _default_out_dir(*, spec_path: Path) -> Path:
    root = _repo_root()
    return root / ".tmp" / "wraparound" / spec_path.stem


def _read_meta_by_node(*, spec_text: str, work_dir: Optional[Path]) -> Dict[str, dict]:
    if work_dir is None:
        return {}

    try:
        model = parse_model(spec_text)
    except Exception as e:
        raise WraparoundWorkflowError(f"failed to parse spec for meta lookup: {e}") from e

    out: Dict[str, dict] = {}
    for alias in model.imports.keys():
        meta_path = work_dir / f"{alias}.meta.json"
        if not meta_path.exists():
            continue
        try:
            out[alias] = json.loads(meta_path.read_text(encoding="utf-8"))
        except Exception:
            # Meta is an optimization input; never fail the workflow on parse errors.
            continue
    return out


@dataclass(frozen=True)
class WraparoundTaskPaths:
    entry_check: str
    closure_check: str
    confirm: str
    pump: str
    accel: str
    accel_probe: str


@dataclass(frozen=True)
class WraparoundManifestCandidate:
    tag: str
    reason: str
    pump_reg: str
    accel_regs: List[str]
    index_value: Optional[int]
    index_expr: Optional[str]
    proj_vars: List[str]
    cutpoint_cond: Optional[str]
    step_op: str
    step_delta: Optional[int]
    bpl: WraparoundTaskPaths


@dataclass(frozen=True)
class WraparoundManifest:
    spec: str
    base_bpl: str
    work_dir: Optional[str]
    candidates: List[WraparoundManifestCandidate]


def generate_wraparound_tasks(
    *,
    spec_path: Path,
    out_dir: Optional[Path] = None,
    base_bpl: Optional[Path] = None,
    p4b_bin: Optional[Path] = None,
    work_dir: Optional[Path] = None,
    max_env_inputs: bool = False,
    enable_slicing: bool = True,
    prune_env_inputs: bool = True,
    por_enabled: bool = False,
    boogie_harness: str = "sequential",
    pipeline_two_stage: bool = True,
) -> Path:
    """
    Generate wraparound verification tasks (Boogie programs) from a `.prop` file.

    This function only generates artifacts:
      - base `.bpl` (faithful semantics)
      - per-candidate staged `.bpl` files (entry_check/closure_check/confirm + debug stages)
      - `wraparound.manifest.json` describing all artifacts

    It does NOT run Ultimate/GemCutter.
    """

    spec_path = spec_path.resolve()
    if not spec_path.exists():
        raise WraparoundWorkflowError(f"spec not found: {spec_path}")

    spec_text = spec_path.read_text(encoding="utf-8")

    out_dir = (out_dir or _default_out_dir(spec_path=spec_path)).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    if base_bpl is None:
        base_bpl = out_dir / f"{spec_path.stem}.bpl"
    base_bpl = base_bpl.resolve()

    if work_dir is None:
        work_dir = Path(str(base_bpl) + ".work")
    work_dir = work_dir.resolve()

    boogie_harness = boogie_harness.lower().strip()
    if boogie_harness != "sequential":
        raise WraparoundWorkflowError("wraparound workflow requires --boogie-harness sequential")

    # 1) Compile base model (if needed).
    if not base_bpl.exists():
        compile_spec_file(
            spec_path=spec_path,
            backend="boogie",
            out=base_bpl,
            p4b_bin=p4b_bin,
            work_dir=work_dir,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            por_enabled=por_enabled,
            por_guard_enabled=True,
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
        )

    bpl_text = base_bpl.read_text(encoding="utf-8", errors="replace")
    meta_by_node = _read_meta_by_node(spec_text=spec_text, work_dir=work_dir if work_dir.exists() else None)

    # 2) Infer candidates.
    candidates = infer_wraparound_candidates(spec_text=spec_text, bpl_text=bpl_text, meta_by_node=meta_by_node)

    # 3) Emit staged tasks.
    manifest_candidates: List[WraparoundManifestCandidate] = []

    for cand in candidates:
        tag = _sanitize_tag(_candidate_tag(cand))
        stem = f"{base_bpl.stem}.{tag}"

        def stage_path(stage: str) -> Path:
            return out_dir / f"{stem}.{stage}.bpl"

        idx_value = cand.index_value
        idx_expr = cand.index_expr
        if idx_value is None and not idx_expr:
            raise WraparoundWorkflowError(f"candidate missing index_value/index_expr: {cand}")

        proj_vars = list(cand.proj_vars) if cand.proj_vars else None
        step_delta = int(cand.step_delta) if cand.step_delta is not None else 1

        entry_check = stage_path("entry_check")
        closure_check = stage_path("closure_check")
        confirm = stage_path("confirm")
        pump = stage_path("pump")
        accel = stage_path("accel")
        accel_probe = stage_path("accel_probe")

        instrument_bpl_file(
            in_path=base_bpl,
            out_path=entry_check,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=idx_value or 0,
            index_expr=idx_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
        )
        instrument_bpl_file(
            in_path=base_bpl,
            out_path=closure_check,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=idx_value or 0,
            index_expr=idx_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
        )
        instrument_bpl_file(
            in_path=base_bpl,
            out_path=confirm,
            stage=WraparoundStage.CONFIRM,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=idx_value or 0,
            index_expr=idx_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
        )

        # Debug stages (optional, but cheap and useful for diagnostics).
        instrument_bpl_file(
            in_path=base_bpl,
            out_path=pump,
            stage=WraparoundStage.PUMP,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=idx_value or 0,
            index_expr=idx_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
        )
        instrument_bpl_file(
            in_path=base_bpl,
            out_path=accel,
            stage=WraparoundStage.ACCEL,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=idx_value or 0,
            index_expr=idx_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
        )
        instrument_bpl_file(
            in_path=base_bpl,
            out_path=accel_probe,
            stage=WraparoundStage.ACCEL_PROBE,
            pump_reg=cand.pump_reg,
            accel_regs=cand.accel_regs,
            index_value=idx_value or 0,
            index_expr=idx_expr,
            proj_vars=proj_vars,
            cutpoint_cond=cand.cutpoint_cond,
            step_op=cand.step_op,
            step_delta=step_delta,
        )

        manifest_candidates.append(
            WraparoundManifestCandidate(
                tag=tag,
                reason=cand.reason,
                pump_reg=cand.pump_reg,
                accel_regs=list(cand.accel_regs),
                index_value=cand.index_value,
                index_expr=cand.index_expr,
                proj_vars=list(cand.proj_vars),
                cutpoint_cond=cand.cutpoint_cond,
                step_op=cand.step_op,
                step_delta=cand.step_delta,
                bpl=WraparoundTaskPaths(
                    entry_check=str(entry_check),
                    closure_check=str(closure_check),
                    confirm=str(confirm),
                    pump=str(pump),
                    accel=str(accel),
                    accel_probe=str(accel_probe),
                ),
            )
        )

    manifest = WraparoundManifest(
        spec=str(spec_path),
        base_bpl=str(base_bpl),
        work_dir=str(work_dir) if work_dir else None,
        candidates=manifest_candidates,
    )

    manifest_path = out_dir / "wraparound.manifest.json"
    manifest_path.write_text(json.dumps(asdict(manifest), indent=2, sort_keys=True), encoding="utf-8")
    return manifest_path


def _default_p4b_bin() -> Path:
    here = Path(__file__).resolve()
    return here.parents[1] / "toolchain" / "p4b_docker.sh"


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Generate wraparound acceleration tasks (no solver run)")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument("--out-dir", default="", help="Output directory (default: .tmp/wraparound/<specstem>)")
    ap.add_argument("--base-bpl", default="", help="Use an existing base .bpl (skip compilation)")
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary (required if compiling)")
    ap.add_argument("--work-dir", default="", help="Work directory for P4B outputs (default: <base>.work)")
    ap.add_argument(
        "--env",
        choices=["spec", "max"],
        default="spec",
        help="Environment model: 'spec' applies assume constraints, 'max' makes inputs fully nondet.",
    )
    ap.add_argument("--no-prune", action="store_true", help="Disable DAG-based slicing/env pruning during compile")
    ap.add_argument("--por", action="store_true", help="Enable POR during base compile (not used in staged tasks)")
    ap.add_argument("--no-two-stage", action="store_true", help="Disable two-stage ingress/egress scheduling")

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec)
    out_dir = Path(args.out_dir) if args.out_dir else None
    base_bpl = Path(args.base_bpl) if args.base_bpl else None
    p4b_bin = Path(args.p4b_bin) if args.p4b_bin else None
    if p4b_bin is None and base_bpl is None:
        p4b_bin = _default_p4b_bin()
    work_dir = Path(args.work_dir) if args.work_dir else None

    max_env_inputs = args.env == "max"
    prune = not args.no_prune

    try:
        manifest_path = generate_wraparound_tasks(
            spec_path=spec_path,
            out_dir=out_dir,
            base_bpl=base_bpl,
            p4b_bin=p4b_bin,
            work_dir=work_dir,
            max_env_inputs=max_env_inputs,
            enable_slicing=prune,
            prune_env_inputs=prune,
            por_enabled=args.por,
            boogie_harness="sequential",
            pipeline_two_stage=not args.no_two_stage,
        )
    except Exception as e:
        raise SystemExit(f"[ERR] {e}") from e

    print(f"[OK] manifest: {manifest_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

