from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Optional, Tuple

from dslc.analysis.wraparound_candidates import WraparoundCandidate
from dslc.toolchain.ultimate_witness import (
    extract_assumptions_from_graphml,
    synthesize_boogie_assumes,
)
from dslc.transform.wraparound_analyze import _parse_global_var_types


_RE_HAVOC = re.compile(r"^\s*havoc\s+(?P<name>[A-Za-z_][A-Za-z0-9_.]*)\s*;\s*$")
_RE_BV_TYPE = re.compile(r"^bv(?P<w>\d+)$")
_RE_SIMPLE_EQ = re.compile(
    r"^(?P<lhs>[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*)\s*==\s*(?P<rhs>.+)$"
)


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
    from dslc.toolchain.ultimate_witness import _RE_SIMPLE_EQ as _WITNESS_SIMPLE_EQ

    out: Dict[str, str] = {}
    for a in extract_assumptions_from_graphml(
        graphml_text,
        include_sourcecode=True,
        include_assignment=False,
    ):
        m = _WITNESS_SIMPLE_EQ.match(a.expr.strip())
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

    from dslc.toolchain.ultimate_witness import _normalize_rhs

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

    from dslc.toolchain.ultimate_witness import _normalize_rhs, _parse_global_var_types

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
        # For env-like refinement we only consume explicit witness assumptions and skip
        # `sourcecode :=` assignments. This avoids pinning large numbers of transient
        # copy statements that do not contribute to stable closure certificates.
        wa = extract_assumptions_from_graphml(
            witness_text,
            include_sourcecode=False,
            include_assignment=False,
        )
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
