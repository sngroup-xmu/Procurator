from __future__ import annotations

from typing import Sequence

from dslc.workflows.wraparound_schedule import dependency_projection_has_hard_certification_gap


def projection_complete_for_certification(
    dep_projection,
    *,
    selected_branch: tuple[str, ...],
    branch_projection_complete: bool,
    index_projection_complete: bool,
) -> bool:
    """
    Classify dependency-projection gaps for schedule certificates.

    Transient cutpoint guard noise is soft: a SAFE closure obligation over the
    original phase bodies discharges it.  Hard gaps still prevent certification
    because closure would be proving the wrong replay state.
    """

    notes = tuple(str(n) for n in (getattr(dep_projection, "notes", ()) or ()))
    unresolved_calls = tuple(str(v) for v in (getattr(dep_projection, "unresolved_calls", ()) or ()))
    if not index_projection_complete:
        return False
    if dependency_projection_has_hard_certification_gap(notes=notes, unresolved_calls=unresolved_calls):
        return False
    if bool(getattr(dep_projection, "complete", False)):
        return True

    allowed_prefixes = (
        "dependency_projection_period=",
        "dependency_projection_live_deps=",
        "dependency_projection_predicates=",
        "dependency_projection_cutpoint_predicates=",
        "dependency_projection_cutpoint_guard_alternatives=",
        "dependency_projection_dynamic_slot_exprs=",
        "dependency_projection_unstable_cutpoint_guards=",
        "dependency_projection_ambiguous_cutpoint_predicates=",
    )

    has_ambiguous_cutpoint = False
    saw_incomplete = False
    for note in notes:
        if note == "dependency_projection_incomplete":
            saw_incomplete = True
            continue
        if note.startswith("dependency_projection_ambiguous_cutpoint_predicates="):
            has_ambiguous_cutpoint = True
            continue
        if any(note.startswith(prefix) for prefix in allowed_prefixes):
            continue
        if "incomplete" in note:
            return False
        return False

    if has_ambiguous_cutpoint and not (selected_branch and branch_projection_complete):
        return False
    return saw_incomplete


def projection_has_mailbox_state(proj_vars: Sequence[str]) -> bool:
    return any(str(v).endswith(("_inbox_count", "_egress_count")) for v in proj_vars)
