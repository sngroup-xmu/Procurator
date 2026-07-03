from __future__ import annotations

from pathlib import Path
from typing import Optional, Tuple

from dslc.toolchain.ultimate_paths import ultimate_asset, ultimate_assets


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
    tc_no_witness = ultimate_asset(root, "ReachSafety.xml")
    tc_witness = ultimate_asset(root, "ReachSafety-Witness.xml")
    tc_legacy_witness = (root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-Witness.xml").resolve()

    # IMPORTANT: some Ultimate releases crash in the witness printer when the result is SAFE.
    # We therefore default CEGIS stages to the non-witness toolchain and only re-run with
    # witness enabled when we actually need a witness (i.e., on UNSAFE for refinement).
    toolchain_nowitness = tc_no_witness if tc_no_witness.exists() else tc_legacy_witness
    toolchain_witness = tc_witness if tc_witness.exists() else tc_legacy_witness

    tc_closure = ultimate_asset(root, "ClosureCheck-ReachSafety.xml")
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
    settings_candidates = ultimate_assets(root, [
        "ReachSafety-32bit-GemCutter-ALL.epf",
        "ReachSafety-32bit-GemCutter-ALL-no-por.epf",
        "ReachSafety-32bit-GemCutter-internal.epf",
        "ReachSafety-32bit-GemCutter-internal-no-por.epf",
        # Higher-memory fallbacks (opt-in via --closure-settings/--settings in callers).
        "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf",
        "ReachSafety-32bit-GemCutter-ALL-8g.epf",
        "ReachSafety-32bit-GemCutter-ALL-12g.epf",
        # Proof-oriented fallback.
        "ReachSafety-32bit-BuchiAutomizer-12g.epf",
    ])
    settings_nowitness = next((p for p in settings_candidates if p.exists()), settings_candidates[0])
    settings_nowitness_legacy = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL.epf"
    )
    settings_nowitness = settings_nowitness if settings_nowitness.exists() else settings_nowitness_legacy

    # Witness printing is controlled by the toolchain; re-use the same settings profile by default.
    settings_witness_candidates = ultimate_assets(root, [
        "ReachSafety-32bit-GemCutter-ALL-witness.epf",
        "ReachSafety-32bit-GemCutter-internal-witness.epf",
        "ReachSafety-32bit-GemCutter-ALL-8g-witness.epf",
        "ReachSafety-32bit-GemCutter-ALL-12g-witness.epf",
        # Last resort: proof-oriented profile (witness printer might still crash on SAFE).
        "ReachSafety-32bit-BuchiAutomizer-12g.epf",
    ])
    settings_witness = next((p for p in settings_witness_candidates if p.exists()), settings_witness_candidates[0])
    settings_witness_legacy = (
        root / "Procurator" / "argo" / "code" / "spec" / "config" / "ReachSafety-32bit-GemCutter-ALL-witness.epf"
    )
    settings_witness = settings_witness if settings_witness.exists() else settings_witness_legacy

    closure_settings = ultimate_asset(root, "ClosureCheck-32bit-GemCutter-ALL-witness.epf")
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
                    ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf"),
                    ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por.epf"),
                    ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout.epf"),
                ]
            )

        # Low-memory fallbacks (WSL safety): prefer these by default.
        candidates.extend(
            [
                ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-no-por.epf"),
                ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL.epf"),
            ]
        )

        if allow_high_mem:
            # Higher-memory fallbacks (use explicitly on machines that can handle it).
            candidates.extend(
                [
                    ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-12g-smallblocks.epf"),
                    # Fallback: proof-oriented Automizer/TraceAbstraction profile.
                    ultimate_asset(root, "ReachSafety-32bit-BuchiAutomizer-12g.epf"),
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


def _schedule_replay_allinline_settings(*, root: Path, ultimate_xmx_gb: int) -> Optional[Path]:
    if int(ultimate_xmx_gb) < 8:
        return None
    candidate = ultimate_asset(root, "ReachSafety-32bit-GemCutter-ALL-8g-noz3timeout-no-por-allinline.epf")
    if candidate.exists():
        return candidate.resolve()
    return None


def _schedule_replay_closure_settings(
    *,
    root: Path,
    closure_settings: Path,
    ultimate_xmx_gb: int,
) -> Path:
    """
    Pick CLOSURE settings for schedule replay.

    Keep `_default_toolchain_paths()` conservative for legacy/debug modes, but
    make the high-memory schedule-replay contract explicit: if the caller opts
    into an 8GB heap and the all-inline profile exists, use it even if a
    closure-specific witness EPF is also present in the checkout.
    """

    return _schedule_replay_allinline_settings(root=root, ultimate_xmx_gb=ultimate_xmx_gb) or closure_settings


def _schedule_replay_stage_settings(
    *,
    root: Path,
    settings_nowitness: Path,
    closure_settings: Path,
    ultimate_xmx_gb: int,
) -> Path:
    """
    Pick the ENTRY/NEAR settings for schedule replay.

    The schedule-replay tasks are straight-line Boogie queries with repeated P4
    helper calls. When the caller explicitly grants an 8GB Ultimate heap, the
    all-inline closure profile is also a better fit for ENTRY/NEAR: it preserves
    semantics, but avoids TraceAbstraction rediscovering summaries for repeated
    procedure calls. Keep the low-memory default unchanged for WSL safety.
    """

    allinline = _schedule_replay_allinline_settings(root=root, ultimate_xmx_gb=ultimate_xmx_gb)
    if allinline is not None:
        return allinline
    if int(ultimate_xmx_gb) >= 8 and "allinline" in closure_settings.name:
        return closure_settings
    return settings_nowitness
