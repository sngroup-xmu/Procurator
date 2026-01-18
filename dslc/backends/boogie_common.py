from __future__ import annotations

import re


_SKIP_INPUT_VARS = {
    # Forwarding control/output metadata (should not be havoc'ed as external input).
    "standard_metadata.egress_port",
    "standard_metadata.egress_spec",
    "ig_intr_tm_md.ucast_egress_port",
    "ig_tm_md.ucast_egress_port",
    "eg_intr_md.egress_port",
}

_SKIP_INPUT_SUFFIX_RE = re.compile(r"\.(?:ucast_egress_port|egress_port|egress_spec)(?:_\d+)?$")


def is_skipped_input_var(name: str) -> bool:
    return name in _SKIP_INPUT_VARS or bool(_SKIP_INPUT_SUFFIX_RE.search(name))


def is_on_wire_packet_var(name: str) -> bool:
    """
    Vars that should be preserved across *network forwarding*.

    In P4, only packet headers are transmitted across links. Per-packet `meta.*`
    and `standard_metadata.*` are local to each switch instance and must not be
    copied from one node to another.
    """
    return name.startswith("hdr.")


def is_packet_var(name: str) -> bool:
    return name.startswith(("hdr.", "meta.", "standard_metadata.")) or "_md." in name


def dsl_is_simple_local_name(name: str) -> bool:
    # No dotted/indexed names: those are assumed to be P4/Boogie vars.
    return bool(name) and ("." not in name) and ("[" not in name) and re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", name)


def dsl_type_to_boogie(dsl_typ: str) -> str:
    if dsl_typ == "int":
        return "int"
    if dsl_typ == "bool":
        return "bool"
    # Defensive fallback
    return "int"
