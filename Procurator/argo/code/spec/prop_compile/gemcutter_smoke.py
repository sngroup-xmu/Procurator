#!/usr/bin/env python3
from __future__ import annotations

import argparse
import re
import subprocess
from pathlib import Path
from typing import Optional, Sequence


def _structural_smoke_check(bpl_text: str) -> list[str]:
    """
    Lightweight sanity checks that the generated Boogie looks like a GemCutter-style
    concurrent program (fork/atomic/ULTIMATE.start present).

    This is NOT a verifier; it just catches obvious generation regressions early.
    """
    errs: list[str] = []

    if not re.search(r"\bprocedure\s+ULTIMATE\.start\s*\(", bpl_text):
        errs.append("missing procedure ULTIMATE.start()")

    if not re.search(r"^\s*fork\b", bpl_text, flags=re.MULTILINE):
        errs.append("missing any fork statements (no concurrency)")

    if not re.search(r"\batomic\s*\{", bpl_text):
        errs.append("missing any atomic blocks (pass-atomic modeling likely broken)")

    return errs


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Smoke-check (and optionally run) Ultimate GemCutter on a Boogie file")
    ap.add_argument("--bpl", required=True, help="Path to the generated .bpl")
    ap.add_argument(
        "--ultimate-run",
        default="",
        help="Optional: path to Ultimate CLI executable (e.g., <UGemCutter-linux>/Ultimate).",
    )
    ap.add_argument(
        "--toolchain",
        default="",
        help="Optional: toolchain XML to run (Ultimate CLI -tc). If omitted, only structural smoke is performed.",
    )
    ap.add_argument(
        "--settings",
        default="",
        help="Optional: settings .epf to run (Ultimate CLI -s).",
    )
    args = ap.parse_args(list(argv) if argv is not None else None)

    bpl_path = Path(args.bpl)
    bpl_text = bpl_path.read_text(encoding="utf-8", errors="replace")

    errs = _structural_smoke_check(bpl_text)
    if errs:
        for e in errs:
            print(f"[SMOKE-FAIL] {e}")
        return 2
    print("[SMOKE-OK] Boogie file looks structurally suitable for GemCutter (fork/atomic/ULTIMATE.start present).")

    if not args.ultimate_run:
        print(
            "\n[NOTE] Ultimate is not run (no --ultimate-run provided). "
            "To run GemCutter locally, point --ultimate-run at a built Ultimate distribution "
            "and provide --toolchain/--settings if needed."
        )
        return 0

    run_script = Path(args.ultimate_run)
    if not run_script.exists():
        print(f"[RUN-FAIL] Ultimate run script not found: {run_script}")
        return 3

    if not args.toolchain:
        print("[RUN-SKIP] --toolchain not provided; skipping Ultimate execution.")
        return 0

    cmd = [str(run_script), "-tc", args.toolchain]
    if args.settings:
        cmd.extend(["-s", args.settings])
    cmd.extend(["-i", str(bpl_path)])

    print("[RUN] " + " ".join(cmd))
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    print(proc.stdout)
    return proc.returncode


if __name__ == "__main__":
    raise SystemExit(main())


