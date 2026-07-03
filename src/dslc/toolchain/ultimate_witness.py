from __future__ import annotations

import re
import xml.etree.ElementTree as ET
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Sequence, Tuple


@dataclass(frozen=True)
class WitnessAssumption:
    """
    A single assumption extracted from an Ultimate GraphML witness.

    We keep it as a raw string expression (Boogie-ish), and optionally include the
    node id for debugging/reproducibility.
    """

    expr: str
    node_id: Optional[str] = None


# Accept both equality constraints (x == c / x = c) and simple assignments that
# may appear in witnesses as sourcecode (x := c). We later filter to literal RHS only.
_RE_SIMPLE_EQ = re.compile(r"^(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*(?P<op>==|=|:=)\s*(?P<rhs>.+)$")


def _strip_ns(tag: str) -> str:
    if "}" in tag:
        return tag.split("}", 1)[1]
    return tag


def _iter_graphml_data_text(root: ET.Element) -> Iterable[Tuple[Optional[str], str]]:
    """
    Yield (node_id, data_text) for all <data> elements under <node>.
    """

    for node in root.iter():
        if _strip_ns(node.tag) != "node":
            continue
        node_id = node.attrib.get("id")
        for d in node:
            if _strip_ns(d.tag) != "data":
                continue
            txt = "".join(d.itertext()).strip()
            if txt:
                yield (node_id, txt)


def extract_assumptions_from_graphml(
    graphml_text: str,
    *,
    include_sourcecode: bool = True,
    include_assignment: bool = True,
) -> List[WitnessAssumption]:
    """
    Best-effort extraction of assumptions from SV-COMP-style GraphML witnesses.

    Typical witnesses store constraints in <data key="assumption">...</data>.
    Ultimate may also embed assumptions as plain text in other <data> entries.

    We keep only simple equalities by default, and return them as raw expressions.
    """

    try:
        root = ET.fromstring(graphml_text)
    except ET.ParseError:
        return []

    out: List[WitnessAssumption] = []

    def _consume_payload(node_id: Optional[str], txt: str, *, from_sourcecode: bool) -> None:
        # Split multi-line / multi-statement payloads.
        #
        # Ultimate commonly emits a conjunction of atomic constraints in a single
        # <data key="assumption">...</data> entry (e.g., "x==0 && y==false && ...").
        # We treat "&&" as a separator as well.
        parts = [p.strip() for p in re.split(r"(?:;|\n|&&)+", txt) if p.strip()]
        for p in parts:
            # Ignore SSA pre-state constraints. We only want current-state equalities
            # that can be re-injected as plain Boogie `assume(...)`.
            if "old(" in p:
                continue
            # Strip simple surrounding parentheses.
            while p.startswith("(") and p.endswith(")") and len(p) > 2:
                p = p[1:-1].strip()
            # Keep only equalities/assignments. This is intentionally conservative: we
            # want constraints that are easy to re-inject as Boogie assumes.
            m = _RE_SIMPLE_EQ.match(p)
            if not m:
                continue
            if (not include_assignment) and m.group("op") == ":=":
                continue
            # Callers may want to ignore all sourcecode payloads and only consume explicit
            # witness assumptions.
            if from_sourcecode and (not include_sourcecode):
                continue
            out.append(WitnessAssumption(expr=p, node_id=node_id))

    # 1) Node-level <data> entries (legacy/variant witnesses).
    for node_id, txt in _iter_graphml_data_text(root):
        _consume_payload(node_id, txt, from_sourcecode=False)

    # 2) Edge-level constraints: Ultimate primarily stores constraints here.
    for edge in root.iter():
        if _strip_ns(edge.tag) != "edge":
            continue
        for d in edge:
            if _strip_ns(d.tag) != "data":
                continue
            # Some witnesses store assignments as "sourcecode" on edges rather than nodes.
            # We consume both and later filter aggressively (only literal RHS, only allowed vars).
            key = d.attrib.get("key")
            if key not in {"assumption", "sourcecode"}:
                continue
            txt = "".join(d.itertext()).strip()
            if txt:
                # Edge assumptions are not associated with a single node id; keep None.
                _consume_payload(None, txt, from_sourcecode=(key == "sourcecode"))
    return out


def _parse_global_var_types(bpl_text: str) -> Dict[str, str]:
    types: Dict[str, str] = {}
    for ln in bpl_text.splitlines():
        ln = ln.strip()
        if not ln.startswith("var "):
            continue
        # var x: bv8;
        m = re.match(r"^var\s+(?P<name>\S+)\s*:\s*(?P<typ>[^;]+);", ln)
        if not m:
            continue
        types[m.group("name")] = m.group("typ").strip()
    return types


def _bv_width(typ: str) -> Optional[int]:
    m = re.match(r"^bv(?P<w>\d+)$", typ.strip())
    if not m:
        return None
    return int(m.group("w"))


def _normalize_rhs(rhs: str, *, var_type: str) -> Optional[str]:
    """
    Normalize RHS literal to a Boogie literal compatible with var_type.
    Return None if we can't normalize.
    """

    r = rhs.strip()
    # Already a Boogie bv literal like 5bv16.
    if re.match(r"^\d+bv\d+$", r):
        return r
    if var_type == "bool":
        if r.lower() in {"true", "false"}:
            return r.lower()
        return None
    if var_type == "int":
        if re.match(r"^-?\d+$", r):
            return r
        return None

    w = _bv_width(var_type)
    if w is None:
        return None
    # Accept decimal integers for bitvectors and convert.
    if re.match(r"^-?\d+$", r):
        v = int(r, 10)
        if v < 0:
            return None
        return f"{v}bv{w}"
    # Accept hex 0x.. for bitvectors.
    if r.lower().startswith("0x"):
        try:
            v = int(r, 16)
        except ValueError:
            return None
        if v < 0:
            return None
        return f"{v}bv{w}"
    return None


def synthesize_boogie_assumes(
    *,
    witness_assumptions: Sequence[WitnessAssumption],
    base_bpl_text: str,
    allow_prefixes: Sequence[str] = ("dsl_", "hdr.", "meta.", "standard_metadata.", "procurator_", "clientTrack_", "leaf_", "spine_"),
    allow_vars: Optional[Sequence[str]] = None,
) -> List[str]:
    """
    Convert witness assumptions into a list of Boogie expressions for `assume(...)`.

    We keep only:
      - scalar variables declared in the Boogie program (no arrays), and
      - simple equalities `x == c` / `x = c` where c is a literal.

    `allow_prefixes` is a conservative filter to avoid pinning low-level helper
    temporaries that may make CEGIS brittle.
    """

    var_types = _parse_global_var_types(base_bpl_text)
    out: List[str] = []
    seen: set[str] = set()
    seen_vars: set[str] = set()

    allow_vars_set = set(allow_vars or [])

    def _allowed_var(var: str) -> bool:
        if allow_vars_set and var in allow_vars_set:
            return True

        # Keep the existing conservative prefix filter for stability.
        if allow_prefixes and any(var.startswith(p) for p in allow_prefixes):
            return True

        # Multi-node Boogie prefixing turns packet/meta namespaces into `<node>_hdr.*`,
        # `<node>_meta.*`, `<node>_standard_metadata.*`, etc. Allow these shapes so
        # witness-guided refinement works beyond DistCache.
        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*_(hdr|hdr_ig|hdr_eg|meta|meta_ig|meta_eg|standard_metadata)\.", var):
            return True

        return False

    for a in witness_assumptions:
        m = _RE_SIMPLE_EQ.match(a.expr.strip())
        if not m:
            continue
        var = m.group("var")
        rhs_raw = m.group("rhs").strip()

        if not _allowed_var(var):
            continue

        typ = var_types.get(var)
        if not typ:
            continue
        # Skip arrays and maps: only allow scalar vars.
        if "[" in typ and "]" in typ:
            continue

        rhs = _normalize_rhs(rhs_raw, var_type=typ)
        if rhs is None:
            continue

        # Keep at most one constraint per variable (first wins). This avoids
        # trivially inconsistent profiles like `x==0` and `x==1` when the witness
        # contains constraints from multiple steps.
        if var in seen_vars:
            continue
        seen_vars.add(var)

        expr = f"{var} == {rhs}"
        if expr in seen:
            continue
        seen.add(expr)
        out.append(expr)

    return out


def find_latest_graphml_witness(*, work_dir: Path) -> Optional[Path]:
    """
    Find the newest GraphML witness under `work_dir`.

    Ultimate's witness printer output location is not stable across releases/
    toolchains. We therefore search both:
      - `work_dir/witness/**/*.graphml` (legacy convention), and
      - `work_dir/**/*.graphml` (some toolchains emit next to the input file).
    """

    wd = work_dir.resolve()
    cands: List[Path] = []

    legacy = wd / "witness"
    if legacy.exists():
        cands.extend(list(legacy.glob("*.graphml")))
        cands.extend(list(legacy.glob("**/*.graphml")))

    # Also accept witnesses emitted directly under work_dir.
    cands.extend(list(wd.glob("*.graphml")))
    cands.extend(list(wd.glob("**/*.graphml")))
    if not cands:
        return None
    cands.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return cands[0]
