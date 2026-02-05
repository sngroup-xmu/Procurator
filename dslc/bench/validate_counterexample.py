#!/usr/bin/env python3
"""
Counterexample sanity checks for Procurator runs.

Goal: distinguish "our DSL property violated" vs "some other internal assert violated",
and validate wraparound certificates (ENTRY+CONFIRM UNSAFE, CLOSURE SAFE).

This is *not* a semantic proof checker; it's a lightweight regression guard to avoid
accidentally reporting pseudo-counterexamples due to spec bugs / wrong assertion.
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Optional


@dataclass(frozen=True)
class WitnessSummary:
    ok: bool
    kind: str  # dsl_assert / internal_assert / missing
    details: str


def _find_latest_witness(out_dir: Path) -> Optional[Path]:
    # Default verify output names end with ".bpl-witness.graphml".
    w = sorted(out_dir.glob("*.bpl-witness.graphml"), key=lambda p: p.stat().st_mtime, reverse=True)
    return w[0] if w else None


def _bpl_path_from_witness_text(witness_text: str) -> Optional[Path]:
    """
    Best-effort extraction of the analyzed Boogie program path from a GraphML witness.

    Rationale: wraparound runs produce multiple stage-specific `.bpl` files (entry/confirm/closure).
    The newest `.bpl` in the directory is not necessarily the one that produced the newest witness.
    We therefore prefer the witness's own `programfile` metadata when available.
    """

    m = re.search(r"<data\s+key=\"programfile\">(?P<path>[^<]+)</data>", witness_text)
    if not m:
        return None
    p = m.group("path").strip()
    if not p:
        return None
    try:
        return Path(p)
    except Exception:
        return None


def _extract_dsl_guard_lines(bpl_text: str) -> list[str]:
    """
    Grab the exact Boogie lines that mark DSL-global assertion violations:
      if (!(...)) { procurator_bad := true; }
    """
    out: list[str] = []
    for ln in bpl_text.splitlines():
        s = ln.strip()
        if "procurator_bad := true" not in s:
            continue
        if not s.startswith("if (!("):
            continue
        out.append(s)
    return out


def _extract_global_assert_lines(bpl_text: str) -> list[str]:
    """
    Extract direct Boogie assertions emitted for DSL `global { assert { ... } }`.

    Some harness modes (e.g., unbounded sequential scheduler) emit assertions directly:
      // DSL assertions
      assert (...);

    Others (bounded/unrolled) accumulate into `procurator_bad`.
    """
    lines = bpl_text.splitlines()
    out: list[str] = []

    try:
        # Historical marker: "// Global assertions"
        # Current harness marker: "// DSL assertions"
        i0 = next(
            i
            for i, ln in enumerate(lines)
            if ln.strip() in {"// Global assertions", "// DSL assertions"}
        )
    except StopIteration:
        return out

    # Collect consecutive "assert ..." lines that follow the marker.
    for ln in lines[i0 + 1 :]:
        s = ln.strip()
        if not s:
            break
        if not s.startswith("assert "):
            continue
        # Keep exact text (witness typically includes the same `assert ...;` as sourcecode).
        out.append(s)
    return out


def _extract_global_assert_exprs(bpl_text: str) -> list[str]:
    """
    Extract DSL global assertion *expressions* from the `// Global assertions` section.

    In most harnesses we emit:
      assert (<expr>);

    But wraparound instrumentation rewrites assertions as wrapper calls:
      call __wraparound_assert(<expr>);

    Ultimate witnesses often normalize parentheses/whitespace inside `<expr>`, so we
    match by expression (with normalization) rather than by exact source line.
    """

    lines = bpl_text.splitlines()
    out: list[str] = []

    try:
        i0 = next(
            i
            for i, ln in enumerate(lines)
            if ln.strip() in {"// Global assertions", "// DSL assertions"}
        )
    except StopIteration:
        return out

    for ln in lines[i0 + 1 :]:
        s = ln.strip()
        if not s:
            break
        if s.startswith("assert "):
            # Strip "assert " prefix and trailing ";".
            expr = s[len("assert ") :].strip()
            if expr.endswith(";"):
                expr = expr[:-1].strip()
            out.append(expr)
            continue
        if s.startswith("call __wraparound_assert"):
            # Typical shape:
            #   call __wraparound_assert(<expr>);
            m = re.match(r"^call\s+__wraparound_assert\s*\(\s*(?P<expr>.*)\s*\)\s*;\s*$", s)
            if not m:
                continue
            out.append(m.group("expr").strip())
            continue
    return out


def _normalize_expr_for_witness_match(s: str) -> str:
    """
    Normalize an expression (or witness text) for robust matching.

    Ultimate's witness printer commonly rewrites expressions by:
      - removing redundant parentheses,
      - changing whitespace,
      - XML-escaping operators (e.g., "&amp;&amp;" for "&&").

    We do NOT attempt semantic parsing here. This is just a regression guard, so a
    coarse normalization is sufficient.
    """

    # Unescape common XML entities used in witnesses.
    s = s.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    # Remove whitespace and parentheses to tolerate witness normalization.
    return "".join(ch for ch in s if (not ch.isspace()) and ch not in "()")


def summarize_witness(*, out_dir: Path) -> WitnessSummary:
    witness = _find_latest_witness(out_dir)
    if not witness:
        return WitnessSummary(False, "missing", "no *.bpl-witness.graphml in out_dir")
    wtxt = witness.read_text(encoding="utf-8", errors="replace")

    # Prefer the witness-referenced program file, falling back to the newest `.bpl` in out_dir.
    bpl_path = _bpl_path_from_witness_text(wtxt)
    if not bpl_path or not bpl_path.exists():
        bpl_files = list(out_dir.glob("*.bpl"))
        if not bpl_files:
            return WitnessSummary(False, "missing", "no .bpl in out_dir")
        bpl_path = sorted(bpl_files, key=lambda p: p.stat().st_mtime, reverse=True)[0]

    bpl_text = bpl_path.read_text(encoding="utf-8", errors="replace")

    # If the witness reaches the harness's global assertion check, it should mention procurator_bad.
    if "procurator_bad" in bpl_text and "procurator_bad" in wtxt:
        # Ultimate's witnessprinter often normalizes/abridges source lines (e.g., bracketed statements
        # like "[procurator_bad := true;]"), so matching the full guard line is too brittle.
        #
        # For our harness, it is sufficient to require that the witness assigns procurator_bad := true,
        # because procurator_bad is the accumulator for global DSL assertions.
        if "procurator_bad := true" in wtxt:
            return WitnessSummary(
                True,
                "dsl_assert",
                f"DSL global assertion violated (accumulator flag set; {witness.name})",
            )
        if "assert !procurator_bad" in wtxt:
            return WitnessSummary(
                True,
                "dsl_assert",
                f"DSL global assertion violated (final accumulator assert hit; {witness.name})",
            )

        # Still useful as a regression guard: the witness *should* contain a write.
        guards = _extract_dsl_guard_lines(bpl_text)
        if not guards:
            return WitnessSummary(
                False,
                "dsl_assert",
                "witness mentions DSL-assert accumulator, but harness has no DSL guard lines",
            )
        return WitnessSummary(
            False,
            "dsl_assert",
            "witness mentions DSL-assert accumulator, but no assignment to true was found",
        )

    # Otherwise, if the harness emits DSL global assertions directly, accept a witness that hits one of them.
    direct_asserts = _extract_global_assert_lines(bpl_text)
    if direct_asserts:
        # Exact sourcecode lines in witnesses are brittle: Ultimate often normalizes away
        # parentheses/whitespace (e.g., `assert (x);` -> `assert x;`).
        #
        # Match by (coarsely normalized) expression instead.
        exprs = _extract_global_assert_exprs(bpl_text)
        w_norm = _normalize_expr_for_witness_match(wtxt)
        for e in exprs:
            e_norm = _normalize_expr_for_witness_match(e)
            if e_norm and (e_norm in w_norm):
                return WitnessSummary(True, "dsl_assert", f"witness hits DSL global assert ({witness.name})")

        # Witness hits an assertion, but not one of our DSL-global assertions.
        if "<data key=\"violation\">true</data>" in wtxt or "assert" in wtxt:
            return WitnessSummary(True, "internal_assert", f"witness does not hit DSL global assert ({witness.name})")

        return WitnessSummary(False, "missing", "witness does not contain any assert sourcecode")

    # Wraparound-instrumented variants rewrite DSL global assertions as wrapper calls
    # inside the same `// Global assertions` section. Match them by expression with a
    # coarse normalization that tolerates witness reformatting.
    exprs = _extract_global_assert_exprs(bpl_text)
    if exprs:
        w_norm = _normalize_expr_for_witness_match(wtxt)
        for e in exprs:
            e_norm = _normalize_expr_for_witness_match(e)
            if e_norm and (e_norm in w_norm):
                return WitnessSummary(True, "dsl_assert", f"witness hits DSL global assert ({witness.name})")

    # Otherwise, treat as "internal assert" counterexample (e.g., P4 @assert or translator bound checks).
    if "<data key=\"violation\">true</data>" in wtxt or "assert" in wtxt:
        return WitnessSummary(True, "internal_assert", f"witness does not mention procurator_bad ({witness.name})")

    return WitnessSummary(False, "missing", "unrecognized witness content")


def validate_wraparound_manifest(manifest_path: Path) -> tuple[bool, str]:
    j = json.loads(manifest_path.read_text(encoding="utf-8"))
    attempts = j.get("attempts", [])
    if not isinstance(attempts, list) or not attempts:
        return False, "manifest has no attempts"

    def _is(res, what: str) -> bool:
        if not isinstance(res, dict):
            return False
        s = str(res.get("result_line") or "")
        return what.lower() in s.lower()

    for a in attempts:
        entry = a.get("entry")
        confirm = a.get("confirm")
        closure = a.get("closure")
        if _is(entry, "unsafe") and _is(confirm, "unsafe") and _is(closure, "safe"):
            return True, "certified: ENTRY+CONFIRM UNSAFE and CLOSURE SAFE"
    return False, "not certified: missing an attempt with (entry unsafe, confirm unsafe, closure safe)"


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out-dir", type=str, default="", help="verify out dir (contains *.bpl and *.graphml)")
    ap.add_argument("--wraparound-manifest", type=str, default="", help="wraparound.cegis.manifest.json path")
    ns = ap.parse_args(argv)

    if ns.wraparound_manifest:
        ok, msg = validate_wraparound_manifest(Path(ns.wraparound_manifest))
        print(("[OK] " if ok else "[FAIL] ") + msg)
        return 0 if ok else 2

    if not ns.out_dir:
        ap.error("need --out-dir or --wraparound-manifest")
    out_dir = Path(ns.out_dir)
    summ = summarize_witness(out_dir=out_dir)
    print(("[OK] " if summ.ok else "[FAIL] ") + f"{summ.kind}: {summ.details}")
    return 0 if summ.ok else 2


if __name__ == "__main__":
    raise SystemExit(main(__import__("sys").argv[1:]))
