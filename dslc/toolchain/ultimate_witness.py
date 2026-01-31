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


_RE_SIMPLE_EQ = re.compile(r"^(?P<var>[A-Za-z_][A-Za-z0-9_.]*)\s*(==|=)\s*(?P<rhs>.+)$")


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


def extract_assumptions_from_graphml(graphml_text: str) -> List[WitnessAssumption]:
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
    for node_id, txt in _iter_graphml_data_text(root):
        # Split multi-line / multi-statement payloads.
        parts = [p.strip() for p in re.split(r"[;\n]+", txt) if p.strip()]
        for p in parts:
            # Keep only equalities/assignments. This is intentionally conservative: we
            # want constraints that are easy to re-inject as Boogie assumes.
            if _RE_SIMPLE_EQ.match(p):
                out.append(WitnessAssumption(expr=p, node_id=node_id))
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

    for a in witness_assumptions:
        m = _RE_SIMPLE_EQ.match(a.expr.strip())
        if not m:
            continue
        var = m.group("var")
        rhs_raw = m.group("rhs").strip()

        if allow_prefixes and not any(var.startswith(p) for p in allow_prefixes):
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

        expr = f"{var} == {rhs}"
        if expr in seen:
            continue
        seen.add(expr)
        out.append(expr)

    return out


def find_latest_graphml_witness(*, work_dir: Path) -> Optional[Path]:
    """
    Find the newest GraphML witness under `work_dir/witness/`.
    """

    wd = (work_dir / "witness").resolve()
    if not wd.exists():
        return None
    cands = list(wd.glob("*.graphml")) + list(wd.glob("**/*.graphml"))
    if not cands:
        return None
    cands.sort(key=lambda p: p.stat().st_mtime, reverse=True)
    return cands[0]

