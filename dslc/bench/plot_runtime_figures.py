#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

plt.rcParams.update(
    {
        "font.family": "serif",
        "font.serif": ["Computer Modern Roman", "DejaVu Serif"],
        "mathtext.fontset": "cm",
        "axes.labelsize": 18,
        "axes.labelweight": "bold",
        "xtick.labelsize": 16,
        "ytick.labelsize": 16,
        "legend.fontsize": 16,
    }
)


SYSTEM_ORDER = [
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

SYSTEM_DISPLAY = {
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

WRAP_LABEL = {
    "netchain_wraparound_bug": "Replica monotonicity",
    "distcache_p2c_spineload_wraparound_bug": "spine selection correctness",
    "distcache_p2c_wraparound_bug": "Overflow-driven progress",
    "fisslock_notification_cnt_wraparound_bug": "Transfer safety",
}


def _load_json(path: Path) -> Dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _system_of_spec(spec: str) -> str:
    stem = Path(spec).stem
    prefix = stem.split("_", 1)[0].lower()
    return SYSTEM_DISPLAY.get(prefix, prefix)


def _is_wrap_row(row: Dict) -> bool:
    s = row.get("slicing", {})
    n = row.get("noslicing", {})
    return bool(s.get("stages")) or bool(n.get("stages"))


def _extract_nonwrap_system_stats(
    compile_data: Dict, total_data: Dict
) -> Tuple[Dict[str, Dict[str, Dict[str, float]]], List[str]]:
    row_by_spec = {r["spec"]: r for r in total_data.get("rows", [])}
    out: Dict[str, Dict[str, Dict[str, float]]] = {}
    skipped_specs: List[str] = []

    for spec, case in compile_data.get("cases", {}).items():
        row = row_by_spec.get(spec)
        if row is None or _is_wrap_row(row):
            continue

        mode_stats = {}
        ok = True
        for mode in ("slicing", "noslicing"):
            prof = (
                case.get(mode, {})
                .get("compile_profile", {})
                .get("profile", {})
            )
            run = row.get(mode, {}).get("run_modelchecker_s")
            if prof is None or run is None:
                ok = False
                break
            prune = float(prof.get("frontend_prune_total_s") or 0.0)
            translate = float(prof.get("frontend_translate_total_s") or 0.0)
            harness = float(prof.get("python_harness_emit_s") or 0.0)
            runtime = float(run)
            mode_stats[mode] = {
                "prune": prune,
                "translate": translate,
                "harness": harness,
                "runtime": runtime,
                "total": prune + translate + harness + runtime,
            }

        if not ok:
            skipped_specs.append(spec)
            continue

        system = _system_of_spec(spec)
        if system not in out:
            out[system] = {
                "slicing": {"prune": 0.0, "translate": 0.0, "harness": 0.0, "runtime": 0.0, "total": 0.0},
                "noslicing": {"prune": 0.0, "translate": 0.0, "harness": 0.0, "runtime": 0.0, "total": 0.0},
                "count": {"specs": 0.0},
            }
        out[system]["count"]["specs"] += 1.0
        for mode in ("slicing", "noslicing"):
            for key in ("prune", "translate", "harness", "runtime", "total"):
                out[system][mode][key] += mode_stats[mode][key]

    ordered = [s for s in SYSTEM_ORDER if s in out]
    return out, skipped_specs


def _extract_wrap_case_stats(total_data: Dict) -> List[Dict]:
    items = []
    for row in total_data.get("rows", []):
        if not _is_wrap_row(row):
            continue
        spec = row["spec"]
        stem = Path(spec).stem
        s = row.get("slicing", {})
        n = row.get("noslicing", {})
        s_stages = s.get("stages")
        n_stages = n.get("stages")
        if not s_stages or not n_stages or len(s_stages) != 3 or len(n_stages) != 3:
            continue
        items.append(
            {
                "spec": spec,
                "label": WRAP_LABEL.get(stem, stem),
                "slicing": [float(x) for x in s_stages],
                "noslicing": [float(x) for x in n_stages],
                "s_total": float(s.get("run_modelchecker_s") or sum(s_stages)),
                "n_total": float(n.get("run_modelchecker_s") or sum(n_stages)),
            }
        )
    order = {
        "netchain_wraparound_bug": 0,
        "distcache_p2c_spineload_wraparound_bug": 1,
        "distcache_p2c_wraparound_bug": 2,
        "fisslock_notification_cnt_wraparound_bug": 3,
    }
    items.sort(key=lambda x: order.get(Path(x["spec"]).stem, 99))
    return items


def _savefig(fig: plt.Figure, out_base: Path) -> None:
    out_base.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(out_base.with_suffix(".png"), dpi=220, bbox_inches="tight")
    fig.savefig(out_base.with_suffix(".pdf"), bbox_inches="tight")
    plt.close(fig)


def _apply_axis_typography(ax: plt.Axes) -> None:
    for tick_label in ax.get_xticklabels():
        tick_label.set_fontweight("bold")
    for tick_label in ax.get_yticklabels():
        tick_label.set_fontweight("bold")


def _plot_nonwrap_stage_share(system_stats: Dict[str, Dict[str, Dict[str, float]]], out_base: Path) -> None:
    systems = [s for s in SYSTEM_ORDER if s in system_stats]
    if not systems:
        return

    components = ["frontend", "backend", "verify"]
    # stage colors requested: frontend encode=blue, verification=orange
    stage_colors = {"frontend": "C0", "backend": "C2", "verify": "C1"}

    x = np.arange(len(systems))
    width = 0.36
    fig, ax = plt.subplots(figsize=(16, 6))
    stage_handles = []

    for mode, offset, alpha, hatch in (
        ("slicing", -width / 2, 0.95, ""),
        ("noslicing", width / 2, 0.82, "//"),
    ):
        bottoms = np.zeros(len(systems))
        for comp_idx, comp in enumerate(components):
            vals = []
            for s in systems:
                if comp == "frontend":
                    vals.append(system_stats[s][mode]["prune"] + system_stats[s][mode]["translate"])
                elif comp == "backend":
                    vals.append(system_stats[s][mode]["harness"])
                else:
                    vals.append(system_stats[s][mode]["runtime"])
            vals_np = np.array(vals, dtype=float)
            bars = ax.bar(
                x + offset,
                vals_np,
                width=width,
                bottom=bottoms,
                color=stage_colors[comp],
                alpha=alpha,
                hatch=hatch,
                edgecolor="white",
                linewidth=0.4,
            )
            if mode == "slicing":
                stage_handles.append(bars[0])
            bottoms += vals_np

    ax.set_ylabel(r"Time (s)")
    ax.set_xticks(x)
    ax.set_xticklabels(systems, rotation=0, ha="center")
    _apply_axis_typography(ax)
    stage_legend = ax.legend(
        stage_handles,
        ["frontend compile+prune", "backend encode", "verification"],
        ncol=3,
        loc="upper left",
        frameon=True,
        framealpha=0.9,
        title="stages",
        title_fontsize=16,
        prop={"size": 16, "weight": "bold"},
    )
    mode_handles = [
        plt.Rectangle((0, 0), 1, 1, facecolor="white", edgecolor="black", hatch="", linewidth=0.8),
        plt.Rectangle((0, 0), 1, 1, facecolor="white", edgecolor="black", hatch="//", linewidth=0.8),
    ]
    mode_legend = ax.legend(
        mode_handles,
        ["slicing", "noslicing"],
        ncol=2,
        loc="upper right",
        frameon=True,
        framealpha=0.9,
        title="mode",
        title_fontsize=16,
        prop={"size": 16, "weight": "bold"},
    )
    ax.add_artist(stage_legend)
    ax.add_artist(mode_legend)
    ax.grid(axis="y", linestyle="--", alpha=0.25)
    fig.tight_layout()
    _savefig(fig, out_base)


def _plot_nonwrap_total_compare(system_stats: Dict[str, Dict[str, Dict[str, float]]], out_base: Path) -> None:
    systems = [s for s in SYSTEM_ORDER if s in system_stats]
    if not systems:
        return
    x = np.arange(len(systems))
    width = 0.36
    s_vals = np.array([system_stats[s]["slicing"]["total"] for s in systems])
    n_vals = np.array([system_stats[s]["noslicing"]["total"] for s in systems])

    fig, ax = plt.subplots(figsize=(16, 6))
    ax.bar(
        x - width / 2,
        s_vals,
        width=width,
        label="slicing",
        color="C0",
        edgecolor="white",
        linewidth=0.4,
    )
    ax.bar(
        x + width / 2,
        n_vals,
        width=width,
        label="noslicing",
        color="C0",
        hatch="//",
        edgecolor="white",
        linewidth=0.4,
    )
    ax.set_ylabel(r"Total Time (s)")
    ax.set_xticks(x)
    ax.set_xticklabels(systems, rotation=0, ha="center")
    _apply_axis_typography(ax)
    ax.grid(axis="y", linestyle="--", alpha=0.25)
    ax.legend(frameon=True, framealpha=0.9, prop={"size": 16, "weight": "bold"})
    fig.tight_layout()
    _savefig(fig, out_base)


def _plot_wrap_stage_compare(wrap_items: List[Dict], out_base: Path) -> None:
    if not wrap_items:
        return
    labels = [it["label"] for it in wrap_items]
    x = np.arange(len(labels))
    width = 0.34
    stage_names = ["entry", "confirm", "closure"]
    stage_handles = []

    fig, ax = plt.subplots(figsize=(14, 6))
    for mode, offset, key, alpha, hatch in (
        ("slicing", -width / 2, "slicing", 0.95, ""),
        ("noslicing", width / 2, "noslicing", 0.82, "//"),
    ):
        # Use default matplotlib color cycle for each mode.
        ax.set_prop_cycle(None)
        bottoms = np.zeros(len(labels))
        for idx_stage in range(3):
            vals = np.array([it[key][idx_stage] for it in wrap_items], dtype=float)
            bars = ax.bar(
                x + offset,
                vals,
                width=width,
                bottom=bottoms,
                alpha=alpha,
                hatch=hatch,
                edgecolor="white",
                linewidth=0.4,
            )
            if mode == "slicing":
                stage_handles.append(bars[0])
            bottoms += vals
        for i, total in enumerate(bottoms):
            ax.text(
                x[i] + offset,
                total + 8,
                f"{total:.1f}",
                ha="center",
                va="bottom",
                fontsize=9,
                fontweight="bold",
            )

    ax.set_ylabel(r"Time (s)")
    ax.set_xticks(x)
    ax.set_xticklabels(labels, rotation=0, ha="center")
    _apply_axis_typography(ax)
    stage_legend = ax.legend(
        stage_handles,
        stage_names,
        ncol=3,
        loc="upper left",
        frameon=True,
        framealpha=0.9,
        title="stages",
        title_fontsize=16,
        prop={"size": 16, "weight": "bold"},
    )
    mode_handles = [
        plt.Rectangle((0, 0), 1, 1, facecolor="white", edgecolor="black", hatch="", linewidth=0.8),
        plt.Rectangle((0, 0), 1, 1, facecolor="white", edgecolor="black", hatch="//", linewidth=0.8),
    ]
    mode_legend = ax.legend(
        mode_handles,
        ["slicing", "noslicing"],
        ncol=2,
        loc="upper right",
        frameon=True,
        framealpha=0.9,
        title="mode",
        title_fontsize=16,
        prop={"size": 16, "weight": "bold"},
    )
    ax.add_artist(stage_legend)
    ax.add_artist(mode_legend)
    ax.grid(axis="y", linestyle="--", alpha=0.25)
    fig.tight_layout()
    _savefig(fig, out_base)


def main() -> int:
    parser = argparse.ArgumentParser(description="Plot runtime comparison figures with matplotlib")
    parser.add_argument(
        "--compile-json",
        default=".tmp/procurator/compile_runtime_integrated_all_systems.json",
        help="Compile/runtime integrated json",
    )
    parser.add_argument(
        "--totaltime-json",
        default=".tmp/procurator/compile_runtime_totaltime_summary.json",
        help="Total-time summary json",
    )
    parser.add_argument(
        "--out-dir",
        default=".tmp/procurator/figures",
        help="Output figure directory",
    )
    args = parser.parse_args()

    compile_data = _load_json(Path(args.compile_json))
    total_data = _load_json(Path(args.totaltime_json))
    out_dir = Path(args.out_dir)

    nonwrap_stats, skipped_specs = _extract_nonwrap_system_stats(compile_data, total_data)
    wrap_items = _extract_wrap_case_stats(total_data)

    _plot_nonwrap_stage_share(nonwrap_stats, out_dir / "non_wrap_system_stage_share")
    _plot_nonwrap_total_compare(nonwrap_stats, out_dir / "non_wrap_system_total_compare")
    _plot_wrap_stage_compare(wrap_items, out_dir / "wrap_case_stage_compare")

    summary = {
        "non_wrap_systems": [s for s in SYSTEM_ORDER if s in nonwrap_stats],
        "non_wrap_skipped_specs_due_to_na": skipped_specs,
        "wrap_cases": [it["spec"] for it in wrap_items],
        "outputs": [
            str((out_dir / "non_wrap_system_stage_share.png")),
            str((out_dir / "non_wrap_system_total_compare.png")),
            str((out_dir / "wrap_case_stage_compare.png")),
            str((out_dir / "non_wrap_system_stage_share.pdf")),
            str((out_dir / "non_wrap_system_total_compare.pdf")),
            str((out_dir / "wrap_case_stage_compare.pdf")),
        ],
    }
    (out_dir / "plot_summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
