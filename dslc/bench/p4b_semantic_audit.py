#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable, Optional

if __package__ in {None, ""}:
    sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from dslc.utils.repo import repo_root


CHECK_OK = "OK"
CHECK_WEAK = "WEAK"
CHECK_FAIL = "FAIL"
CHECK_PRUNED = "PRUNED"
CHECK_SKIP = "SKIP"


@dataclass(frozen=True)
class SemanticCheck:
    feature: str
    status: str
    detail: str
    evidence: tuple[str, ...] = ()

    def as_dict(self) -> dict[str, Any]:
        return {
            "feature": self.feature,
            "status": self.status,
            "detail": self.detail,
            "evidence": list(self.evidence),
        }


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def _strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//.*", "", text)


def _strip_extern_declarations(text: str) -> str:
    text = re.sub(r"\bextern\s+\w+(?:\s*<[^{};]*>)?\s*\{.*?\}\s*;?", "", text, flags=re.S)
    text = re.sub(r"\bextern\s+[^;{}]+\s+\w+\s*(?:<[^;{}]*>)?\s*\([^;{}]*\)\s*;", "", text)
    return text


def _has(pattern: str, text: str, flags: int = 0) -> bool:
    return re.search(pattern, text, flags) is not None


def _hash_model_precisions(bpl: str, *, kind: Optional[str] = None) -> set[str]:
    pattern = r"//\s*p4b_hash_model:\s*(?P<body>[^\n]*)"
    precisions: set[str] = set()
    for match in re.finditer(pattern, bpl):
        body = match.group("body")
        if kind is not None and kind not in body:
            continue
        precision_match = re.search(r"\bprecision=([A-Za-z0-9_]+)", body)
        if precision_match:
            precisions.add(precision_match.group(1))
    return precisions


def _hash_model_details(bpl: str, *, kind: Optional[str] = None) -> tuple[str, ...]:
    out: list[str] = []
    for match in re.finditer(r"//\s*p4b_hash_model:\s*(?P<body>[^\n]*)", bpl):
        body = match.group("body").strip()
        if kind is None or kind in body:
            out.append(body)
    return tuple(out[:8])


def _call_arities(src: str, name: str) -> list[int]:
    arities: list[int] = []
    for match in re.finditer(rf"\b{re.escape(name)}\s*(?:<[^;{{}}()]*>)?\s*\(", src):
        start = match.end()
        depth = 1
        commas = 0
        i = start
        while i < len(src) and depth > 0:
            ch = src[i]
            if ch in "({[":
                depth += 1
            elif ch in ")}]":
                depth -= 1
            elif ch == "," and depth == 1:
                commas += 1
            i += 1
        if depth == 0:
            body = src[start : i - 1].strip()
            arities.append(0 if body == "" else commas + 1)
    return arities


def _source_features(source: str) -> set[str]:
    src = _strip_extern_declarations(_strip_comments(source))
    features: set[str] = set()

    if _has(r"\b(?:register|Register)\s*(?:<|\()", src):
        features.add("register")
    if _has(r"\.(?:read|write)\s*\(", src) and "register" in features:
        features.add("register_access")
    if _has(r"\b(?:Direct)?RegisterAction\s*<", src):
        features.add("register_action")
    hash_arities = _call_arities(src, "hash")
    if any(arity >= 5 for arity in hash_arities):
        features.add("v1model_hash")
    if any(arity == 3 for arity in hash_arities):
        features.add("hash_builtin_3arg")
    if _has(r"\bHash\s*<", src) and _has(r"\.(?:get|get_hash)\s*\(", src):
        features.add("hash_extern")
    if _has(r"\bRandom\s*<", src) or _has(r"\brandom\s*<", src) or _has(r"\brandom\s*\(", src):
        features.add("random")
    if (
        _has(r"\b(?:Counter|DirectCounter)\s*<", src)
        or _has(r"\b(?:counter|direct_counter)\s*(?:<|\()", src)
        or _has(r"\bCounterArray\s*\(", src)
        or _has(r"\.count\s*\(", src)
        or _has(r"\.increment\s*\(", src)
    ):
        features.add("counter")
    if "counter" in features and _has(r"\.(?:count|increment|add)\s*\(", src):
        features.add("counter_update")
    if _has(r"\b(?:Meter|DirectMeter)\s*<", src) or _has(r"\b(?:meter|direct_meter)\s*(?:<|\()", src):
        features.add("meter")
    if _has(r"\b(?:clone|clone3|clone_preserving_field_list)\s*\(", src) or _has(r"\bMirror\s*<", src):
        features.add("clone")
    if _has(r"\brecirculate\s*(?:<[^;{}()]*>)?\s*\(", src):
        features.add("recirculate")
    if _has(r"\bresubmit\s*(?:<[^;{}()]*>)?\s*\(", src) or _has(r"\bResubmit\s*<", src):
        features.add("resubmit")
    if (
        _has(r"\b(?:Checksum|Checksum16|InternetChecksum)\b", src)
        or _has(r"\b(?:verify_checksum|update_checksum|compute_hash|csum_replace[24]|ebpf_ipv4_checksum)\s*(?:<[^;{}()]*>)?\s*\(", src)
    ):
        features.add("checksum")
    if _has(r"\.extract\s*(?:<[^;{}()]*>)?\s*\(", src):
        features.add("packet_extract")
    if _has(r"\.lookahead\s*(?:<[^;{}()]*>)?\s*\(", src):
        features.add("packet_lookahead")
    if _has(r"\btable\s+\w+", src):
        features.add("table")
    if _has(r"\bActionProfile\s*\(", src) or _has(r"\bActionSelector\s*\(", src):
        features.add("action_selection")
    if _has(r"\bdigest\s*(?:<[^;{}()]*>)?\s*\(", src) or _has(r"\bDigest\s*<", src):
        features.add("digest")
    if _has(r"\bmark_to_drop\s*\(", src):
        features.add("mark_to_drop")
    if _has(r"\b(?:PNA_NIC|PSA_Switch|V1Switch|Switch)\s*\(", src):
        features.add("architecture_package")

    return features


def _bpl_has_feature(feature: str, bpl: str) -> bool:
    checks = {
        "register": r"\bvar\s+\w+\s*:\s*\[.*?\].*?;|\bfunction\b.*\.\s*read\b|\bprocedure\b.*\.\s*write\b",
        "register_access": r"\.\s*read\s*\(|\.\s*write\s*\(",
        "register_action": r"RegisterAction|__ra_val_|__ra_ret_",
        "v1model_hash": r"\bfunction\s+hash[_$A-Za-z0-9.]*\(",
        "hash_extern": r"\bfunction\s+[A-Za-z0-9_.]+\.(?:get|get_hash)[A-Za-z0-9_$]*\(",
        "random": r"__random_read_|havoc\s+__random_read_",
        "counter": r"__counter_|\.count\s*\(|\.increment\s*\(|\.add\s*\(|//\s*count\b",
        "meter": r"\.execute\s*\(|execute_meter|//\s*execute_meter\b",
        "clone": r"p4b_clone_(?:i2e|e2e|i2i)",
        "recirculate": r"p4b_recirculate",
        "resubmit": r"p4b_recirculate",
        "checksum": r"\bfunction\s+(?:compute_hash|csum_replace[24]|ebpf_ipv4_checksum)|verify_checksum|update_checksum|//\s*(?:verify_checksum|update_checksum)\b",
        "packet_extract": r"packet_in\.extract|isValid\[.*?\]\s*==\s*true|\.valid\s*:=\s*true",
        "packet_lookahead": r"lookahead|havoc",
        "table": r"\.apply\(\)|action_run|\.hit\b",
        "action_selection": r"ActionProfile|ActionSelector|action_run",
        "digest": r"p4b_digest|//\s*digest\b",
        "mark_to_drop": r"mark_to_drop|drop\s*==\s*true|drop\s*:=\s*true",
        "checksum": r"p4b_checksum_(?:verified|updated|error)|\bfunction\s+(?:compute_hash|csum_replace[24]|ebpf_ipv4_checksum)|verify_checksum|update_checksum|//\s*(?:verify_checksum|update_checksum)\b",
        "architecture_package": r"procedure\s+mainProcedure|p4b_clone_|p4b_recirculate",
    }
    pattern = checks.get(feature)
    return bool(pattern and _has(pattern, bpl, re.S))


def _check_register(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_read = _has(r"\bfunction\b.*\.\s*read\s*\(", bpl)
    has_write = _has(r"\bprocedure\b.*\.\s*write\s*\(", bpl)
    has_mirrors = all(token in bpl for token in ("__wrote_any", "__last_value", "__last0_value"))
    if has_read and has_write and has_mirrors:
        return SemanticCheck("register", CHECK_OK, "register array, read/write procedures, and write mirrors are present")
    if slicing_mode and not (has_read or has_write or has_mirrors):
        return SemanticCheck("register", CHECK_PRUNED, "register feature appears pruned from sliced BPL")
    missing = []
    if not has_read:
        missing.append("read function")
    if not has_write:
        missing.append("write procedure")
    if not has_mirrors:
        missing.append("write mirrors")
    return SemanticCheck("register", CHECK_FAIL, "missing " + ", ".join(missing))


def _check_register_action(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_ra = "RegisterAction" in bpl or "__ra_val_" in bpl or "__ra_ret_" in bpl
    has_rw = _has(r"\.\s*read\s*\(", bpl) and _has(r"\.\s*write\s*\(", bpl)
    if has_ra and has_rw:
        return SemanticCheck("register_action", CHECK_OK, "RegisterAction lowers to register read/apply/write sequence")
    if slicing_mode and not has_ra:
        return SemanticCheck("register_action", CHECK_PRUNED, "RegisterAction feature appears pruned from sliced BPL")
    return SemanticCheck("register_action", CHECK_FAIL, "missing RegisterAction temporaries or underlying register read/write")


def _check_v1model_hash(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    precisions = _hash_model_precisions(bpl, kind="builtin")
    has_function = _has(r"\bfunction\s+hash[_$A-Za-z0-9.]*\(", bpl)
    has_range = _has(r"assume\s*\(\s*buge\.bv\d+\(.*?bule\.bv\d+\(", bpl, re.S)
    if "weak" in precisions:
        return SemanticCheck(
            "v1model_hash",
            CHECK_WEAK,
            "hash uses havoc fallback for unsupported data shape",
            _hash_model_details(bpl, kind="builtin"),
        )
    if "deterministic_uninterpreted" in precisions:
        detail = "hash is deterministic and range-constrained but algorithm is uninterpreted"
        if has_range or has_function:
            return SemanticCheck("v1model_hash", CHECK_WEAK, detail, _hash_model_details(bpl, kind="builtin"))
    if "precise" in precisions:
        return SemanticCheck("v1model_hash", CHECK_OK, "hash algorithm is modeled precisely", _hash_model_details(bpl, kind="builtin"))
    if has_function and has_range:
        return SemanticCheck("v1model_hash", CHECK_WEAK, "hash is deterministic and range-constrained but algorithm precision is unmarked")
    if slicing_mode and not (has_function or "// hash" in bpl):
        return SemanticCheck("v1model_hash", CHECK_PRUNED, "hash call appears pruned from sliced BPL")
    if "// hash" in bpl:
        return SemanticCheck("v1model_hash", CHECK_FAIL, "hash call survived only as a comment/no-op")
    return SemanticCheck("v1model_hash", CHECK_FAIL, "missing deterministic hash function or range assume")


def _check_hash_builtin_3arg(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    precisions = _hash_model_precisions(bpl, kind="builtin")
    has_function = _has(r"\bfunction\s+hash[_$A-Za-z0-9.]*\(", bpl)
    has_assign = _has(r":=\s*hash[_$A-Za-z0-9.]*\(", bpl)
    if "target_helper" in precisions:
        return SemanticCheck(
            "hash_builtin_3arg",
            CHECK_OK,
            "three-argument hash is summarized as the target runtime helper",
            _hash_model_details(bpl, kind="builtin"),
        )
    if "weak" in precisions:
        return SemanticCheck("hash_builtin_3arg", CHECK_WEAK, "three-argument hash uses havoc fallback", _hash_model_details(bpl, kind="builtin"))
    if "deterministic_uninterpreted" in precisions:
        return SemanticCheck(
            "hash_builtin_3arg",
            CHECK_WEAK,
            "three-argument hash lowers to a deterministic uninterpreted function",
            _hash_model_details(bpl, kind="builtin"),
        )
    if "precise" in precisions:
        return SemanticCheck("hash_builtin_3arg", CHECK_OK, "three-argument hash algorithm is modeled precisely", _hash_model_details(bpl, kind="builtin"))
    if has_function and has_assign:
        return SemanticCheck("hash_builtin_3arg", CHECK_WEAK, "three-argument hash lowers to an unmarked deterministic function assignment")
    if slicing_mode and not (has_function or "// hash" in bpl):
        return SemanticCheck("hash_builtin_3arg", CHECK_PRUNED, "three-argument hash appears pruned from sliced BPL")
    if "// hash" in bpl:
        return SemanticCheck("hash_builtin_3arg", CHECK_FAIL, "three-argument hash survived only as a comment/no-op")
    return SemanticCheck("hash_builtin_3arg", CHECK_FAIL, "missing deterministic three-argument hash assignment")


def _check_hash_extern(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    precisions = _hash_model_precisions(bpl, kind="extern")
    has_function = _has(r"\bfunction\s+[A-Za-z0-9_.]+\.(?:get|get_hash)[A-Za-z0-9_$]*\(", bpl)
    has_havoc_fallback = "__hash_get_" in bpl and _has(r"havoc\s+__hash_get_", bpl)
    if "target_helper" in precisions:
        return SemanticCheck(
            "hash_extern",
            CHECK_OK,
            "Hash.get/get_hash is summarized as the target runtime helper",
            _hash_model_details(bpl, kind="extern"),
        )
    if "deterministic_uninterpreted" in precisions:
        return SemanticCheck(
            "hash_extern",
            CHECK_WEAK,
            "Hash.get/get_hash lowers to a deterministic uninterpreted function",
            _hash_model_details(bpl, kind="extern"),
        )
    if "weak" in precisions:
        return SemanticCheck("hash_extern", CHECK_WEAK, "Hash extern uses havoc fallback for unsupported data shape", _hash_model_details(bpl, kind="extern"))
    if "precise" in precisions:
        return SemanticCheck("hash_extern", CHECK_OK, "Hash.get/get_hash algorithm is modeled precisely", _hash_model_details(bpl, kind="extern"))
    if has_function:
        return SemanticCheck("hash_extern", CHECK_WEAK, "Hash.get/get_hash lowers to an unmarked uninterpreted function of typed data")
    if slicing_mode and not has_havoc_fallback:
        return SemanticCheck("hash_extern", CHECK_PRUNED, "Hash extern appears pruned from sliced BPL")
    if has_havoc_fallback:
        return SemanticCheck("hash_extern", CHECK_WEAK, "Hash extern uses havoc fallback for unsupported data shape")
    return SemanticCheck("hash_extern", CHECK_FAIL, "missing Hash.get/get_hash model")


def _check_random(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_tmp = "__random_read_" in bpl and _has(r"havoc\s+__random_read_", bpl)
    has_range = _has(r"assume\s*\(.*?(?:buge\.bv\d+|>=).*?(?:bule\.bv\d+|>=).*?\)", bpl, re.S)
    if has_tmp and has_range:
        return SemanticCheck("random", CHECK_OK, "random read is havoced and constrained to constructor bounds")
    if has_tmp:
        return SemanticCheck("random", CHECK_WEAK, "random read is havoced but no bounds were found")
    if slicing_mode:
        return SemanticCheck("random", CHECK_PRUNED, "random feature appears pruned from sliced BPL")
    if "// random" in bpl:
        return SemanticCheck("random", CHECK_FAIL, "random call survived only as a comment/no-op")
    return SemanticCheck("random", CHECK_FAIL, "missing random read model")


def _check_counter(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_state = _has(r"\bvar\s+[A-Za-z_][A-Za-z0-9_.]*__counter\s*:", bpl) or _has(r"\bvar\s+\w+__count(?:_|:)", bpl)
    has_proc = _has(r"\bprocedure\b.*\.(?:count|increment|add)\s*\(", bpl)
    has_call = _has(r"\bcall\s+.*\.(?:count|increment|add)\s*\(", bpl)
    if has_state and has_proc:
        return SemanticCheck("counter", CHECK_OK, "counter state and update procedures are present")
    if slicing_mode and not (has_state or has_proc or has_call or "// count" in bpl):
        return SemanticCheck("counter", CHECK_PRUNED, "counter feature appears pruned from sliced BPL")
    if "// count" in bpl and not (has_state or has_proc or has_call):
        return SemanticCheck("counter", CHECK_FAIL, "counter update survived only as a comment/no-op")
    if has_proc or has_call:
        return SemanticCheck("counter", CHECK_WEAK, "counter has an uninterpreted call/procedure but no state summary")
    return SemanticCheck("counter", CHECK_FAIL, "missing counter update model")


def _check_counter_update(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_call = _has(r"\bcall\s+.*\.(?:count|increment|add)\s*\(", bpl)
    if has_call:
        return SemanticCheck("counter_update", CHECK_OK, "explicit counter update lowers to a stateful call")
    if slicing_mode and "// count" not in bpl:
        return SemanticCheck("counter_update", CHECK_PRUNED, "counter update appears pruned from sliced BPL")
    if "// count" in bpl:
        return SemanticCheck("counter_update", CHECK_FAIL, "counter update survived only as a comment/no-op")
    return SemanticCheck("counter_update", CHECK_FAIL, "missing explicit counter update call")


def _check_meter(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_call = _has(r"\bcall\s+.*\.execute\s*\(", bpl) or _has(r":=\s*.*\.execute\s*\(", bpl) or _has(r"execute_meter", bpl)
    has_proc = _has(r"\bprocedure\s+.*\.execute\s*\(", bpl)
    has_state = "__meter" in bpl and "__last_index" in bpl and "__executed_any" in bpl
    if has_state and (has_call or has_proc):
        return SemanticCheck("meter", CHECK_OK, "meter state and execute model are present")
    if has_call or has_proc:
        return SemanticCheck("meter", CHECK_WEAK, "meter execute is retained as an uninterpreted effect")
    if slicing_mode:
        return SemanticCheck("meter", CHECK_PRUNED, "meter feature appears pruned from sliced BPL")
    return SemanticCheck("meter", CHECK_FAIL, "missing meter execute model")


def _check_flag(feature: str, bpl: str, flag: str, detail: str, *, slicing_mode: bool) -> SemanticCheck:
    if flag in bpl and _has(rf"{re.escape(flag)}\s*:=", bpl):
        return SemanticCheck(feature, CHECK_OK, detail)
    if slicing_mode and flag not in bpl:
        return SemanticCheck(feature, CHECK_PRUNED, f"{feature} feature appears pruned from sliced BPL")
    return SemanticCheck(feature, CHECK_FAIL, f"missing {flag} flag update")


def _check_checksum(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_function = _has(r"\bfunction\s+(?:compute_hash|csum_replace[24]|ebpf_ipv4_checksum)", bpl)
    has_event_summary = (
        "p4b_checksum_verified" in bpl
        or "p4b_checksum_updated" in bpl
        or "p4b_checksum_error" in bpl
    )
    has_extern_summary = _has(r"\bfunction\s+[A-Za-z0-9_.]+\.get\s*\(", bpl) and _has(r"\bcall\s+[A-Za-z0-9_.]+\.(?:clear|add|subtract)\s*\(", bpl)
    has_comment = _has(r"//\s*(?:verify_checksum|update_checksum)\b", bpl)
    if has_function:
        return SemanticCheck("checksum", CHECK_OK, "checksum/hash helper lowers to a pure Boogie function")
    if has_event_summary:
        return SemanticCheck("checksum", CHECK_OK, "checksum update/verification is modeled by conservative event flags and nondet value updates")
    if has_extern_summary:
        return SemanticCheck("checksum", CHECK_WEAK, "checksum extern is retained as clear/add/get summary")
    if has_comment:
        return SemanticCheck("checksum", CHECK_WEAK, "checksum verification/update is retained only as a coarse comment")
    if slicing_mode:
        return SemanticCheck("checksum", CHECK_PRUNED, "checksum feature appears pruned from sliced BPL")
    return SemanticCheck("checksum", CHECK_FAIL, "missing checksum model")


def _check_packet_extract(bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    has_proc = "packet_in.extract" in bpl
    has_validity = _has(r"isValid\[.*?\]\s*==\s*true|\.valid\s*:=\s*true", bpl)
    if has_proc and has_validity:
        return SemanticCheck("packet_extract", CHECK_OK, "extract marks the target header valid")
    if slicing_mode and not (has_proc or has_validity):
        return SemanticCheck("packet_extract", CHECK_PRUNED, "extract feature appears pruned from sliced BPL")
    return SemanticCheck("packet_extract", CHECK_FAIL, "missing extract validity effect")


def _check_generic(feature: str, bpl: str, *, slicing_mode: bool) -> SemanticCheck:
    if _bpl_has_feature(feature, bpl):
        return SemanticCheck(feature, CHECK_OK, "feature has matching BPL evidence")
    if slicing_mode:
        return SemanticCheck(feature, CHECK_PRUNED, f"{feature} appears pruned from sliced BPL")
    return SemanticCheck(feature, CHECK_FAIL, "missing BPL evidence")


def audit_text(source: str, bpl: str, meta: Optional[dict[str, Any]] = None, *, slicing_mode: bool = False) -> dict[str, Any]:
    features = sorted(_source_features(source))
    checks: list[SemanticCheck] = []
    meta = meta or {}

    for feature in features:
        if feature == "register":
            checks.append(_check_register(bpl, slicing_mode=slicing_mode))
        elif feature == "register_access":
            continue
        elif feature == "register_action":
            checks.append(_check_register_action(bpl, slicing_mode=slicing_mode))
        elif feature == "v1model_hash":
            checks.append(_check_v1model_hash(bpl, slicing_mode=slicing_mode))
        elif feature == "hash_builtin_3arg":
            checks.append(_check_hash_builtin_3arg(bpl, slicing_mode=slicing_mode))
        elif feature == "hash_extern":
            checks.append(_check_hash_extern(bpl, slicing_mode=slicing_mode))
        elif feature == "random":
            checks.append(_check_random(bpl, slicing_mode=slicing_mode))
        elif feature == "counter":
            checks.append(_check_counter(bpl, slicing_mode=slicing_mode))
        elif feature == "counter_update":
            checks.append(_check_counter_update(bpl, slicing_mode=slicing_mode))
        elif feature == "meter":
            checks.append(_check_meter(bpl, slicing_mode=slicing_mode))
        elif feature == "clone":
            checks.append(_check_flag("clone", bpl, "p4b_clone_i2e", "clone/mirror updates clone flags", slicing_mode=slicing_mode))
        elif feature == "recirculate":
            checks.append(_check_flag("recirculate", bpl, "p4b_recirculate", "recirculate updates packet recirculation flag", slicing_mode=slicing_mode))
        elif feature == "resubmit":
            checks.append(_check_flag("resubmit", bpl, "p4b_recirculate", "resubmit is modeled as a recirculation event", slicing_mode=slicing_mode))
        elif feature == "checksum":
            checks.append(_check_checksum(bpl, slicing_mode=slicing_mode))
        elif feature == "packet_extract":
            checks.append(_check_packet_extract(bpl, slicing_mode=slicing_mode))
        else:
            checks.append(_check_generic(feature, bpl, slicing_mode=slicing_mode))

    register_sizes = meta.get("register_sizes")
    if "register" in features and isinstance(register_sizes, dict) and checks:
        for i, check in enumerate(checks):
            if check.feature == "register" and check.status == CHECK_OK:
                checks[i] = SemanticCheck(
                    check.feature,
                    check.status,
                    check.detail + "; meta register_sizes is present",
                    tuple(sorted(register_sizes.keys())[:8]),
                )
                break

    statuses = [c.status for c in checks]
    if CHECK_FAIL in statuses:
        overall = CHECK_FAIL
    elif CHECK_WEAK in statuses:
        overall = CHECK_WEAK
    elif CHECK_OK in statuses:
        overall = CHECK_OK
    elif CHECK_PRUNED in statuses:
        overall = CHECK_SKIP
    else:
        overall = CHECK_SKIP

    return {
        "semantic_status": overall,
        "semantic_features": features,
        "semantic_checks": [c.as_dict() for c in checks],
        "semantic_failures": [
            f"{c.feature}: {c.detail}" for c in checks if c.status in {CHECK_FAIL, CHECK_WEAK}
        ],
    }


def audit_paths(source_path: Path, bpl_path: Path, meta_path: Optional[Path] = None, *, slicing_mode: bool = False) -> dict[str, Any]:
    source = _read(source_path)
    bpl = _read(bpl_path)
    meta: Optional[dict[str, Any]] = None
    if meta_path is not None and meta_path.exists():
        try:
            meta = json.loads(_read(meta_path))
        except json.JSONDecodeError:
            meta = None
    return audit_text(source, bpl, meta, slicing_mode=slicing_mode)


def _resolve_report_path(root: Path, item: Optional[str]) -> Optional[Path]:
    if not item:
        return None
    path = Path(item)
    if not path.is_absolute():
        path = root / path
    return path


def audit_record(root: Path, record: dict[str, Any], *, slicing_mode: bool = False) -> dict[str, Any]:
    if record.get("status") != "OK":
        return {
            "semantic_status": CHECK_SKIP,
            "semantic_features": [],
            "semantic_checks": [],
            "semantic_failures": [],
        }
    source = _resolve_report_path(root, record.get("path"))
    bpl = _resolve_report_path(root, record.get("out_bpl"))
    meta = _resolve_report_path(root, record.get("out_meta"))
    if source is None or bpl is None or not source.exists() or not bpl.exists():
        return {
            "semantic_status": CHECK_FAIL,
            "semantic_features": [],
            "semantic_checks": [],
            "semantic_failures": ["missing source or BPL artifact for semantic audit"],
        }
    return audit_paths(source, bpl, meta, slicing_mode=slicing_mode)


def _counts(records: Iterable[dict[str, Any]]) -> dict[str, int]:
    counts: dict[str, int] = {}
    for rec in records:
        status = str(rec.get("semantic_status", CHECK_SKIP))
        counts[status] = counts.get(status, 0) + 1
    return dict(sorted(counts.items()))


def _markdown(report: dict[str, Any]) -> str:
    records = report.get("records", [])
    lines = [
        "# P4B Semantic Audit",
        "",
        f"Generated from: `{report.get('coverage_json', '-')}`",
        f"Mode: `{'with-slicing' if report.get('with_slicing') else 'base-no-slicing'}`",
        "",
        "## Summary",
        "",
        "| semantic status | count |",
        "|---|---:|",
    ]
    for key, value in _counts(records).items():
        lines.append(f"| `{key}` | {value} |")
    lines.extend(["", "## Weak Or Failing Checks", "", "| path | semantic | details |", "|---|---|---|"])
    for rec in records:
        status = rec.get("semantic_status", CHECK_SKIP)
        if status not in {CHECK_FAIL, CHECK_WEAK}:
            continue
        failures = "<br>".join(rec.get("semantic_failures") or [])
        lines.append(f"| `{rec.get('path', '-')}` | `{status}` | {failures} |")
    lines.append("")
    return "\n".join(lines)


def audit_coverage_report(coverage: dict[str, Any], *, root: Path, slicing_mode: Optional[bool] = None) -> dict[str, Any]:
    with_slicing = bool(coverage.get("with_slicing")) if slicing_mode is None else slicing_mode
    out_records: list[dict[str, Any]] = []
    for record in coverage.get("records", []):
        rec = dict(record)
        rec.update(audit_record(root, rec, slicing_mode=with_slicing))
        out_records.append(rec)
    out = dict(coverage)
    out["with_slicing"] = with_slicing
    out["records"] = out_records
    return out


def main(argv: Optional[list[str]] = None) -> int:
    ap = argparse.ArgumentParser(description="Audit whether P4 architecture features have BPL semantic evidence.")
    ap.add_argument("--coverage-json", required=True, help="Input coverage.json produced by scan_p4b_coverage.py.")
    ap.add_argument("--out-json", default="", help="Output audited JSON. Defaults to <coverage-dir>/semantic_coverage.json.")
    ap.add_argument("--out-md", default="", help="Output Markdown summary. Defaults to <coverage-dir>/semantic_coverage.md.")
    ap.add_argument("--slicing-mode", choices=["auto", "base", "slicing"], default="auto")
    ns = ap.parse_args(argv)

    root = repo_root()
    coverage_path = Path(ns.coverage_json)
    if not coverage_path.is_absolute():
        coverage_path = root / coverage_path
    coverage = json.loads(_read(coverage_path))
    if ns.slicing_mode == "auto":
        slicing_mode = None
    else:
        slicing_mode = ns.slicing_mode == "slicing"
    audited = audit_coverage_report(coverage, root=root, slicing_mode=slicing_mode)
    audited["coverage_json"] = str(coverage_path)

    out_json = Path(ns.out_json) if ns.out_json else coverage_path.parent / "semantic_coverage.json"
    out_md = Path(ns.out_md) if ns.out_md else coverage_path.parent / "semantic_coverage.md"
    if not out_json.is_absolute():
        out_json = root / out_json
    if not out_md.is_absolute():
        out_md = root / out_md
    out_json.write_text(json.dumps(audited, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    out_md.write_text(_markdown(audited), encoding="utf-8")
    print(f"wrote {out_json}")
    print(f"wrote {out_md}")
    statuses = [r.get("semantic_status") for r in audited.get("records", [])]
    return 1 if CHECK_FAIL in statuses else 0


if __name__ == "__main__":
    raise SystemExit(main())
