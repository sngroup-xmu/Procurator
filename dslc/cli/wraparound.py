from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Sequence

from dslc.cli.common import find_default_p4b_bin, fresh_run_dir, wrap_resource_limits
from dslc.compiler import compile_spec_file
from dslc.analysis.wraparound_candidates import WraparoundCandidate, infer_wraparound_candidates
from dslc.transform.wraparound import (
    WraparoundStage,
    instrument_bpl_text,
    unroll_mainprocedure_loop_text,
)
from dslc.utils.repo import repo_root


@dataclass(frozen=True)
class _Stage:
    name: str
    bpl_path: Path
    log_path: Path


def _default_out_dir() -> Path:
    # Kept for backward compatibility (tests/old docs); prefer per-run dirs in `main()`.
    out = repo_root() / ".tmp" / "procurator"
    out.mkdir(parents=True, exist_ok=True)
    return out


def _extract_result_line(log_text: str) -> Optional[str]:
    for line in log_text.splitlines():
        if "RESULT:" in line:
            return line.strip()
    return None


def _result_is_safe(res_line: str) -> bool:
    res = res_line.strip()
    return ("RESULT: SAFE" in res) or ("proved your program to be correct" in res)


def _infer_regs_from_asserts(spec_text: str) -> tuple[list[str], int]:
    # Heuristic: extract array-like references from `assert { ... }` blocks.
    assert_blocks = re.findall(r"assert\s*\{([\s\S]*?)\};", spec_text)
    for blk in assert_blocks:
        hits = re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)\[(\d+)\]", blk)
        if not hits:
            continue
        regs: list[str] = []
        idxs: list[int] = []
        for r, i in hits:
            regs.append(r)
            idxs.append(int(i))
        idx0 = idxs[0]
        if any(i != idx0 for i in idxs):
            raise ValueError(f"multiple indices in assert blocks: {sorted(set(idxs))}; pass --index explicitly")
        seen = set()
        uniq: list[str] = []
        for r in regs:
            if r not in seen:
                seen.add(r)
                uniq.append(r)
        return uniq, idx0
    raise ValueError("failed to infer target register(s) from assert blocks; pass --pump-reg/--accel-regs/--index")


def _extract_registers_from_bpl(bpl_text: str) -> set[str]:
    # P4B emits register arrays with methods `<reg>.read`/`<reg>.write`.
    return set(re.findall(r"^procedure\b.*\b([A-Za-z_][A-Za-z0-9_]*)\.write\s*\(", bpl_text, flags=re.MULTILINE))


def _resolve_register_name(reg: str, available: set[str]) -> str:
    # Some older .prop specs refer to `<name>_0` while P4B emits `<name>`.
    if reg in available:
        return reg
    if reg.endswith("_0") and reg[:-2] in available:
        return reg[:-2]
    return reg


def _load_meta_by_node(work_dir: Path) -> dict[str, dict]:
    """
    Load per-node P4B meta JSONs produced during compile into {node_alias: meta_obj}.

    boogie.py writes meta to `<work_dir>/<alias>.meta.json`.
    """

    out: dict[str, dict] = {}
    if not work_dir.exists():
        return out
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            out[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue
    return out


def _wrap_resource_limits(cmd: list[str], *, enable: bool, os_timeout_s: int) -> list[str]:
    # Backward-compat shim; use `dslc.cli.common.wrap_resource_limits`.
    return wrap_resource_limits(cmd, enable=enable, os_timeout_s=os_timeout_s)


def _resolve_default_toolchains(
    *,
    root: Path,
    toolchain_arg: str,
    closure_toolchain_arg: str,
) -> tuple[Path, Path]:
    """
    Resolve toolchains for wraparound runs.

    - `toolchain` is used for pump/accel/confirm.
    - `closure_toolchain` is used for closure_check only.

    Rationale: Ultimate's witness printer has been observed to crash on some
    SAFE closure_check tasks (NullPointerException). We therefore default to
    a toolchain without the witness printer plugin for closure_check.
    """

    toolchain = (
        Path(toolchain_arg).expanduser().resolve()
        if toolchain_arg
        else (
            (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml").resolve()
            if (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml").exists()
            else (root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml").resolve()
        )
    )

    closure_toolchain = (
        Path(closure_toolchain_arg).expanduser().resolve()
        if closure_toolchain_arg
        else (
            (root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-ReachSafety.xml").resolve()
            if (root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-ReachSafety.xml").exists()
            else toolchain
        )
    )

    return toolchain, closure_toolchain


def _run_ultimate(
    *,
    ultimate: Path,
    toolchain: Path,
    settings: Path,
    input_bpl: Path,
    log_path: Path,
    ultimate_home: Path,
    timeout_seconds: int,
    resource_limits: bool,
) -> int:
    cmd = [
        str(ultimate),
        f"--core.toolchain.timeout.in.seconds={timeout_seconds}",
        "-tc",
        str(toolchain),
        "-s",
        str(settings),
        "-i",
        str(input_bpl),
    ]
    os_timeout = timeout_seconds + 60 if timeout_seconds > 0 else 0
    cmd = _wrap_resource_limits(cmd, enable=resource_limits, os_timeout_s=os_timeout)

    print("[RUN] " + " ".join(cmd))
    ultimate_home.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env["HOME"] = str(ultimate_home)
    # Preserve caller-provided JAVA_TOOL_OPTIONS (e.g., -Xmx) and force a per-run user.home
    # to keep Ultimate caches/artifacts isolated and avoid confusing cross-run reuse.
    prev_java_opts = env.get("JAVA_TOOL_OPTIONS", "").strip()
    user_home_opt = f"-Duser.home={ultimate_home}"
    env["JAVA_TOOL_OPTIONS"] = f"{prev_java_opts} {user_home_opt}".strip()

    log_path.parent.mkdir(parents=True, exist_ok=True)
    with log_path.open("wb") as log_file:
        log_file.write(("[RUN] " + " ".join(cmd) + "\\n").encode("utf-8"))
        log_file.flush()
        proc = subprocess.run(
            cmd,
            stdout=log_file,
            stderr=subprocess.STDOUT,
            env=env,
            # Keep Ultimate side effects (witnesses, temp files) under the per-run output dir.
            cwd=str(log_path.parent),
        )

    txt = log_path.read_text(encoding="utf-8", errors="replace")
    res = _extract_result_line(txt)
    if res:
        print(f"[RESULT] {res}")
    else:
        print("[RESULT] No RESULT line found; check log.")
    print(f"[LOG] {log_path}")
    return proc.returncode


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Run wrap-around (closure_check/pump/accel/confirm) pipeline on a .prop spec")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument(
        "--tag",
        default="",
        help="Optional suffix to disambiguate outputs (appended to the spec stem).",
    )
    ap.add_argument(
        "--out-dir",
        default="",
        help=(
            "Output directory. If omitted, a fresh per-run directory is created under "
            "`.tmp/procurator/wraparound/<spec>/<run_id>/` (no cache by default)."
        ),
    )
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary")
    ap.add_argument("--ultimate", default="", help="Path to Ultimate CLI executable")
    ap.add_argument("--toolchain", default="", help="Ultimate toolchain XML (default: ReachSafety-Witness.xml)")
    ap.add_argument(
        "--closure-toolchain",
        default="",
        help=(
            "Ultimate toolchain XML for closure_check only "
            "(default: dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml if present; "
            "falls back to --toolchain)"
        ),
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Ultimate settings EPF (default: dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf)",
    )
    ap.add_argument(
        "--closure-settings",
        default="",
        help=(
            "Ultimate settings EPF for closure_check only "
            "(default: dslc/toolchain/ultimate/ClosureCheck-32bit-GemCutter-ALL-witness.epf; "
            "falls back to --settings if missing)"
        ),
    )
    ap.add_argument("--timeout-seconds", type=int, default=1200, help="Ultimate timeout per stage (default: 1200s)")
    ap.add_argument(
        "--stages",
        default="closure_check,pump,accel,confirm",
        help="Comma-separated stages: closure_check,pump,accel,confirm (default: closure_check,pump,accel,confirm)",
    )
    ap.add_argument("--pump-reg", default="", help="Boogie global register array variable to pump (e.g., s1_sequence_reg_0)")
    ap.add_argument(
        "--accel-regs",
        default="",
        help="Comma-separated Boogie registers to fast-forward to MAX (default: inferred from assert)",
    )
    ap.add_argument("--index", type=int, default=-1, help="Target index (default: inferred from assert)")
    ap.add_argument("--confirm-unroll", type=int, default=3, help="Unroll bound for confirm stage (default: 3)")
    ap.add_argument(
        "--pump-unroll",
        type=int,
        default=0,
        help="Optional unroll bound for pump stage mainProcedure loop (0 = keep loop)",
    )
    ap.add_argument(
        "--accel-unroll",
        type=int,
        default=0,
        help="Optional unroll bound for accel stage mainProcedure loop (0 = keep loop)",
    )
    ap.add_argument("--no-slicing", action="store_true", help="Disable P4 slicing/pruning in base compile")
    ap.add_argument(
        "--no-two-stage",
        action="store_true",
        help="Disable two-stage ingress/egress scheduling when compiling the base sequential harness",
    )
    ap.add_argument(
        "--drop-dsl-asserts",
        action="store_true",
        help="(Deprecated) No-op. The wraparound transform already strips unrelated asserts in pump/closure/entry tasks.",
    )
    ap.add_argument(
        "--allow-unsound-confirm",
        action="store_true",
        help="Allow running CONFIRM even if CLOSURE_CHECK did not prove SAFE (diagnostic only; UNSAFE may be unsound)",
    )
    ap.add_argument(
        "--no-resource-limits",
        action="store_true",
        help="Disable CPU/IO niceness limits when running Ultimate (may freeze WSL on heavy runs).",
    )

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec).expanduser()
    if not spec_path.is_absolute():
        spec_path = (Path.cwd() / spec_path).resolve()

    stem = spec_path.stem
    if args.tag:
        safe = re.sub(r"[^A-Za-z0-9_.-]", "_", args.tag.strip())
        if safe:
            stem = f"{stem}.{safe}"

    if args.out_dir:
        out_dir = Path(args.out_dir).expanduser().resolve()
        out_dir.mkdir(parents=True, exist_ok=True)
    else:
        out_dir = fresh_run_dir(category="wraparound", name=stem)

    base_bpl = out_dir / f"{stem}.base.bpl"
    work_dir = out_dir / "work"

    root = repo_root()
    p4b_bin: Optional[Path] = None
    if args.p4b_bin:
        p4b_bin = Path(args.p4b_bin).expanduser()
    else:
        p4b_bin = find_default_p4b_bin()
    if not p4b_bin:
        raise SystemExit(
            "missing --p4b-bin (and no default P4B translator found at "
            "`P4B-Translator/build-host/p4c-translator` or `dslc/toolchain/p4b_docker.sh`)"
        )

    # Compile base BPL (sequential harness; no trace arrays).
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=not args.no_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=not args.no_two_stage,
    )
    print(f"[OK] base bpl: {base_bpl}")

    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")
    meta_by_node = _load_meta_by_node(work_dir)

    cand: Optional[WraparoundCandidate] = None
    cands = infer_wraparound_candidates(spec_text=spec_text, bpl_text=base_text, meta_by_node=meta_by_node)
    if cands:
        cand = cands[0]
        if len(cands) > 1:
            print(f"[NOTE] multiple wraparound candidates inferred; using the first:\n  - " + "\n  - ".join(c.reason for c in cands))

    # Defaults from inference (preferred) or legacy assert-block heuristic.
    inferred_regs: list[str] = []
    inferred_idx: int = 0
    if cand is None:
        try:
            inferred_regs, inferred_idx = _infer_regs_from_asserts(spec_text)
        except Exception:
            inferred_regs, inferred_idx = [], 0

    pump_reg = args.pump_reg.strip() or (cand.pump_reg if cand else (inferred_regs[0] if inferred_regs else ""))
    if not pump_reg:
        raise SystemExit("failed to infer pump_reg; pass --pump-reg (or ensure global assert/meta exposes a counter)")

    index_expr = cand.index_expr if cand else None
    index_value = (
        args.index
        if args.index >= 0
        else (cand.index_value if cand and cand.index_value is not None else inferred_idx)
    )
    # If the user forces a concrete index, we treat it as authoritative.
    if args.index >= 0:
        index_expr = None

    step_op = cand.step_op if cand else "add"
    step_delta = int(cand.step_delta) if cand and cand.step_delta is not None else 1
    proj_vars = list(cand.proj_vars) if (cand and cand.proj_vars) else None
    cutpoint_cond = cand.cutpoint_cond if cand else None

    accel_regs: list[str]
    if args.accel_regs.strip():
        accel_regs = [x.strip() for x in args.accel_regs.split(",") if x.strip()]
    elif cand is not None and cand.accel_regs:
        accel_regs = list(cand.accel_regs)
    elif inferred_regs:
        accel_regs = list(inferred_regs)
    else:
        accel_regs = [pump_reg]

    stages = [s.strip() for s in args.stages.split(",") if s.strip()]
    if ("confirm" in stages) and ("closure_check" in stages) and (not args.allow_unsound_confirm):
        if stages.index("closure_check") > stages.index("confirm"):
            raise SystemExit("stages order must be closure_check,...,confirm (or pass --allow-unsound-confirm)")

    stage_jobs: list[_Stage] = []
    for s in stages:
        stage_jobs.append(
            _Stage(
                name=s,
                bpl_path=out_dir / f"{stem}.{s}.bpl",
                log_path=out_dir / f"{stem}.{s}.gemcutter.log",
            )
        )

    # The wraparound transform already strips unrelated asserts for ENTRY_CHECK/CLOSURE_CHECK/PUMP/ACCEL_PROBE.
    # Keep this split for readability and future extensions.
    base_text_no_dsl_asserts = base_text
    base_text_for_pump_accel = base_text
    available_regs = _extract_registers_from_bpl(base_text)

    raw_pump_reg = pump_reg
    pump_reg = _resolve_register_name(pump_reg, available_regs)
    if pump_reg != raw_pump_reg:
        print(f"[NOTE] resolved pump reg: {raw_pump_reg} -> {pump_reg}")

    raw_accel_regs = list(accel_regs)
    accel_regs = [_resolve_register_name(r, available_regs) for r in accel_regs]
    if accel_regs != raw_accel_regs:
        print(f"[NOTE] resolved accel regs: {raw_accel_regs} -> {accel_regs}")

    seen = set()
    accel_regs = [r for r in accel_regs if not (r in seen or seen.add(r))]

    missing = [r for r in [pump_reg, *accel_regs] if r not in available_regs]
    if missing:
        raise SystemExit(
            "register not found in compiled Boogie: "
            + ", ".join(missing)
            + f"\\nAvailable registers (sample): {sorted(available_regs)[:20]}"
        )

    for job in stage_jobs:
        if job.name == "closure_check":
            out_text = instrument_bpl_text(
                bpl_text=base_text_no_dsl_asserts,
                stage=WraparoundStage.CLOSURE_CHECK,
                pump_reg=pump_reg,
                accel_regs=accel_regs,
                index_value=index_value,
                index_expr=index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cutpoint_cond,
                step_op=step_op,
                step_delta=step_delta,
            )
        elif job.name == "pump":
            out_text = instrument_bpl_text(
                bpl_text=base_text_for_pump_accel,
                stage=WraparoundStage.PUMP,
                pump_reg=pump_reg,
                accel_regs=[],
                index_value=index_value,
                index_expr=index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cutpoint_cond,
                step_op=step_op,
                step_delta=step_delta,
            )
            if args.pump_unroll > 0:
                out_text = unroll_mainprocedure_loop_text(bpl_text=out_text, steps=args.pump_unroll)
        elif job.name == "accel":
            out_text = instrument_bpl_text(
                bpl_text=base_text_for_pump_accel,
                stage=WraparoundStage.ACCEL,
                pump_reg=pump_reg,
                accel_regs=accel_regs,
                index_value=index_value,
                index_expr=index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cutpoint_cond,
                step_op=step_op,
                step_delta=step_delta,
            )
            if args.accel_unroll > 0:
                out_text = unroll_mainprocedure_loop_text(bpl_text=out_text, steps=args.accel_unroll)
        elif job.name == "confirm":
            out_text = instrument_bpl_text(
                bpl_text=base_text,
                stage=WraparoundStage.CONFIRM,
                pump_reg=pump_reg,
                accel_regs=accel_regs,
                index_value=index_value,
                index_expr=index_expr,
                proj_vars=proj_vars,
                cutpoint_cond=cutpoint_cond,
                step_op=step_op,
                step_delta=step_delta,
            )
            out_text = unroll_mainprocedure_loop_text(bpl_text=out_text, steps=args.confirm_unroll)
        else:
            raise SystemExit(f"unknown stage: {job.name} (expected closure_check, pump, accel, confirm)")

        job.bpl_path.write_text(out_text, encoding="utf-8")
        print(f"[OK] stage bpl ({job.name}): {job.bpl_path}")

    if not args.ultimate:
        print("[NOTE] --ultimate not provided; skipping Ultimate runs.")
        return 0

    ultimate = Path(args.ultimate).expanduser().resolve()
    toolchain, closure_toolchain = _resolve_default_toolchains(
        root=root,
        toolchain_arg=args.toolchain,
        closure_toolchain_arg=args.closure_toolchain,
    )
    settings = (
        Path(args.settings).expanduser().resolve()
        if args.settings
        else (
            (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-witness.epf").resolve()
            if (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-witness.epf").exists()
            else (
                root
                / "Procurator"
                / "argo"
                / "code"
                / "spec"
                / "config"
                / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
            ).resolve()
        )
    )
    closure_settings = (
        Path(args.closure_settings).expanduser().resolve()
        if args.closure_settings
        else (
            (root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf").resolve()
            if (root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf").exists()
            else (
                root
                / "Procurator"
                / "argo"
                / "code"
                / "spec"
                / "config"
                / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
            ).resolve()
        )
    )
    if not closure_settings.exists():
        closure_settings = settings

    ultimate_home_root = out_dir / "ultimate-home"
    closure_safe: Optional[bool] = None
    closure_requested = any(j.name == "closure_check" for j in stage_jobs)

    for job in stage_jobs:
        stage_settings = closure_settings if job.name == "closure_check" else settings
        stage_toolchain = closure_toolchain if job.name == "closure_check" else toolchain
        print(f"[STAGE] {job.name} (pump={pump_reg}, accel={accel_regs}, index={index_value})")
        if job.name == "confirm" and closure_requested and (not args.allow_unsound_confirm):
            if closure_safe is not True:
                print("[SKIP] confirm is skipped because closure_check was not proven SAFE")
                continue

        _run_ultimate(
            ultimate=ultimate,
            toolchain=stage_toolchain,
            settings=stage_settings,
            input_bpl=job.bpl_path,
            log_path=job.log_path,
            ultimate_home=ultimate_home_root / f"{stem}.{job.name}",
            timeout_seconds=args.timeout_seconds,
            resource_limits=not args.no_resource_limits,
        )

        if job.name == "closure_check":
            txt = job.log_path.read_text(encoding="utf-8", errors="replace")
            res = _extract_result_line(txt) or ""
            closure_safe = _result_is_safe(res)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
