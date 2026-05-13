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
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Optional

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.transform.wraparound_analyze import _parse_global_var_types
from dslc.workflows.focused_direct import bounded_dsl_replay_marker_for_bpl, focused_unsafe_marker_for_bpl
from dslc.workflows.wraparound_cegis import _manifest_certified_unsafe_data
from dslc.workflows.wraparound_schedule import (
    compute_actor_schedule_id,
    dependency_projection_has_hard_certification_gap,
    infer_static_deterministic_schedule,
    sha256_text,
)
from dslc.workflows.wraparound_support.certification.manifest import _env_shape_assumes_are_certifiable


@dataclass(frozen=True)
class WitnessSummary:
    ok: bool
    kind: str  # dsl_assert / internal_assert / missing
    details: str


def _find_latest_witness(out_dir: Path) -> Optional[Path]:
    # Default verify output names end with ".bpl-witness.graphml".
    w = sorted(out_dir.glob("*.bpl-witness.graphml"), key=lambda p: p.stat().st_mtime, reverse=True)
    return w[0] if w else None


def _find_latest_focused_marker(out_dir: Path) -> Optional[Path]:
    markers = sorted(
        list(out_dir.glob("*.focused-index0.unsafe.json"))
        + list(out_dir.glob("*.bounded-dsl-replay.unsafe.json")),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    for marker in markers:
        try:
            data = json.loads(marker.read_text(encoding="utf-8"))
        except Exception:
            continue
        src = data.get("source_bpl")
        if not isinstance(src, str) or not src:
            continue
        bpl_path = Path(src)
        if focused_unsafe_marker_for_bpl(out_dir=marker.parent, bpl_path=bpl_path) == marker:
            return marker
        if bounded_dsl_replay_marker_for_bpl(out_dir=marker.parent, bpl_path=bpl_path) == marker:
            return marker
    return None


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


def _extract_witness_sourcecode_text(witness_text: str) -> str:
    """Return concatenated witness sourcecode entries, excluding assumptions."""

    chunks = re.findall(
        r"<data\s+key=\"sourcecode\">(?P<src>.*?)</data>",
        witness_text,
        flags=re.DOTALL,
    )
    return "\n".join(chunks)


def summarize_witness(*, out_dir: Path) -> WitnessSummary:
    witness = _find_latest_witness(out_dir)
    if not witness:
        focused_marker = _find_latest_focused_marker(out_dir)
        if focused_marker is not None:
            try:
                marker_data = json.loads(focused_marker.read_text(encoding="utf-8"))
                marker_kind = str(marker_data.get("kind") or "focused_under_approx")
            except Exception:
                marker_kind = "focused_under_approx"
            return WitnessSummary(
                True,
                marker_kind,
                f"{marker_kind} witness ({focused_marker.name})",
            )
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

    witness_source = _extract_witness_sourcecode_text(wtxt)

    # If the witness reaches the harness's global assertion check, it should mention
    # the actual accumulator hit in sourcecode. Initialization (`procurator_bad := false`)
    # and state snapshots are not evidence that the DSL accumulator caused the violation.
    witness_hits_dsl_accumulator = (
        "procurator_bad := true" in witness_source
        or "assert !procurator_bad" in witness_source
    )
    if "procurator_bad" in bpl_text and witness_hits_dsl_accumulator:
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


def _resolve_manifest_path(raw: object, *, manifest_path: Path) -> Optional[Path]:
    if not isinstance(raw, str) or not raw.strip():
        return None
    p = Path(raw)
    if p.exists():
        return p
    s = raw.strip()
    m = re.match(r"^/mnt/(?P<drive>[A-Za-z])/(?P<rest>.*)$", s)
    if m:
        win = Path(f"{m.group('drive').upper()}:/" + m.group("rest"))
        if win.exists():
            return win
    rel = manifest_path.parent / s
    if rel.exists():
        return rel
    return p


def _candidate_from_manifest(data: dict) -> Optional[WraparoundCandidate]:
    cand = data.get("candidate")
    if not isinstance(cand, dict):
        return None
    try:
        accel = cand.get("accel_regs") or []
        proj = cand.get("proj_vars") or []
        if not isinstance(accel, (list, tuple)) or not isinstance(proj, (list, tuple)):
            return None
        step_delta_raw = cand.get("step_delta", 1)
        step_delta = None if step_delta_raw is None else int(step_delta_raw)
        index_value_raw = cand.get("index_value")
        index_value = None if index_value_raw is None else int(index_value_raw)
        return WraparoundCandidate(
            pump_reg=str(cand.get("pump_reg") or ""),
            accel_regs=tuple(str(v) for v in accel),
            index_value=index_value,
            index_expr=cand.get("index_expr"),
            proj_vars=tuple(str(v) for v in proj),
            cutpoint_cond=cand.get("cutpoint_cond"),
            reason=str(cand.get("reason") or ""),
            step_op=str(cand.get("step_op") or "add"),
            step_delta=step_delta,
        )
    except (TypeError, ValueError):
        return None


def _effective_scalar_projection_vars(base_text: str, proj_vars: list[str]) -> list[str]:
    var_types = _parse_global_var_types(base_text.splitlines())
    out: list[str] = []
    seen: set[str] = set()
    for v in proj_vars:
        if v in seen:
            continue
        t = var_types.get(v)
        if t is None or "[" in t or "]" in t:
            continue
        seen.add(v)
        out.append(v)
    return out


def _schedule_replay_artifacts_match(attempt: dict, *, manifest_path: Path) -> bool:
    artifacts = attempt.get("artifacts")
    if not isinstance(artifacts, dict):
        return False
    checks = (
        ("entry_log", "entry_bpl", "entry", "entry", "unsafe"),
        ("confirm_log", "confirm_bpl", "near_wrap", "near_wrap", "unsafe"),
        ("closure_log", "closure_bpl", "closure", "closure", "safe"),
    )
    for log_key, bpl_key, result_key, stage, expected in checks:
        bpl_path = _resolve_manifest_path(artifacts.get(bpl_key), manifest_path=manifest_path)
        if bpl_path is None or not bpl_path.exists():
            return False
        try:
            bpl_text = bpl_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            return False
        if not _stage_bpl_has_expected_instrumentation(bpl_text, stage=stage):
            return False
        if not _stage_bpl_matches_attempt_cfg(bpl_text, attempt=attempt, stage=stage):
            return False
        log_path = _resolve_manifest_path(artifacts.get(log_key), manifest_path=manifest_path)
        if log_path is None or not log_path.exists():
            return False
        try:
            log_text = log_path.read_text(encoding="utf-8", errors="replace")
        except Exception:
            return False
        if not _log_mentions_exact_bpl(log_text, bpl_path):
            return False
        recorded = attempt.get(result_key)
        if not isinstance(recorded, dict):
            return False
        if not _result_line_is(str(recorded.get("result_line") or ""), expected):
            return False
        if not _log_contains_result_evidence(log_text, expected):
            return False
    return True


def _stage_bpl_matches_attempt_cfg(bpl_text: str, *, attempt: dict, stage: str) -> bool:
    cfg = attempt.get("cfg")
    sched = attempt.get("schedule")
    if not isinstance(cfg, dict) or not isinstance(sched, dict):
        return False

    required_symbols = _artifact_required_symbols(cfg, sched)
    if any(not _bpl_contains_symbol(bpl_text, symbol) for symbol in required_symbols):
        return False

    required_exprs = []
    required_exprs.extend(_list_field(cfg.get("env_shape_assumes")) or [])
    index_expr = cfg.get("index_expr")
    if isinstance(index_expr, str) and index_expr.strip():
        required_exprs.append(index_expr)
    if stage != "closure":
        required_exprs.extend(_list_field(cfg.get("proj_predicates")) or [])
        required_exprs.extend(_list_field(cfg.get("proj_exprs")) or [])
        cutpoint_cond = cfg.get("cutpoint_cond")
        if isinstance(cutpoint_cond, str) and cutpoint_cond.strip():
            required_exprs.append(cutpoint_cond)
    if any(not _bpl_contains_expr_fragment(bpl_text, expr) for expr in required_exprs):
        return False

    if stage == "closure":
        predicates = _list_field(cfg.get("proj_predicates")) or []
        for i, pred in enumerate(predicates):
            if f"wrap_closure_pred_{i}" not in bpl_text:
                return False
            if not _closure_bpl_binds_snapshot_expr(
                bpl_text,
                expr=str(pred),
                snapshot=f"wrap_closure_pred_{i}",
                cfg=cfg,
            ):
                return False
        for proj_var in _list_field(cfg.get("proj_vars")) or []:
            proj_text = str(proj_var)
            snap = f"wrap_closure_snap_{_bpl_identifier_suffix(proj_text)}"
            if not _closure_bpl_binds_snapshot_expr(
                bpl_text,
                expr=proj_text,
                snapshot=snap,
                cfg=cfg,
            ):
                return False
        for i, expr in enumerate(_list_field(cfg.get("proj_exprs")) or []):
            if f"wrap_closure_expr_{i}" not in bpl_text:
                return False
            if not _closure_bpl_binds_snapshot_expr(
                bpl_text,
                expr=str(expr),
                snapshot=f"wrap_closure_expr_{i}",
                cfg=cfg,
            ):
                return False
    return True


def _artifact_required_symbols(cfg: dict, sched: dict) -> list[str]:
    symbols: list[str] = []
    symbols.append(str(cfg.get("pump_reg") or ""))
    symbols.extend(str(v) for v in (_list_field(cfg.get("accel_regs")) or []))
    symbols.extend(str(v) for v in (_list_field(sched.get("target_regs")) or []))
    symbols.extend(str(v) for v in (_list_field(cfg.get("proj_vars")) or []))
    projection = _list_field(sched.get("projection")) or []
    for item in projection:
        if not isinstance(item, dict):
            continue
        if str(item.get("kind") or "") in {"predicate", "expr"}:
            continue
        symbols.append(str(item.get("lhs") or ""))
    return _unique_nonempty_strings(symbols)


def _unique_nonempty_strings(values: list[str]) -> list[str]:
    out: list[str] = []
    seen: set[str] = set()
    for value in values:
        item = str(value or "").strip()
        if not item or item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out


def _bpl_contains_symbol(bpl_text: str, symbol: str) -> bool:
    pattern = rf"(?<![A-Za-z0-9_.$]){re.escape(symbol)}(?![A-Za-z0-9_.$])"
    return re.search(pattern, bpl_text) is not None


def _bpl_identifier_suffix(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_]", "_", value)


def _bpl_contains_expr_fragment(bpl_text: str, expr: object) -> bool:
    if not isinstance(expr, str) or not expr.strip():
        return False
    return _normalize_bpl_fragment(expr) in _normalize_bpl_fragment(bpl_text)


def _closure_bpl_binds_snapshot_expr(bpl_text: str, *, expr: str, snapshot: str, cfg: dict) -> bool:
    exprs = _closure_expr_variants(expr, cfg)
    normalized_bpl = _normalize_bpl_fragment(bpl_text)
    for candidate in exprs:
        candidate_norm = _normalize_bpl_fragment(candidate)
        if not candidate_norm:
            continue
        assign_ok = any(
            _normalize_bpl_fragment(form) in normalized_bpl
            for form in (
                f"{snapshot} := {candidate};",
                f"{snapshot} := ({candidate});",
            )
        )
        equality_ok = any(
            _normalize_bpl_fragment(form) in normalized_bpl
            for form in (
                f"{candidate} == {snapshot}",
                f"({candidate}) == {snapshot}",
            )
        )
        if assign_ok and equality_ok:
            return True
    return False


def _closure_expr_variants(expr: str, cfg: dict) -> list[str]:
    out = [str(expr)]
    idx_expr = cfg.get("index_expr")
    pump_reg = str(cfg.get("pump_reg") or "")
    if isinstance(idx_expr, str) and idx_expr.strip() and pump_reg:
        alias = f"wrap_closure_idx_{_bpl_identifier_suffix(pump_reg)}"
        out.append(str(expr).replace(idx_expr, alias))
    return _unique_nonempty_strings(out)


def _normalize_bpl_fragment(text: str) -> str:
    return "".join(ch for ch in text if not ch.isspace())


def _log_contains_result_evidence(log_text: str, expected: str) -> bool:
    stage_result = _extract_final_explicit_result_line(log_text)
    return stage_result is not None and _result_line_is(stage_result, expected)


def _stage_bpl_has_expected_instrumentation(bpl_text: str, *, stage: str) -> bool:
    if stage == "entry":
        return "__wraparound_entry_error" in bpl_text and "WRAPAROUND_ENTRY_ASSERT" in bpl_text
    if stage == "near_wrap":
        return (
            "__wraparound_assert" in bpl_text
            and "wraparound confirm fast-forward" in bpl_text
            and "UNROLLED" in bpl_text
            and "WRAPAROUND_NEAR_FOCUSED_ASSERT" not in bpl_text
        )
    if stage == "closure":
        return (
            "__wraparound_closure_assert_all" in bpl_text
            and "wraparound closure_check setup" in bpl_text
            and "wraparound closure_check asserts" in bpl_text
        )
    return False


def _log_mentions_exact_bpl(log_text: str, bpl_path: Path) -> bool:
    candidates = {str(bpl_path), bpl_path.as_posix()}
    raw = str(bpl_path)
    m = re.match(r"^(?P<drive>[A-Za-z]):[\\/](?P<rest>.*)$", raw)
    if m:
        drive = m.group("drive").lower()
        rest = m.group("rest").replace("\\", "/")
        candidates.add(f"/mnt/{drive}/{rest}")
    return any(_log_mentions_path_token(log_text, path) for path in candidates)


def _log_mentions_path_token(log_text: str, path: str) -> bool:
    escaped = re.escape(path)
    patterns = [
        rf"(?<!\S)-i\s+{escaped}(?!\S)",
        rf"(?<!\S)-i\s+'{escaped}'(?!\S)",
        rf'(?<!\S)-i\s+"{escaped}"(?!\S)',
    ]
    return any(re.search(pattern, log_text) is not None for pattern in patterns)


def _extract_final_explicit_result_line(log_text: str) -> Optional[str]:
    result = None
    for line in log_text.splitlines():
        if "RESULT:" in line:
            result = line.strip()
    return result


def _result_line_is(line: str, expected: str) -> bool:
    s = str(line or "").lower()
    if expected == "unsafe":
        return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)
    if expected == "safe":
        return ("result: safe" in s) or ("proved your program to be correct" in s)
    return False


def _validate_schedule_replay_manifest_with_artifacts(data: dict, *, manifest_path: Path) -> bool:
    base_bpl = _resolve_manifest_path(data.get("base_bpl"), manifest_path=manifest_path)
    if base_bpl is None or not base_bpl.exists():
        return False
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")
    base_hash = sha256_text(base_text)
    if str(data.get("base_bpl_sha256") or "") != base_hash:
        return False
    cand = _candidate_from_manifest(data)
    if cand is None or not cand.pump_reg:
        return False
    attempts = data.get("attempts") or []
    if not isinstance(attempts, list):
        return False
    for attempt in attempts:
        if not isinstance(attempt, dict) or attempt.get("certified") is not True:
            continue
        cfg = attempt.get("cfg")
        sched = attempt.get("schedule")
        if not isinstance(cfg, dict) or not isinstance(sched, dict):
            continue
        if not _schedule_replay_attempt_shape_certifiable(data, attempt):
            continue
        expected_proj_vars = _list_field(cfg.get("proj_vars"))
        expected_proj_predicates = _list_field(cfg.get("proj_predicates"))
        expected_proj_predicate_sources = _list_field(cfg.get("proj_predicate_sources"))
        expected_proj_exprs = _list_field(cfg.get("proj_exprs"))
        if (
            expected_proj_vars is None
            or expected_proj_predicates is None
            or expected_proj_predicate_sources is None
            or expected_proj_exprs is None
        ):
            continue
        if len(expected_proj_predicate_sources) != len(expected_proj_predicates):
            continue
        if list(cfg.get("proj_vars") or []) != expected_proj_vars:
            continue
        if list(cfg.get("proj_predicates") or []) != expected_proj_predicates:
            continue
        if list(cfg.get("proj_exprs") or []) != expected_proj_exprs:
            continue
        try:
            schedule_cand = WraparoundCandidate(
                pump_reg=cand.pump_reg,
                accel_regs=cand.accel_regs,
                index_value=cand.index_value,
                index_expr=cand.index_expr,
                proj_vars=cand.proj_vars,
                cutpoint_cond=cfg.get("cutpoint_cond"),
                reason=cand.reason,
                step_op=cand.step_op,
                step_delta=cand.step_delta,
                stable_substitutions=cand.stable_substitutions,
            )
        except Exception:
            continue
        cfg_schedule = infer_static_deterministic_schedule(
            base_bpl_text=base_text,
            candidate=schedule_cand,
            base_bpl_sha256=base_hash,
        )
        if cfg_schedule is None:
            continue
        expected_schedule = cfg_schedule.with_projection_vars(
            expected_proj_vars,
            proj_predicates=expected_proj_predicates,
            proj_predicate_sources=expected_proj_predicate_sources,
            proj_exprs=expected_proj_exprs,
            conditions=(),
            source="dependency_projection",
        )
        if sched.get("actors") != list(expected_schedule.actors):
            continue
        if str(sched.get("candidate_id") or "") != expected_schedule.candidate_id:
            continue
        if [str(v) for v in (sched.get("target_regs") or [])] != list(expected_schedule.target_regs):
            continue
        sched_index = _int_field(sched.get("index_value"))
        sched_delta = _int_field(sched.get("step_delta"))
        if sched_index is None or sched_delta is None:
            continue
        if sched_index != int(expected_schedule.index_value):
            continue
        if sched_delta != int(expected_schedule.step_delta):
            continue
        expected_projection = [asdict(p) for p in expected_schedule.projection]
        if sched.get("projection") != expected_projection:
            continue
        try:
            recomputed_schedule_id = compute_actor_schedule_id(
                candidate_id=str(sched.get("candidate_id") or ""),
                target_regs=[str(v) for v in (sched.get("target_regs") or [])],
                index_value=sched_index,
                step_delta=sched_delta,
                actors=[str(v) for v in (sched.get("actors") or [])],
                projection=list(sched.get("projection") or []),
                base_bpl_sha256=base_hash,
            )
        except (TypeError, ValueError):
            continue
        if sched.get("schedule_id") != recomputed_schedule_id:
            continue
        if _schedule_replay_artifacts_match(attempt, manifest_path=manifest_path):
            return True
    return False


def _schedule_replay_attempt_shape_certifiable(data: dict, attempt: dict) -> bool:
    cfg = attempt.get("cfg")
    sched = attempt.get("schedule")
    if not isinstance(cfg, dict) or not isinstance(sched, dict):
        return False
    if cfg.get("projection_complete") is not True:
        return False
    if not _is_empty_sequence(cfg.get("closure_assumes")):
        return False
    if "phases" in sched or "reactions" in sched:
        return False
    if not _is_empty_sequence(sched.get("conditions")):
        return False
    if not _env_shape_assumes_are_certifiable(
        cfg_env_shape=cfg.get("env_shape_assumes"),
        manifest_cand=data.get("candidate"),
    ):
        return False
    cfg_notes = cfg.get("notes") or []
    if not isinstance(cfg_notes, (list, tuple)):
        return False
    if dependency_projection_has_hard_certification_gap(notes=[str(n) for n in cfg_notes]):
        return False
    cfg_pred = _list_field(cfg.get("proj_predicates"))
    cfg_pred_sources = _list_field(cfg.get("proj_predicate_sources"))
    if cfg_pred is None or cfg_pred_sources is None:
        return False
    if len(cfg_pred_sources) != len(cfg_pred):
        return False
    if any(str(src) != "dependency_projection" for src in cfg_pred_sources):
        return False
    cand = data.get("candidate")
    if not _cfg_matches_manifest_candidate(cfg, cand):
        return False
    return True


def _cfg_matches_manifest_candidate(cfg: dict, cand: object) -> bool:
    if not isinstance(cand, dict):
        return False
    if str(cfg.get("pump_reg") or "") != str(cand.get("pump_reg") or ""):
        return False
    cfg_accel = _list_field(cfg.get("accel_regs"))
    cand_accel = _list_field(cand.get("accel_regs"))
    if cfg_accel is None or cand_accel is None:
        return False
    if [str(v) for v in cfg_accel] != [str(v) for v in cand_accel]:
        return False
    if str(cfg.get("step_op") or "") != str(cand.get("step_op") or ""):
        return False
    if _int_field(cfg.get("step_delta")) != _int_field(cand.get("step_delta")):
        return False
    cand_index_expr = cand.get("index_expr")
    if cand_index_expr is not None and str(cfg.get("index_expr") or "") != str(cand_index_expr):
        return False
    cand_index_value = cand.get("index_value")
    if cand_index_value is not None and _int_field(cfg.get("index_value")) != _int_field(cand_index_value):
        return False
    return True


def _is_empty_sequence(value: object) -> bool:
    return isinstance(value, (list, tuple)) and len(value) == 0


def _list_field(value: object) -> Optional[list]:
    if value is None:
        return []
    if isinstance(value, (list, tuple)):
        return list(value)
    return None


def _int_field(value: object) -> Optional[int]:
    try:
        return int(value)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        return None


def validate_wraparound_manifest(manifest_path: Path) -> tuple[bool, str]:
    j = json.loads(manifest_path.read_text(encoding="utf-8"))
    attempts = j.get("attempts", [])
    if not isinstance(attempts, list) or not attempts:
        return False, "manifest has no attempts"

    mode = str(j.get("cegar_mode") or "legacy_closure_assumes")
    if mode == "schedule_replay":
        if _validate_schedule_replay_manifest_with_artifacts(j, manifest_path=manifest_path):
            return True, "certified: ENTRY+NEAR_WRAP UNSAFE and CLOSURE SAFE for one schedule_id"
        return False, "not certified: missing a valid certified wraparound attempt"
    if _manifest_certified_unsafe_data(j):
        return True, "certified: ENTRY+CONFIRM UNSAFE and CLOSURE SAFE"
    return False, "not certified: missing a valid certified wraparound attempt"


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
