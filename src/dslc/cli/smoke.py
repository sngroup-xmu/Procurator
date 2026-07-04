from __future__ import annotations

import argparse
import re
from pathlib import Path
from typing import Optional, Sequence


def _structural_smoke_check(*, bpl_text: str, harness: str) -> list[str]:
    """
    Lightweight structural checks on generated Boogie.

    This is NOT a verifier. It only catches obvious generation regressions early.
    """
    errs: list[str] = []
    harness = harness.lower().strip()
    if harness not in {"concurrent", "sequential"}:
        return [f"unsupported harness: {harness}"]

    if not re.search(r"\bprocedure\s+ULTIMATE\.start\s*\(", bpl_text):
        errs.append("missing procedure ULTIMATE.start()")

    if harness == "concurrent":
        if not re.search(r"^\s*fork\b", bpl_text, flags=re.MULTILINE):
            errs.append("missing any fork statements (no concurrency)")
        if not re.search(r"\batomic\s*\{", bpl_text):
            errs.append("missing any atomic blocks (pass-atomic modeling likely broken)")
    else:
        # Sequential harnesses use a single mainProcedure loop. Concurrent
        # harnesses enter through ULTIMATE.start and spawn per-actor threads.
        if not re.search(r"\bprocedure\s+mainProcedure\s*\(", bpl_text):
            errs.append("missing procedure mainProcedure()")

    return errs


def main(argv: Optional[Sequence[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Smoke-check generated Boogie (structural, no solver run)")
    ap.add_argument("--bpl", required=True, help="Path to the generated .bpl")
    ap.add_argument(
        "--harness",
        choices=["concurrent", "sequential"],
        default="concurrent",
        help="Expected harness style (default: concurrent)",
    )
    args = ap.parse_args(list(argv) if argv is not None else None)

    bpl_path = Path(args.bpl).expanduser()
    if not bpl_path.is_absolute():
        bpl_path = (Path.cwd() / bpl_path).resolve()
    if not bpl_path.exists():
        print(f"[SMOKE-FAIL] .bpl not found: {bpl_path}")
        return 2

    bpl_text = bpl_path.read_text(encoding="utf-8", errors="replace")
    errs = _structural_smoke_check(bpl_text=bpl_text, harness=str(args.harness))
    if errs:
        for e in errs:
            print(f"[SMOKE-FAIL] {e}")
        return 2
    print(f"[SMOKE-OK] {bpl_path} looks structurally OK for harness={args.harness}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
