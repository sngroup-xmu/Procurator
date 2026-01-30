from __future__ import annotations

import argparse
from pathlib import Path
from typing import Optional, Sequence

from dslc.cli.common import find_default_p4b_bin, fresh_run_dir
from dslc.compiler import compile_spec_file
from dslc.speclang import parse_model
from dslc.utils.repo import repo_root


def _needs_p4b(spec_path: Path) -> bool:
    txt = spec_path.read_text(encoding="utf-8", errors="replace")
    model = parse_model(txt)
    return any((not imp.path.endswith(".bpl")) for imp in model.imports.values())


def _needs_p4c(spec_path: Path) -> bool:
    """
    The Promela backend only needs `p4c-translator` when at least one import is not a direct `.pml` file.
    """
    txt = spec_path.read_text(encoding="utf-8", errors="replace")
    model = parse_model(txt)
    return any((not imp.path.endswith(".pml")) for imp in model.imports.values())


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Compile a .prop spec to a backend artifact (no cache by default)")
    ap.add_argument("--spec", required=True, help="Path to .prop file")
    ap.add_argument(
        "--backend",
        choices=["boogie", "promela"],
        default="boogie",
        help="Backend to compile to (default: boogie)",
    )
    ap.add_argument(
        "--out",
        default="",
        help=(
            "Output path. If omitted, a fresh per-run directory is created under "
            "`.tmp/procurator/compile/<spec>/<run_id>/` (no cache by default)."
        ),
    )
    ap.add_argument("--work-dir", default="", help="Work directory for P4B outputs (boogie backend)")
    ap.add_argument("--p4b-bin", default="", help="Path to P4->Boogie translator binary (boogie backend)")
    ap.add_argument("--p4c-translator-bin", default="", help="Path to p4c-translator binary (promela backend)")
    ap.add_argument("--clean", action="store_true", help="Clean output directory before emitting (promela backend)")
    ap.add_argument(
        "--env",
        choices=["spec", "max"],
        default="spec",
        help="Environment model for external inputs: 'spec' applies assume constraints, 'max' makes inputs fully nondet",
    )
    ap.add_argument(
        "--no-prune",
        action="store_true",
        help="Disable DAG-based slicing and env-input pruning (boogie backend)",
    )
    ap.add_argument("--por", action="store_true", help="Enable commutativity-based POR (boogie backend)")
    ap.add_argument(
        "--boogie-harness",
        choices=["concurrent", "sequential"],
        default="concurrent",
        help=(
            "Boogie harness style: 'concurrent' uses fork/atomic threads; "
            "'sequential' emits a single-thread nondet scheduler."
        ),
    )
    ap.add_argument(
        "--no-two-stage",
        action="store_true",
        help="Disable two-stage ingress/egress scheduling when it can be inferred (boogie backend)",
    )
    ap.add_argument(
        "--max-steps",
        type=int,
        default=None,
        help=(
            "Bound the number of Procurator steps (BMC-style bug finding). "
            "UNSAFE is sound; SAFE is only within the bound. Default: unbounded."
        ),
    )
    ap.add_argument(
        "--use-spec-max-steps",
        action="store_true",
        help="Honor `global.max_steps` from the DSL spec (disabled by default).",
    )

    args = ap.parse_args(list(argv) if argv is not None else None)

    spec_path = Path(args.spec).expanduser()
    if not spec_path.is_absolute():
        spec_path = (Path.cwd() / spec_path).resolve()

    backend = args.backend

    out: Path
    run_dir: Optional[Path] = None
    if args.out:
        out = Path(args.out).expanduser().resolve()
    else:
        run_dir = fresh_run_dir(category="compile", name=spec_path.stem)
        if backend == "boogie":
            out = run_dir / f"{spec_path.stem}.bpl"
        else:
            out = run_dir / "model"

    max_env_inputs = args.env == "max"
    prune = not args.no_prune
    enable_slicing = prune
    prune_env_inputs = prune
    por_enabled = args.por
    boogie_harness = args.boogie_harness
    pipeline_two_stage = not args.no_two_stage

    p4b_bin: Optional[Path] = Path(args.p4b_bin).resolve() if args.p4b_bin else None
    if backend == "boogie" and _needs_p4b(spec_path) and not p4b_bin:
        p4b_bin = find_default_p4b_bin()
        if not p4b_bin:
            raise SystemExit(
                "missing --p4b-bin (and no default P4B translator found at "
                "`P4B-Translator/build-host/p4c-translator` or `dslc/toolchain/p4b_docker.sh`)"
            )

    p4c_bin: Optional[Path] = Path(args.p4c_translator_bin).resolve() if args.p4c_translator_bin else None
    if backend == "promela" and _needs_p4c(spec_path) and not p4c_bin:
        raise SystemExit("missing --p4c-translator-bin (required for promela backend when importing P4/JSON)")

    work_dir: Optional[Path] = Path(args.work_dir).resolve() if args.work_dir else None
    if backend == "boogie" and run_dir and not work_dir:
        work_dir = run_dir / "work"

    outp = compile_spec_file(
        spec_path=spec_path,
        backend=backend,
        out=out,
        p4c_translator_bin=p4c_bin,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        clean=args.clean,
        run_semantics=True,
        max_env_inputs=max_env_inputs,
        enable_slicing=enable_slicing,
        prune_env_inputs=prune_env_inputs,
        por_enabled=por_enabled,
        por_guard_enabled=True,
        boogie_harness=boogie_harness,
        pipeline_two_stage=pipeline_two_stage,
        max_steps=args.max_steps,
        honor_spec_max_steps=bool(args.use_spec_max_steps),
    )

    for k, v in outp.artifacts.items():
        print(f"[OK] {k}: {v}")
    if run_dir:
        print(f"[OUT] {run_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
