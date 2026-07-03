#!/usr/bin/env python3
from __future__ import annotations

import argparse
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Optional, Tuple


def _parse_float(text: str) -> Optional[float]:
    text = text.strip()
    if not text or text == "-":
        return None
    try:
        return float(text)
    except Exception:
        return None


_SYSTEM_ORDER: List[str] = [
    "NetChain",
    "P4xos",
    "Gecko",
    "DistCache",
    "ATP",
    "Cheetah",
    "DDOSD",
    "FRR",
    "FissLock",
    "NetLock",
    "P4DB",
    "P4NIS",
]

_SYSTEM_DISPLAY: Dict[str, str] = {
    "atp": "ATP",
    "cheetah": "Cheetah",
    "ddosd": "DDOSD",
    "distcache": "DistCache",
    "fisslock": "FissLock",
    "frr": "FRR",
    "gecko": "Gecko",
    "netchain": "NetChain",
    "netlock": "NetLock",
    "p4db": "P4DB",
    "p4nis": "P4NIS",
    "p4xos": "P4xos",
}

# Align assertion naming with Tab. bugs (paper table).
_ASSERTION_META_BY_STEM: Dict[str, Dict[str, object]] = {
    # NetChain
    "netchain_wraparound_bug": {
        "system": "NetChain",
        "assertion": "Replica monotonicity",
        "category": "Wraparound",
        "order": 1,
    },
    # P4xos
    "p4xos_bug": {
        "system": "P4xos",
        "assertion": "Instance indexing safety",
        "category": "Implementation",
        "order": 2,
    },
    "p4xos_dropflag_bug": {
        "system": "P4xos",
        "assertion": "Quorum delivery",
        "category": "Implementation",
        "order": 3,
    },
    "p4xos_majority_quorum_bug": {
        "system": "P4xos",
        "assertion": "Quorum safety",
        "category": "Interleaving",
        "order": 4,
    },
    # Gecko
    "gecko_bug1_timer_loss": {
        "system": "Gecko",
        "assertion": "Timer progress",
        "category": "Functional",
        "order": 5,
    },
    "gecko_bug2_concurrency": {
        "system": "Gecko",
        "assertion": "Concurrency handling",
        "category": "Interleaving",
        "order": 6,
    },
    "gecko_bug3_timer_init": {
        "system": "Gecko",
        "assertion": "Initialization safety",
        "category": "Implementation",
        "order": 7,
    },
    # DistCache
    "distcache_leaf_pktloss_clone_drop_bug": {
        "system": "DistCache",
        "assertion": "Loss-handling correctness",
        "category": "Functional",
        "order": 8,
    },
    "distcache_cm34_write_bug": {
        "system": "DistCache",
        "assertion": "Sketch update integrity",
        "category": "Implementation",
        "order": 9,
    },
    "distcache_spine_cache_frequency_idx_bug": {
        "system": "DistCache",
        "assertion": "Cache-frequency update",
        "category": "Implementation",
        "order": 10,
    },
    "distcache_p2c_spineload_wraparound_bug": {
        "system": "DistCache",
        "assertion": "spine selection correctness",
        "category": "Wraparound",
        "order": 11,
    },
    "distcache_p2c_wraparound_bug": {
        "system": "DistCache",
        "assertion": "Overflow-driven progress",
        "category": "Wraparound",
        "order": 12,
    },
    # ATP
    "atp_bug": {
        "system": "ATP",
        "assertion": "Aggregation path safety",
        "category": "Implementation",
        "order": 13,
    },
    "atp_count_mismatch_bug": {
        "system": "ATP",
        "assertion": "Aggregation correctness",
        "category": "Functional",
        "order": 14,
    },
    # Cheetah
    "cheetah_slot_index_collision_bug": {
        "system": "Cheetah",
        "assertion": "Slot allocation safety",
        "category": "Implementation",
        "order": 15,
    },
    # DDOSD
    "ddosd_window_label_collision_bug": {
        "system": "DDOSD",
        "assertion": "Window label uniqueness",
        "category": "Implementation",
        "order": 16,
    },
    # FRR
    "frr_bug1_unexpected_mirror": {
        "system": "FRR",
        "assertion": "Loop freedom",
        "category": "Implementation",
        "order": 17,
    },
    "frr_bug2_state_inconsistency": {
        "system": "FRR",
        "assertion": "Routing-state invariant",
        "category": "Interleaving",
        "order": 18,
    },
    # FissLock
    "fisslock_notification_cnt_wraparound_bug": {
        "system": "FissLock",
        "assertion": "Transfer safety",
        "category": "Wraparound",
        "order": 19,
    },
    # NetLock
    "netlock_pkt_type_bug": {
        "system": "NetLock",
        "assertion": "Packet-type soundness",
        "category": "Implementation",
        "order": 20,
    },
    "netlock_pushback_length_in_server_underflow_bug": {
        "system": "NetLock",
        "assertion": "Push-back robustness",
        "category": "Implementation",
        "order": 21,
    },
    "netlock_release_counter_underflow_bug": {
        "system": "NetLock",
        "assertion": "Release counter safety",
        "category": "Implementation",
        "order": 22,
    },
    "netlock_release_empty_queue_head_bug": {
        "system": "NetLock",
        "assertion": "Queue head safety",
        "category": "Functional",
        "order": 23,
    },
    "netlock_release_empty_slots_overflow_bug": {
        "system": "NetLock",
        "assertion": "Capacity invariant",
        "category": "Implementation",
        "order": 24,
    },
    # P4DB
    "p4db_router_ttl_expiry_bug": {
        "system": "P4DB",
        "assertion": "TTL safety",
        "category": "Implementation",
        "order": 25,
    },
    "p4db_damper_threshold_off_by_one_bug": {
        "system": "P4DB",
        "assertion": "Damper threshold behavior",
        "category": "Implementation",
        "order": 26,
    },
    # P4NIS
    "p4nis_bug1_forwarding_sequence_desync": {
        "system": "P4NIS",
        "assertion": "Forwarding correctness",
        "category": "Interleaving",
        "order": 27,
    },
    "p4nis_bug2_tunnel_state_leakage": {
        "system": "P4NIS",
        "assertion": "Tunnel isolation",
        "category": "Functional",
        "order": 28,
    },
}


def _system_display_for_spec(spec: str) -> str:
    stem = Path(spec).stem
    meta = _ASSERTION_META_BY_STEM.get(stem)
    if meta:
        return str(meta["system"])
    prefix = stem.split("_", 1)[0].lower()
    return _SYSTEM_DISPLAY.get(prefix, prefix)


def _assertion_display_for_spec(spec: str) -> str:
    stem = Path(spec).stem
    meta = _ASSERTION_META_BY_STEM.get(stem)
    if meta:
        return str(meta["assertion"])
    return stem


def _spec_order(spec: str) -> int:
    stem = Path(spec).stem
    meta = _ASSERTION_META_BY_STEM.get(stem)
    if meta and "order" in meta:
        return int(meta["order"])
    return 10_000


def _escape_latex(text: str) -> str:
    rep = {
        "\\": r"\textbackslash{}",
        "_": r"\_",
        "&": r"\&",
        "%": r"\%",
        "$": r"\$",
        "#": r"\#",
        "{": r"\{",
        "}": r"\}",
    }
    for k, v in rep.items():
        text = text.replace(k, v)
    return text


def _parse_md_table(md_path: Path) -> Tuple[List[str], List[Dict[str, str]], int, int]:
    lines = md_path.read_text(encoding="utf-8").splitlines()
    header_idx = -1
    for i, ln in enumerate(lines):
        if ln.strip().startswith("| spec |") or ln.strip().startswith("| system |"):
            header_idx = i
            break
    if header_idx < 0 or header_idx + 1 >= len(lines):
        raise RuntimeError(f"table header not found in {md_path}")

    sep_idx = header_idx + 1
    row_end = sep_idx + 1
    while row_end < len(lines) and lines[row_end].strip().startswith("|"):
        row_end += 1

    header_cells = [c.strip() for c in lines[header_idx].strip().strip("|").split("|")]
    rows: List[Dict[str, str]] = []
    for ln in lines[sep_idx + 1 : row_end]:
        cells = [c.strip() for c in ln.strip().strip("|").split("|")]
        if len(cells) != len(header_cells):
            continue
        rows.append(dict(zip(header_cells, cells)))
    return lines, rows, header_idx, row_end


def _rewrite_md_with_system(
    md_path: Path,
    lines: List[str],
    rows: List[Dict[str, str]],
    header_idx: int,
    row_end: int,
) -> List[Dict[str, str]]:
    normalized_rows: List[Dict[str, str]] = []
    for r in rows:
        spec = r["spec"]
        # Always derive from spec to keep display names stable (NetChain/P4xos/...).
        system = _system_display_for_spec(spec.strip("`"))

        nr = {
            "system": f"`{system}`",
            "spec": spec,
            "encode slicing(s)": r["encode slicing(s)"],
            "run slicing(s)": r["run slicing(s)"],
            "total slicing(s)": r["total slicing(s)"],
            "encode noslicing(s)": r["encode noslicing(s)"],
            "run noslicing(s)": r["run noslicing(s)"],
            "total noslicing(s)": r["total noslicing(s)"],
            "total speedup(noslicing/slicing)": r["total speedup(noslicing/slicing)"],
            "wrap stages slicing(e/c/cl)": r["wrap stages slicing(e/c/cl)"],
            "wrap stages noslicing(e/c/cl)": r["wrap stages noslicing(e/c/cl)"],
        }
        normalized_rows.append(nr)

    new_header = (
        "| system | spec | encode slicing(s) | run slicing(s) | total slicing(s) | "
        "encode noslicing(s) | run noslicing(s) | total noslicing(s) | "
        "total speedup(noslicing/slicing) | wrap stages slicing(e/c/cl) | "
        "wrap stages noslicing(e/c/cl) |"
    )
    new_sep = "|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|"
    new_rows = []
    for r in normalized_rows:
        new_rows.append(
            "| "
            + " | ".join(
                [
                    r["system"],
                    r["spec"],
                    r["encode slicing(s)"],
                    r["run slicing(s)"],
                    r["total slicing(s)"],
                    r["encode noslicing(s)"],
                    r["run noslicing(s)"],
                    r["total noslicing(s)"],
                    r["total speedup(noslicing/slicing)"],
                    r["wrap stages slicing(e/c/cl)"],
                    r["wrap stages noslicing(e/c/cl)"],
                ]
            )
            + " |"
        )

    rewritten = lines[:header_idx] + [new_header, new_sep] + new_rows + lines[row_end:]
    md_path.write_text("\n".join(rewritten) + "\n", encoding="utf-8")
    return normalized_rows


def _build_system_aggregate(rows: List[Dict[str, str]]) -> List[Dict[str, object]]:
    agg: Dict[str, Dict[str, float]] = defaultdict(lambda: {"cases": 0.0, "sum_s": 0.0, "sum_n": 0.0})
    for r in rows:
        ts = _parse_float(r["total slicing(s)"])
        tn = _parse_float(r["total noslicing(s)"])
        if ts is None or tn is None:
            continue  # exclude NA rows
        system_raw = r["system"].strip("`")
        system = _SYSTEM_DISPLAY.get(system_raw.lower(), system_raw)
        agg[system]["cases"] += 1
        agg[system]["sum_s"] += ts
        agg[system]["sum_n"] += tn

    out: List[Dict[str, object]] = []
    order_idx = {s: i for i, s in enumerate(_SYSTEM_ORDER)}
    for system in sorted(agg.keys(), key=lambda s: (order_idx.get(s, 999), s)):
        rec = agg[system]
        c = int(rec["cases"])
        ss = rec["sum_s"]
        sn = rec["sum_n"]
        speedup = (sn / ss) if ss > 0 else None
        avg_delta = ((sn - ss) / c) if c > 0 else None
        out.append(
            {
                "system": system,
                "cases": c,
                "slicing_total_s": ss,
                "noslicing_total_s": sn,
                "speedup_n_over_s": speedup,
                "avg_delta_s": avg_delta,
            }
        )
    return out


def _fmt3(v: Optional[float]) -> str:
    if v is None:
        return "N/A"
    return f"{v:.3f}"


def _render_system_latex(system_rows: List[Dict[str, object]]) -> str:
    lines: List[str] = []
    lines.append(r"\begin{table}[htbp]")
    lines.append(r"\centering")
    lines.append(
        r"\caption{System-level slicing vs. no-slicing total-time comparison (NA cases excluded)}"
    )
    lines.append(r"\begin{tabular}{lrrrrr}")
    lines.append(r"\toprule")
    lines.append(r"System & Cases & Slicing Total (s) & No-slicing Total (s) & Speedup (N/S) & Avg Delta (s) \\")
    lines.append(r"\midrule")
    for r in system_rows:
        lines.append(
            f"{_escape_latex(str(r['system']))} & "
            f"{int(r['cases'])} & "
            f"{_fmt3(r['slicing_total_s'])} & "
            f"{_fmt3(r['noslicing_total_s'])} & "
            f"{_fmt3(r['speedup_n_over_s'])} & "
            f"{_fmt3(r['avg_delta_s'])} \\\\"
        )
    lines.append(r"\bottomrule")
    lines.append(r"\end{tabular}")
    lines.append(r"\end{table}")
    lines.append("")
    return "\n".join(lines)


def _time_cell(total_s: Optional[float], stages: str) -> str:
    if total_s is None:
        return "N/A"
    stages = stages.strip().strip("`")
    if stages and stages != "-":
        parts = [p.strip() for p in stages.split("/") if p.strip()]
        if len(parts) == 3:
            a, b, c = parts
            return f"{total_s:.3f} ({a},{b},{c})"
    return f"{total_s:.3f}"


def _render_big_latex(rows: List[Dict[str, str]]) -> str:
    rows = sorted(rows, key=lambda r: (_spec_order(r["spec"].strip("`")), r["spec"]))
    formatted_rows: List[Dict[str, str]] = []
    for r in rows:
        spec = r["spec"].strip("`")
        system = _system_display_for_spec(spec)
        assertion = _assertion_display_for_spec(spec)
        total_s = _parse_float(r["total slicing(s)"])
        total_n = _parse_float(r["total noslicing(s)"])
        sp = _parse_float(r["total speedup(noslicing/slicing)"])
        if total_s is None or total_n is None:
            sp = None

        formatted_rows.append(
            {
                "system": system,
                "assertion": assertion,
                "slicing": _time_cell(total_s, r["wrap stages slicing(e/c/cl)"]),
                "noslicing": _time_cell(total_n, r["wrap stages noslicing(e/c/cl)"]),
                "speedup": _fmt3(sp),
            }
        )

    groups: List[Tuple[str, List[Dict[str, str]]]] = []
    for fr in formatted_rows:
        if not groups or groups[-1][0] != fr["system"]:
            groups.append((fr["system"], [fr]))
        else:
            groups[-1][1].append(fr)

    lines: List[str] = []
    lines.append(r"\begin{table*}[t]")
    lines.append(r"\centering")
    lines.append(r"\small")
    lines.append(r"\setlength{\tabcolsep}{6pt}")
    lines.append(r"\resizebox{\textwidth}{!}{%")
    lines.append(r"\begin{tabular}{|l|l|l|l|l|}")
    lines.append(r"\hline")
    lines.append(
        r"\textbf{System} & \textbf{Assertion} & \textbf{Slicing time (s)} & \textbf{No-slicing time (s)} & \textbf{Speedup (N/S)} \\"
    )
    lines.append(r"\hline")

    # Merge the System column using multirow, matching the paper-style tables.
    # Note: requires LaTeX package: \usepackage{multirow}
    for system, items in groups:
        sys_txt = _escape_latex(system)
        for idx, it in enumerate(items):
            if idx == 0:
                sys_cell = rf"\multirow{{{len(items)}}}{{*}}{{{sys_txt}}}"
            else:
                sys_cell = ""
            lines.append(
                f"{sys_cell} & "
                f"{_escape_latex(it['assertion'])} & "
                f"{_escape_latex(it['slicing'])} & "
                f"{_escape_latex(it['noslicing'])} & "
                f"{it['speedup']} \\\\"
            )
        lines.append(r"\hline")

    lines.append(r"\end{tabular}%")
    lines.append(r"}")
    lines.append(r"\caption{Slicing vs. no-slicing total time per verification task (wraparound shown as total(stage1,stage2,stage3)).}")
    lines.append(r"\label{tab:time_slicing}")
    lines.append(r"\vspace{-4mm}")
    lines.append(r"\end{table*}")
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Add system column to stage-runtime markdown and export LaTeX tables"
    )
    ap.add_argument("--md", default="EXPERIMENT_STAGE_RUNTIME_CURRENT.md")
    ap.add_argument(
        "--out-system-tex",
        default="EXPERIMENT_STAGE_RUNTIME_SYSTEM_COMPARE.tex",
        help="LaTeX table: per-system comparison (NA excluded)",
    )
    ap.add_argument(
        "--out-big-tex",
        default="EXPERIMENT_STAGE_RUNTIME_CASE_TABLE.tex",
        help="LaTeX table: case-by-case large table",
    )
    ap.add_argument(
        "--out-system-json",
        default=".tmp/procurator/system_slicing_compare_no_na.json",
        help="JSON summary for per-system comparison",
    )
    ns = ap.parse_args()

    md_path = Path(ns.md).resolve()
    lines, rows, header_idx, row_end = _parse_md_table(md_path)
    normalized_rows = _rewrite_md_with_system(md_path, lines, rows, header_idx, row_end)

    system_rows = _build_system_aggregate(normalized_rows)
    out_system_tex = Path(ns.out_system_tex).resolve()
    out_big_tex = Path(ns.out_big_tex).resolve()
    out_system_json = Path(ns.out_system_json).resolve()

    out_system_tex.write_text(_render_system_latex(system_rows), encoding="utf-8")
    out_big_tex.write_text(_render_big_latex(normalized_rows), encoding="utf-8")
    out_system_json.parent.mkdir(parents=True, exist_ok=True)
    out_system_json.write_text(
        __import__("json").dumps(system_rows, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print(f"[OK] updated markdown: {md_path}")
    print(f"[OK] wrote: {out_system_tex}")
    print(f"[OK] wrote: {out_big_tex}")
    print(f"[OK] wrote: {out_system_json}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
