from __future__ import annotations

import json
import os
import re
import signal
import time
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Callable, Dict, List, Optional, Protocol, Sequence, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate, infer_wraparound_candidates
from dslc.compiler import compile_spec_file
from dslc.speclang.parse import parse_model
from dslc.transform.wraparound import WraparoundStage, instrument_bpl_text, unroll_mainprocedure_loop_text
from dslc.transform.wraparound_analyze import _infer_deterministic_scheduler_period, _parse_global_var_types
from dslc.transform.wraparound_common import _RE_PROC_SCHED
# NOTE: We rewrite quantified register init assumptions only when it is provably safe.
#
# Ultimate often struggles with init patterns like:
#   assume (forall i:bv32 :: reg[i] == 0bvW);
# For wraparound stages, this is safe to expand to finitely many indices *only if*
# we can infer a finite bound on the accessed index domain (from `assume` constraints).
#
# The actual rewriting happens in `dslc/transform/wraparound_stages.py` and is
# conservative by construction: if no finite bound is inferred, we keep the quantifier
# to preserve semantics and avoid spurious counterexamples.
from dslc.transform.wraparound_analyze import _inline_deterministic_round_into_mainprocedure
from dslc.toolchain.ultimate_witness import (
    extract_assumptions_from_graphml,
    find_latest_graphml_witness,
    synthesize_boogie_assumes,
)
from dslc.toolchain.ultimate_runner import extract_result_line as ultimate_extract_result_line
from dslc.toolchain.ultimate_runner import run_ultimate
from dslc.utils.repo import repo_root


class WraparoundCegisError(RuntimeError):
    pass


_RE_HAVOC = re.compile(r"^\s*havoc\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*;\s*$")
_RE_BV_TYPE = re.compile(r"^bv(?P<w>\d+)$")
_RE_SIMPLE_EQ = re.compile(
    r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*==\s*(?P<rhs>.+)$"
)


def _read_tail_text(path: Path, *, max_bytes: int = 1_000_000) -> str:
    """
    Read the last `max_bytes` bytes of a text file (best-effort).

    Rationale: Ultimate logs can be large. For early-stop monitoring we only need
    the most recent lines that contain RESULT / "Registering result ..." markers.
    """

    try:
        with path.open("rb") as f:
            try:
                f.seek(-max(1, int(max_bytes)), os.SEEK_END)
            except OSError:
                f.seek(0)
            data = f.read()
    except FileNotFoundError:
        return ""
    return data.decode("utf-8", errors="replace")


def _toolchain_has_witnessprinter(toolchain: Path) -> bool:
    """
    Best-effort detection for whether a toolchain XML enables witness printing.

    We use this to avoid a redundant second CONFIRM run:
      - if CONFIRM already runs with a witness-enabled toolchain, we reuse its witness.
      - otherwise, we may re-run with a witness toolchain when we explicitly need one.
    """

    try:
        txt = toolchain.read_text(encoding="utf-8", errors="ignore").lower()
    except Exception:
        return False
    return "ultimate.witnessprinter" in txt


def _zero_value_for_boogie_type(typ: str) -> Optional[str]:
    t = typ.strip()
    if t == "bool":
        return "false"
    if t == "int":
        return "0"
    m = _RE_BV_TYPE.match(t)
    if m:
        return f"0bv{m.group('w')}"
    return None


def _collect_env_assigned_vars_from_model(model) -> set[str]:
    """
    Collect dotted variables that appear on the LHS of assignments/decls inside env blocks.
    """

    from lark import Token, Tree

    def dotted_var_to_str(node) -> str:
        if isinstance(node, Token):
            return str(node)
        if not isinstance(node, Tree):
            return str(node)
        if str(node.data) != "dotted_var":
            if len(node.children) == 1:
                return dotted_var_to_str(node.children[0])
            return ".".join(str(c) for c in node.children)

        cur = ""
        for item in node.children:
            if isinstance(item, Token):
                if item.type == "NAME":
                    cur += str(item) + "."
                elif item.type == "NUMBER":
                    cur = cur.rstrip(".")
                    cur += f"[{item}]."
        return cur.rstrip(".")

    def collect_from_tree(node, out: set[str]) -> None:
        """
        Recursively collect assignment/decl LHS variables from an env statement subtree.

        Env blocks can contain control constructs (e.g., `if (...) { ... }`) whose
        children contain nested `assignment` nodes. We must traverse recursively,
        otherwise env-completion under-approx may incorrectly treat conditionally-
        assigned fields (e.g., `hdr.op_hdr.optype`) as "unassigned" and pin them to 0.
        """

        if isinstance(node, Tree):
            tt = str(node.data)
            if tt in {"assignment", "var_decl"}:
                var_tree = node.children[0] if tt == "assignment" else node.children[1]
                out.add(dotted_var_to_str(var_tree))
            for ch in node.children:
                collect_from_tree(ch, out)

    assigned: set[str] = set()
    for nd in model.nodes.values():
        for st in nd.env_statements:
            collect_from_tree(st, assigned)
    for hd in model.hosts.values():
        for st in hd.env_statements:
            collect_from_tree(st, assigned)
    return assigned


def _synthesize_env_completion_assumes(*, model, base_text: str) -> List[str]:
    """
    Under-approximate the environment by setting *unassigned* injected fields to zero.

    This is used as a refinement when CONFIRM times out on large programs (e.g., DistCache).
    It is sound for bug finding because it only restricts environment nondeterminism.
    """

    assigned = _collect_env_assigned_vars_from_model(model)
    host_names = sorted(model.hosts.keys())
    if not host_names:
        return []

    lines = [ln.rstrip("\n") for ln in base_text.splitlines()]
    var_types = _parse_global_var_types(lines)

    out: List[str] = []
    seen: set[str] = set()
    for ln in lines:
        m = _RE_HAVOC.match(ln)
        if not m:
            continue
        name = m.group("name")
        if not any(name.startswith(f"{hn}_") for hn in host_names):
            continue
        typ = var_types.get(name)
        if not typ:
            continue
        z = _zero_value_for_boogie_type(typ)
        if z is None:
            continue

        # Map "<host>_..." -> "..." for matching env LHS names.
        suffix = name
        for hn in host_names:
            if suffix.startswith(f"{hn}_"):
                suffix = suffix[len(hn) + 1 :]
                break
        if suffix in assigned:
            continue

        expr = f"({name} == {z})"
        if expr not in seen:
            out.append(expr)
            seen.add(expr)

    return sorted(out)


def _collect_env_input_prefixes(model) -> Tuple[str, ...]:
    """
    Compute a conservative set of variable prefixes that correspond to *environment*
    packet/meta inputs.

    We use this to restrict witness-guided refinement to input shapes only, avoiding
    pinning internal scheduler/state variables (e.g., procurator_step/phase) that can
    easily make closure brittle or unsound as a certificate.
    """

    names: set[str] = set()
    # Host actors inject packets through <host>_hdr/meta/standard_metadata globals.
    names.update(model.hosts.keys())
    # EnvThread injects packets directly to nodes marked external_input=true.
    for n, nd in model.nodes.items():
        if nd.external_input is True:
            names.add(n)

    prefixes: List[str] = ["hdr.", "meta.", "standard_metadata."]
    for nm in sorted(names):
        # Our Boogie encoding commonly uses stage-qualified header/meta namespaces like
        # `<actor>_hdr_ig.*` / `<actor>_hdr_eg.*` in two-stage harnesses and for saved
        # copies. Include these so witness-guided refinement can lock an "input shape"
        # even when the interesting fields only show up in egress copies (e.g., `io_hdr_eg.*`).
        prefixes.extend(
            [
                f"{nm}_hdr.",
                f"{nm}_hdr_ig.",
                f"{nm}_hdr_eg.",
                f"{nm}_meta.",
                f"{nm}_meta_ig.",
                f"{nm}_meta_eg.",
                f"{nm}_standard_metadata.",
            ]
        )
    return tuple(prefixes)


def _collect_wraparound_candidate_vars(candidate: WraparoundCandidate) -> Tuple[str, ...]:
    """
    Variables that are directly associated with the wraparound target.

    This is used to (optionally) allow witness-guided refinements to pin down
    the pumped register(s) and related state. Keep it small and predictable.
    """

    vars_out: List[str] = [candidate.pump_reg]
    vars_out.extend(list(candidate.accel_regs))
    return tuple(sorted(set(v for v in vars_out if v)))


def _extract_witness_assignments(graphml_text: str) -> Dict[str, str]:
    from dslc.toolchain.ultimate_witness import _RE_SIMPLE_EQ  # reuse parser for lhs/rhs

    out: Dict[str, str] = {}
    for a in extract_assumptions_from_graphml(graphml_text):
        m = _RE_SIMPLE_EQ.match(a.expr.strip())
        if not m:
            continue
        var = m.group("var")
        rhs = m.group("rhs").strip()
        if var not in out:
            out[var] = rhs
    return out


def _find_latest_graphml_witness_since(*, work_dir: Path, since_time: float) -> Optional[Path]:
    """
    Find the newest GraphML witness produced after `since_time` (epoch seconds).

    Ultimate's witness printer output path is not stable across versions, and we can have
    multiple witness runs in a single wraparound CEGIS attempt (confirm/closure).
    Filtering by mtime is the most reliable way to select the witness for the current stage.
    """

    wd = work_dir.resolve()
    cands: List[Path] = []

    legacy = wd / "witness"
    if legacy.exists():
        cands.extend(list(legacy.glob("*.graphml")))
        cands.extend(list(legacy.glob("**/*.graphml")))
    cands.extend(list(wd.glob("*.graphml")))
    cands.extend(list(wd.glob("**/*.graphml")))

    # Only keep witnesses created during/after this stage run.
    out = [p for p in cands if p.is_file() and p.stat().st_mtime >= since_time]
    if not out:
        return None
    out.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return out[0]


def _normalize_witness_assignments(*, witness_text: str, base_bpl_text: str) -> Dict[str, str]:
    """
    Parse GraphML witness `lhs == rhs` assumptions and normalize RHS values to Boogie syntax.

    The output map only includes scalar global variables that have known types in `base_bpl_text`.
    """

    from dslc.toolchain.ultimate_witness import _normalize_rhs  # reuse witness parser helpers

    raw = _extract_witness_assignments(witness_text)
    if not raw:
        return {}

    # NOTE: this must use the Boogie-text parser from `ultimate_witness`, not the
    # `wraparound_analyze` helper (which expects a list of lines).
    from dslc.toolchain.ultimate_witness import _parse_global_var_types as _parse_global_var_types_text

    var_types = _parse_global_var_types_text(base_bpl_text)

    # Parse `const unique <name> : <type>;` so we can accept enum-like RHS values.
    const_types: Dict[str, str] = {}
    for ln in base_bpl_text.splitlines():
        ln = ln.strip()
        if not ln.startswith("const "):
            continue
        m = re.match(r"^const\s+(?:unique\s+)?(?P<name>\S+)\s*:\s*(?P<typ>[^;]+);", ln)
        if not m:
            continue
        const_types[m.group("name")] = m.group("typ").strip()

    out: Dict[str, str] = {}
    for var, rhs_raw in raw.items():
        typ = var_types.get(var)
        if not typ:
            continue
        # Skip arrays/maps; only keep scalar vars.
        if "[" in typ and "]" in typ:
            continue
        rhs = _normalize_rhs(rhs_raw.strip(), var_type=typ)
        if rhs is None:
            r = rhs_raw.strip()
            if re.match(r"^[A-Za-z_][A-Za-z0-9_.]*$", r) and const_types.get(r) == typ:
                rhs = r
        if rhs is None:
            continue
        if var not in out:
            out[var] = rhs
    return out


def _rank_refinement_lhs(lhs: str) -> Tuple[int, int, str]:
    """
    Priority order for refinement assumptions (lower is better).

    Goal: converge quickly on "shape" constraints that lock a stable path and index landing
    (e.g., DistCache P2C), rather than over-constraining unrelated env fields.
    """

    l = lhs.lower()
    # Table control and action selection are the most impactful for closure.
    if lhs.endswith(".action_run") or lhs.endswith(".hit"):
        return (0, 0, lhs)
    # Hash outputs / partition selection.
    if "hashval" in l or (("hash_" in l) and ("tbl" in l or "partition" in l)):
        return (1, 0, lhs)
    if "partition" in l:
        return (2, 0, lhs)
    # Index/cap-related knobs.
    if ("idx" in l) or ("index" in l) or ("cap" in l):
        return (3, 0, lhs)
    if "optype" in l:
        return (4, 0, lhs)
    # Default: env fields.
    return (9, 0, lhs)


def _select_refinement_assumes_from_witness_diff(
    *,
    confirm_witness_text: str,
    cex_witness_text: str,
    base_bpl_text: str,
    candidate: WraparoundCandidate,
    spec_model,
    max_new: int,
) -> List[str]:
    """
    CEGAR-style refinement for CLOSURE:

    Pick assumptions that are:
      - satisfied by the CONFIRM witness (so we preserve the already-found bug path), and
      - violated by the CLOSURE counterexample witness (so they block the non-closure behavior).

    This makes refinement P2C-aware without hardcoding DistCache-specific cases:
    it naturally prioritizes fixing the concrete path/shape decisions seen in CONFIRM.
    """

    max_new = max(0, int(max_new))
    if max_new <= 0:
        return []

    # Candidate pool: all witness-derived equalities we are willing to pin.
    confirm_assumes = _synthesize_refinement_assumes_from_witness(
        witness_text=confirm_witness_text,
        base_bpl_text=base_bpl_text,
        candidate=candidate,
        spec_model=spec_model,
    )
    if not confirm_assumes:
        return []

    cex_map = _normalize_witness_assignments(witness_text=cex_witness_text, base_bpl_text=base_bpl_text)
    if not cex_map:
        return []

    # Avoid pinning the pump target itself; closure needs to be universally quantified over seq0.
    forbid = {candidate.pump_reg, *list(candidate.accel_regs or ())}

    out: List[str] = []
    for aexpr in confirm_assumes:
        m = _RE_SIMPLE_EQ.match(aexpr.strip())
        if not m:
            continue
        lhs = m.group("lhs").strip()
        rhs = m.group("rhs").strip()
        if lhs in forbid:
            continue
        cex_rhs = cex_map.get(lhs)
        if cex_rhs is None:
            continue
        if cex_rhs != rhs:
            out.append(aexpr)

    out.sort(key=lambda e: _rank_refinement_lhs(_RE_SIMPLE_EQ.match(e).group("lhs")))  # type: ignore[union-attr]
    return out[:max_new]


def _synthesize_shape_assumes_from_witness(
    *,
    witness_text: str,
    base_bpl_text: str,
    candidate: WraparoundCandidate,
    spec_model,
) -> List[str]:
    """
    DistCache/P2C-aware refinement: infer stable hash/partition shapes and
    pin them as assumptions for closure.

    We focus on "shape" variables that tend to control DistCache behavior:
      - hash/partition helpers: *_meta.hashval_*, *_partition, *partition_id, *cap
      - table control variables: *_tbl_*.hit / *_tbl_*.action_run
      - action parameters that affect routing/landing: *_tbl_*.<action>.(eport|port|...)

    These are intentionally *under-approximating* constraints (sound for bug finding).
    In particular, we allow constraining table control vars even though they are not
    "environment inputs": in our Boogie encoding they are typically modeled via `havoc`
    inside table apply procedures, so pinning them can make closure proofs tractable
    while still representing a concrete execution.
    """

    from dslc.toolchain.ultimate_witness import _parse_global_var_types, _normalize_rhs

    wmap = _extract_witness_assignments(witness_text)
    if not wmap:
        return []

    # Collect candidate-scoped prefixes (e.g., clientTrack_*, leaf_*, spine_*).
    cand_vars = _collect_wraparound_candidate_vars(candidate)
    cand_node_prefixes = sorted({cv.split("_", 1)[0] for cv in cand_vars if "_" in cv and cv.split("_", 1)[0]})

    prefixes = list(_collect_env_input_prefixes(spec_model))
    # If spec_model parsing was unavailable/incomplete (e.g., unit tests), still allow
    # canonical multi-node prefixes derived from the candidate.
    for p in cand_node_prefixes:
        prefixes.extend([f"{p}_hdr.", f"{p}_meta.", f"{p}_standard_metadata."])
    allow_prefixes = tuple(sorted(set(prefixes)))

    var_types = _parse_global_var_types(base_bpl_text)
    # Parse `const unique <name> : <type>;` so we can accept enum-like RHS values.
    const_types: Dict[str, str] = {}
    for ln in base_bpl_text.splitlines():
        ln = ln.strip()
        if not ln.startswith("const "):
            continue
        m = re.match(r"^const\s+(?:unique\s+)?(?P<name>\S+)\s*:\s*(?P<typ>[^;]+);", ln)
        if not m:
            continue
        const_types[m.group("name")] = m.group("typ").strip()

    out: List[str] = []
    seen: set[str] = set()

    def _is_table_control_var(name: str) -> bool:
        return name.endswith(".hit") or name.endswith(".action_run")

    def _is_table_action_param_var(name: str) -> bool:
        # Examples:
        #   clientTrack_hash_leaf_partition_tbl_0.hash_leaf_partition.eport
        #   <node>_<tbl>.<action>.<param>
        if "_tbl_" not in name:
            return False
        parts = name.split(".")
        if len(parts) != 3:
            return False
        if "_tbl_" not in parts[0]:
            return False
        # Keep only parameters that are likely to influence routing / index landing.
        param = parts[2]
        return ("port" in param) or ("eport" in param) or ("idx" in param) or ("index" in param) or ("cap" in param)

    def _maybe_add(var: str, rhs_raw: str, *, allow_candidate_shape: bool) -> None:
        # Allow env-like prefixes always; additionally allow candidate-scoped "shape"
        # vars when they match our patterns (under-approx is sound for bug finding).
        if not any(var.startswith(p) for p in allow_prefixes):
            if not cand_node_prefixes:
                return
            if not var.startswith(tuple(f"{p}_" for p in cand_node_prefixes)):
                return
            if (not allow_candidate_shape) and (not (_is_table_control_var(var) or _is_table_action_param_var(var))):
                return
        typ = var_types.get(var)
        if not typ:
            return
        # Skip arrays; only allow scalar variables.
        if "[" in typ and "]" in typ:
            return
        rhs = _normalize_rhs(rhs_raw, var_type=typ)
        if rhs is None:
            # Enum-like RHS values often appear as `SomeType.SomeCtor` in witnesses.
            # Accept them if they are declared as a Boogie constant of the right type.
            r = rhs_raw.strip()
            if re.match(r"^[A-Za-z_][A-Za-z0-9_.]*$", r) and const_types.get(r) == typ:
                rhs = r
        if rhs is None:
            return
        expr = f"{var} == {rhs}"
        if expr in seen:
            return
        seen.add(expr)
        out.append(expr)

    # Heuristic patterns for DistCache P2C-like shapes.
    #
    # Keep these broad: we only add constraints that also pass the type checks above.
    patterns = (
        "hashval_",
        "hash_for_",
        "hash_",
        "partition",
        "partition_id",
        "inswitch_hdr.idx",
        "cap",
        "optype",
        "is_spine",
        "is_leaf",
        "poweroftwochoice_tbl_",
        "hash_for_partition_tbl",
        "hash_leaf_partition_tbl",
        "hash_spine_partition_tbl",
    )

    for var, rhs in wmap.items():
        is_tbl = _is_table_control_var(var) or _is_table_action_param_var(var)
        is_pat = any(pat in var for pat in patterns)
        if is_tbl or is_pat:
            _maybe_add(var, rhs, allow_candidate_shape=is_pat)

    return out


def _synthesize_refinement_assumes_from_witness(
    *,
    witness_text: str,
    base_bpl_text: str,
    candidate: WraparoundCandidate,
    spec_model,
) -> List[str]:
    """
    Witness-seeded refinement for wraparound CEGIS.

    We combine two sources:
      1) input/profile constraints on env-like variables (hdr/meta/standard_metadata),
      2) P2C/DistCache "shape" constraints (hash/partition/table control/action params).

    This function is intentionally under-approximating: it only adds assumptions that
    appear as equalities in a concrete witness, so it cannot introduce behaviors that
    were not already feasible under the current CEGIS attempt.
    """

    try:
        wa = extract_assumptions_from_graphml(witness_text)
    except Exception:
        wa = []

    env_assumes: List[str] = []
    if wa:
        try:
            env_assumes = synthesize_boogie_assumes(
                witness_assumptions=wa,
                base_bpl_text=base_bpl_text,
                allow_prefixes=_collect_env_input_prefixes(spec_model),
                allow_vars=_collect_wraparound_candidate_vars(candidate),
            )
        except Exception:
            env_assumes = []

    try:
        shape_assumes = _synthesize_shape_assumes_from_witness(
            witness_text=witness_text,
            base_bpl_text=base_bpl_text,
            candidate=candidate,
            spec_model=spec_model,
        )
    except Exception:
        shape_assumes = []

    out: List[str] = []
    seen: set[str] = set()
    for aexpr in list(env_assumes) + list(shape_assumes):
        if aexpr in seen:
            continue
        seen.add(aexpr)
        out.append(aexpr)
    return out


def _unroll_confirm_like_mainprocedure(
    *,
    bpl_text: str,
    requested_steps: int,
    deterministic_period: Optional[int],
) -> Tuple[str, int]:
    """
    Unroll `mainProcedure` for a "confirm-like" stage (CONFIRM/ENABLE_CHECK).

    Important subtlety: in the sequential harness with `deterministic_scheduler=true`,
    one logical external input + node processing "round" may require multiple scheduler
    steps (phases). The user's `requested_steps` is specified in *round* units, but
    `unroll_mainprocedure_loop_text()` operates on the low-level scheduler loop body.

    We therefore scale the unroll bound by the inferred deterministic scheduler period
    when available, and opportunistically inline the round-robin dispatcher to reduce
    solver load.
    """

    req = max(1, int(requested_steps))
    steps = req
    if deterministic_period is not None and deterministic_period > 0:
        steps = req * deterministic_period

    txt = unroll_mainprocedure_loop_text(bpl_text=bpl_text, steps=steps)

    # Optional post-processing: inline deterministic phases and eliminate heavy forall inits.
    lines = txt.splitlines(keepends=True)
    no_nl = [ln.rstrip("\n") for ln in lines]
    has_sched_proc = any(_RE_PROC_SCHED.match(ln.strip()) for ln in no_nl)
    if deterministic_period is not None and has_sched_proc:
        try:
            _inline_deterministic_round_into_mainprocedure(lines, period=deterministic_period, steps=steps)
        except Exception:
            # Best-effort: inlining is a performance optimization only.
            pass

    return "".join(lines), steps


class StageRunner(Protocol):
    """
    Runner interface for solver stages.

    This indirection makes the CEGIS loop unit-testable (mockable) without requiring
    Ultimate to be installed/runnable in the test environment.
    """

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> "StageRunResult": ...


@dataclass(frozen=True)
class StageRunResult:
    stage: str
    returncode: int
    wall_time_s: float
    result_line: Optional[str]

    @property
    def is_unknown(self) -> bool:
        """
        True when we could not classify the run as SAFE/UNSAFE.

        Typical causes:
          - Ultimate timed out / crashed (no RESULT line),
          - toolchain printed no recognizable result marker.
        """

        return (not self.is_safe) and (not self.is_unsafe)

    @property
    def timed_out(self) -> bool:
        """
        Best-effort timeout detection.

        We commonly run Ultimate under the external `timeout` wrapper, which
        returns 124 on timeout and 137 if killed (SIGKILL).
        """

        if self.returncode in (124, 137):
            return True
        # Ultimate can also exit with 0 but still report a timeout in its RESULT line.
        # We treat this as a timeout for refinement/certification logic.
        if self.result_line and "timeout" in self.result_line.lower():
            return True
        return False

    @property
    def is_safe(self) -> bool:
        if not self.result_line:
            return False
        s = self.result_line.lower()
        return ("result: safe" in s) or ("proved your program to be correct" in s)

    @property
    def is_unsafe(self) -> bool:
        if not self.result_line:
            return False
        s = self.result_line.lower()
        return ("result: unsafe" in s) or ("proved your program to be incorrect" in s)


def _select_stage_result_line(
    *,
    killed_early: bool,
    observed_result_line: Optional[str],
    final_result_line: Optional[str],
) -> Optional[str]:
    """
    Choose a stable semantic stage result line.

    Rationale:
    - Some Ultimate toolchains can keep running (post-processing) after reaching SAFE/UNSAFE.
    - When we early-stop, Ultimate may log a synthetic Timeout/Cancel RESULT line due to SIGTERM.
      In that case the "observed" SAFE/UNSAFE is the semantic result we intentionally stopped on.
    """

    if killed_early and observed_result_line:
        return observed_result_line
    return final_result_line


def _extract_result_line(log_text: str) -> Optional[str]:
    lines = log_text.splitlines()

    # Prefer explicit top-level RESULT markers when available.
    #
    # Rationale: Ultimate may emit intermediate "Registering result SAFE ..." lines for
    # error locations but still end the run with an explicit Timeout/Unknown. Treating
    # such runs as SAFE is unsafe for regression tracking (it can hide real bugs).
    last_result: Optional[str] = None
    for line in lines:
        if "RESULT:" in line:
            last_result = line.strip()

    # UNSAFE always wins (even if later timeouts happen).
    re_remaining = re.compile(
        r"Registering result (SAFE|UNSAFE) .*\((?P<rem>\d+) of (?P<tot>\d+) remaining\)"
    )
    for line in lines:
        if "Registering result UNSAFE" in line:
            return "RESULT: UNSAFE"

    # If Ultimate printed a RESULT marker, trust it.
    if last_result is not None:
        return last_result

    # Otherwise, fall back to SAFE when all error locations are resolved.
    #
    # IMPORTANT: safe registration is only meaningful when Ultimate indicates
    # "(0 of N remaining)".
    for line in lines:
        m = re_remaining.search(line)
        if not m:
            continue
        if m.group(1) != "SAFE":
            continue
        if int(m.group("rem")) == 0:
            return "RESULT: SAFE"

    return None


def _default_toolchain_paths(*, root: Path, ultimate_xmx_gb: int = 0) -> Tuple[Path, Path, Path, Path, Path, Path]:
    """
    Best-effort defaults that work for both in-repo toolchains and legacy Procurator paths.
    """

    # Toolchains.
    # Default to the reachability-safety toolchains (TraceAbstraction).
    #
    # Important for sound bug finding: some Ultimate toolchains focus on termination
    # or other analyses and can print "proved your program to be correct" even when
    # assertions are not treated as reachability properties under our harness.
    tc_no_witness = (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety.xml").resolve()
    tc_witness = (root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-Witness.xml").resolve()
    tc_legacy_witness = (root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml").resolve()

    # IMPORTANT: some Ultimate releases crash in the witness printer when the result is SAFE.
    # We therefore default CEGIS stages to the non-witness toolchain and only re-run with
    # witness enabled when we actually need a witness (i.e., on UNSAFE for refinement).
    toolchain_nowitness = tc_no_witness if tc_no_witness.exists() else tc_legacy_witness
    toolchain_witness = tc_witness if tc_witness.exists() else tc_legacy_witness

    tc_closure = root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-ReachSafety.xml"
    closure_toolchain = tc_closure.resolve() if tc_closure.exists() else toolchain_nowitness

    # Settings.
    #
    # For performance and robustness, we default ENTRY/CLOSURE/CONFIRM to a *non-witness*
    # settings profile. We only enable witness printing when we explicitly re-run CONFIRM
    # for CEGIS refinement.
    #
    # Policy (NSDI/CEGIS workflow):
    #   - ENTRY/CONFIRM are existential checks; prioritize fast bug finding => GemCutter-style profiles.
    #   - CLOSURE is a proof obligation; we may choose a more proof-oriented profile below.
    # WSL safety: prefer the ~2GB Z3 settings profiles by default. Larger profiles
    # (8-12GB `-memory:`) can OOM the VM even if Ultimate's JVM heap is bounded.
    settings_candidates = [
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-no-por.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-internal.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-internal-no-por.epf",
        # Higher-memory fallbacks (opt-in via --closure-settings/--settings in callers).
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-12g.epf",
        # Proof-oriented fallback.
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-BuchiAutomizer-12g.epf",
    ]
    settings_nowitness = next((p for p in settings_candidates if p.exists()), settings_candidates[0])
    settings_nowitness_legacy = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL.epf"
    )
    settings_nowitness = settings_nowitness if settings_nowitness.exists() else settings_nowitness_legacy

    # Witness printing is controlled by the toolchain; re-use the same settings profile by default.
    settings_witness_candidates = [
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-witness.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-internal-witness.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g-witness.epf",
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-12g-witness.epf",
        # Last resort: proof-oriented profile (witness printer might still crash on SAFE).
        root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-BuchiAutomizer-12g.epf",
    ]
    settings_witness = next((p for p in settings_witness_candidates if p.exists()), settings_witness_candidates[0])
    settings_witness_legacy = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    )
    settings_witness = settings_witness if settings_witness.exists() else settings_witness_legacy

    closure_settings = root / "dslc" / "toolchain" / "ultimate" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
    closure_settings_legacy = root / "Procurator" / "argo" / "code" / "spec" / "config" / "ClosureCheck-32bit-GemCutter-ALL-witness.epf"
    closure_settings = closure_settings if closure_settings.exists() else closure_settings_legacy
    if not closure_settings.exists():
        xmx = int(ultimate_xmx_gb) if ultimate_xmx_gb else 0
        allow_high_mem = xmx >= 8

        # Prefer a closure-friendly settings profile when available.
        #
        # Closure checks are often proof-heavy; disabling POR and using smaller blocks
        # can reduce overhead. In practice, we also want to avoid solver-internal
        # timeouts during long closure proofs (e.g., NetChain/DistCache), so prefer
        # the "noz3timeout" profiles when available.
        candidates = []
        if allow_high_mem:
            # Prefer robust "noz3timeout" profiles first: they tend to make closure
            # certification much more stable than the strict low-memory defaults.
            candidates.extend(
                [
                    root
                    / "dslc"
                    / "toolchain"
                    / "ultimate"
                    / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf",
                    root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf",
                ]
            )

        # Low-memory fallbacks (WSL safety): prefer these by default.
        candidates.extend(
            [
                root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-no-por.epf",
                root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL.epf",
            ]
        )

        if allow_high_mem:
            # Higher-memory fallbacks (use explicitly on machines that can handle it).
            candidates.extend(
                [
                    root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-12g-smallblocks.epf",
                    # Fallback: proof-oriented Automizer/TraceAbstraction profile.
                    root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-BuchiAutomizer-12g.epf",
                ]
            )
        closure_settings = next((p for p in candidates if p.exists()), settings_nowitness)

    if not settings_nowitness.exists():
        # This should not happen in-repo, but keep a reasonable fallback to avoid crashing.
        settings_nowitness = settings_witness

    return (
        toolchain_nowitness,
        toolchain_witness,
        closure_toolchain.resolve(),
        settings_nowitness.resolve(),
        settings_witness.resolve(),
        closure_settings.resolve(),
    )


@dataclass(frozen=True)
class CegisAttemptConfig:
    attempt: int
    pump_reg: str
    accel_regs: Tuple[str, ...]
    index_value: int
    index_expr: Optional[str]
    proj_vars: Tuple[str, ...]
    cutpoint_cond: Optional[str]
    step_op: str
    step_delta: int
    # CEGIS-synthesized constraints used for *CLOSURE only* (Boogie expressions).
    #
    # ENTRY/CONFIRM are existential checks and must be run under the original environment;
    # refinement assumptions are applied only to CLOSURE (seeded from a concrete CONFIRM witness).
    closure_assumes: Tuple[str, ...] = ()
    notes: Tuple[str, ...] = ()


@dataclass(frozen=True)
class CegisAttemptArtifacts:
    entry_bpl: str
    closure_bpl: str
    confirm_bpl: str
    entry_log: str
    closure_log: str
    confirm_log: str
    # Optional retry log for closure_check when we re-run it with a larger timeout.
    closure_log_retry: str = ""
    # Optional artifacts for the pump-enable (reach `target != MAX`) refinement.
    enable_bpl: str = ""
    enable_log: str = ""


@dataclass(frozen=True)
class CegisAttemptRecord:
    cfg: CegisAttemptConfig
    artifacts: CegisAttemptArtifacts
    entry: Optional[StageRunResult]
    closure: Optional[StageRunResult]
    # Optional second closure attempt (e.g. full-timeout retry after a capped run).
    # Kept for reproducibility/debugging; not part of the certification predicate.
    closure_retry: Optional[StageRunResult] = None
    confirm: Optional[StageRunResult] = None


@dataclass(frozen=True)
class CegisManifest:
    spec: str
    base_bpl: str
    work_dir: str
    # Full candidate information for reproducibility (e.g., pump_reg/index/step/proj/cutpoint).
    # Keep `candidate_reason` as a human-readable summary for grep-friendly manifests.
    candidate: dict
    candidate_reason: str
    attempts: List[CegisAttemptRecord]


def _write_manifest(*, out_dir: Path, spec_path: Path, base_bpl: Path, work_dir: Path, cand: WraparoundCandidate, attempts: List[CegisAttemptRecord]) -> Path:
    """
    Write the current CEGIS manifest (incremental).

    We write after each attempt so an interrupted run still leaves a reproducible
    record of what was tried and which artifacts/logs were produced.
    """

    manifest = CegisManifest(
        spec=str(spec_path),
        base_bpl=str(base_bpl),
        work_dir=str(work_dir),
        candidate=asdict(cand),
        candidate_reason=cand.reason,
        attempts=attempts,
    )
    manifest_path = out_dir / "wraparound.cegis.manifest.json"
    manifest_path.write_text(json.dumps(asdict(manifest), indent=2, sort_keys=True), encoding="utf-8")
    return manifest_path


class UltimateStageRunner:
    def __init__(self, *, ultimate: Path, xmx_gb: int = 6) -> None:
        self._ultimate = ultimate
        self._xmx_gb = max(1, int(xmx_gb))

    def run(
        self,
        *,
        stage: str,
        input_bpl: Path,
        log_path: Path,
        ultimate_home: Path,
        toolchain: Path,
        settings: Path,
        timeout_seconds: int,
        resource_limits: bool,
    ) -> StageRunResult:
        # Keep some progress visible on stdout. Ultimate itself writes to log_path.
        # This also makes E2E runs (dslc/bench/run_e2e_ablations.py) easier to monitor.
        print(
            f"[WRAP] stage={stage} input={input_bpl.name} timeout_s={timeout_seconds} toolchain={toolchain.name} settings={settings.name}",
            flush=True,
        )
        start = time.time()
        os_timeout = timeout_seconds + 60 if timeout_seconds > 0 else 0
        spawn = run_ultimate(
            ultimate=self._ultimate,
            toolchain=toolchain,
            settings=settings,
            input_bpl=input_bpl,
            log_path=log_path,
            ultimate_home=ultimate_home,
            toolchain_timeout_seconds=timeout_seconds,
            os_timeout_seconds=os_timeout,
            cwd=log_path.parent,
            async_run=True,
            resource_limits=resource_limits,
            launcher_xmx_gb=self._xmx_gb,
        )

        if spawn.pid is None:
            raise WraparoundCegisError(f"internal error: async Ultimate run did not return a pid (stage={stage})")

        pid = int(spawn.pid)
        rc: Optional[int] = None
        killed_early = False
        observed_result_line: Optional[str] = None

        def _witness_required_on_unsafe(st: str) -> bool:
            # For wraparound CEGIS, we only need a witness to seed closure refinements.
            # Entry/closure are feasibility/proof obligations that do not require witnesses.
            if st == "confirm":
                return True
            if st.startswith("confirm.witness."):
                return True
            if st.startswith("closure_check.witness."):
                return True
            if st.startswith("enable_check"):
                return True
            return False

        need_witness = _witness_required_on_unsafe(stage)

        def _stage_witness_path() -> Path:
            # Ultimate's witness printer typically emits "<input>.bpl-witness.graphml"
            # next to the input. Prefer this deterministic path to avoid confusing
            # older stage witnesses in the same directory (mtime resolution on /mnt
            # can be coarse and cause false positives).
            return log_path.parent / f"{input_bpl.name}-witness.graphml"

        # Early-stop policy:
        # - Some Ultimate toolchains keep running (post-processing) after they already
        #   registered SAFE/UNSAFE. This makes runs look "hung" and regresses throughput.
        # - For witness-producing stages, only stop once a GraphML witness exists.
        while True:
            try:
                wpid, status = os.waitpid(pid, os.WNOHANG)
            except ChildProcessError:
                # Already reaped.
                wpid, status = (pid, 0)
            if wpid == pid:
                # Finished naturally (or already reaped).
                if os.WIFEXITED(status):
                    rc = int(os.WEXITSTATUS(status))
                elif os.WIFSIGNALED(status):
                    rc = -int(os.WTERMSIG(status))
                else:
                    rc = 0
                break

            tail = _read_tail_text(log_path)
            res_line = ultimate_extract_result_line(tail) if tail else None
            if res_line == "RESULT: SAFE":
                killed_early = True
                observed_result_line = res_line
            elif res_line == "RESULT: UNSAFE":
                if not need_witness:
                    killed_early = True
                    observed_result_line = res_line
                else:
                    # Only stop when the witness for *this input* has been written.
                    # Do not use a "latest witness in dir" heuristic: entry/closure
                    # stages can leave witnesses behind, and timestamp resolution on
                    # Windows-backed file systems can make them look "newer".
                    wit = _stage_witness_path()
                    if wit.exists():
                        killed_early = True
                        observed_result_line = res_line

            if killed_early:
                # run_ultimate() starts Ultimate in its own session (start_new_session=True),
                # so killpg(pid) is safe and terminates the whole process tree.
                try:
                    os.killpg(pid, signal.SIGTERM)
                except ProcessLookupError:
                    pass

                # Give it a moment to exit cleanly; then SIGKILL.
                t_kill = time.time()
                while time.time() - t_kill < 5.0:
                    try:
                        wpid2, _status2 = os.waitpid(pid, os.WNOHANG)
                    except ChildProcessError:
                        wpid2 = pid
                    if wpid2 == pid:
                        break
                    time.sleep(0.05)
                else:
                    try:
                        os.killpg(pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
                    try:
                        os.waitpid(pid, 0)
                    except ChildProcessError:
                        pass

                # Treat early-stop as a successful run; the semantic result is in the log.
                rc = 0
                break

            time.sleep(0.5)

        wall = time.time() - start
        txt = log_path.read_text(encoding="utf-8", errors="replace")
        final_line = ultimate_extract_result_line(txt)

        effective_line = _select_stage_result_line(
            killed_early=killed_early,
            observed_result_line=observed_result_line,
            final_result_line=final_line,
        )
        out = StageRunResult(stage=stage, returncode=int(rc or 0), wall_time_s=wall, result_line=effective_line)
        print(
            f"[WRAP] stage={stage} rc={out.returncode} early_stop={str(killed_early).lower()} "
            f"result={out.result_line or 'RESULT: <missing>'} wall_s={out.wall_time_s:.1f}",
            flush=True,
        )
        if killed_early and final_line and (final_line != effective_line):
            print(f"[WRAP] stage={stage} early_stop_note: log ended with {final_line!r}", flush=True)
        return out


def _is_distcache_like(spec_text: str) -> bool:
    """
    Best-effort classifier for DistCache-style specs.

    We purposely keep this broad: DistCache specs do not necessarily mention
    concrete table names, but they typically mention DistCache-specific meta
    fields (hashval_for_partition / hashval_for_spine_partition) and/or import
    paths containing "distcache".
    """

    lo = spec_text.lower()
    if "distcache" in lo:
        return True
    # Meta fields used in clientTrack/leaf DistCache pipelines.
    if "hashval_for_partition" in spec_text or "hashval_for_spine_partition" in spec_text:
        return True
    # Table names appear in some specs as comments/explanations.
    if ("hash_leaf_partition_tbl" in spec_text) or ("hash_spine_partition_tbl" in spec_text):
        return True
    return False


_RE_PROP_IMPORT_ENTRIES = re.compile(r"\bentries\s+\"([^\"]+)\"\s*;", flags=re.MULTILINE)
_RE_BMV2_TABLE_ADD_RANGE = re.compile(
    r"^\s*table_add\s+(?P<table>\S+)\s+\S+\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<lo>0x[0-9a-fA-F]+)->(?P<hi>0x[0-9a-fA-F]+)\s+=>",
    flags=re.MULTILINE,
)
_RE_BMV2_TABLE_ADD_RANGE_EPORT = re.compile(
    # Some entries include additional action args after the egress port (e.g., "=> 0x480 4").
    # We only need the first hex token after "=>".
    r"^\s*table_add\s+(?P<table>\S+)\s+\S+\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<lo>0x[0-9a-fA-F]+)->(?P<hi>0x[0-9a-fA-F]+)\s+=>\s*(?P<eport>0x[0-9a-fA-F]+)\b",
    flags=re.MULTILINE,
)

_RE_BMV2_CACHE_LOOKUP_IDX = re.compile(
    r"^\s*table_add\s+cache_lookup_tbl\s+cached_action\b.*=>\s*(?P<idx>\d+)\b",
    flags=re.MULTILINE,
)

_RE_BMV2_ACCESS_CACHE_FREQUENCY = re.compile(
    r"^\s*table_add\s+access_cache_frequency_tbl\s+(?P<action>\S+)\s+(?P<optype>0x[0-9a-fA-F]+)\s+(?P<is_sampled>0x[0-9a-fA-F]+)\s+(?P<is_cached>0x[0-9a-fA-F]+)\s+(?P<is_latest>0x[0-9a-fA-F]+)\s*=>",
    flags=re.MULTILINE,
)


def _infer_distcache_hash_caps(spec_text: str, *, spec_dir: Path) -> Dict[str, int]:
    caps: Dict[str, int] = {}
    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in _RE_BMV2_TABLE_ADD_RANGE.finditer(txt):
            table = m.group("table")
            hi = int(m.group("hi"), 16)
            if "hash_leaf_partition_tbl" in table:
                caps["hashval_for_partition"] = max(caps.get("hashval_for_partition", -1), hi)
            if "hash_spine_partition_tbl" in table:
                caps["hashval_for_spine_partition"] = max(caps.get("hashval_for_spine_partition", -1), hi)
    return {k: v for k, v in caps.items() if v >= 0}


def _infer_distcache_partition_eports(spec_text: str, *, spec_dir: Path) -> Dict[str, int]:
    ports: Dict[str, int] = {}
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


def _infer_distcache_cache_lookup_idx(spec_text: str, *, spec_dir: Path) -> Optional[int]:
    """
    Infer the (cached) key -> idx mapping from BMv2 control-plane entries.

    This is DistCache-specific: some functional wraparound bugs (e.g., cache_frequency)
    update a particular counter cell selected by `inswitch_hdr.idx`. If `idx` is left
    symbolic, CONFIRM often times out (array + table branching). Pinning it to the
    configured cached cell (from `cache_lookup_tbl`) can dramatically reduce solver work.
    """

    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        m = _RE_BMV2_CACHE_LOOKUP_IDX.search(txt)
        if not m:
            continue
        try:
            return int(m.group("idx"))
        except Exception:
            continue
    return None


def _infer_distcache_cache_frequency_update_profile(spec_text: str, *, spec_dir: Path) -> Dict[str, int]:
    """
    Infer the access_cache_frequency_tbl match pattern for update_cache_frequency.

    We prefer the non-sampled update rule (is_sampled=0) when multiple update rules exist.
    """

    best: Optional[Dict[str, int]] = None
    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in _RE_BMV2_ACCESS_CACHE_FREQUENCY.finditer(txt):
            if m.group("action") != "update_cache_frequency":
                continue
            try:
                optype = int(m.group("optype"), 16)
                is_sampled = int(m.group("is_sampled"), 16)
                is_cached = int(m.group("is_cached"), 16)
                is_latest = int(m.group("is_latest"), 16)
            except Exception:
                continue
            cand = {
                "optype": optype,
                "is_sampled": is_sampled,
                "is_cached": is_cached,
                "is_latest": is_latest,
            }
            # Prefer the "no-sample" update rule; otherwise keep the first seen.
            if best is None or (best.get("is_sampled") != 0 and is_sampled == 0):
                best = cand
    return best or {}


def _infer_distcache_cache_frequency_get_optype(
    spec_text: str, *, spec_dir: Path, is_sampled: Optional[int] = None, is_cached: Optional[int] = None, is_latest: Optional[int] = None
) -> Optional[int]:
    """
    Infer the `get_cache_frequency` optype (typically 0x24) from BMv2 entries.

    If match flags are provided, we prefer a get entry with the same
    (is_sampled, is_cached, is_latest) tuple so that a single stable input
    shape can drive both pump and query packets.
    """

    entries_paths = [m.group(1) for m in _RE_PROP_IMPORT_ENTRIES.finditer(spec_text)]
    fallback: Optional[int] = None
    for rel in entries_paths:
        p = (spec_dir / rel).resolve()
        if not p.exists():
            continue
        txt = p.read_text(encoding="utf-8", errors="replace")
        for m in _RE_BMV2_ACCESS_CACHE_FREQUENCY.finditer(txt):
            if m.group("action") != "get_cache_frequency":
                continue
            try:
                optype = int(m.group("optype"), 16)
                samp = int(m.group("is_sampled"), 16)
                cach = int(m.group("is_cached"), 16)
                lat = int(m.group("is_latest"), 16)
            except Exception:
                continue
            if fallback is None:
                fallback = optype
            if is_sampled is None or is_cached is None or is_latest is None:
                return optype
            if samp == int(is_sampled) and cach == int(is_cached) and lat == int(is_latest):
                return optype
    return fallback


def _apply_hash_caps_to_bpl(bpl_text: str, *, node_prefixes: Sequence[str], caps: Dict[str, int]) -> str:
    if not caps:
        return bpl_text

    lines = bpl_text.splitlines(keepends=True)
    wanted: List[Tuple[str, int]] = []
    for suffix, cap in caps.items():
        for pref in node_prefixes:
            wanted.append((f"{pref}_meta.{suffix}", cap))

    out_lines: List[str] = []
    havoc_re = re.compile(r"^(?P<indent>\s*)havoc\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*;\s*$")
    for line in lines:
        out_lines.append(line)

        # Constrain havoc'd hash outputs to the configured range-table domain.
        #
        # Motivation (bug-finding, not proof): DistCache models hash as `havoc` in Boogie.
        # If it escapes the configured key domain (e.g., 0..15), downstream range tables
        # may miss and leave indices unconstrained, which can make wraparound CONFIRM
        # spuriously SAFE (the pumped cell never updates, so assertions stay gated off).
        mh = havoc_re.match(line.rstrip("\n"))
        if mh:
            name = mh.group("name")
            for var, cap in wanted:
                if name != var:
                    continue
                indent = mh.group("indent")
                # Use unsigned comparisons consistent with P4B's helpers.
                out_lines.append(f"{indent}assume(buge.bv16({var}, 0bv16));\n")
                out_lines.append(f"{indent}assume(bule.bv16({var}, {cap}bv16));\n")
                break

        stripped = line.strip()
        if not stripped.startswith("assume("):
            continue
        if "buge.bv" not in stripped or "bule.bv" not in stripped:
            continue
        for var, cap in wanted:
            if var not in stripped:
                continue
            m = re.search(r"buge\.bv(\d+)\(", stripped)
            if not m:
                continue
            bv = m.group(1)
            indent = re.match(r"^[ \t]*", line).group(0)  # type: ignore[union-attr]
            out_lines.append(f"{indent}assume(bule.bv{bv}({var}, {cap}bv{bv}));\n")
            break

    return "".join(out_lines)


def _refine_proj_vars_greedy(
    proj_vars: List[str],
    *,
    mandatory: Sequence[str],
    max_drops: int,
) -> List[str]:
    """
    Simple, predictable refinement: drop at most `max_drops` non-mandatory vars.

    This is intentionally conservative; we can upgrade to ddmin later if needed.
    """

    mandatory_set = set(mandatory)

    def _noise_rank(v: str) -> Tuple[int, int]:
        """
        Lower rank = drop earlier.

        Heuristic:
          - Packet-local meta/hash/index values tend to break closure and add SMT noise.
          - Inbox/egress counts can matter for scheduler/queue stability, but we allow
            dropping them if needed to make progress. We therefore drop them late.
        """

        low = v.lower()
        noisy = 0
        if "hash" in low:
            noisy = -3
        elif "switchidx" in low or low.endswith("idx") or ".idx" in low:
            noisy = -2
        elif "inbox_count" in low or "egress_count" in low:
            noisy = 3
        elif "tmp" in low or "scratch" in low:
            noisy = -1
        # Prefer dropping meta.* over other namespaces.
        ns = 0
        if "_meta." in v or v.startswith("meta."):
            ns = -1
        return (noisy, ns)

    out = list(proj_vars)
    # Choose a deterministic drop order to keep manifests stable.
    candidates = [v for v in out if v not in mandatory_set]
    candidates.sort(key=_noise_rank)

    drops = 0
    for v in candidates:
        if drops >= max_drops:
            break
        try:
            out.remove(v)
        except ValueError:
            continue
        drops += 1
    return out


def _confirm_unroll_schedule(*, base: int, max_unroll: int) -> List[int]:
    """
    Generate a small, deterministic unroll schedule for CONFIRM.

    Motivation: some wraparound bugs require a slightly longer suffix than the
    default bound (e.g., P2C after overflow). We first try the base bound for
    speed, then grow it a few times before giving up on this candidate.
    """

    b = max(1, int(base))
    cap = max(b, int(max_unroll))
    # Additive growth:
    # - Our deterministic two-phase harness typically needs a few extra "actor steps"
    #   to accommodate an additional injected packet / pass.
    # - Multiplying the bound (e.g., 6 -> 12 -> 24) can easily overshoot into a much
    #   harder search (or timeout) before we tried the next meaningful small bound.
    #
    # We keep the schedule short and align to common "one more packet/round" increments.
    out: List[int] = []
    for inc in (0, 1, 2, 4):
        v = min(cap, b + inc)
        if v not in out:
            out.append(v)
    return out


def run_wraparound_cegis(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Optional[Path],
    ultimate: Path,
    candidate: Optional[WraparoundCandidate] = None,
    timeout_seconds: int = 1200,
    # If >0, cap each closure_check attempt to this timeout (seconds).
    #
    # Default: 0 (no cap). This avoids interrupting a long-running proof attempt
    # that might succeed with a larger budget.
    closure_timeout_cap_seconds: int = 0,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    confirm_unroll: int = 3,
    # 0 => do not grow (single confirm).
    max_confirm_unroll: int = 0,
    max_iters: int = 6,
    # Heuristic refinement: if CONFIRM times out, under-approximate env by zeroing unassigned inputs.
    enable_env_completion_refinement: bool = True,
    # Default order for the standalone wraparound workflow.
    stage_order: str = "entry_confirm_closure",
    # Auto mode policy: require P4B monotone-update meta when inferring candidates from global asserts.
    require_meta_step_for_global_asserts: bool = False,
    runner: Optional[StageRunner] = None,
    # Toolchain selection:
    #   - toolchain_nowitness: used by default for ENTRY/CONFIRM to avoid witness-printer crashes on SAFE.
    #   - toolchain_witness: used only when we need a witness (CEGIS refinement).
    toolchain: Optional[Path] = None,
    witness_toolchain: Optional[Path] = None,
    closure_toolchain: Optional[Path] = None,
    settings: Optional[Path] = None,
    closure_settings: Optional[Path] = None,
) -> Path:
    """
    Iterative wraparound CEGIS loop for sound bug finding.

    We support multiple stage orders:

      - entry_closure_confirm (default): ENTRY -> CLOSURE -> CONFIRM
        Useful when you expect closure to hold and want to gate confirm on a
        proven pump summary.

      - entry_confirm_closure: ENTRY -> CONFIRM -> CLOSURE
        Recommended when integrating wraparound into the main verification
        pipeline: if CONFIRM does not find a bug, CLOSURE is wasted work.

    Refinement (when closure_check is not SAFE):
      - distcache-specific index stabilization (index_expr -> constant eport), if applicable;
      - witness-guided refinement when closure_check is UNSAFE (add assumptions that
        preserve the seeded CONFIRM witness but block the closure counterexample).

    All artifacts and outcomes are recorded into `wraparound.cegis.manifest.json`.
    """

    spec_path = spec_path.resolve()
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    work_dir = out_dir / "work"
    base_bpl = out_dir / f"{spec_path.stem}.base.bpl"

    # 1) Compile base model (sequential harness; deterministic scheduler expected for closure/entry).
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=enable_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=pipeline_two_stage,
    )

    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")

    # 2) P4B meta is an optimization input; tolerate missing meta files.
    meta_by_node: Dict[str, dict] = {}
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            meta_by_node[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue

    # 3) DistCache stabilization: hash caps and constant partition eports.
    partition_ports: Dict[str, int] = {}
    if _is_distcache_like(spec_text):
        caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
        if caps:
            node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
            patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=caps)
            if patched != base_text:
                base_text = patched
                base_bpl.write_text(base_text, encoding="utf-8")
        partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

    # 4) Infer candidates from spec/meta unless caller provided an explicit candidate.
    if candidate is None:
        cands = infer_wraparound_candidates(
            spec_text=spec_text,
            bpl_text=base_text,
            meta_by_node=meta_by_node,
            require_meta_step_for_global_asserts=require_meta_step_for_global_asserts,
        )
        if not cands:
            raise WraparoundCegisError("failed to infer wraparound candidates; pass a spec that exposes a counter update")
        cand = cands[0]
    else:
        cand = candidate

    # 5) Resolve defaults for solver toolchains/settings.
    root = repo_root()
    tc_nowit_def, tc_wit_def, tc_cl_def, st_nowit_def, st_wit_def, st_cl_def = _default_toolchain_paths(
        root=root, ultimate_xmx_gb=0
    )
    toolchain_nowitness = (toolchain or tc_nowit_def).resolve()
    toolchain_witness = (witness_toolchain or tc_wit_def).resolve()
    closure_toolchain = (closure_toolchain or tc_cl_def).resolve()
    settings = (settings or st_nowit_def).resolve()
    witness_settings = st_wit_def.resolve()
    closure_settings = (closure_settings or st_cl_def).resolve()

    runner = runner or UltimateStageRunner(ultimate=ultimate)

    manifest_path = _run_cegis_loop(
        spec_path=spec_path,
        spec_text=spec_text,
        base_bpl=base_bpl,
        base_text=base_text,
        out_dir=out_dir,
        work_dir=work_dir,
        candidate=cand,
        partition_ports=partition_ports,
        timeout_seconds=timeout_seconds,
        closure_timeout_cap_seconds=closure_timeout_cap_seconds,
        resource_limits=resource_limits,
        confirm_unroll=confirm_unroll,
        max_confirm_unroll=max_confirm_unroll,
        max_iters=max_iters,
        enable_env_completion_refinement=enable_env_completion_refinement,
        runner=runner,
        toolchain_nowitness=toolchain_nowitness,
        toolchain_witness=toolchain_witness,
        witness_settings=witness_settings,
        closure_toolchain=closure_toolchain,
        settings=settings,
        closure_settings=closure_settings,
        confirm_settings_fallback=None,
        stage_order=stage_order,
    )
    return manifest_path


def _run_cegis_loop(
    *,
    spec_path: Path,
    spec_text: str,
    base_bpl: Path,
    base_text: str,
    out_dir: Path,
    work_dir: Path,
    candidate: WraparoundCandidate,
    partition_ports: Dict[str, int],
    timeout_seconds: int,
    closure_timeout_cap_seconds: int,
    resource_limits: bool,
    confirm_unroll: int,
    max_confirm_unroll: int,
    max_iters: int,
    enable_env_completion_refinement: bool,
    runner: StageRunner,
    toolchain_nowitness: Path,
    toolchain_witness: Path,
    witness_settings: Path,
    closure_toolchain: Path,
    settings: Path,
    closure_settings: Path,
    confirm_settings_fallback: Optional[Path] = None,
    stage_order: str,
) -> Path:
    """
    Core iterative loop (unit-testable via a fake StageRunner).
    """

    cand = candidate
    det_period = _infer_deterministic_scheduler_period(base_text.splitlines())

    try:
        spec_model = parse_model(spec_text)
    except Exception:
        # Unit tests may call `_run_cegis_loop` with dummy/empty spec text.
        # Env-completion refinement is optional; fall back to an empty model.
        from dslc.speclang.model import SpecModel

        spec_model = SpecModel()

    pump_reg = cand.pump_reg
    accel_regs = cand.accel_regs

    index_expr = cand.index_expr
    index_value = cand.index_value if cand.index_value is not None else 0
    # Conditional existence/profile assumptions synthesized by CEGIS refinements.
    extra_assumes: List[str] = []
    env_completion_done = False
    witness_profile_done = False
    # Do not globally "attempt only once": witness extraction can fail spuriously
    # (e.g., toolchain timeout before witnessprinter) or produce no useful env
    # constraints in early iterations. Allow a small number of retries across
    # refinements so CEGIS can make progress.
    witness_profile_attempts = 0
    # When CONFIRM times out, prefer mining the already-known-reachable ENTRY trace
    # (cheap, UNSAFE) before running ENABLE_CHECK (potentially expensive).
    entry_witness_attempts = 0
    # Once CONFIRM is UNSAFE, do not re-run it as part of refinement. Instead,
    # keep the concrete counterexample fixed and only refine the CLOSURE proof
    # obligation (witness-seeded).
    seed_confirm_res: Optional[StageRunResult] = None
    seed_confirm_bpl: Optional[Path] = None
    seed_confirm_log: Optional[Path] = None
    seed_confirm_unroll: Optional[int] = None
    # Cached GraphML text for the seeded CONFIRM witness (the one we certify).
    # This is used for witness-diff refinement in the CLOSURE stage.
    seed_confirm_witness_text: Optional[str] = None
    # Once we have a concrete CONFIRM counterexample, we also freeze the ENTRY reachability
    # witness that establishes the pump cutpoint is reachable. Subsequent refinements must
    # not re-run ENTRY under refined assumptions; refinement is closure-only.
    seed_entry_res: Optional[StageRunResult] = None
    seed_entry_bpl: Optional[Path] = None
    seed_entry_log: Optional[Path] = None

    def _sanitize_local(name: str) -> str:
        # Keep consistent with dslc/transform/wraparound_common.py
        return re.sub(r"[^A-Za-z0-9_]", "_", name)

    def _closure_failed_proc_name(log_text: str) -> Optional[str]:
        """
        Best-effort extraction of which closure assert wrapper failed.

        With per-assert wrappers, Ultimate typically logs lines like:
          "=== Iteration k === Targeting __wraparound_closure_assert_proj_xxxASSERT_VIOLATIONASSERT ==="
        """

        m = re.search(r"Targeting\s+(?P<name>__wraparound_closure_assert_[A-Za-z0-9_]+)", log_text)
        if m:
            return m.group("name")
        # Fallback: some toolchains mention the error location without "Targeting".
        m = re.search(r"(?P<name>__wraparound_closure_assert_[A-Za-z0-9_]+)", log_text)
        if m:
            return m.group("name")
        return None

    def _extract_equality_parts(expr: str) -> Optional[Tuple[str, str]]:
        """
        Extract `(lhs, rhs)` from a (possibly parenthesized) equality `lhs == rhs`.

        We accept:
          - raw:              "x == 1bv1"
          - wrapped:          "(x == 1bv1)"
          - assume wrapper:   "assume(x == 1bv1)" / "assume x == 1bv1"

        This is used to avoid adding conflicting shape constraints across refinements.
        """

        s = str(expr).strip()
        if not s:
            return None
        if s.startswith("assume(") and s.endswith(")"):
            s = s[len("assume(") : -1].strip()
        if s.startswith("assume "):
            s = s[len("assume ") :].strip()
        if s.endswith(";"):
            s = s[:-1].strip()
        while s.startswith("(") and s.endswith(")"):
            # Strip a single layer of wrapping parens if it encloses the whole string.
            depth = 0
            wraps_entire = True
            for i, ch in enumerate(s):
                if ch == "(":
                    depth += 1
                elif ch == ")":
                    depth -= 1
                    if depth == 0 and i != len(s) - 1:
                        wraps_entire = False
                        break
            if wraps_entire and depth == 0:
                s = s[1:-1].strip()
                continue
            break
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*==\s*(.+)$", s)
        if not m:
            return None
        lhs = m.group(1).strip()
        rhs = m.group(2).strip()
        if not lhs or not rhs:
            return None
        return lhs, rhs

    # Track which LHS variables we already pinned via `lhs == rhs` constraints.
    #
    # We keep a priority so that later refinements can override weak under-approximations
    # (env-completion) with stronger, witness-derived shape constraints.
    #   - 3: hard pins from control-plane entries / fixed templates
    #   - 2: witness-derived pins (ENTRY/ENABLE/CONFIRM witness)
    #   - 1: env-completion under-approx pins
    pinned_eq: Dict[str, Tuple[str, str, int]] = {}  # lhs -> (rhs, expr, priority)

    def _add_assume(expr: str, *, priority: int = 2) -> bool:
        """
        Add an assume expression if it is new, or replace an existing weaker equality
        on the same LHS.
        """

        expr = str(expr).strip()
        if not expr:
            return False
        if expr in extra_assumes:
            return False

        parts = _extract_equality_parts(expr)
        if parts is None:
            # Non-equality constraint; treat as a pure set element.
            extra_assumes.append(expr)
            return True

        lhs, rhs = parts
        prev = pinned_eq.get(lhs)
        if prev is None:
            pinned_eq[lhs] = (rhs, expr, int(priority))
            extra_assumes.append(expr)
            return True

        prev_rhs, prev_expr, prev_pri = prev
        if rhs == prev_rhs:
            # Already pinned to the same RHS (possibly with different parentheses formatting).
            return False

        if int(priority) <= int(prev_pri):
            # Do not override stronger (or equal-strength) pins.
            return False

        # Override a weaker pin.
        try:
            extra_assumes.remove(prev_expr)
        except ValueError:
            pass
        pinned_eq[lhs] = (rhs, expr, int(priority))
        extra_assumes.append(expr)
        return True

    proj_vars = list(cand.proj_vars)

    cutpoint_cond = cand.cutpoint_cond
    step_op = cand.step_op
    step_delta = int(cand.step_delta) if cand.step_delta is not None else 1

    # Projection variables are a *certificate choice*.
    #
    # We keep `procurator_phase` mandatory because our sequential harness relies on it
    # for deterministic scheduling; without it, closure/pump reasoning becomes unstable.
    #
    # Queue counters (e.g., `<node>_inbox_count`) can help make the pump proof stronger,
    # but they are not strictly required for *bug finding* soundness: if closure cannot be
    # certified with them, we allow CEGIS to drop them and search for a weaker (still sound)
    # summary. This is important for benchmarks like NetChain where proving queue stability
    # can dominate runtime.
    mandatory_proj = ["procurator_phase"]

    attempts: List[CegisAttemptRecord] = []
    base_proj_set = set(proj_vars)
    base_index_expr = index_expr
    base_index_value = index_value

    for it in range(max_iters):
        # Timeout policy:
        # - If closure_timeout_cap_seconds == 0 (default), do not cap: run closure_check
        #   with the full timeout budget to avoid interrupting a proof attempt.
        # - If a cap is provided (>0), we still let the *final* iteration use the full
        #   timeout as a last-chance certification run.
        cap = int(closure_timeout_cap_seconds)
        if cap <= 0:
            closure_timeout_this_attempt = int(timeout_seconds)
        else:
            closure_timeout_this_attempt = min(int(timeout_seconds), max(1, cap))
            if it + 1 >= max_iters:
                closure_timeout_this_attempt = int(timeout_seconds)

        notes: List[str] = []
        if it > 0:
            notes.append(f"refine_iter={it}")
        if det_period is not None:
            notes.append(f"deterministic_scheduler_period={det_period}")
        notes.append(f"closure_timeout={closure_timeout_this_attempt}")
        if base_index_expr is not None and index_expr is None:
            notes.append("index_expr=const")
        if int(index_value) != int(base_index_value):
            notes.append(f"index_value={index_value}")
        dropped_proj = sorted(base_proj_set.difference(set(proj_vars)))
        if dropped_proj:
            # Keep it stable and grep-friendly for manifests.
            notes.append("drop_proj_vars=" + ",".join(dropped_proj))

        cfg = CegisAttemptConfig(
            attempt=it,
            pump_reg=pump_reg,
            accel_regs=accel_regs,
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=tuple(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            closure_assumes=tuple(extra_assumes),
            notes=tuple(notes),
        )

        stem = f"{spec_path.stem}.cegis.{it:02d}"
        entry_bpl = out_dir / f"{stem}.entry_check.bpl"
        closure_bpl = out_dir / f"{stem}.closure_check.bpl"
        entry_log = out_dir / f"{stem}.entry_check.log"
        closure_log = out_dir / f"{stem}.closure_check.log"

        entry_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.ENTRY_CHECK,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            # ENTRY is a pure reachability check; do not mix in refinement assumptions.
            extra_assumes=(),
        )
        entry_bpl.write_text(entry_txt, encoding="utf-8")

        closure_txt = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CLOSURE_CHECK,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            extra_assumes=extra_assumes,
        )
        closure_bpl.write_text(closure_txt, encoding="utf-8")

        # Always emit a default CONFIRM instance so that artifacts are well-defined even
        # if we exit early after ENTRY (e.g., ENTRY is SAFE/UNKNOWN).
        #
        # For entry_confirm_closure we may emit additional confirm instances with a larger
        # unroll bound later; those are recorded as separate attempts in the manifest.
        confirm_bpl = out_dir / f"{stem}.confirm.unroll{confirm_unroll}.bpl"
        confirm_log = out_dir / f"{stem}.confirm.unroll{confirm_unroll}.log"
        confirm_txt0 = instrument_bpl_text(
            bpl_text=base_text,
            stage=WraparoundStage.CONFIRM,
            pump_reg=pump_reg,
            accel_regs=list(accel_regs),
            index_value=index_value,
            index_expr=index_expr,
            proj_vars=list(proj_vars),
            cutpoint_cond=cutpoint_cond,
            step_op=step_op,
            step_delta=step_delta,
            # CONFIRM is existential bug finding; refinements are closure-only.
            extra_assumes=(),
        )
        confirm_txt0, _confirm_steps0 = _unroll_confirm_like_mainprocedure(
            bpl_text=confirm_txt0, requested_steps=confirm_unroll, deterministic_period=det_period
        )
        confirm_bpl.write_text(confirm_txt0, encoding="utf-8")

        artifacts = CegisAttemptArtifacts(
            entry_bpl=str(entry_bpl),
            closure_bpl=str(closure_bpl),
            confirm_bpl=str(confirm_bpl),
            entry_log=str(entry_log),
            closure_log=str(closure_log),
            confirm_log=str(confirm_log),
        )

        ultimate_home_root = out_dir / "ultimate-home"

        if seed_confirm_res is None:
            # ENTRY_CHECK is a pure reachability gate: is the deterministic round executable?
            # We run it with the *non-witness* toolchain to avoid witness-printer crashes on SAFE.
            entry_res = runner.run(
                stage="entry_check",
                input_bpl=entry_bpl,
                log_path=entry_log,
                ultimate_home=ultimate_home_root / stem / "entry",
                toolchain=toolchain_nowitness,
                settings=settings,
                timeout_seconds=timeout_seconds,
                resource_limits=resource_limits,
            )

            if not entry_res.is_unsafe:
                attempts.append(
                    CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=None, confirm=None)
                )
                _write_manifest(
                    out_dir=out_dir,
                    spec_path=spec_path,
                    base_bpl=base_bpl,
                    work_dir=work_dir,
                    cand=cand,
                    attempts=attempts,
                )
                break

            # Persist a reproducible "ENTRY reached" record early.
            #
            # Rationale: ENTRY is usually fast, while CONFIRM/CLOSURE may take minutes.
            # If the user interrupts mid-run, we still want a manifest describing the
            # attempted target and the generated artifacts.
            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=None, confirm=None))
            _write_manifest(
                out_dir=out_dir,
                spec_path=spec_path,
                base_bpl=base_bpl,
                work_dir=work_dir,
                cand=cand,
                attempts=attempts,
            )
        else:
            # Closure-only refinement mode: do not rerun ENTRY under refined assumptions.
            if seed_entry_res is None:
                raise WraparoundCegisError("internal error: CONFIRM is seeded but ENTRY is not seeded")
            entry_res = seed_entry_res

        if stage_order not in {"entry_closure_confirm", "entry_confirm_closure"}:
            raise WraparoundCegisError(f"unknown stage_order: {stage_order}")

        closure_res: Optional[StageRunResult] = None
        confirm_res: Optional[StageRunResult] = None

        if stage_order == "entry_closure_confirm":
            closure_res = runner.run(
                stage="closure_check",
                input_bpl=closure_bpl,
                log_path=closure_log,
                ultimate_home=ultimate_home_root / stem / "closure",
                toolchain=closure_toolchain,
                settings=closure_settings,
                timeout_seconds=closure_timeout_this_attempt,
                resource_limits=resource_limits,
            )
            if closure_res.is_safe:
                # Legacy ordering: we already proved closure, so we do not need a witness.
                # Run confirm with the non-witness toolchain to avoid witness printer crashes.
                confirm_res = runner.run(
                    stage="confirm",
                    input_bpl=confirm_bpl,
                    log_path=confirm_log,
                    ultimate_home=ultimate_home_root / stem / "confirm",
                    toolchain=toolchain_nowitness,
                    settings=settings,
                    timeout_seconds=timeout_seconds,
                    resource_limits=resource_limits,
                )
                attempts.append(
                    CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=confirm_res)
                )
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )
                break

            attempts.append(CegisAttemptRecord(cfg=cfg, artifacts=artifacts, entry=entry_res, closure=closure_res, confirm=None))
            _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)

        else:
            # entry_confirm_closure (default): treat CONFIRM as an existential bug-finding query.
            #
            # Once CONFIRM is UNSAFE, refinements are only for CLOSURE (witness-seeded).
            # Do NOT rerun CONFIRM under refined assumptions; that would turn CONFIRM
            # into part of the synthesis loop and can bias/lose the original witness.
            if seed_confirm_res is not None:
                # Closure-only refinement mode (seeded by an earlier CONFIRM counterexample).
                confirm_res = seed_confirm_res
                seed_bpl = seed_confirm_bpl if seed_confirm_bpl is not None else confirm_bpl
                seed_log = seed_confirm_log if seed_confirm_log is not None else confirm_log
                seed_unroll = seed_confirm_unroll if seed_confirm_unroll is not None else int(confirm_unroll)

                # Ensure the manifest points at the concrete CONFIRM instance that produced
                # the counterexample we are certifying.
                artifacts = CegisAttemptArtifacts(
                    entry_bpl=str(seed_entry_bpl) if seed_entry_bpl is not None else artifacts.entry_bpl,
                    closure_bpl=artifacts.closure_bpl,
                    confirm_bpl=str(seed_bpl),
                    entry_log=str(seed_entry_log) if seed_entry_log is not None else artifacts.entry_log,
                    closure_log=artifacts.closure_log,
                    confirm_log=str(seed_log),
                    closure_log_retry=artifacts.closure_log_retry,
                    enable_bpl=artifacts.enable_bpl,
                    enable_log=artifacts.enable_log,
                )
                cfg_i = CegisAttemptConfig(
                    attempt=cfg.attempt,
                    pump_reg=cfg.pump_reg,
                    accel_regs=cfg.accel_regs,
                    index_value=cfg.index_value,
                    index_expr=cfg.index_expr,
                    proj_vars=cfg.proj_vars,
                    cutpoint_cond=cfg.cutpoint_cond,
                    step_op=cfg.step_op,
                    step_delta=cfg.step_delta,
                    closure_assumes=tuple(extra_assumes),
                    notes=tuple(list(cfg.notes) + ["confirm_seeded=true", f"confirm_seed_unroll={seed_unroll}"]),
                )

                closure_res = runner.run(
                    stage="closure_check",
                    input_bpl=closure_bpl,
                    log_path=closure_log,
                    ultimate_home=ultimate_home_root / stem / "closure",
                    toolchain=closure_toolchain,
                    settings=closure_settings,
                    timeout_seconds=closure_timeout_this_attempt,
                    resource_limits=resource_limits,
                )
                closure_retry_res: Optional[StageRunResult] = None
                closure_res_eff = closure_res

                # If the user provided a cap (< full timeout) and we hit the cap, retry once
                # with the full timeout budget. Do not refine on timeout: without a concrete
                # counterexample, there's no evidence to guide synthesis.
                if (
                    closure_res.is_unknown
                    and closure_res.timed_out
                    and int(closure_timeout_this_attempt) < int(timeout_seconds)
                ):
                    closure_log_retry = out_dir / f"{stem}.closure_check.retry.log"
                    closure_retry_res = runner.run(
                        stage="closure_check.retry",
                        input_bpl=closure_bpl,
                        log_path=closure_log_retry,
                        ultimate_home=ultimate_home_root / stem / "closure.retry",
                        toolchain=closure_toolchain,
                        settings=closure_settings,
                        timeout_seconds=timeout_seconds,
                        resource_limits=resource_limits,
                    )
                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=artifacts.entry_bpl,
                        closure_bpl=artifacts.closure_bpl,
                        confirm_bpl=artifacts.confirm_bpl,
                        entry_log=artifacts.entry_log,
                        closure_log=artifacts.closure_log,
                        confirm_log=artifacts.confirm_log,
                        closure_log_retry=str(closure_log_retry),
                        enable_bpl=artifacts.enable_bpl,
                        enable_log=artifacts.enable_log,
                    )
                    closure_res_eff = closure_retry_res

                attempts.append(
                    CegisAttemptRecord(
                        cfg=cfg_i,
                        artifacts=artifacts,
                        entry=entry_res,
                        closure=closure_res,
                        closure_retry=closure_retry_res,
                        confirm=confirm_res,
                    )
                )
                _write_manifest(
                    out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts
                )

                if closure_res_eff.is_safe:
                    break

                if closure_res_eff.is_unknown:
                    # No evidence to refine; stop and let the caller increase timeouts or
                    # optimize the spec/encoding case-by-case.
                    break

                # Witness-seeded refinement for closure (P2C-aware shape constraints).
                #
                # IMPORTANT: do not add generic env-completion under-approximations here;
                # closure refinements must preserve the already-found CONFIRM witness.
                added_any = False
                witness_timeout_s = min(timeout_seconds, max(120, min(300, int(closure_timeout_this_attempt))))
                # Cache the seeded CONFIRM witness once. We use it both to pin down a stable
                # input "shape" and to drive CEGAR-style refinement against CLOSURE counterexamples.
                if seed_confirm_witness_text is None and (witness_profile_attempts < 3) and (it + 1 < max_iters):
                    witness_profile_attempts += 1
                    witness_log = out_dir / f"{stem}.confirm_seed.witness.unroll{seed_unroll}.log"
                    t0 = time.time()
                    _ = runner.run(
                        stage=f"confirm.witness.unroll{seed_unroll}",
                        input_bpl=seed_bpl,
                        log_path=witness_log,
                        ultimate_home=ultimate_home_root / stem / f"confirm.unroll{seed_unroll}.witness.seed",
                        toolchain=toolchain_witness,
                        settings=witness_settings,
                        timeout_seconds=witness_timeout_s,
                        resource_limits=resource_limits,
                    )
                    witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                        work_dir=out_dir
                    )
                    if witness:
                        try:
                            wtxt = witness.read_text(encoding="utf-8", errors="replace")
                            seed_confirm_witness_text = wtxt
                            new_assumes = _synthesize_refinement_assumes_from_witness(
                                witness_text=wtxt,
                                base_bpl_text=base_text,
                                candidate=cand,
                                spec_model=spec_model,
                            )
                        except Exception:
                            new_assumes = []
                        for aexpr in new_assumes:
                            if _add_assume(aexpr, priority=2):
                                added_any = True
                        witness_profile_done = True

                # If CLOSURE is UNSAFE, refine using a witness diff:
                # add assumptions that match the seeded CONFIRM witness but disagree with
                # the CLOSURE counterexample witness, thereby blocking the non-closure behavior.
                if (
                    (not added_any)
                    and closure_res_eff.is_unsafe
                    and seed_confirm_witness_text is not None
                    and (it + 1 < max_iters)
                ):
                    cex_log = out_dir / f"{stem}.closure_check.witness.it{it}.log"
                    t1 = time.time()
                    _ = runner.run(
                        stage=f"closure_check.witness.it{it}",
                        input_bpl=closure_bpl,
                        log_path=cex_log,
                        ultimate_home=ultimate_home_root / stem / f"closure.witness.it{it}",
                        toolchain=toolchain_witness,
                        settings=witness_settings,
                        timeout_seconds=witness_timeout_s,
                        resource_limits=resource_limits,
                    )
                    cex = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t1) or find_latest_graphml_witness(
                        work_dir=out_dir
                    )
                    if cex:
                        try:
                            cex_txt = cex.read_text(encoding="utf-8", errors="replace")
                            diff_assumes = _select_refinement_assumes_from_witness_diff(
                                confirm_witness_text=seed_confirm_witness_text,
                                cex_witness_text=cex_txt,
                                base_bpl_text=base_text,
                                candidate=cand,
                                spec_model=spec_model,
                                max_new=max(1, min(8, 2 + it * 2)),
                            )
                        except Exception:
                            diff_assumes = []
                        for aexpr in diff_assumes:
                            if _add_assume(aexpr, priority=2):
                                added_any = True

                if added_any:
                    # We refined the closure obligation using witness evidence; rerun CLOSURE.
                    # Do not heuristically weaken the certificate (e.g., by dropping proj vars)
                    # as that makes the algorithm harder to reason about and can bias results.
                    continue

            else:
                # We do not yet have a CONFIRM counterexample; search for one.
                need_retry = False
                certified = False
                enable_refine_tried = False

                # CONFIRM is an existential bug-finding query; by default we run it once
                # (no unroll growth). Callers can opt into a small growth schedule by
                # passing a larger `max_confirm_unroll`.
                max_unroll = int(max_confirm_unroll) if int(max_confirm_unroll) > 0 else int(confirm_unroll)
                for unroll in _confirm_unroll_schedule(base=confirm_unroll, max_unroll=max_unroll):
                    confirm_bpl = out_dir / f"{stem}.confirm.unroll{unroll}.bpl"
                    confirm_log = out_dir / f"{stem}.confirm.unroll{unroll}.log"

                    confirm_txt = instrument_bpl_text(
                        bpl_text=base_text,
                        stage=WraparoundStage.CONFIRM,
                        pump_reg=pump_reg,
                        accel_regs=list(accel_regs),
                        index_value=index_value,
                        index_expr=index_expr,
                        proj_vars=list(proj_vars),
                        cutpoint_cond=cutpoint_cond,
                        step_op=step_op,
                        step_delta=step_delta,
                        # CONFIRM is existential bug finding; refinements are closure-only.
                        extra_assumes=(),
                    )
                    confirm_txt, confirm_steps = _unroll_confirm_like_mainprocedure(
                        bpl_text=confirm_txt, requested_steps=unroll, deterministic_period=det_period
                    )
                    confirm_bpl.write_text(confirm_txt, encoding="utf-8")

                    artifacts = CegisAttemptArtifacts(
                        entry_bpl=str(entry_bpl),
                        closure_bpl=str(closure_bpl),
                        confirm_bpl=str(confirm_bpl),
                        entry_log=str(entry_log),
                        closure_log=str(closure_log),
                        confirm_log=str(confirm_log),
                    )

                    notes = list(cfg.notes) + [f"confirm_unroll={unroll}"] + (
                        [f"confirm_steps={confirm_steps}"] if confirm_steps != int(unroll) else []
                    )

                    t0 = time.time()
                    confirm_res = runner.run(
                        stage="confirm",
                        input_bpl=confirm_bpl,
                        log_path=confirm_log,
                        ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}",
                        toolchain=toolchain_nowitness,
                        settings=settings,
                        timeout_seconds=timeout_seconds,
                        resource_limits=resource_limits,
                    )

                    if (
                        confirm_res.is_unknown
                        and confirm_res.timed_out
                        and confirm_settings_fallback is not None
                        and confirm_settings_fallback != settings
                    ):
                        confirm_res2 = runner.run(
                            stage="confirm",
                            input_bpl=confirm_bpl,
                            log_path=confirm_log,
                            ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.noz3timeout",
                            toolchain=toolchain_nowitness,
                            settings=confirm_settings_fallback,
                            timeout_seconds=timeout_seconds,
                            resource_limits=resource_limits,
                        )
                        if not confirm_res2.is_unknown:
                            confirm_res = confirm_res2
                            notes.append(f"confirm_settings={confirm_settings_fallback.name}")

                    # If CONFIRM already ran with a witness-enabled toolchain, reuse its witness
                    # instead of re-running a separate `confirm.witness` task later.
                    if (
                        confirm_res.is_unsafe
                        and seed_confirm_witness_text is None
                        and _toolchain_has_witnessprinter(toolchain_nowitness)
                    ):
                        witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                            work_dir=out_dir
                        )
                        if witness:
                            try:
                                wtxt = witness.read_text(encoding="utf-8", errors="replace")
                            except Exception:
                                wtxt = None
                            if wtxt is not None:
                                seed_confirm_witness_text = wtxt
                                # Seed closure assumptions immediately from the CONFIRM witness:
                                # closure_check is a proof obligation and should not waste time
                                # considering packet shapes that are irrelevant to the concrete
                                # CONFIRM counterexample we are trying to certify.
                                #
                                # NOTE: This does *not* affect ENTRY/CONFIRM themselves; those
                                # stages always run under the original environment. The seeded
                                # assumptions are injected into CLOSURE only.
                                before = len(extra_assumes)
                                try:
                                    seed_assumes = _synthesize_refinement_assumes_from_witness(
                                        witness_text=wtxt,
                                        base_bpl_text=base_text,
                                        candidate=cand,
                                        spec_model=spec_model,
                                    )
                                except Exception:
                                    seed_assumes = []
                                for aexpr in seed_assumes:
                                    _add_assume(aexpr, priority=2)
                                added = len(extra_assumes) - before
                                if added > 0:
                                    notes.append(f"closure_seed_assumes={added}")
                                witness_profile_done = True

                    cfg_i = CegisAttemptConfig(
                        attempt=cfg.attempt,
                        pump_reg=cfg.pump_reg,
                        accel_regs=cfg.accel_regs,
                        index_value=cfg.index_value,
                        index_expr=cfg.index_expr,
                        proj_vars=cfg.proj_vars,
                        cutpoint_cond=cfg.cutpoint_cond,
                        step_op=cfg.step_op,
                        step_delta=cfg.step_delta,
                        closure_assumes=tuple(extra_assumes),
                        notes=tuple(notes),
                    )

                    if confirm_res.is_unknown:
                        attempts.append(
                            CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                        )
                        _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )
                        # CONFIRM is existential bug finding. We do not CEGIS-refine ENTRY/CONFIRM;
                        # closure refinement is seeded by a concrete CONFIRM witness.
                        break  # stop unroll growth on UNKNOWN

                    if not confirm_res.is_unsafe:
                        attempts.append(
                            CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                        )
                        _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )
                        continue

                    # CONFIRM found a bug. Seed it and certify via CLOSURE.
                    seed_confirm_res = confirm_res
                    seed_confirm_bpl = confirm_bpl
                    seed_confirm_log = confirm_log
                    seed_confirm_unroll = int(unroll)
                    seed_entry_res = entry_res
                    seed_entry_bpl = entry_bpl
                    seed_entry_log = entry_log

                    attempts.append(
                        CegisAttemptRecord(cfg=cfg_i, artifacts=artifacts, entry=entry_res, closure=None, confirm=confirm_res)
                    )
                    _write_manifest(
                        out_dir=out_dir,
                        spec_path=spec_path,
                        base_bpl=base_bpl,
                        work_dir=work_dir,
                        cand=cand,
                        attempts=attempts,
                    )

                    # If we seeded any closure assumptions from the CONFIRM witness, we must
                    # regenerate the closure_check BPL for this attempt. (It was emitted at
                    # the top of the outer loop before we had a witness.)
                    if extra_assumes:
                        closure_txt = instrument_bpl_text(
                            bpl_text=base_text,
                            stage=WraparoundStage.CLOSURE_CHECK,
                            pump_reg=pump_reg,
                            accel_regs=list(accel_regs),
                            index_value=index_value,
                            index_expr=index_expr,
                            proj_vars=list(proj_vars),
                            cutpoint_cond=cutpoint_cond,
                            step_op=step_op,
                            step_delta=step_delta,
                            extra_assumes=extra_assumes,
                        )
                        closure_bpl.write_text(closure_txt, encoding="utf-8")

                    closure_res = runner.run(
                        stage="closure_check",
                        input_bpl=closure_bpl,
                        log_path=closure_log,
                        ultimate_home=ultimate_home_root / stem / "closure",
                        toolchain=closure_toolchain,
                        settings=closure_settings,
                        timeout_seconds=closure_timeout_this_attempt,
                        resource_limits=resource_limits,
                    )
                    closure_retry_res: Optional[StageRunResult] = None
                    closure_res_eff = closure_res

                    if (
                        closure_res.is_unknown
                        and closure_res.timed_out
                        and int(closure_timeout_this_attempt) < int(timeout_seconds)
                    ):
                        closure_log_retry = out_dir / f"{stem}.closure_check.retry.log"
                        closure_retry_res = runner.run(
                            stage="closure_check.retry",
                            input_bpl=closure_bpl,
                            log_path=closure_log_retry,
                            ultimate_home=ultimate_home_root / stem / "closure.retry",
                            toolchain=closure_toolchain,
                            settings=closure_settings,
                            timeout_seconds=timeout_seconds,
                            resource_limits=resource_limits,
                        )
                        artifacts = CegisAttemptArtifacts(
                            entry_bpl=artifacts.entry_bpl,
                            closure_bpl=artifacts.closure_bpl,
                            confirm_bpl=artifacts.confirm_bpl,
                            entry_log=artifacts.entry_log,
                            closure_log=artifacts.closure_log,
                            confirm_log=artifacts.confirm_log,
                            closure_log_retry=str(closure_log_retry),
                            enable_bpl=artifacts.enable_bpl,
                            enable_log=artifacts.enable_log,
                        )
                        closure_res_eff = closure_retry_res

                    attempts.append(
                        CegisAttemptRecord(
                            cfg=cfg_i,
                            artifacts=artifacts,
                            entry=entry_res,
                            closure=closure_res,
                            closure_retry=closure_retry_res,
                            confirm=confirm_res,
                        )
                    )
                    _write_manifest(
                        out_dir=out_dir,
                        spec_path=spec_path,
                        base_bpl=base_bpl,
                        work_dir=work_dir,
                        cand=cand,
                        attempts=attempts,
                    )

                    if closure_res_eff.is_safe:
                        # Certified: emit a CONFIRM witness for the final counterexample artifact.
                        #
                        # We intentionally do this *after* the closure proof succeeded. If closure
                        # times out/UNKNOWN (no evidence), we stop without running witnessprinter.
                        witness_timeout_s = min(timeout_seconds, max(120, min(300, int(closure_timeout_this_attempt))))
                        if seed_confirm_witness_text is None and (witness_profile_attempts < 3):
                            witness_profile_attempts += 1
                            witness_log = confirm_log.with_suffix(confirm_log.suffix + ".witness.log")
                            t0 = time.time()
                            _ = runner.run(
                                stage=f"confirm.witness.unroll{unroll}",
                                input_bpl=confirm_bpl,
                                log_path=witness_log,
                                ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.witness",
                                toolchain=toolchain_witness,
                                settings=witness_settings,
                                timeout_seconds=witness_timeout_s,
                                resource_limits=resource_limits,
                            )
                            witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                                work_dir=out_dir
                            )
                            if witness:
                                try:
                                    seed_confirm_witness_text = witness.read_text(encoding="utf-8", errors="replace")
                                except Exception:
                                    seed_confirm_witness_text = None
                                # Cache that we successfully obtained a witness (even if we do not
                                # use it for refinement in this run).
                                witness_profile_done = True
                        certified = True
                        break
                    if closure_res_eff.is_unknown:
                        # No counterexample -> no evidence to refine. Stop here and let the caller
                        # increase timeouts or optimize the spec/encoding case-by-case.
                        return _write_manifest(
                            out_dir=out_dir,
                            spec_path=spec_path,
                            base_bpl=base_bpl,
                            work_dir=work_dir,
                            cand=cand,
                            attempts=attempts,
                        )

                    # Not certified yet: mine witness-derived assumptions once and retry via CLOSURE-only mode.
                    added_any = False
                    witness_timeout_s = min(timeout_seconds, max(120, min(300, int(closure_timeout_this_attempt))))
                    if (not witness_profile_done) and (witness_profile_attempts < 3) and (it + 1 < max_iters):
                        witness_profile_attempts += 1
                        witness_log = confirm_log.with_suffix(confirm_log.suffix + ".witness.log")
                        t0 = time.time()
                        _ = runner.run(
                            stage=f"confirm.witness.unroll{unroll}",
                            input_bpl=confirm_bpl,
                            log_path=witness_log,
                            ultimate_home=ultimate_home_root / stem / f"confirm.unroll{unroll}.witness",
                            toolchain=toolchain_witness,
                            settings=witness_settings,
                            timeout_seconds=witness_timeout_s,
                            resource_limits=resource_limits,
                        )
                        witness = _find_latest_graphml_witness_since(work_dir=out_dir, since_time=t0) or find_latest_graphml_witness(
                            work_dir=out_dir
                        )
                        if witness:
                            try:
                                wtxt = witness.read_text(encoding="utf-8", errors="replace")
                                seed_confirm_witness_text = wtxt
                                new_assumes = _synthesize_refinement_assumes_from_witness(
                                    witness_text=wtxt,
                                    base_bpl_text=base_text,
                                    candidate=cand,
                                    spec_model=spec_model,
                                )
                            except Exception:
                                new_assumes = []
                            for aexpr in new_assumes:
                                if _add_assume(aexpr, priority=2):
                                    added_any = True
                            # Cache that we successfully obtained a witness (even if it adds no new assumes);
                            # future CEGAR refinements compare closure counterexamples against this witness.
                            witness_profile_done = True

                    if added_any:
                        need_retry = True
                    # Either way, stop trying longer unrolls once we have a bug witness.
                    break

                if certified:
                    break
                if need_retry:
                    # We obtained new closure assumptions from a concrete CONFIRM witness; retry.
                    continue
                if seed_confirm_res is None:
                    # No bug found and no pre-bug refinement to try.
                    break

        if index_expr is not None and cand.index_value is not None:
            index_expr = None
            index_value = int(cand.index_value)
            continue

        # No more evidence-backed refinements available (and we avoid heuristic weakening).
        break

    return _write_manifest(out_dir=out_dir, spec_path=spec_path, base_bpl=base_bpl, work_dir=work_dir, cand=cand, attempts=attempts)


def run_wraparound_cegis_multi(
    *,
    spec_path: Path,
    out_dir: Path,
    p4b_bin: Optional[Path],
    ultimate: Path,
    ultimate_xmx_gb: int = 6,
    timeout_seconds: int = 1200,
    # Default: 0 (no cap). Avoid interrupting long-running closure proofs; do not refine on timeout.
    closure_timeout_cap_seconds: int = 0,
    resource_limits: bool = True,
    enable_slicing: bool = True,
    pipeline_two_stage: bool = True,
    confirm_unroll: int = 3,
    # 0 => do not grow (single confirm).
    max_confirm_unroll: int = 0,
    max_iters: int = 6,
    stage_order: str = "entry_confirm_closure",
    max_targets: int = 8,
    require_meta_step_for_global_asserts: bool = False,
) -> List[Path]:
    """
    Run wraparound CEGIS for multiple candidates (best-effort).

    This is intended for integration into the main verification pipeline:
      - try a coarse "group" first (when candidates are compatible),
      - then fall back to per-register candidates.

    Returns a list of manifest paths (one per attempted target), in order.
    """

    spec_path = spec_path.resolve()
    out_dir = out_dir.resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    # Compile once and infer candidates.
    work_dir = out_dir / "work"
    base_bpl = out_dir / f"{spec_path.stem}.base.bpl"
    compile_spec_file(
        spec_path=spec_path,
        backend="boogie",
        out=base_bpl,
        p4b_bin=p4b_bin,
        work_dir=work_dir,
        max_env_inputs=False,
        enable_slicing=enable_slicing,
        prune_env_inputs=True,
        por_enabled=False,
        por_guard_enabled=True,
        boogie_harness="sequential",
        pipeline_two_stage=pipeline_two_stage,
    )
    spec_text = spec_path.read_text(encoding="utf-8", errors="replace")
    base_text = base_bpl.read_text(encoding="utf-8", errors="replace")

    meta_by_node: Dict[str, dict] = {}
    for p in sorted(work_dir.glob("*.meta.json")):
        alias = p.name[: -len(".meta.json")]
        try:
            meta_by_node[alias] = json.loads(p.read_text(encoding="utf-8"))
        except Exception:
            continue

    partition_ports: Dict[str, int] = {}
    if _is_distcache_like(spec_text):
        caps = _infer_distcache_hash_caps(spec_text, spec_dir=spec_path.parent)
        if caps:
            node_prefixes = sorted(set(re.findall(r"\b([A-Za-z_][A-Za-z0-9_]*)_meta\.", base_text)))
            patched = _apply_hash_caps_to_bpl(base_text, node_prefixes=node_prefixes, caps=caps)
            if patched != base_text:
                base_text = patched
                base_bpl.write_text(base_text, encoding="utf-8")
        partition_ports = _infer_distcache_partition_eports(spec_text, spec_dir=spec_path.parent)

    cands = infer_wraparound_candidates(
        spec_text=spec_text,
        bpl_text=base_text,
        meta_by_node=meta_by_node,
        require_meta_step_for_global_asserts=require_meta_step_for_global_asserts,
    )
    if not cands:
        return []

    # Deterministic target ordering for reproducibility.
    cands = sorted(cands, key=lambda c: (c.pump_reg, str(c.index_value), str(c.index_expr)))

    # If multiple wraparound candidates exist, prefer the one that matches the
    # benchmark's intent. This matters for DistCache where both leafload/spineload
    # are monotone counters but a given .prop is usually written to target one of them.
    stem_lower = spec_path.stem.lower()
    prefer_token: Optional[str] = None
    if "spineload" in stem_lower:
        prefer_token = "spineload"
    elif "leafload" in stem_lower:
        prefer_token = "leafload"
    elif "cache_frequency" in stem_lower:
        prefer_token = "cache_frequency"
    if prefer_token is not None and len(cands) > 1:
        def _pref_key(c: WraparoundCandidate) -> tuple[int, str, str, str]:
            hit = 0 if (prefer_token in c.pump_reg.lower() or prefer_token in c.reason.lower()) else 1
            return (hit, c.pump_reg, str(c.index_value), str(c.index_expr))

        cands = sorted(cands, key=_pref_key)
        # If the preferred token matches at least one candidate, drop the rest.
        # This keeps `--wraparound auto` aligned with the benchmark's intent and
        # avoids spending time on irrelevant counters.
        preferred = [
            c
            for c in cands
            if (prefer_token in c.pump_reg.lower() or prefer_token in c.reason.lower())
        ]
        if preferred:
            cands = preferred
    cands = cands[: max(1, int(max_targets))]

    roots: List[WraparoundCandidate] = []

    # Try a coarse group if (step_op, step_delta, cutpoint) align.
    if cands:
        base0 = cands[0]
        compatible = all(
            (c.step_op == base0.step_op)
            and (int(c.step_delta or 1) == int(base0.step_delta or 1))
            and (str(c.cutpoint_cond) == str(base0.cutpoint_cond))
            for c in cands
        )
        same_index = all((c.index_value == base0.index_value) and (c.index_expr == base0.index_expr) for c in cands)
        if compatible and same_index and len(cands) > 1:
            regs: List[str] = []
            for c in cands:
                regs.append(c.pump_reg)
                regs.extend(list(c.accel_regs))
            seen = set()
            uniq_regs: List[str] = []
            for r in regs:
                if r not in seen:
                    seen.add(r)
                    uniq_regs.append(r)
            proj: List[str] = []
            for c in cands:
                proj.extend(list(c.proj_vars))
            roots.append(
                WraparoundCandidate(
                    pump_reg=base0.pump_reg,
                    accel_regs=tuple(sorted(set(uniq_regs))),
                    index_value=base0.index_value,
                    index_expr=base0.index_expr,
                    proj_vars=tuple(sorted(set(proj))),
                    cutpoint_cond=base0.cutpoint_cond,
                    reason="group0(all_regs): " + "; ".join(sorted(set(c.reason for c in cands))),
                    step_op=base0.step_op,
                    step_delta=base0.step_delta,
                )
            )

    # Then try each candidate individually.
    roots.extend(cands)

    # Run CEGIS per root candidate, in isolated subdirectories (reuse the compiled base model).
    manifests: List[Path] = []
    root = repo_root()
    tc_nowit_def, tc_wit_def, tc_cl_def, st_nowit_def, st_wit_def, st_cl_def = _default_toolchain_paths(
        root=root, ultimate_xmx_gb=int(ultimate_xmx_gb)
    )
    runner = UltimateStageRunner(ultimate=ultimate, xmx_gb=int(ultimate_xmx_gb))
    # If available, retry CONFIRM with a "no z3 timeout" settings profile when
    # the default settings return UNKNOWN due to timeouts. This improves
    # determinism for wraparound bug finding and reduces spurious fallbacks.
    confirm_settings_fallback: Optional[Path] = None
    # WSL safety: only try the high-memory "no z3 timeout" fallback when the user
    # explicitly allocates a larger heap. Otherwise, prefer deterministic timeouts
    # over risking an OOM.
    if int(ultimate_xmx_gb) >= 8:
        st_confirm_noz3 = root / "dslc" / "toolchain" / "ultimate" / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf"
        st_confirm_noz3_legacy = (
            root
            / "Procurator"
            / "argo"
            / "code"
            / "spec"
            / "config"
            / "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf"
        )
        cand = (st_confirm_noz3 if st_confirm_noz3.exists() else st_confirm_noz3_legacy)
        if cand.exists():
            confirm_settings_fallback = cand

    def _is_certified_unsafe(manifest_path: Path) -> bool:
        """
        Best-effort check for "ENTRY+CONFIRM UNSAFE and CLOSURE SAFE" in a manifest.

        We use this to early-stop `run_wraparound_cegis_multi`: once we have a certified
        counterexample for one candidate, running additional candidates is wasted work
        (and can be confusing in logs/experiments).
        """

        try:
            j = json.loads(manifest_path.read_text(encoding="utf-8"))
        except Exception:
            return False

        attempts = j.get("attempts", [])
        if not isinstance(attempts, list):
            return False

        def _is(res, what: str) -> bool:
            if not isinstance(res, dict):
                return False
            s = str(res.get("result_line") or "")
            return what.lower() in s.lower()

        for a in attempts:
            if not isinstance(a, dict):
                continue
            if _is(a.get("entry"), "unsafe") and _is(a.get("confirm"), "unsafe") and _is(a.get("closure"), "safe"):
                return True
        return False

    for i, cand in enumerate(roots):
        subdir = out_dir / f"target.{i:02d}.{cand.pump_reg}"
        subdir.mkdir(parents=True, exist_ok=True)
        mpath = _run_cegis_loop(
            spec_path=spec_path,
            spec_text=spec_text,
            base_bpl=base_bpl,
            base_text=base_text,
            out_dir=subdir,
            work_dir=work_dir,
            candidate=cand,
            partition_ports=partition_ports,
            timeout_seconds=timeout_seconds,
            closure_timeout_cap_seconds=closure_timeout_cap_seconds,
            resource_limits=resource_limits,
            confirm_unroll=confirm_unroll,
            max_confirm_unroll=max_confirm_unroll,
            max_iters=max_iters,
            # ENTRY/CONFIRM are existential checks and should not be part of synthesis.
            # Refinements are closure-only and must be evidence-backed (witness-guided).
            enable_env_completion_refinement=False,
            runner=runner,
            # Prefer a witness-enabled CONFIRM by default in the integrated path:
            # it avoids an extra expensive `confirm.witness` rerun and keeps timings sane.
            toolchain_nowitness=tc_wit_def,
            toolchain_witness=tc_wit_def,
            witness_settings=st_wit_def,
            closure_toolchain=tc_cl_def,
            settings=st_wit_def,
            closure_settings=st_cl_def,
            confirm_settings_fallback=confirm_settings_fallback,
            stage_order=stage_order,
        )
        manifests.append(mpath)
        if _is_certified_unsafe(mpath):
            break
    return manifests
