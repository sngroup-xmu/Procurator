from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Optional, Sequence

from .backends import BoogieBackend, PromelaBackend
from .speclang import SpecParseError, parse_model, parse_tree
from .speclang import SemanticAnalyzer, SemanticError


class CompileError(RuntimeError):
    pass


@dataclass(frozen=True)
class CompileOutput:
    backend: str
    artifacts: Dict[str, Path]


def compile_spec_text(
    *,
    spec_text: str,
    backend: str,
    out: Path,
    p4c_translator_bin: Optional[Path] = None,
    p4b_bin: Optional[Path] = None,
    work_dir: Optional[Path] = None,
    clean: bool = False,
    run_semantics: bool = True,
    max_env_inputs: bool = False,
    enable_slicing: bool = True,
    prune_env_inputs: bool = True,
    por_enabled: bool = False,
    por_guard_enabled: bool = True,
    boogie_harness: str = "concurrent",
    pipeline_two_stage: bool = True,
    feasibility_check: bool = False,
    refine_trace: bool = False,
) -> CompileOutput:
    """
    Compile a DSL spec into a backend artifact.

    Pipeline:
      parse (Lark) -> semantic checks -> model -> backend compile
    """
    backend = backend.lower().strip()
    if backend not in {"promela", "boogie"}:
        raise CompileError(f"unsupported backend: {backend}")

    # 1) parse tree
    try:
        tree = parse_tree(spec_text)
    except Exception as e:
        raise CompileError(f"parse failed: {e}") from e

    # 2) semantic checks (conservative)
    if run_semantics:
        try:
            SemanticAnalyzer().analyze(tree)
        except SemanticError as e:
            raise CompileError(str(e)) from e

    # 3) build model
    try:
        model = parse_model(spec_text)
    except SpecParseError as e:
        raise CompileError(str(e)) from e

    # 4) backend compile
    if backend == "boogie":
        boogie_harness = boogie_harness.lower().strip()
        if boogie_harness not in {"concurrent", "sequential"}:
            raise CompileError(f"unsupported boogie harness: {boogie_harness}")
        out_bpl = out
        if out_bpl.suffix != ".bpl":
            raise CompileError(f"--out must end with .bpl for boogie backend, got: {out_bpl}")
        out_bpl.parent.mkdir(parents=True, exist_ok=True)
        b = BoogieBackend(p4b_bin=str(p4b_bin) if p4b_bin else None)
        out_path = b.compile(
            model,
            out_bpl=out_bpl,
            work_dir=work_dir,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            por_enabled=por_enabled,
            por_guard_enabled=por_guard_enabled,
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
            feasibility_check=feasibility_check,
            refine_trace=refine_trace,
        )
        return CompileOutput(backend="boogie", artifacts={"bpl": out_path})

    # promela
    out_dir = out
    out_dir.mkdir(parents=True, exist_ok=True)
    pb = PromelaBackend(p4c_translator_bin=p4c_translator_bin)
    res = pb.compile(model, out_dir=out_dir, clean=clean)
    return CompileOutput(backend="promela", artifacts={"out_dir": res.out_dir, "main_model": res.main_model})


def compile_spec_file(
    *,
    spec_path: Path,
    backend: str,
    out: Path,
    p4c_translator_bin: Optional[Path] = None,
    p4b_bin: Optional[Path] = None,
    work_dir: Optional[Path] = None,
    clean: bool = False,
    run_semantics: bool = True,
    max_env_inputs: bool = False,
    enable_slicing: bool = True,
    prune_env_inputs: bool = True,
    por_enabled: bool = False,
    por_guard_enabled: bool = True,
    boogie_harness: str = "concurrent",
    pipeline_two_stage: bool = True,
    feasibility_check: bool = False,
    refine_trace: bool = False,
) -> CompileOutput:
    spec_text = spec_path.read_text(encoding="utf-8")
    return compile_spec_text(
        spec_text=spec_text,
        backend=backend,
        out=out,
        p4c_translator_bin=p4c_translator_bin,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        clean=clean,
        run_semantics=run_semantics,
        max_env_inputs=max_env_inputs,
        enable_slicing=enable_slicing,
        prune_env_inputs=prune_env_inputs,
        por_enabled=por_enabled,
        por_guard_enabled=por_guard_enabled,
        boogie_harness=boogie_harness,
        pipeline_two_stage=pipeline_two_stage,
        feasibility_check=feasibility_check,
        refine_trace=refine_trace,
    )


def _default_p4c_translator_bin() -> Path:
    # repo-local default (may not exist until built)
    here = Path(__file__).resolve()
    repo_root = here.parents[1]  # .../dslc -> repo root
    return repo_root / "Procurator" / "argo" / "code" / "Translator" / "build" / "p4c-translator"


def _default_p4b_bin() -> Path:
    # Default to the Docker wrapper script shipped with dslc.
    here = Path(__file__).resolve()
    return here.parent / "toolchain" / "p4b_docker.sh"


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Procurator DSL compiler (front-end + backends)")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument("--backend", choices=["promela", "boogie"], required=True)
    ap.add_argument("--out", required=True, help="Output path (dir for promela, .bpl file for boogie)")
    ap.add_argument("--clean", action="store_true", help="Clean output directory before emitting (promela)")
    ap.add_argument("--no-semantics", action="store_true", help="Skip semantic analysis (debug)")
    ap.add_argument("--no-slicing", action="store_true", help="Disable P4 slicing/pruning (Boogie backend)")
    ap.add_argument(
        "--no-env-prune",
        action="store_true",
        help="Disable env input pruning based on sliced Boogie usage (Boogie backend)",
    )
    ap.add_argument("--por", action="store_true", help="Enable commutativity-based POR (Boogie backend)")
    ap.add_argument(
        "--no-por-guard",
        action="store_true",
        help="Disable POR guards even when --por is enabled (Boogie backend)",
    )
    ap.add_argument(
        "--boogie-harness",
        choices=["concurrent", "sequential"],
        default="concurrent",
        help="Boogie harness style: 'concurrent' uses fork/atomic threads; 'sequential' emits a single-thread nondet scheduler.",
    )
    ap.add_argument(
        "--no-two-stage",
        action="store_true",
        help="Disable two-stage ingress/egress scheduling when it can be inferred (Boogie backend)",
    )
    ap.add_argument(
        "--env",
        choices=["spec", "max"],
        default="spec",
        help="Environment model for external inputs: 'spec' applies assume constraints, 'max' makes them fully nondet.",
    )

    ap.add_argument(
        "--p4c-translator-bin",
        default=str(_default_p4c_translator_bin()),
        help="Path to p4c-translator binary (promela backend)",
    )
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary (boogie backend)")
    ap.add_argument("--work-dir", default="", help="Working directory (boogie backend)")

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec)
    out = Path(args.out)
    backend = args.backend
    run_semantics = not args.no_semantics
    max_env_inputs = args.env == "max"
    enable_slicing = not args.no_slicing
    prune_env_inputs = not args.no_env_prune
    por_enabled = args.por
    por_guard_enabled = not args.no_por_guard
    boogie_harness = args.boogie_harness
    pipeline_two_stage = not args.no_two_stage

    p4c_bin = Path(args.p4c_translator_bin) if args.p4c_translator_bin else None
    # Prefer docker wrapper by default (works once the p4b docker image is built).
    p4b_bin = Path(args.p4b_bin) if args.p4b_bin else _default_p4b_bin()
    work_dir = Path(args.work_dir) if args.work_dir else None

    try:
        outp = compile_spec_file(
            spec_path=spec_path,
            backend=backend,
            out=out,
            p4c_translator_bin=p4c_bin,
            p4b_bin=p4b_bin,
            work_dir=work_dir,
            clean=args.clean,
            run_semantics=run_semantics,
            max_env_inputs=max_env_inputs,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
            por_enabled=por_enabled,
            por_guard_enabled=por_guard_enabled,
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
        )
    except Exception as e:
        raise SystemExit(f"[ERR] {e}") from e

    for k, v in outp.artifacts.items():
        print(f"[OK] {k}: {v}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
