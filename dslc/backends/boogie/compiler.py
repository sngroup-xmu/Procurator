from __future__ import annotations

import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

from lark import Tree

from ...speclang.model import SpecModel
from .core.bpl import (
    assert_no_missing_var_decls,
    assert_no_missing_type_decls,
    collect_input_vars_and_egress_type,
    filter_input_vars_by_usage,
    looks_like_bpl,
)
from .core.common import is_packet_var, is_skipped_input_var
from .core.errors import BoogieBackendError
from .core.pipeline import split_pipeline_stages
from .core.prefix import BoogiePrefixer
from .harness import BoogieHarnessEmitter
from .merge import merge_boogie_program
from .node.p4b import P4BTranslator
from .node.registers import (
    assert_complete_register_write_mirrors,
    backfill_legacy_register_write_mirrors,
    collect_register_arrays,
    find_unmarked_register_arrays,
)
from .node.seeds import build_slicing_plan
from .profile import BackendCompileProfile


@dataclass(frozen=True)
class _BoogieNodeInfo:
    raw_bpl: str
    source_kind: str
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
        skip_duplicated_fail_fast_global_asserts: bool = False,
    ) -> Path:
        boogie_harness = boogie_harness.lower().strip()
        if boogie_harness not in {"concurrent", "sequential"}:
            raise BoogieBackendError(f"unsupported boogie harness: {boogie_harness}")

        prof = BackendCompileProfile(
            boogie_harness=boogie_harness,
            pipeline_two_stage=pipeline_two_stage,
            enable_slicing=enable_slicing,
            prune_env_inputs=prune_env_inputs,
        )
        prof_record = prof.record

        work_dir = work_dir or Path(str(out_bpl) + ".work")
        work_dir.mkdir(parents=True, exist_ok=True)

        t_plan = prof.mark()
        slicing_plan = build_slicing_plan(
            spec,
            enable_slicing=enable_slicing,
            keep_control_seeds=keep_control_seeds,
        )
        prof_record["build_slicing_plan_s"] = prof.elapsed_since(t_plan)
        p4b_fail_fast_global_assert_indices: set[int] = set()
        p4b_fail_fast_candidates: Dict[str, List[tuple[str, int]]] = {}

        node_info: Dict[str, _BoogieNodeInfo] = {}

        # 1) Load or compile each imported unit into raw Boogie
        for alias, imp in spec.imports.items():
            node_prof: Dict[str, object] = {}
            t_node_total = prof.mark()
            src_path = imp.path
            effective_slicing_vars = list(slicing_plan.slicing_vars.get(alias, []))
            p4b: Optional[P4BTranslator] = None
            raw_path: Optional[Path] = None
            meta_path: Optional[Path] = None
            fail_fast_asserts: List[str] = []
            fail_fast_pairs: List[tuple[str, int]] = []
            p4b_keep_vars: List[str] = []
            if src_path.endswith(".bpl"):
                t_load_raw = prof.mark()
                raw_text = Path(src_path).read_text(encoding="utf-8", errors="replace")
                node_prof["load_raw_bpl_s"] = prof.elapsed_since(t_load_raw)
                source_kind = "legacy_bpl"
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
                fail_fast_asserts = _infer_fail_fast_register_asserts(spec, alias)
                fail_fast_pairs = _infer_fail_fast_register_assert_pairs(spec, alias)
                t_translate = prof.mark()
                p4b.compile_to_bpl(
                    src_path,
                    str(raw_path),
                    imp.entries_path,
                    out_meta=str(meta_path),
                    slicing_vars=effective_slicing_vars,
                    slicing_keep_vars=p4b_keep_vars,
                    fail_fast_register_asserts=fail_fast_asserts,
                    disable_slicing=not enable_slicing,
                    # DSLC already adds the control seeds needed for the system harness
                    # in build_slicing_plan(). Disable P4B's own implicit control-root
                    # expansion here so the same seed set is used by compile/verify and
                    # local feature-register checks do not retain unrelated suffix logic.
                    keep_control_seeds=False,
                )
                node_prof["p4_to_bpl_s"] = prof.elapsed_since(t_translate)
                t_read_raw = prof.mark()
                raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
                node_prof["read_translated_bpl_s"] = prof.elapsed_since(t_read_raw)
                try:
                    t_meta = prof.mark()
                    meta_obj = json.loads(meta_path.read_text(encoding="utf-8"))
                    node_prof["meta_json_load_s"] = prof.elapsed_since(t_meta)
                except Exception:
                    meta_obj = None
                source_kind = "p4b_generated"

            # Declare packet vars referenced by the DSL/spec so the merged program is well-typed.
            if not looks_like_bpl(raw_text):
                raise BoogieBackendError(
                    f"Input for node '{alias}' does not look like Boogie (.bpl). "
                    f"If you passed a Promela translator, please pass a P4->Boogie translator instead."
                )

            # Correctness: refuse ill-typed Boogie early (e.g., missing `type T;` for `var x:T;`).
            try:
                t_typecheck = prof.mark()
                assert_no_missing_type_decls(raw_text)
                node_prof["type_decl_check_s"] = prof.elapsed_since(t_typecheck)
            except ValueError as e:
                raise BoogieBackendError(f"Invalid Boogie for node '{alias}': {e}") from e

            # Correctness: do not "best-effort patch" missing packet/meta declarations.
            #
            # If slicing/translation left a dangling reference, it is a translator/slicer bug and
            # we must fail fast; otherwise we risk silently changing semantics.
            try:
                t_varcheck = prof.mark()
                assert_no_missing_var_decls(raw_text, required_vars=slicing_plan.required_packet_vars.get(alias, []))
                node_prof["var_decl_check_s"] = prof.elapsed_since(t_varcheck)
            except ValueError as e:
                retried = False
                if enable_slicing and p4b is not None and raw_path is not None:
                    required_packet = [
                        v
                        for v in slicing_plan.required_packet_vars.get(alias, [])
                        if is_packet_var(v) and not is_skipped_input_var(v)
                    ]
                    fallback_keep_vars = sorted(set(p4b_keep_vars) | set(required_packet))
                    if fallback_keep_vars != sorted(set(p4b_keep_vars)):
                        retried = True
                        p4b.compile_to_bpl(
                            src_path,
                            str(raw_path),
                            imp.entries_path,
                            out_meta=str(meta_path) if meta_path is not None else None,
                            slicing_vars=effective_slicing_vars,
                            slicing_keep_vars=fallback_keep_vars,
                            fail_fast_register_asserts=fail_fast_asserts,
                            disable_slicing=False,
                            keep_control_seeds=False,
                        )
                        raw_text = raw_path.read_text(encoding="utf-8", errors="replace")
                        if meta_path is not None:
                            try:
                                meta_obj = json.loads(meta_path.read_text(encoding="utf-8"))
                            except Exception:
                                meta_obj = None
                        p4b_keep_vars = fallback_keep_vars
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

            if skip_duplicated_fail_fast_global_asserts and fail_fast_pairs:
                p4b_fail_fast_candidates[alias] = [
                    (item, idx) for item, idx in fail_fast_pairs if _raw_bpl_has_fail_fast_register_assert(raw_text, item)
                ]

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
                t_env_prune = prof.mark()
                input_vars = filter_input_vars_by_usage(
                    raw_text,
                    input_vars,
                    force_keep=sorted(force_keep),
                )
                node_prof["env_input_prune_s"] = prof.elapsed_since(t_env_prune)

            node_info[alias] = _BoogieNodeInfo(
                raw_bpl=raw_text,
                source_kind=source_kind,
                input_vars=input_vars,
                egress_port_type=egress_t,
                egress_port_var=egress_var,
                declared_vars=declared,
                var_types=var_types,
                type_defs=type_defs,
                meta=meta_obj,
            )
            node_prof["node_total_s"] = prof.elapsed_since(t_node_total)
            cast_nodes = prof_record.get("nodes")
            if isinstance(cast_nodes, dict):
                cast_nodes[alias] = node_prof

        # 2) Prefix each Boogie unit to avoid collisions
        node_prefixed: Dict[str, str] = {}
        node_main_modifies: Dict[str, set[str]] = {}
        node_register_arrays: Dict[str, Dict[str, tuple[str, str]]] = {}
        t_prefix_all = prof.mark()
        for alias, info in node_info.items():
            t_prefix = prof.mark()
            prefixed = BoogiePrefixer(alias).prefix_content(info.raw_bpl)
            regs = collect_register_arrays(prefixed, alias)
            if info.source_kind == "legacy_bpl":
                prefixed = backfill_legacy_register_write_mirrors(prefixed, regs)
            else:
                unmarked_regs = find_unmarked_register_arrays(prefixed, regs)
                if unmarked_regs:
                    raise BoogieBackendError(
                        f"Invalid P4B Boogie for node '{alias}': register write procedures lack P4B "
                        f"register markers for: {', '.join(unmarked_regs)}. "
                        "P4B must emit `// <alias>_Register <name>` markers so DSLC can consume "
                        "register state without guessing P4-local semantics."
                    )
                try:
                    assert_complete_register_write_mirrors(prefixed, regs)
                except ValueError as e:
                    raise BoogieBackendError(f"Invalid P4B Boogie for node '{alias}': {e}") from e
            for item, idx in p4b_fail_fast_candidates.get(alias, []):
                prefixed_item = _prefix_fail_fast_register_assert_item(alias, item)
                if _raw_bpl_has_fail_fast_register_assert(prefixed, prefixed_item):
                    p4b_fail_fast_global_assert_indices.add(idx)
            node_prefixed[alias] = prefixed
            node_register_arrays[alias] = regs
            node_main_modifies[alias] = _extract_mainprocedure_modifies(prefixed, alias)
            cast_nodes = prof_record.get("nodes")
            if isinstance(cast_nodes, dict):
                n = cast_nodes.get(alias)
                if isinstance(n, dict):
                    n["prefix_and_reg_instrument_s"] = prof.elapsed_since(t_prefix)
        prof_record["prefix_and_reg_instrument_total_s"] = prof.elapsed_since(t_prefix_all)

        node_pipeline_stages = {}
        t_pipeline = prof.mark()
        if pipeline_two_stage:
            for alias, prefixed in node_prefixed.items():
                if not _node_needs_two_stage(prefixed, alias):
                    continue
                stages = split_pipeline_stages(prefixed, alias)
                if stages:
                    node_pipeline_stages[alias] = stages
        prof_record["pipeline_two_stage_infer_s"] = prof.elapsed_since(t_pipeline)

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
        t_harness_emit = prof.mark()
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
            p4b_fail_fast_global_assert_indices=sorted(p4b_fail_fast_global_assert_indices),
        )
        helpers = emitter.emit_helpers()
        harness = emitter.emit(emit_helpers=False)
        prof_record["python_harness_emit_s"] = prof.elapsed_since(t_harness_emit)

        # 4) Concatenate into a single .bpl
        t_merge_write = prof.mark()
        merged_text = merge_boogie_program(
            spec=spec,
            helpers=helpers,
            node_prefixed=node_prefixed,
            harness=harness,
            enqueue_emitter=emitter,
        )
        out_bpl.write_text(merged_text, encoding="utf-8")
        prof_record["merge_and_write_bpl_s"] = prof.elapsed_since(t_merge_write)
        prof_record["frontend_prune_total_s"] = round(
            float(prof_record.get("build_slicing_plan_s", 0.0))
            + sum(
                float(v.get("env_input_prune_s", 0.0))
                for v in (prof_record.get("nodes", {}) or {}).values()
                if isinstance(v, dict)
            ),
            6,
        )
        prof_record["frontend_translate_total_s"] = round(
            sum(
                float(v.get("p4_to_bpl_s", 0.0))
                for v in (prof_record.get("nodes", {}) or {}).values()
                if isinstance(v, dict)
            ),
            6,
        )
        prof_record["total_backend_compile_s"] = prof.total_elapsed()
        prof.append()
        return out_bpl


def _infer_fail_fast_register_asserts(spec: SpecModel, alias: str) -> List[str]:
    """
    Detect exact mirror-only global assertions that P4B can duplicate at write sites.

    Only the narrow forms below are eligible, and the original global assertion remains
    in the harness:
      !(alias_Reg__wrote_any && alias_Reg__last_value == C)
      !(alias_Reg__wrote_index0 && alias_Reg__last0_value == C)
    """

    out: List[str] = []
    prefix = f"{alias}_"
    for expr in spec.global_decl.assert_exprs:
        matched = _match_fail_fast_expr(expr)
        if matched is None:
            continue
        reg, mode, const_value = matched
        if not reg.startswith(prefix):
            continue
        local_reg = reg[len(prefix) :]
        if local_reg:
            out.append(f"{local_reg}:{mode}:{const_value}")
    return out


def _infer_fail_fast_global_assert_indices(spec: SpecModel, alias: str) -> List[int]:
    """
    Return global assertion indices that were duplicated by P4B at register write sites.

    The harness may skip these duplicate end-of-step checks for performance, but only
    after a P4B-generated node accepted the corresponding fail-fast request.
    """

    out: List[int] = []
    prefix = f"{alias}_"
    for idx, expr in enumerate(spec.global_decl.assert_exprs):
        matched = _match_fail_fast_expr(expr)
        if matched is None:
            continue
        reg, _mode, _const_value = matched
        if reg.startswith(prefix) and reg[len(prefix) :]:
            out.append(idx)
    return out


def _infer_fail_fast_register_assert_pairs(spec: SpecModel, alias: str) -> List[tuple[str, int]]:
    out: List[tuple[str, int]] = []
    prefix = f"{alias}_"
    for idx, expr in enumerate(spec.global_decl.assert_exprs):
        matched = _match_fail_fast_expr(expr)
        if matched is None:
            continue
        reg, mode, const_value = matched
        if not reg.startswith(prefix):
            continue
        local_reg = reg[len(prefix) :]
        if local_reg:
            out.append((f"{local_reg}:{mode}:{const_value}", idx))
    return out


def _prefix_fail_fast_register_assert_item(alias: str, item: str) -> str:
    parts = item.split(":")
    if len(parts) != 3:
        return item
    reg, mode, const_value = parts
    return f"{alias}_{reg}:{mode}:{const_value}"


def _raw_bpl_has_fail_fast_register_assert(raw_text: str, item: str) -> bool:
    parts = item.split(":")
    if len(parts) != 3:
        return False
    reg, mode, const_value = parts
    if not reg or mode not in {"any", "slot0"}:
        return False
    proc_sig = f"procedure {{:inline 1}} {reg}.write("
    start = raw_text.find(proc_sig)
    if start < 0:
        proc_sig = f"procedure {reg}.write("
        start = raw_text.find(proc_sig)
    if start < 0:
        return False
    next_proc = raw_text.find("\nprocedure", start + len(proc_sig))
    body = raw_text[start:] if next_proc < 0 else raw_text[start:next_proc]
    const_patterns = {const_value}
    if const_value.isdigit():
        const_patterns.update({f"{const_value}bv8", f"{const_value}bv16", f"{const_value}bv32", f"{const_value}bv64"})
    if mode == "any":
        return (
            "assert false;" in body
            and f"{reg}__wrote_any" in body
            and f"{reg}__last_value" in body
            and any(f"{reg}__last_value == {pat}" in body for pat in const_patterns)
        )
    return (
        "assert false;" in body
        and f"{reg}__wrote_index0" in body
        and f"{reg}__last0_value" in body
        and any(f"{reg}__last0_value == {pat}" in body for pat in const_patterns)
    )


def _match_fail_fast_expr(expr: Tree) -> Optional[tuple[str, str, str]]:
    if not isinstance(expr, Tree) or str(expr.data) != "not_op":
        return None
    children = [c for c in expr.children if isinstance(c, Tree)]
    if len(children) != 1 or str(children[0].data) != "and_op":
        return None
    terms = [c for c in children[0].children if isinstance(c, Tree)]
    if len(terms) != 2:
        return None

    bool_var: Optional[str] = None
    eq_info: Optional[tuple[str, str]] = None
    for term in terms:
        var_name = _expr_dotted_var(term)
        if var_name is not None:
            bool_var = var_name
            continue
        maybe_eq = _expr_eq_var_number(term)
        if maybe_eq is not None:
            eq_info = maybe_eq
            continue
        return None

    if bool_var is None or eq_info is None:
        return None
    value_var, const_value = eq_info
    if bool_var.endswith("__wrote_any") and value_var.endswith("__last_value"):
        reg_a = bool_var[: -len("__wrote_any")]
        reg_b = value_var[: -len("__last_value")]
        if reg_a == reg_b:
            return reg_a, "any", const_value
    if bool_var.endswith("__wrote_index0") and value_var.endswith("__last0_value"):
        reg_a = bool_var[: -len("__wrote_index0")]
        reg_b = value_var[: -len("__last0_value")]
        if reg_a == reg_b:
            return reg_a, "slot0", const_value
    return None


def _expr_dotted_var(expr: Tree) -> Optional[str]:
    if not isinstance(expr, Tree):
        return None
    if str(expr.data) == "var" and expr.children and isinstance(expr.children[0], Tree):
        return _expr_dotted_var(expr.children[0])
    if str(expr.data) != "dotted_var":
        return None
    parts: List[str] = []
    for child in expr.children:
        if isinstance(child, Tree):
            if child.children:
                parts.append(str(child.children[0]))
        else:
            parts.append(str(child))
    return ".".join(p for p in parts if p)


def _expr_eq_var_number(expr: Tree) -> Optional[tuple[str, str]]:
    if not isinstance(expr, Tree) or str(expr.data) != "eq":
        return None
    terms = [c for c in expr.children if isinstance(c, Tree)]
    if len(terms) != 2:
        return None

    left_var = _expr_dotted_var(terms[0])
    right_num = _expr_number(terms[1])
    if left_var is not None and right_num is not None:
        return left_var, right_num

    right_var = _expr_dotted_var(terms[1])
    left_num = _expr_number(terms[0])
    if right_var is not None and left_num is not None:
        return right_var, left_num
    return None


def _expr_number(expr: Tree) -> Optional[str]:
    if isinstance(expr, Tree) and str(expr.data) == "number" and expr.children:
        return str(expr.children[0])
    return None


__all__ = ["BoogieBackend"]
