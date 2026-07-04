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
from dslc.toolchain.ultimate_paths import (
    resolve_ultimate_asset_path,
    ultimate_asset,
)
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

def _result_is_unsafe(res_line: str) -> bool:
    res = res_line.strip()
    return ("RESULT: UNSAFE" in res) or ("proved your program to be incorrect" in res)


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

    if toolchain_arg:
        toolchain = resolve_ultimate_asset_path(toolchain_arg, root=root)
    else:
        tc_no_witness = ultimate_asset(root, "ReachSafety.xml")
        tc_witness = ultimate_asset(root, "ReachSafety-Witness.xml")
        tc_legacy = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml"
        # Prefer witness by default for bug finding; closure_check defaults to a
        # witness-free toolchain to avoid crashes on some SAFE tasks.
        if tc_witness.exists():
            toolchain = tc_witness.resolve()
        elif tc_no_witness.exists():
            toolchain = tc_no_witness.resolve()
        else:
            toolchain = tc_legacy.resolve()

    closure_toolchain = (
        resolve_ultimate_asset_path(closure_toolchain_arg, root=root)
        if closure_toolchain_arg
        else (
            ultimate_asset(root, "ClosureCheck-ReachSafety.xml").resolve()
            if ultimate_asset(root, "ClosureCheck-ReachSafety.xml").exists()
            else toolchain
        )
    )

    return toolchain, closure_toolchain


def _resolve_default_settings(
    *,
    root: Path,
    settings_arg: str,
    closure_settings_arg: str,
) -> tuple[Path, Path]:
    if settings_arg:
        settings = resolve_ultimate_asset_path(settings_arg, root=root)
    else:
        settings = (
            ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-witness.epf").resolve()
            if ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-witness.epf").exists()
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

    closure_settings = (
        resolve_ultimate_asset_path(closure_settings_arg, root=root)
        if closure_settings_arg
        else (
            ultimate_asset(root, "ClosureCheck-32bit-GemCutter-ALL-witness.epf").resolve()
            if ultimate_asset(root, "ClosureCheck-32bit-GemCutter-ALL-witness.epf").exists()
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

    return settings, closure_settings


def _resolve_cegis_toolchain_settings(
    *,
    root: Path,
    toolchain_arg: str,
    closure_toolchain_arg: str,
    settings_arg: str,
    closure_settings_arg: str,
    cegar_mode: str,
    ultimate_xmx_gb: int = 0,
) -> tuple[Path, Path, Path, Path]:
    toolchain, closure_toolchain = _resolve_default_toolchains(
        root=root,
        toolchain_arg=toolchain_arg,
        closure_toolchain_arg=closure_toolchain_arg,
    )
    settings, closure_settings = _resolve_default_settings(
        root=root,
        settings_arg=settings_arg,
        closure_settings_arg=closure_settings_arg,
    )

    if cegar_mode == "schedule_replay":
        if not toolchain_arg:
            tc_no_witness = ultimate_asset(root, "ReachSafety.xml")
            if tc_no_witness.exists():
                toolchain = tc_no_witness.resolve()
        if not settings_arg:
            st_no_witness = ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL.epf")
            if st_no_witness.exists():
                settings = st_no_witness.resolve()
        if int(ultimate_xmx_gb) >= 8:
            st_allinline = ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf")
            if st_allinline.exists():
                if not settings_arg:
                    settings = st_allinline.resolve()
                if not closure_settings_arg:
                    closure_settings = st_allinline.resolve()

    return toolchain, closure_toolchain, settings, closure_settings


_RE_PROP_IMPORT_ENTRIES = re.compile(r"\bentries\s+\"([^\"]+)\"\s*;", flags=re.MULTILINE)
_RE_BMV2_TABLE_ADD_RANGE = re.compile(
    r"^\s*table_add\s+(?P<table>\S+)\s+\S+\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<lo>0x[0-9a-fA-F]+)->(?P<hi>0x[0-9a-fA-F]+)\s+=>",
    flags=re.MULTILINE,
)
_RE_BMV2_TABLE_ADD_RANGE_EPORT = re.compile(
    r"^\s*table_add\s+(?P<table>\S+)\s+\S+\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<lo>0x[0-9a-fA-F]+)->(?P<hi>0x[0-9a-fA-F]+)\s+=>\s*(?P<eport>0x[0-9a-fA-F]+)\s*(?:#.*)?$",
    flags=re.MULTILINE,
)


def _infer_distcache_hash_caps(spec_text: str, *, spec_dir: Path) -> dict[str, int]:
    """
    Infer "hash output caps" from BMv2 command files referenced in the spec.

    Motivation:
      DistCache computes `meta.hashval_for_{partition,spine_partition}` via `hash(...)` and then
      uses range tables (`hash_{leaf,spine}_partition_tbl`) to set `meta.{leaf,spine}switchidx`,
      which indexes `leafload_reg/spineload_reg`.

      In verification we often abstract hash by `havoc` (P4B), so without additional constraints,
      the hash outputs can miss the configured range entries and the register index becomes
      nondeterministic, breaking closure proofs.

    This helper reads `table_add hash_{leaf,spine}_partition_tbl ... <lo>-><hi>` lines and
    returns caps for the corresponding hash outputs: `hi` (inclusive).
    """

    caps: dict[str, int] = {}
    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in _RE_BMV2_TABLE_ADD_RANGE.finditer(txt):
            table = m.group("table")
            hi = int(m.group("hi"), 16)
            # Table->hash-output mapping for DistCache clientTrack.
            if "hash_leaf_partition_tbl" in table:
                caps["hashval_for_partition"] = max(caps.get("hashval_for_partition", -1), hi)
            if "hash_spine_partition_tbl" in table:
                caps["hashval_for_spine_partition"] = max(caps.get("hashval_for_spine_partition", -1), hi)
    return {k: v for k, v in caps.items() if v >= 0}


def _infer_distcache_partition_eports(spec_text: str, *, spec_dir: Path) -> dict[str, int]:
    """
    Infer DistCache clientTrack partition egress ports from BMv2 command files.

    The partition tables map hash ranges to fixed eports (leaf=0x2, spine=0x3 in the
    shipped DistCache benchmarks). These values are then used as register indices.
    """

    ports: dict[str, int] = {}
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


def _apply_hash_caps_to_bpl(bpl_text: str, *, node_prefixes: Sequence[str], caps: dict[str, int]) -> str:
    """
    Patch Boogie text to add extra `assume` constraints on hash outputs.

    We target P4B's translation of `hash(result, ...)`, which emits:
      havoc <result>;
      assume(buge.bvW(<result>, <from>) && bule.bvW(<result>, <to>));

    We add:
      assume(bule.bvW(<result>, <cap>bvW));
    """

    if not caps:
        return bpl_text

    # Avoid fragile multi-line regex substitutions: Ultimate logs and generated Boogie
    # can differ slightly in whitespace. We patch line-by-line.
    lines = bpl_text.splitlines(keepends=True)
    wanted: list[tuple[str, int]] = []
    for suffix, cap in caps.items():
        for pref in node_prefixes:
            wanted.append((f"{pref}_meta.{suffix}", cap))

    out_lines: list[str] = []
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
            # Only patch assumes that constrain `var` to a from..to range (P4B hash translation).
            # Example:
            #   assume(buge.bv16(var, 0bv16) && bule.bv16(var, 32768bv16));
            m = re.search(r"buge\.bv(\d+)\(", stripped)
            if not m:
                continue
            bv = m.group(1)
            indent = re.match(r"^[ \t]*", line).group(0)  # type: ignore[union-attr]
            out_lines.append(f"{indent}assume(bule.bv{bv}({var}, {cap}bv{bv}));\n")
            break

    return "".join(out_lines)


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
    ap.add_argument(
        "--ultimate-xmx-gb",
        type=int,
        default=4,
        help="Max Java heap for Ultimate in GB (WSL safety; default: 4).",
    )
    ap.add_argument("--toolchain", default="", help="Ultimate toolchain XML (default: ReachSafety-Witness.xml)")
    ap.add_argument(
        "--closure-toolchain",
        default="",
        help=(
            "Ultimate toolchain XML for closure_check only "
            "(default: src/dslc/toolchain/ultimate/ClosureCheck-ReachSafety.xml if present; "
            "falls back to --toolchain)"
        ),
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Ultimate settings EPF (default: src/dslc/toolchain/ultimate/ReachSafety-32bit-GemCutter-ALL-witness.epf)",
    )
    ap.add_argument(
        "--closure-settings",
        default="",
        help=(
            "Ultimate settings EPF for closure_check only "
            "(default: src/dslc/toolchain/ultimate/ClosureCheck-32bit-GemCutter-ALL-witness.epf; "
            "falls back to --settings if missing)"
        ),
    )
    ap.add_argument("--timeout-seconds", type=int, default=1200, help="Ultimate timeout per stage (default: 1200s)")
    ap.add_argument(
        "--cegis",
        action="store_true",
        help=(
            "(Deprecated) CEGIS is now the default behavior when --ultimate is provided. "
            "Use --legacy to force the old multi-stage pipeline."
        ),
    )
    ap.add_argument(
        "--legacy",
        action="store_true",
        help=(
            "Use the legacy multi-stage wraparound pipeline (closure_check/pump/accel/confirm) "
            "without iterative refinement. Not recommended for wraparound bugs."
        ),
    )
    ap.add_argument(
        "--cegis-max-iters",
        type=int,
        default=6,
        help="Max refinement iterations for --cegis (default: 6).",
    )
    ap.add_argument(
        "--wraparound-cegar-mode",
        choices=["legacy_closure_assumes", "schedule_replay"],
        default="legacy_closure_assumes",
        help=(
            "Wraparound CEGAR implementation mode. "
            "schedule_replay uses the ENTRY -> NEAR_WRAP -> CLOSURE replay loop; "
            "legacy_closure_assumes keeps the existing closure-only refinement path."
        ),
    )
    ap.add_argument(
        "--wraparound-stop-after",
        choices=["none", "entry", "near_wrap", "closure"],
        default="none",
        help="Stop CEGIS after the selected stage and write the incremental manifest.",
    )
    ap.add_argument(
        "--stages",
        default="closure_check,pump,accel,confirm",
        help="Comma-separated stages: closure_check,pump,accel,confirm (default: closure_check,pump,accel,confirm)",
    )
    ap.add_argument(
        "--soundness",
        default="closure",
        choices=["closure", "cegis", "none"],
        help=(
            "Soundness gate for CONFIRM:\n"
            "  - closure: require CLOSURE_CHECK == SAFE (default)\n"
            "  - cegis: require PUMP to find a repeatable +1 cycle (UNSAFE at pump marker)\n"
            "  - none: always run confirm (diagnostic only)"
        ),
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
        "--proj-vars",
        default="",
        help=(
            "Comma-separated projection vars for wraparound stages (overrides inferred/default proj vars). "
            "Useful for CEGIS/CEGAR experiments that refine the closure/pump context."
        ),
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
            "`src/p4b/source/build-host/p4c-translator` or `src/dslc/toolchain/p4b_docker.sh`)"
        )

    # CEGIS is the default behavior for wraparound bug finding when Ultimate is available.
    # Use `--legacy` to force the old multi-stage pipeline.
    if (not args.legacy) and args.ultimate:
        ultimate = Path(args.ultimate).expanduser().resolve()

        toolchain, closure_toolchain, settings, closure_settings = _resolve_cegis_toolchain_settings(
            root=root,
            toolchain_arg=args.toolchain,
            closure_toolchain_arg=args.closure_toolchain,
            settings_arg=args.settings,
            closure_settings_arg=args.closure_settings,
            cegar_mode=args.wraparound_cegar_mode,
            ultimate_xmx_gb=max(1, int(args.ultimate_xmx_gb)),
        )

        from dslc.workflows.wraparound_cegis import UltimateStageRunner, run_wraparound_cegis

        # WSL safety: bound the Ultimate JVM heap. The external resource limits wrapper
        # additionally pins Ultimate to a single core and lowers CPU/IO priority.
        runner = UltimateStageRunner(ultimate=ultimate, xmx_gb=max(1, int(args.ultimate_xmx_gb)))

        manifest_path = run_wraparound_cegis(
            spec_path=spec_path,
            out_dir=out_dir,
            p4b_bin=p4b_bin,
            ultimate=ultimate,
            runner=runner,
            timeout_seconds=args.timeout_seconds,
            resource_limits=not args.no_resource_limits,
            enable_slicing=not args.no_slicing,
            pipeline_two_stage=not args.no_two_stage,
            confirm_unroll=args.confirm_unroll,
            max_iters=args.cegis_max_iters,
            toolchain=toolchain,
            closure_toolchain=closure_toolchain,
            settings=settings,
            closure_settings=closure_settings,
            cegar_mode=args.wraparound_cegar_mode,
            stop_after=args.wraparound_stop_after,
        )
        # Print a stable summary that downstream scripts (e.g. ablations) can parse.
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        print(f"[OK] base bpl: {manifest.get('base_bpl')}")
        print(f"[OK] cegis manifest: {manifest_path}")

        attempts = manifest.get("attempts") or []
        if attempts:
            last = attempts[-1]
            art = last.get("artifacts") or {}
            for stage_key, log_key, res_key in [
                ("entry_check", "entry_log", "entry"),
                ("closure_check", "closure_log", "closure"),
                ("confirm", "confirm_log", "confirm"),
            ]:
                res = last.get(res_key)
                if not res:
                    continue
                print(f"[STAGE] {stage_key}")
                print(f"[RESULT] {res.get('result_line') or 'RESULT: UNKNOWN'}")
                if art.get(log_key):
                    print(f"[LOG] {art.get(log_key)}")
        return 0

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

    # DistCache-specific: infer and apply "hash caps" to stabilize partition indices.
    # This is used by wraparound closure_check to avoid nondet misses on range tables.
    hash_caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
    if hash_caps:
        # Heuristic: apply to all node prefixes we see in the compiled BPL (alias_meta.*).
        node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
        patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=hash_caps)
        if patched != base_text:
            base_text = patched
            base_bpl.write_text(base_text, encoding="utf-8")
            print(f"[NOTE] applied hash caps for closure stability: {hash_caps}")

    # DistCache-specific: infer stable partition eports that act as register indices.
    partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

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
    elif cand is not None and index_expr is not None and partition_ports:
        # DistCache specialization: `meta.{leaf,spine}switchidx` is computed by range tables and may
        # not be initialized at the closure setup point. If we can infer the fixed eport values
        # from the BMv2 command files, prefer a concrete index for wraparound stages.
        if ("leafload" in pump_reg) and ("leaf_eport" in partition_ports) and ("leafswitchidx" in index_expr):
            index_expr = None
            index_value = partition_ports["leaf_eport"]
        if ("spineload" in pump_reg) and ("spine_eport" in partition_ports) and ("spineswitchidx" in index_expr):
            index_expr = None
            index_value = partition_ports["spine_eport"]
    elif index_expr is None and partition_ports:
        # If index is not specified by the user nor inferred from the spec/meta, and we
        # recognize the DistCache clientTrack partition ports, use them as a better default
        # than "0". This keeps closure_check sound for wraparound counters that are indexed
        # by fixed eports (leaf=2, spine=3).
        if ("leafload" in pump_reg) and ("leaf_eport" in partition_ports):
            index_value = partition_ports["leaf_eport"]
        if ("spineload" in pump_reg) and ("spine_eport" in partition_ports):
            index_value = partition_ports["spine_eport"]

    step_op = cand.step_op if cand else "add"
    step_delta = int(cand.step_delta) if cand and cand.step_delta is not None else 1
    if args.proj_vars.strip():
        proj_vars = [x.strip() for x in args.proj_vars.split(",") if x.strip()]
    else:
        proj_vars = list(cand.proj_vars) if (cand and cand.proj_vars) else None
    cutpoint_cond = cand.cutpoint_cond if cand else None

    # DistCache specialization: the hash outputs and derived switch indices are per-packet values
    # that can legitimately change within/after a round (P4B models hash as havoc). For wraparound
    # pumping we only need the mailbox counts / scheduler phase to stay stable.
    if (not args.proj_vars.strip()) and proj_vars and partition_ports:
        drop_suffixes = (
            ".leafswitchidx",
            ".spineswitchidx",
            ".hashval_for_partition",
            ".hashval_for_spine_partition",
        )
        proj_vars = [v for v in proj_vars if not v.endswith(drop_suffixes)]

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

    # If we use the CEGIS soundness gate, we need the pump stage result even if the
    # caller didn't request generating/running it explicitly.
    if args.soundness == "cegis":
        names = {j.name for j in stage_jobs}
        if "pump" not in names:
            stage_jobs.insert(
                0,
                _Stage(
                    name="pump",
                    bpl_path=out_dir / f"{stem}.pump.bpl",
                    log_path=out_dir / f"{stem}.pump.gemcutter.log",
                ),
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
        resolve_ultimate_asset_path(args.settings, root=root)
        if args.settings
        else (
            ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-witness.epf").resolve()
            if ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-witness.epf").exists()
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
        resolve_ultimate_asset_path(args.closure_settings, root=root)
        if args.closure_settings
        else (
            ultimate_asset(root, "ClosureCheck-32bit-GemCutter-ALL-witness.epf").resolve()
            if ultimate_asset(root, "ClosureCheck-32bit-GemCutter-ALL-witness.epf").exists()
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
    pump_found: Optional[bool] = None
    closure_requested = any(j.name == "closure_check" for j in stage_jobs)

    for job in stage_jobs:
        # Avoid correctness-witness generation for stages that are expected to be SAFE/UNKNOWN,
        # because some Ultimate versions crash (NPE) when printing correctness witnesses.
        # For bug finding we only need witnesses for CONFIRM.
        stage_settings = closure_settings if job.name == "closure_check" else settings
        stage_toolchain = closure_toolchain if job.name in {"closure_check", "pump", "accel"} else toolchain
        print(f"[STAGE] {job.name} (pump={pump_reg}, accel={accel_regs}, index={index_value})")
        if job.name == "confirm":
            if args.soundness == "closure" and closure_requested and (not args.allow_unsound_confirm):
                if closure_safe is not True:
                    print("[SKIP] confirm is skipped because closure_check was not proven SAFE")
                    continue
            if args.soundness == "cegis":
                if pump_found is not True:
                    print("[SKIP] confirm is skipped because pump CEGIS did not find a repeatable +1 cycle")
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

        if job.name in {"closure_check", "pump"}:
            txt = job.log_path.read_text(encoding="utf-8", errors="replace")
            res = _extract_result_line(txt) or ""
            if job.name == "closure_check":
                closure_safe = _result_is_safe(res)
            else:
                # For PUMP, UNSAFE means we found a +1 cycle under the chosen projection.
                pump_found = _result_is_unsafe(res)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
