from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

from ..speclang.model import SpecModel
from .boogie_bpl import (
    assert_no_missing_var_decls,
    assert_no_missing_type_decls,
    collect_input_vars_and_egress_type,
    filter_input_vars_by_usage,
    looks_like_bpl,
)
from .boogie_errors import BoogieBackendError
from .boogie_harness import BoogieHarnessEmitter
from .boogie_p4b import P4BTranslator
from .boogie_pipeline import split_pipeline_stages
from .boogie_prefix import BoogiePrefixer, dedup_bvbuiltin_decls, ultimate_rewrite_bvbuiltin_attrs
from .boogie_registers import collect_register_arrays, instrument_register_writes
from .boogie_seeds import build_slicing_plan
from .boogie_common import is_packet_var, is_skipped_input_var


@dataclass(frozen=True)
class _BoogieNodeInfo:
    raw_bpl: str
    input_vars: List[str]
    egress_port_type: str
    egress_port_var: str
    declared_vars: set[str]
    var_types: Dict[str, str]
    type_defs: Dict[str, str]
    meta: Optional[dict]


def _extract_mainprocedure_modifies(prefixed_bpl: str, alias: str) -> set[str]:
    proc_name = f"{alias}_mainProcedure"
    rx = re.compile(
        rf"procedure(?:\s*\{{:[^}}]+\}}\s*)*\s+{re.escape(proc_name)}\s*\([^)]*\)\s*(?:returns\s*\([^)]*\))?\s*"
        rf"(?:\n|\r\n)\s*modifies\s+([^;]+);",
        re.MULTILINE,
    )
    m = rx.search(prefixed_bpl)
    if not m:
        return set()
    clause = m.group(1)
    items = [x.strip() for x in clause.split(",")]
    return {x for x in items if x}


def _node_needs_two_stage(prefixed_bpl: str, alias: str) -> bool:
    """
    Heuristic: enable the (more expensive) two-stage ingress/egress scheduling only
    for nodes whose P4B-translated Boogie program can emit cross-pass events.

    Rationale:
      - Recirculation/clone split a logical "send" across multiple passes.
      - Modeling these effects as separate stages is useful to expose interleavings.
      - For nodes without such effects, forcing two-stage adds unnecessary actions
        and can significantly slow down TraceAbstraction.
    """
    # P4B uses these boolean flags to represent extern-triggered events.
    rx = re.compile(
        rf"\b{re.escape(alias)}_p4b_(?:recirculate|clone_i2e|clone_e2e|clone_i2i)\b\s*:=\s*true\b"
    )
    return bool(rx.search(prefixed_bpl))


def _resolve_declared_name(declared: set[str], base: str) -> Optional[str]:
    """
    Resolve a spec-level name against a raw Boogie unit's declared globals.

    This mirrors the `_0`-suffix resolution in `boogie_harness_dsl.py` but
    operates on *unprefixed* names (the per-node raw .bpl scope).

    We use this to fail fast when the spec references packet vars that do not
    exist in the imported/translated program (instead of silently patching in
    ghost declarations).
    """

    base_name = base
    suffix = ""
    if "[" in base:
        base_name, rest = base.split("[", 1)
        suffix = "[" + rest

    candidates: List[str] = [base_name]
    if base_name.endswith("_0"):
        candidates.append(base_name[:-2])
    else:
        candidates.append(base_name + "_0")

    for cand in candidates:
        if cand and (cand + suffix) in declared:
            return cand + suffix
    return None


class BoogieBackend:
    def __init__(self, p4b_bin: Optional[str] = None):
        self._p4b_bin = p4b_bin

    def compile(
        self,
        spec: SpecModel,
        out_bpl: Path,
        work_dir: Optional[Path] = None,
        *,
        max_env_inputs: bool = False,
        enable_slicing: bool = True,
        prune_env_inputs: bool = True,
        keep_control_seeds: bool = True,
        por_enabled: bool = False,
        por_guard_enabled: bool = True,
        boogie_harness: str = "concurrent",
        pipeline_two_stage: bool = True,
        max_steps: Optional[int] = None,
        honor_spec_max_steps: bool = False,
        emit_reg_debug: bool = True,
    ) -> Path:
        boogie_harness = boogie_harness.lower().strip()
        if boogie_harness not in {"concurrent", "sequential"}:
            raise BoogieBackendError(f"unsupported boogie harness: {boogie_harness}")

        work_dir = work_dir or Path(str(out_bpl) + ".work")
        work_dir.mkdir(parents=True, exist_ok=True)

        slicing_plan = build_slicing_plan(
            spec,
            enable_slicing=enable_slicing,
            keep_control_seeds=keep_control_seeds,
        )

        node_info: Dict[str, _BoogieNodeInfo] = {}

        # 1) Load or compile each imported unit into raw Boogie
        for alias, imp in spec.imports.items():
            src_path = imp.path
            effective_slicing_vars = list(slicing_plan.slicing_vars.get(alias, []))
            p4b: Optional[P4BTranslator] = None
            raw_path: Optional[Path] = None
            meta_path: Optional[Path] = None
            if src_path.endswith(".bpl"):
                raw_text = Path(src_path).read_text(encoding="utf-8", errors="replace")
                meta_obj: Optional[dict] = None
                meta_candidates: List[Path] = []
                src = Path(src_path)
                meta_candidates.append(src.with_suffix(".meta.json"))
                if src.name.endswith(".raw.bpl"):
                    meta_candidates.append(src.with_name(src.name.replace(".raw.bpl", ".meta.json")))
                for cand in meta_candidates:
                    if cand.exists():
                        try:
                            meta_obj = json.loads(cand.read_text(encoding="utf-8"))
                        except Exception:
                            meta_obj = None
                        break
            else:
                if not self._p4b_bin:
                    raise BoogieBackendError(
                        f"import {alias} from '{src_path}': not a .bpl file; "
                        f"provide p4b_bin to compile P4/JSON to Boogie"
                    )
                raw_path = work_dir / f"{alias}.raw.bpl"
                meta_path = work_dir / f"{alias}.meta.json"
                p4b = P4BTranslator(self._p4b_bin)
                p4b.compile_to_bpl(
                    src_path,
                    str(raw_path),
                    imp.entries_path,
                    out_meta=str(meta_path),
                    slicing_vars=effective_slicing_vars,
                    disable_slicing=not enable_slicing,
                    # Keep P4B slicing control seeds that influence
                    # communication behavior (forward/drop/clone/recirc) by default.
                    #
                    # Without these, slicing can remove e.g. `p4b_recirculate := true`,
                    # making distributed harnesses miss real interleavings and report
                    # false SAFE results. For single-switch local checks, callers may
                    # explicitly disable this for performance.
                    keep_control_seeds=keep_control_seeds,
                )
                raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
                try:
                    meta_obj = json.loads(meta_path.read_text(encoding="utf-8"))
                except Exception:
                    meta_obj = None

            # Declare packet vars referenced by the DSL/spec so the merged program is well-typed.
            if not looks_like_bpl(raw_text):
                raise BoogieBackendError(
                    f"Input for node '{alias}' does not look like Boogie (.bpl). "
                    f"If you passed a Promela translator, please pass a P4->Boogie translator instead."
                )

            # Correctness: refuse ill-typed Boogie early (e.g., missing `type T;` for `var x:T;`).
            try:
                assert_no_missing_type_decls(raw_text)
            except ValueError as e:
                raise BoogieBackendError(f"Invalid Boogie for node '{alias}': {e}") from e

            # Correctness: do not "best-effort patch" missing packet/meta declarations.
            #
            # If slicing/translation left a dangling reference, it is a translator/slicer bug and
            # we must fail fast; otherwise we risk silently changing semantics.
            try:
                assert_no_missing_var_decls(raw_text, required_vars=slicing_plan.required_packet_vars.get(alias, []))
            except ValueError as e:
                retried = False
                if enable_slicing and p4b is not None and raw_path is not None:
                    required_packet = [
                        v
                        for v in slicing_plan.required_packet_vars.get(alias, [])
                        if is_packet_var(v) and not is_skipped_input_var(v)
                    ]
                    fallback_slicing_vars = sorted(set(effective_slicing_vars) | set(required_packet))
                    if fallback_slicing_vars != sorted(set(effective_slicing_vars)):
                        retried = True
                        p4b.compile_to_bpl(
                            src_path,
                            str(raw_path),
                            imp.entries_path,
                            out_meta=str(meta_path) if meta_path is not None else None,
                            slicing_vars=fallback_slicing_vars,
                            disable_slicing=False,
                            keep_control_seeds=keep_control_seeds,
                        )
                        raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
                        if meta_path is not None:
                            try:
                                meta_obj = json.loads(meta_path.read_text(encoding="utf-8"))
                            except Exception:
                                meta_obj = None
                        effective_slicing_vars = fallback_slicing_vars
                        try:
                            assert_no_missing_var_decls(
                                raw_text, required_vars=slicing_plan.required_packet_vars.get(alias, [])
                            )
                        except ValueError as e2:
                            raise BoogieBackendError(
                                f"Invalid Boogie for node '{alias}' after slicing fallback retry: {e2}"
                            ) from e2
                if not retried:
                    raise BoogieBackendError(f"Invalid Boogie for node '{alias}': {e}") from e

            input_vars, egress_t, declared, var_types, egress_var, type_defs = collect_input_vars_and_egress_type(
                raw_text
            )

            # Correctness: any packet var referenced by the spec must resolve to an existing
            # declared Boogie global (possibly via `_0` suffix). Otherwise we'd end up
            # synthesizing "ghost" packet vars that are disconnected from the actual P4
            # semantics (unsound), or we'd pass ill-typed Boogie to Ultimate (confusing).
            for req in slicing_plan.required_packet_vars.get(alias, []):
                if _resolve_declared_name(declared, req) is None:
                    raise BoogieBackendError(
                        f"Spec references packet var '{req}' for node '{alias}', but it is not declared by the "
                        f"imported/translated Boogie program.\n"
                        "This usually means either:\n"
                        "  (a) the spec references a non-existent P4 field, or\n"
                        "  (b) the translator/slicer dropped the field declarations (translator bug).\n"
                        "Fix the spec or repair the translator; refusing to auto-declare ghost vars."
                    )

            if enable_slicing and prune_env_inputs:
                # Keep packet vars that were selected as slicing seeds *and* actually exist in the
                # (possibly sliced) Boogie output. This keeps env havoc and forwarding-field copying
                # aligned with the sliced program without introducing undeclared ghost vars.
                force_keep = {
                    v
                    for v in (effective_slicing_vars if enable_slicing else [])
                    if is_packet_var(v) and not is_skipped_input_var(v) and v in declared
                }
                # `required_packet_vars` are referenced by DSL assume/env constraints and host.env
                # injections. They do not need to participate in P4 slicing, but they must stay in
                # harness input declarations; otherwise generated assignments (e.g., io_hdr.* := ...)
                # become ill-typed.
                for req in slicing_plan.required_packet_vars.get(alias, []):
                    if not is_packet_var(req) or is_skipped_input_var(req):
                        continue
                    resolved = _resolve_declared_name(declared, req)
                    if resolved is not None:
                        force_keep.add(resolved)
                input_vars = filter_input_vars_by_usage(
                    raw_text,
                    input_vars,
                    force_keep=sorted(force_keep),
                )

            node_info[alias] = _BoogieNodeInfo(
                raw_bpl=raw_text,
                input_vars=input_vars,
                egress_port_type=egress_t,
                egress_port_var=egress_var,
                declared_vars=declared,
                var_types=var_types,
                type_defs=type_defs,
                meta=meta_obj,
            )

        # 2) Prefix each Boogie unit to avoid collisions
        node_prefixed: Dict[str, str] = {}
        node_main_modifies: Dict[str, set[str]] = {}
        node_register_arrays: Dict[str, Dict[str, tuple[str, str]]] = {}
        for alias, info in node_info.items():
            prefixed = BoogiePrefixer(alias).prefix_content(info.raw_bpl)
            regs = collect_register_arrays(prefixed, alias)
            prefixed = instrument_register_writes(prefixed, regs)
            node_prefixed[alias] = prefixed
            node_register_arrays[alias] = regs
            node_main_modifies[alias] = _extract_mainprocedure_modifies(prefixed, alias)

        node_pipeline_stages = {}
        if pipeline_two_stage:
            for alias, prefixed in node_prefixed.items():
                if not _node_needs_two_stage(prefixed, alias):
                    continue
                stages = split_pipeline_stages(prefixed, alias)
                if stages:
                    node_pipeline_stages[alias] = stages

        host_to_node: Dict[str, str] = {}
        host_input_vars: Dict[str, List[str]] = {}
        host_var_types: Dict[str, Dict[str, str]] = {}

        def _prefix_host_type(node: str, typ: str) -> str:
            if not typ:
                return typ
            if typ in {"int", "bool"}:
                return typ
            if typ.startswith("bv") and typ[2:].isdigit():
                return typ
            if typ.startswith(f"{node}_"):
                return typ
            return f"{node}_{typ}"

        for host, hd in spec.hosts.items():
            if not hd.connect_to:
                raise BoogieBackendError(f"host '{host}' missing connect target")
            if hd.connect_to not in node_info:
                raise BoogieBackendError(f"host '{host}' connect target '{hd.connect_to}' not found among imports")
            host_to_node[host] = hd.connect_to
            host_input_vars[host] = list(node_info[hd.connect_to].input_vars)
            host_var_types[host] = {
                k: _prefix_host_type(hd.connect_to, v) for k, v in node_info[hd.connect_to].var_types.items()
            }

        # 3) Emit harness
        emitter = BoogieHarnessEmitter(
            spec,
            node_input_vars={a: info.input_vars for a, info in node_info.items()},
            node_egress_port_type={a: info.egress_port_type for a, info in node_info.items()},
            node_egress_port_var={a: info.egress_port_var for a, info in node_info.items()},
            node_declared_vars={a: info.declared_vars for a, info in node_info.items()},
            node_mainprocedure_modifies=node_main_modifies,
            node_register_arrays=node_register_arrays,
            node_pipeline_stages=node_pipeline_stages,
            node_var_types={a: info.var_types for a, info in node_info.items()},
            node_type_defs={a: info.type_defs for a, info in node_info.items()},
            node_meta={a: info.meta for a, info in node_info.items()},
            host_to_node=host_to_node,
            host_input_vars=host_input_vars,
            host_var_types=host_var_types,
            max_env_inputs=max_env_inputs,
            por_enabled=por_enabled,
            por_guard_enabled=por_guard_enabled,
            harness_mode=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
            max_steps=max_steps,
            honor_spec_max_steps=honor_spec_max_steps,
            emit_reg_debug=emit_reg_debug,
        )
        helpers = emitter.emit_helpers()
        harness = emitter.emit(emit_helpers=False)

        # 4) Concatenate into a single .bpl
        merged: List[str] = []
        if helpers:
            merged.append("// ===== BEGIN PREAMBLE =====\n")
            merged.append(helpers)
            if not helpers.endswith("\n"):
                merged.append("\n")
            merged.append("// ===== END PREAMBLE =====\n\n")

        seen_bvbuiltins: set[str] = set()
        for alias in sorted(node_prefixed.keys()):
            merged.append(f"// ===== BEGIN NODE {alias} (prefixed) =====\n")
            node_body = dedup_bvbuiltin_decls(node_prefixed[alias], seen_bvbuiltins)
            merged.append(node_body)
            if not node_body.endswith("\n"):
                merged.append("\n")
            merged.append(f"// ===== END NODE {alias} =====\n\n")

        # enqueue procs (need them after node vars)
        merged.append("// ===== BEGIN ENQUEUE PROCEDURES =====\n")
        k = spec.global_decl.queue_capacity if spec.global_decl.queue_capacity is not None else 5
        for l in spec.links:
            merged.append(emitter._emit_enqueue_proc(l.src, l.dst, k))  # noqa: SLF001
            merged.append("\n")
        merged.append("// ===== END ENQUEUE PROCEDURES =====\n\n")

        merged.append("// ===== BEGIN HARNESS =====\n")
        merged.append(harness)
        merged.append("// ===== END HARNESS =====\n")

        merged_text = ultimate_rewrite_bvbuiltin_attrs("".join(merged))
        out_bpl.write_text(merged_text, encoding="utf-8")
        return out_bpl


__all__ = ["BoogieBackend"]
