from __future__ import annotations

import re
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple


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
