from __future__ import annotations

import argparse
from typing import Optional, Sequence

from dslc.cli import ablation, compile, gemcutter, smoke, wraparound


def main(argv: Optional[Sequence[str]] = None) -> int:
    """
    Single-entry CLI for Procurator workflows.

    This file is intentionally small and delegates to the existing command modules:
      - `procurator compile ...`    -> `dslc.cli.compile.main`
      - `procurator verify ...`     -> `dslc.cli.gemcutter.main`
      - `procurator wraparound ...` -> `dslc.cli.wraparound.main`
      - `procurator ablation ...`   -> `dslc.cli.ablation.main`
      - `procurator smoke ...`      -> `dslc.cli.smoke.main`
    """

    ap = argparse.ArgumentParser(prog="procurator", add_help=True)
    sub = ap.add_subparsers(dest="cmd")

    # Keep subparser stubs minimal: we forward args verbatim to each module's `main`.
    sub.add_parser("compile", add_help=False)
    sub.add_parser("verify", add_help=False)
    sub.add_parser("wraparound", add_help=False)
    sub.add_parser("ablation", add_help=False)
    sub.add_parser("smoke", add_help=False)

    args, rest = ap.parse_known_args(list(argv) if argv is not None else None)

    if args.cmd == "compile":
        return compile.main(rest)
    if args.cmd == "verify":
        return gemcutter.main(rest)
    if args.cmd == "wraparound":
        return wraparound.main(rest)
    if args.cmd == "ablation":
        return ablation.main(rest)
    if args.cmd == "smoke":
        return smoke.main(rest)

    ap.print_help()
    print("\nCommands:")
    print("  compile     Compile a .prop spec to a backend artifact (Boogie/Promela)")
    print("  verify      Compile + run Ultimate/GemCutter (or just compile if --ultimate omitted)")
    print("  wraparound  Run wraparound (closure_check/pump/accel/confirm) pipeline")
    print("  ablation    Run symmetry/splitting/slicing ablations and record times")
    print("  smoke       Structural smoke-check for generated Boogie (no solver run)")
    print("\nUse: procurator <command> --help")
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
