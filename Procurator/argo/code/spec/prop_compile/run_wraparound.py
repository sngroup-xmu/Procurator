#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence, Tuple

_REPO_ROOT = Path(__file__).resolve().parents[5]
if str(_REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT))

from dslc.analysis.wraparound_candidates import WraparoundCandidate, infer_wraparound_candidates
from dslc.compiler import compile_spec_file
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_file, unroll_mainprocedure_loop_file


@dataclass(frozen=True)
class _Paths:
    base_bpl: Path
    entry_check_bpl: Path
    closure_check_bpl: Path
    pump_bpl: Path
    accel_bpl: Path
    accel_probe_bpl: Path
    confirm_bpl: Path
    entry_check_log: Path
    closure_check_log: Path
    pump_log: Path
    accel_log: Path
    accel_probe_log: Path
    confirm_log: Path
    ultimate_home_root: Path


@dataclass(frozen=True)
class _UltimateRun:
    returncode: int
    elapsed_s: float
    result_line: Optional[str]


def _repo_root() -> Path:
    here = Path(__file__).resolve()
    return here.parents[5]


def _default_paths(spec_path: Path) -> _Paths:
    root = _repo_root()
    stem = spec_path.stem
    out_dir = root / ".tmp" / "dslc"
    out_dir.mkdir(parents=True, exist_ok=True)
    base = out_dir / f"{stem}.bpl"
    entry_check = out_dir / f"{stem}.entry_check.bpl"
    closure_check = out_dir / f"{stem}.closure_check.bpl"
    pump = out_dir / f"{stem}.pump.bpl"
    accel = out_dir / f"{stem}.accel.bpl"
    accel_probe = out_dir / f"{stem}.accel_probe.bpl"
    confirm = out_dir / f"{stem}.confirm.bpl"
    entry_check_log = out_dir / f"{stem}.entry_check.gemcutter.log"
    closure_check_log = out_dir / f"{stem}.closure_check.gemcutter.log"
    pump_log = out_dir / f"{stem}.pump.gemcutter.log"
    accel_log = out_dir / f"{stem}.accel.gemcutter.log"
    accel_probe_log = out_dir / f"{stem}.accel_probe.gemcutter.log"
    confirm_log = out_dir / f"{stem}.confirm.gemcutter.log"
    ultimate_home_root = root / ".tmp" / "ultimate-home-wraparound" / stem
    return _Paths(
        base_bpl=base,
        entry_check_bpl=entry_check,
        closure_check_bpl=closure_check,
        pump_bpl=pump,
        accel_bpl=accel,
        accel_probe_bpl=accel_probe,
        confirm_bpl=confirm,
        entry_check_log=entry_check_log,
        closure_check_log=closure_check_log,
        pump_log=pump_log,
        accel_log=accel_log,
        accel_probe_log=accel_probe_log,
        confirm_log=confirm_log,
        ultimate_home_root=ultimate_home_root,
    )


def _paths_for_base_bpl(spec_path: Path, base_bpl: Path) -> _Paths:
    root = _repo_root()
    stem = base_bpl.stem
    out_dir = base_bpl.parent
    entry_check = out_dir / f"{stem}.entry_check.bpl"
    closure_check = out_dir / f"{stem}.closure_check.bpl"
    pump = out_dir / f"{stem}.pump.bpl"
    accel = out_dir / f"{stem}.accel.bpl"
    accel_probe = out_dir / f"{stem}.accel_probe.bpl"
    confirm = out_dir / f"{stem}.confirm.bpl"
    entry_check_log = out_dir / f"{stem}.entry_check.gemcutter.log"
    closure_check_log = out_dir / f"{stem}.closure_check.gemcutter.log"
    pump_log = out_dir / f"{stem}.pump.gemcutter.log"
    accel_log = out_dir / f"{stem}.accel.gemcutter.log"
    accel_probe_log = out_dir / f"{stem}.accel_probe.gemcutter.log"
    confirm_log = out_dir / f"{stem}.confirm.gemcutter.log"
    ultimate_home_root = root / ".tmp" / "ultimate-home-wraparound" / stem
    return _Paths(
        base_bpl=base_bpl,
        entry_check_bpl=entry_check,
        closure_check_bpl=closure_check,
        pump_bpl=pump,
        accel_bpl=accel,
        accel_probe_bpl=accel_probe,
        confirm_bpl=confirm,
        entry_check_log=entry_check_log,
        closure_check_log=closure_check_log,
        pump_log=pump_log,
        accel_log=accel_log,
        accel_probe_log=accel_probe_log,
        confirm_log=confirm_log,
        ultimate_home_root=ultimate_home_root,
    )


def _sanitize_tag(tag: str) -> str:
    tag = tag.strip()
    if not tag:
        return "cand"
    return re.sub(r"[^A-Za-z0-9_]+", "_", tag)


def _paths_for_candidate(base: _Paths, tag: str) -> _Paths:
    """
    Derive per-candidate output paths while reusing the same base .bpl.
    """

    tag = _sanitize_tag(tag)
    stem = base.base_bpl.stem
    out_dir = base.base_bpl.parent
    cand_stem = f"{stem}.{tag}"

    ultimate_home_root = base.ultimate_home_root.parent / cand_stem

    return _Paths(
        base_bpl=base.base_bpl,
        entry_check_bpl=out_dir / f"{cand_stem}.entry_check.bpl",
        closure_check_bpl=out_dir / f"{cand_stem}.closure_check.bpl",
        pump_bpl=out_dir / f"{cand_stem}.pump.bpl",
        accel_bpl=out_dir / f"{cand_stem}.accel.bpl",
        accel_probe_bpl=out_dir / f"{cand_stem}.accel_probe.bpl",
        confirm_bpl=out_dir / f"{cand_stem}.confirm.bpl",
        entry_check_log=out_dir / f"{cand_stem}.entry_check.gemcutter.log",
        closure_check_log=out_dir / f"{cand_stem}.closure_check.gemcutter.log",
        pump_log=out_dir / f"{cand_stem}.pump.gemcutter.log",
        accel_log=out_dir / f"{cand_stem}.accel.gemcutter.log",
        accel_probe_log=out_dir / f"{cand_stem}.accel_probe.gemcutter.log",
        confirm_log=out_dir / f"{cand_stem}.confirm.gemcutter.log",
        ultimate_home_root=ultimate_home_root,
    )

def _candidate_tag(cand: WraparoundCandidate) -> str:
    parts = [cand.pump_reg]
    if cand.index_value is not None:
        parts.append(f"idx{cand.index_value}")
    elif cand.index_expr is not None:
        parts.append("idxexpr")
    parts.append(cand.reason)
    return ".".join(parts)


def _run_ultimate(
    *,
    ultimate: Path,
    toolchain: Path,
    settings: Path,
    bpl: Path,
    log_path: Path,
    ultimate_home: Path,
    timeout_seconds: int,
) -> _UltimateRun:
    cmd = [
        str(ultimate),
        f"--core.toolchain.timeout.in.seconds={timeout_seconds}",
        "-tc",
        str(toolchain),
        "-s",
        str(settings),
        "-i",
        str(bpl),
    ]
    print("[RUN] " + " ".join(cmd))
    ultimate_home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HOME"] = str(ultimate_home)
    env["JAVA_TOOL_OPTIONS"] = f"-Duser.home={ultimate_home}"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    start = time.time()
    result_line: Optional[str] = None
    with log_path.open("w", encoding="utf-8") as logf:
        logf.write("[RUN] " + " ".join(cmd) + "\n")
        logf.flush()
        proc = subprocess.Popen(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            env=env,
            bufsize=1,
        )
        assert proc.stdout is not None
        for line in proc.stdout:
            logf.write(line)
            logf.flush()
            if line.startswith("RESULT:"):
                result_line = line.strip()
        returncode = proc.wait()

        elapsed_s = time.time() - start
        logf.write(f"\n[EXIT] returncode={returncode} elapsed_s={elapsed_s:.1f}\n")
        logf.flush()

    print(f"[LOG] {log_path}")
    return _UltimateRun(returncode=returncode, elapsed_s=elapsed_s, result_line=result_line)


def _classify_ultimate_result(result_line: Optional[str]) -> str:
    if not result_line:
        return "unknown"
    low = result_line.lower()
    if "incorrect syntax" in low or "syntax error" in low:
        return "error"
    if "incorrect" in low:
        return "incorrect"
    if "correct" in low:
        return "correct"
    if "unknown" in low:
        return "unknown"
    return "unknown"


def _read_last_result_line(log_path: Path) -> Optional[str]:
    if not log_path.exists():
        return None
    for ln in reversed(log_path.read_text(encoding="utf-8", errors="replace").splitlines()):
        if ln.startswith("RESULT:"):
            return ln.strip()
    return None


def _parse_unroll_map(spec: str) -> dict[str, int]:
    if not spec:
        return {}
    spec = spec.strip()
    if not spec:
        return {}

    if spec.isdigit():
        v = int(spec)
        return {"pump": v, "accel": v, "accel_probe": v, "confirm": v}

    out: dict[str, int] = {}
    for item in spec.split(","):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            raise SystemExit(f"[ERR] --unroll expects N or stage=N,...; got: {spec}")
        stage, val = item.split("=", 1)
        stage = stage.strip().lower()
        if stage not in {"pump", "accel", "accel_probe", "confirm"}:
            raise SystemExit(f"[ERR] unknown unroll stage '{stage}' in --unroll: {spec}")
        if not val.strip().isdigit():
            raise SystemExit(f"[ERR] invalid unroll value for '{stage}': {val}")
        out[stage] = int(val)
    return out


def _with_unroll_suffix(path: Path, steps: int) -> Path:
    return path.with_name(f"{path.stem}.unroll{steps}{path.suffix}")


def _witness_path_for_input(bpl: Path) -> Path:
    # The WitnessPrinter is configured to write besides the input file, with the
    # default naming scheme `<input>.bpl-witness.graphml`.
    return bpl.with_name(bpl.name + "-witness.graphml")


def _should_skip_stage(*, bpl: Path, outputs: Sequence[Path], rerun: bool) -> bool:
    if rerun:
        return False
    try:
        bpl_mtime = bpl.stat().st_mtime
    except FileNotFoundError:
        return False
    for out in outputs:
        try:
            if out.exists() and out.stat().st_mtime >= bpl_mtime:
                return True
        except FileNotFoundError:
            continue
    return False


def _with_log_unroll_suffix(path: Path, steps: int) -> Path:
    name = path.name
    if name.endswith(".gemcutter.log"):
        name = name[: -len(".gemcutter.log")] + f".unroll{steps}.gemcutter.log"
    else:
        name = f"{name}.unroll{steps}"
    return path.with_name(name)


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Wrap-around pipeline runner (entry_check / closure_check / confirm)")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument(
        "--base-bpl",
        default="",
        help="Path to an existing sequential .bpl (skip DSL->Boogie compilation; still uses the .prop to infer targets).",
    )
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary")
    ap.add_argument("--work-dir", default="", help="Work directory for P4B outputs")
    ap.add_argument(
        "--env",
        choices=["spec", "max"],
        default="spec",
        help="Environment model: 'spec' applies assume constraints, 'max' makes inputs fully nondet",
    )
    ap.add_argument("--no-prune", action="store_true", help="Disable DAG-based slicing and env-input pruning")
    ap.add_argument("--por", action="store_true", help="Enable commutativity-based POR (normal model only)")
    ap.add_argument(
        "--boogie-harness",
        choices=["sequential", "concurrent"],
        default="sequential",
        help="Use sequential harness (recommended for pump/accel) or concurrent harness.",
    )
    ap.add_argument("--no-two-stage", action="store_true", help="Disable two-stage ingress/egress scheduling")

    ap.add_argument("--ultimate", default="", help="Path to Ultimate CLI executable")
    ap.add_argument(
        "--ultimate-timeout-seconds",
        type=int,
        default=0,
        help="Ultimate toolchain timeout in seconds (0 disables timeout).",
    )
    ap.add_argument(
        "--toolchain",
        default="",
        help="Ultimate toolchain XML (default: Procurator spec/config/ReachSafety-Witness.xml)",
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Ultimate settings EPF (default: Procurator spec/config/ReachSafety-32bit-GemCutter-ALL-witness.epf)",
    )
    ap.add_argument(
        "--entry-check-toolchain",
        default="",
        help="Override toolchain XML for stage 'entry_check' (recommended: non-witness toolchain).",
    )
    ap.add_argument(
        "--entry-check-settings",
        default="",
        help="Override settings EPF for stage 'entry_check' (recommended: non-witness settings).",
    )
    ap.add_argument("--pump-toolchain", default="", help="Override toolchain XML for stage 'pump'")
    ap.add_argument("--pump-settings", default="", help="Override settings EPF for stage 'pump'")
    ap.add_argument("--accel-toolchain", default="", help="Override toolchain XML for stage 'accel'")
    ap.add_argument("--accel-settings", default="", help="Override settings EPF for stage 'accel'")
    ap.add_argument("--accel-probe-toolchain", default="", help="Override toolchain XML for stage 'accel_probe'")
    ap.add_argument("--accel-probe-settings", default="", help="Override settings EPF for stage 'accel_probe'")
    ap.add_argument("--confirm-toolchain", default="", help="Override toolchain XML for stage 'confirm'")
    ap.add_argument("--confirm-settings", default="", help="Override settings EPF for stage 'confirm'")
    ap.add_argument(
        "--closure-check-toolchain",
        default="",
        help="Override toolchain XML for stage 'closure_check' (proof task).",
    )
    ap.add_argument(
        "--closure-check-settings",
        default="",
        help="Override settings EPF for stage 'closure_check' (proof task).",
    )
    ap.add_argument(
        "--certify-unsafe",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="When enabled, require entry_check=incorrect and closure_check=correct before running accel/confirm (certified UNSAFE).",
    )
    ap.add_argument(
        "--stages",
        default="entry_check,closure_check,confirm",
        help="Comma-separated stages to run: entry_check,closure_check,pump,accel,accel_probe,confirm (default: entry_check,closure_check,confirm).",
    )
    ap.add_argument(
        "--unroll",
        default="",
        help="Unroll mainProcedure loop for selected stages: N or stage=N,stage=N (e.g. pump=10,confirm=3).",
    )
    ap.add_argument(
        "--rerun",
        action="store_true",
        help="Do not reuse existing outputs; rerun Ultimate even if logs/witnesses already exist.",
    )

    args = ap.parse_args(list(argv) if argv is not None else None)

    stages = {s.strip().lower() for s in str(args.stages).split(",") if s.strip()}

    if args.certify_unsafe and ("accel" in stages or "confirm" in stages):
        needed = {"entry_check", "closure_check"}
        missing = needed - stages
        if missing:
            print(f"[NOTE] --certify-unsafe enabled; adding prerequisite stages: {', '.join(sorted(missing))}")
        stages |= needed

    allowed_stages = {"entry_check", "closure_check", "pump", "accel", "accel_probe", "confirm"}
    unknown = sorted(stages - allowed_stages)
    if unknown:
        raise SystemExit(f"[ERR] unknown stage(s) in --stages: {', '.join(unknown)}")

    spec_path = Path(args.spec).resolve()
    if not spec_path.exists():
        raise SystemExit(f"[ERR] spec not found: {spec_path}")
    spec_text = spec_path.read_text(encoding="utf-8")

    root = _repo_root()
    if args.base_bpl:
        base_bpl = Path(args.base_bpl).resolve()
        if not base_bpl.exists():
            raise SystemExit(f"[ERR] base .bpl not found: {base_bpl}")
        if base_bpl.suffix != ".bpl":
            raise SystemExit(f"[ERR] base .bpl must end with .bpl, got: {base_bpl}")
        paths = _paths_for_base_bpl(spec_path, base_bpl)
    else:
        paths = _default_paths(spec_path)

    default_reach_toolchain = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml"
    default_reach_settings = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    )
    default_closure_toolchain = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ClosureCheck-ReachSafety.xml"
    default_closure_settings = (
        root
        / "Procurator"
        / "argo"
        / "code"
        / "spec"
        / "config"
        / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf"
    )

    toolchain = Path(args.toolchain).resolve() if args.toolchain else default_reach_toolchain
    settings = Path(args.settings).resolve() if args.settings else default_reach_settings

    stage_toolchains = {
        "entry_check": Path(args.entry_check_toolchain).resolve()
        if args.entry_check_toolchain
        else default_closure_toolchain,
        "closure_check": Path(args.closure_check_toolchain).resolve()
        if args.closure_check_toolchain
        else default_closure_toolchain,
        "pump": Path(args.pump_toolchain).resolve() if args.pump_toolchain else toolchain,
        "accel": Path(args.accel_toolchain).resolve() if args.accel_toolchain else toolchain,
        "accel_probe": Path(args.accel_probe_toolchain).resolve() if args.accel_probe_toolchain else toolchain,
        "confirm": Path(args.confirm_toolchain).resolve() if args.confirm_toolchain else toolchain,
    }
    stage_settings = {
        "entry_check": Path(args.entry_check_settings).resolve()
        if args.entry_check_settings
        else default_reach_settings,
        "closure_check": Path(args.closure_check_settings).resolve()
        if args.closure_check_settings
        else default_closure_settings,
        "pump": Path(args.pump_settings).resolve() if args.pump_settings else settings,
        "accel": Path(args.accel_settings).resolve() if args.accel_settings else settings,
        "accel_probe": Path(args.accel_probe_settings).resolve() if args.accel_probe_settings else settings,
        "confirm": Path(args.confirm_settings).resolve() if args.confirm_settings else settings,
    }

    ultimate = Path(args.ultimate).resolve() if args.ultimate else None
    if ultimate and not ultimate.exists():
        raise SystemExit(f"[ERR] Ultimate executable not found: {ultimate}")
    for stage in stages:
        tc = stage_toolchains[stage]
        st = stage_settings[stage]
        if not tc.exists():
            raise SystemExit(f"[ERR] Toolchain not found for stage '{stage}': {tc}")
        if not st.exists():
            raise SystemExit(f"[ERR] Settings not found for stage '{stage}': {st}")

    max_env_inputs = args.env == "max"
    prune = not args.no_prune
    enable_slicing = prune
    prune_env_inputs = prune
    por_enabled = args.por
    pipeline_two_stage = not args.no_two_stage

    p4b_bin = Path(args.p4b_bin).resolve() if args.p4b_bin else (root / "dslc" / "toolchain" / "p4b_docker.sh")
    work_dir = Path(args.work_dir).resolve() if args.work_dir else None

    # 1) Compile base model once (faithful semantics), unless a pre-generated .bpl was provided.
    if args.base_bpl:
        print(f"[OK] base bpl (provided): {paths.base_bpl}")
    else:
        compile_spec_file(
            spec_path=spec_path,
            backend="boogie",
            out=paths.base_bpl,
            p4b_bin=p4b_bin,
            work_dir=work_dir,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            por_enabled=por_enabled,
            por_guard_enabled=True,
            boogie_harness=args.boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
        )
        print(f"[OK] base bpl: {paths.base_bpl}")

    base_bpl_text = paths.base_bpl.read_text(encoding="utf-8", errors="replace")

    # 2) Infer wraparound candidates from (spec + compiled Boogie + P4B meta).
    meta_by_node = {}
    meta_dir = Path(str(paths.base_bpl) + ".work")
    if meta_dir.is_dir():
        for mp in sorted(meta_dir.glob("*.meta.json")):
            key = mp.name
            if key.endswith(".meta.json"):
                key = key[: -len(".meta.json")]
            try:
                meta_by_node[key] = json.loads(mp.read_text(encoding="utf-8"))
            except Exception:
                continue
    candidates = infer_wraparound_candidates(spec_text=spec_text, bpl_text=base_bpl_text, meta_by_node=meta_by_node)
    if not candidates:
        raise SystemExit(
            "[ERR] no wraparound candidates inferred.\n"
            "      - NetChain-style: global assert should reference reg[i].\n"
            "      - DistCache-style: global assert should reference a var that is written by a monotonic register update."
        )
    print(f"[WRAP] candidates={len(candidates)}")
    for i, cand in enumerate(candidates):
        idx_desc = str(cand.index_value) if cand.index_value is not None else (cand.index_expr or "?")
        step_desc = f"{cand.step_op}{cand.step_delta}" if cand.step_delta is not None else f"{cand.step_op}(unknown)"
        print(
            f"  - cand[{i}] reason={cand.reason} pump_reg={cand.pump_reg} idx={idx_desc} accel_regs={list(cand.accel_regs)} step={step_desc}"
        )

    unroll_map = _parse_unroll_map(args.unroll)

    # 3) Emit variants.
    entry_status: Optional[str] = None
    if "entry_check" in stages:
        seed = candidates[0]
        instrument_bpl_file(
            in_path=paths.base_bpl,
            out_path=paths.entry_check_bpl,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=seed.pump_reg,
            accel_regs=seed.accel_regs,
            index_value=seed.index_value or 0,
            index_expr=seed.index_expr,
            proj_vars=seed.proj_vars or None,
            cutpoint_cond=seed.cutpoint_cond,
            step_op=seed.step_op,
            step_delta=seed.step_delta or 1,
        )
        entry_check_bpl = paths.entry_check_bpl
        entry_check_log = paths.entry_check_log
        entry_check_home = paths.ultimate_home_root / "entry_check"
        print(f"[OK] entry_check bpl: {entry_check_bpl}")

    # 4) Run Ultimate (optional).
    if not ultimate:
        print("[NOTE] --ultimate not provided; only emitting instrumented .bpl files (skipping Ultimate run).")

    if ultimate and "entry_check" in stages:
        entry_outputs = [entry_check_log]
        if _should_skip_stage(bpl=entry_check_bpl, outputs=entry_outputs, rerun=args.rerun):
            entry_status = _classify_ultimate_result(_read_last_result_line(entry_check_log))
            print(f"[RES] entry_check (cached): {entry_status}")
        else:
            res = _run_ultimate(
                ultimate=ultimate,
                toolchain=stage_toolchains["entry_check"],
                settings=stage_settings["entry_check"],
                bpl=entry_check_bpl,
                log_path=entry_check_log,
                ultimate_home=entry_check_home,
                timeout_seconds=args.ultimate_timeout_seconds,
            )
            entry_status = _classify_ultimate_result(res.result_line)
            print(f"[RES] entry_check: {entry_status} ({res.elapsed_s:.1f}s)")
        if entry_status == "error":
            raise SystemExit(f"[ERR] entry_check failed (syntax error). See: {entry_check_log}")

    if ultimate and args.certify_unsafe and ("accel" in stages or "confirm" in stages):
        if entry_status is None:
            raise SystemExit("[ERR] internal: entry_check status missing under --certify-unsafe")
        if entry_status != "incorrect":
            raise SystemExit(f"[ERR] entry_check is {entry_status}; base model seems infeasible (check env/table entries).")

    for cand in candidates:
        tag = _candidate_tag(cand)
        cand_paths = _paths_for_candidate(paths, tag)
        idx_value = cand.index_value or 0
        proj_vars = cand.proj_vars or None

        print(f"\n[WRAP] candidate: {tag}")

        closure_status: Optional[str] = None

        if "closure_check" in stages:
            instrument_bpl_file(
                in_path=paths.base_bpl,
                out_path=cand_paths.closure_check_bpl,
                stage=WraparoundStage.CLOSURE_CHECK,
                pump_reg=cand.pump_reg,
                accel_regs=cand.accel_regs,
                index_value=idx_value,
                index_expr=cand.index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cand.cutpoint_cond,
                step_op=cand.step_op,
                step_delta=cand.step_delta or 1,
            )
            closure_check_bpl = cand_paths.closure_check_bpl
            closure_check_log = cand_paths.closure_check_log
            closure_check_home = cand_paths.ultimate_home_root / "closure_check"
            print(f"[OK] closure_check bpl: {closure_check_bpl}")

            if ultimate:
                closure_outputs = [closure_check_log]
                if _should_skip_stage(bpl=closure_check_bpl, outputs=closure_outputs, rerun=args.rerun):
                    closure_status = _classify_ultimate_result(_read_last_result_line(closure_check_log))
                    print(f"[RES] closure_check (cached): {closure_status}")
                else:
                    res = _run_ultimate(
                        ultimate=ultimate,
                        toolchain=stage_toolchains["closure_check"],
                        settings=stage_settings["closure_check"],
                        bpl=closure_check_bpl,
                        log_path=closure_check_log,
                        ultimate_home=closure_check_home,
                        timeout_seconds=args.ultimate_timeout_seconds,
                    )
                    closure_status = _classify_ultimate_result(res.result_line)
                    print(f"[RES] closure_check: {closure_status} ({res.elapsed_s:.1f}s)")
                if closure_status == "error":
                    raise SystemExit(f"[ERR] closure_check failed (syntax error). See: {closure_check_log}")

        if ultimate and args.certify_unsafe and ("accel" in stages or "confirm" in stages):
            if closure_status != "correct":
                print(f"[SKIP] closure_check is {closure_status}; refusing to run accel/confirm under --certify-unsafe")
                continue

        if "pump" in stages:
            instrument_bpl_file(
                in_path=paths.base_bpl,
                out_path=cand_paths.pump_bpl,
                stage=WraparoundStage.PUMP,
                pump_reg=cand.pump_reg,
                accel_regs=cand.accel_regs,
                index_value=idx_value,
                index_expr=cand.index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cand.cutpoint_cond,
                step_op=cand.step_op,
                step_delta=cand.step_delta or 1,
            )
            pump_bpl = cand_paths.pump_bpl
            pump_log = cand_paths.pump_log
            pump_home = cand_paths.ultimate_home_root / "pump"
            if unroll_map.get("pump", 0) > 0:
                steps = unroll_map["pump"]
                pump_bpl_unroll = _with_unroll_suffix(pump_bpl, steps)
                unroll_mainprocedure_loop_file(in_path=pump_bpl, out_path=pump_bpl_unroll, steps=steps)
                pump_bpl = pump_bpl_unroll
                pump_log = _with_log_unroll_suffix(pump_log, steps)
                pump_home = cand_paths.ultimate_home_root / f"pump-unroll{steps}"
            print(f"[OK] pump bpl: {pump_bpl}")

            if ultimate:
                pump_outputs = [pump_log, _witness_path_for_input(pump_bpl)]
                if _should_skip_stage(bpl=pump_bpl, outputs=pump_outputs, rerun=args.rerun):
                    print(f"[SKIP] pump outputs up-to-date: {pump_bpl}")
                else:
                    res = _run_ultimate(
                        ultimate=ultimate,
                        toolchain=stage_toolchains["pump"],
                        settings=stage_settings["pump"],
                        bpl=pump_bpl,
                        log_path=pump_log,
                        ultimate_home=pump_home,
                        timeout_seconds=args.ultimate_timeout_seconds,
                    )
                    print(f"[RES] pump: {_classify_ultimate_result(res.result_line)} ({res.elapsed_s:.1f}s)")

        if "accel_probe" in stages:
            instrument_bpl_file(
                in_path=paths.base_bpl,
                out_path=cand_paths.accel_probe_bpl,
                stage=WraparoundStage.ACCEL_PROBE,
                pump_reg=cand.pump_reg,
                accel_regs=cand.accel_regs,
                index_value=idx_value,
                index_expr=cand.index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cand.cutpoint_cond,
                step_op=cand.step_op,
                step_delta=cand.step_delta or 1,
            )
            accel_probe_bpl = cand_paths.accel_probe_bpl
            accel_probe_log = cand_paths.accel_probe_log
            accel_probe_home = cand_paths.ultimate_home_root / "accel_probe"
            if unroll_map.get("accel_probe", 0) > 0:
                steps = unroll_map["accel_probe"]
                accel_probe_bpl_unroll = _with_unroll_suffix(accel_probe_bpl, steps)
                unroll_mainprocedure_loop_file(in_path=accel_probe_bpl, out_path=accel_probe_bpl_unroll, steps=steps)
                accel_probe_bpl = accel_probe_bpl_unroll
                accel_probe_log = _with_log_unroll_suffix(accel_probe_log, steps)
                accel_probe_home = cand_paths.ultimate_home_root / f"accel_probe-unroll{steps}"
            print(f"[OK] accel_probe bpl: {accel_probe_bpl}")

            if ultimate:
                accel_probe_outputs = [accel_probe_log, _witness_path_for_input(accel_probe_bpl)]
                if _should_skip_stage(bpl=accel_probe_bpl, outputs=accel_probe_outputs, rerun=args.rerun):
                    print(f"[SKIP] accel_probe outputs up-to-date: {accel_probe_bpl}")
                else:
                    res = _run_ultimate(
                        ultimate=ultimate,
                        toolchain=stage_toolchains["accel_probe"],
                        settings=stage_settings["accel_probe"],
                        bpl=accel_probe_bpl,
                        log_path=accel_probe_log,
                        ultimate_home=accel_probe_home,
                        timeout_seconds=args.ultimate_timeout_seconds,
                    )
                    print(f"[RES] accel_probe: {_classify_ultimate_result(res.result_line)} ({res.elapsed_s:.1f}s)")

        if "accel" in stages:
            instrument_bpl_file(
                in_path=paths.base_bpl,
                out_path=cand_paths.accel_bpl,
                stage=WraparoundStage.ACCEL,
                pump_reg=cand.pump_reg,
                accel_regs=cand.accel_regs,
                index_value=idx_value,
                index_expr=cand.index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cand.cutpoint_cond,
                step_op=cand.step_op,
                step_delta=cand.step_delta or 1,
            )
            accel_bpl = cand_paths.accel_bpl
            accel_log = cand_paths.accel_log
            accel_home = cand_paths.ultimate_home_root / "accel"
            if unroll_map.get("accel", 0) > 0:
                steps = unroll_map["accel"]
                accel_bpl_unroll = _with_unroll_suffix(accel_bpl, steps)
                unroll_mainprocedure_loop_file(in_path=accel_bpl, out_path=accel_bpl_unroll, steps=steps)
                accel_bpl = accel_bpl_unroll
                accel_log = _with_log_unroll_suffix(accel_log, steps)
                accel_home = cand_paths.ultimate_home_root / f"accel-unroll{steps}"
            print(f"[OK] accel bpl: {accel_bpl}")

            if ultimate:
                accel_outputs = [accel_log, _witness_path_for_input(accel_bpl)]
                if _should_skip_stage(bpl=accel_bpl, outputs=accel_outputs, rerun=args.rerun):
                    print(f"[SKIP] accel outputs up-to-date: {accel_bpl}")
                else:
                    res = _run_ultimate(
                        ultimate=ultimate,
                        toolchain=stage_toolchains["accel"],
                        settings=stage_settings["accel"],
                        bpl=accel_bpl,
                        log_path=accel_log,
                        ultimate_home=accel_home,
                        timeout_seconds=args.ultimate_timeout_seconds,
                    )
                    print(f"[RES] accel: {_classify_ultimate_result(res.result_line)} ({res.elapsed_s:.1f}s)")

        if "confirm" in stages:
            instrument_bpl_file(
                in_path=paths.base_bpl,
                out_path=cand_paths.confirm_bpl,
                stage=WraparoundStage.CONFIRM,
                pump_reg=cand.pump_reg,
                accel_regs=cand.accel_regs,
                index_value=idx_value,
                index_expr=cand.index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cand.cutpoint_cond,
                step_op=cand.step_op,
                step_delta=cand.step_delta or 1,
            )
            confirm_bpl = cand_paths.confirm_bpl
            confirm_log = cand_paths.confirm_log
            confirm_home = cand_paths.ultimate_home_root / "confirm"
            if unroll_map.get("confirm", 0) > 0:
                steps = unroll_map["confirm"]
                confirm_bpl_unroll = _with_unroll_suffix(confirm_bpl, steps)
                unroll_mainprocedure_loop_file(in_path=confirm_bpl, out_path=confirm_bpl_unroll, steps=steps)
                confirm_bpl = confirm_bpl_unroll
                confirm_log = _with_log_unroll_suffix(confirm_log, steps)
                confirm_home = cand_paths.ultimate_home_root / f"confirm-unroll{steps}"
            print(f"[OK] confirm bpl: {confirm_bpl}")

            if ultimate:
                confirm_outputs = [confirm_log, _witness_path_for_input(confirm_bpl)]
                if _should_skip_stage(bpl=confirm_bpl, outputs=confirm_outputs, rerun=args.rerun):
                    confirm_status = _classify_ultimate_result(_read_last_result_line(confirm_log))
                    print(f"[RES] confirm (cached): {confirm_status}")
                else:
                    res = _run_ultimate(
                        ultimate=ultimate,
                        toolchain=stage_toolchains["confirm"],
                        settings=stage_settings["confirm"],
                        bpl=confirm_bpl,
                        log_path=confirm_log,
                        ultimate_home=confirm_home,
                        timeout_seconds=args.ultimate_timeout_seconds,
                    )
                    confirm_status = _classify_ultimate_result(res.result_line)
                    print(f"[RES] confirm: {confirm_status} ({res.elapsed_s:.1f}s)")
                if confirm_status == "error":
                    raise SystemExit(f"[ERR] confirm failed (syntax error). See: {confirm_log}")

                if confirm_status == "incorrect":
                    if args.certify_unsafe:
                        print(
                            "[CERT] UNSAFE (certified): entry_check=incorrect, closure_check=correct, confirm=incorrect"
                        )
                        return 0
                    print("[WARN] UNSAFE (uncertified): run with --certify-unsafe for a soundness gate")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
