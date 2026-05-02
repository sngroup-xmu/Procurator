#include "backends/verify/slicing/slicer_selftest.h"

#include <iostream>
#include <map>
#include <string>
#include <unordered_set>

#include "ir/ir.h"

namespace P4Verify {

static bool _setContains(const std::unordered_set<cstring>& set, const char* value) {
    return set.count(cstring(value)) > 0;
}

static bool _mapTryGet(const std::map<cstring, int>& map, const char* key, int& out) {
    auto it = map.find(cstring(key));
    if (it == map.end()) {
        return false;
    }
    out = it->second;
    return true;
}

int runSlicingSelftest(cstring selftestCase,
                       const SliceResult& sres,
                       const IR::P4Program* slicedProgram) {
    const std::string caseName = selftestCase ? selftestCase.c_str() : "";
    if (caseName.empty()) {
        std::cerr << "[SELFTEST] missing --slicing-selftest=<case>\n";
        return 2;
    }

    if (caseName != "netchain_seq" && caseName != "netchain_pop_front" &&
        caseName != "distcache_reg_alias" && caseName != "distcache_parser_select" &&
        caseName != "recirc_meta_flow" && caseName != "frr_pkt_par_write" &&
        caseName != "netlock_pushback_underflow" && caseName != "etc_pkt_len_target_prefix" &&
        caseName != "flowdos_hash_index_dependency") {
        std::cerr << "[SELFTEST] unknown case: " << caseName << "\n";
        return 2;
    }

    bool ok = true;
    auto expect = [&](bool cond, const std::string& msg) {
        if (!cond) {
            ok = false;
            std::cerr << "[SELFTEST] FAIL: " << msg << "\n";
        }
    };

    if (caseName == "netchain_seq") {
        // Netchain slicing regression (field-sensitive headers):
        // Seed: sequence_reg_0[0] (sequence register only). Expected effects:
        //  - keep write path (assign_value/maintain_sequence/get_sequence)
        //  - drop value_reg / nc_hdr.value dependent path (read_value)
        //  - prune register index domain to {0} for sequence_reg
        expect(_setContains(sres.keepTables, "assign_value"), "expected keepTables contains assign_value");
        expect(_setContains(sres.keepTables, "maintain_sequence"), "expected keepTables contains maintain_sequence");
        expect(_setContains(sres.keepTables, "get_sequence"), "expected keepTables contains get_sequence");
        expect(!_setContains(sres.keepTables, "read_value"), "expected keepTables does NOT contain read_value");

        expect(_setContains(sres.keepVarNames, "hdr.nc_hdr.seq"), "expected keepVarNames contains hdr.nc_hdr.seq");
        expect(!_setContains(sres.keepVarNames, "hdr.nc_hdr.value"),
               "expected keepVarNames does NOT contain hdr.nc_hdr.value");

        int maxIdx = -1;
        const bool hasSeq = _mapTryGet(sres.regMaxIndex, "sequence_reg", maxIdx) ||
                            _mapTryGet(sres.regMaxIndex, "sequence_reg_0", maxIdx);
        expect(hasSeq, "expected regMaxIndex contains sequence_reg (or sequence_reg_0)");
        if (hasSeq) {
            expect(maxIdx == 0, "expected regMaxIndex(sequence_reg) == 0");
        }
        expect(!_setContains(sres.keepVarNames, "value_reg"), "expected keepVarNames does NOT contain value_reg");
        expect(!_setContains(sres.keepVarNames, "value_reg_0"), "expected keepVarNames does NOT contain value_reg_0");

        // applySlice() should also remove the unused register Declaration_Instance from the IR,
        // otherwise translation will still emit the register array and helper procs.
        if (slicedProgram) {
            class InstNameCollector : public Inspector {
             public:
                std::unordered_set<std::string> names;
                bool preorder(const IR::Declaration_Instance* inst) override {
                    if (inst) {
                        names.insert(inst->name.name.c_str());
                    }
                    return false;
                }
            };
            InstNameCollector col;
            slicedProgram->apply(col);
            expect(col.names.count("sequence_reg_0") > 0, "expected sliced IR contains Declaration_Instance sequence_reg_0");
            expect(col.names.count("value_reg_0") == 0, "expected sliced IR prunes unused Declaration_Instance value_reg_0");
        }
    } else if (caseName == "distcache_reg_alias") {
        // DistCache slicing regression: allow dslc to seed slicing using Boogie-level register names
        // (sanitized control-plane names), even when the IR instance name differs.
        //
        // Expected: seed `netcacheEgress_cm3_reg` maps to internal `cm3_reg_0`, and we keep both
        // names so translation can retain the Boogie-level declaration while slicing reasons about
        // the IR name.
        expect(_setContains(sres.keepVarNames, "cm3_reg_0"), "expected keepVarNames contains cm3_reg_0");
        expect(_setContains(sres.keepVarNames, "netcacheEgress_cm3_reg"),
               "expected keepVarNames contains netcacheEgress_cm3_reg");
        expect(_setContains(sres.keepVarNames, "cm4_reg_0"), "expected keepVarNames contains cm4_reg_0");
        expect(_setContains(sres.keepVarNames, "netcacheEgress_cm4_reg"),
               "expected keepVarNames contains netcacheEgress_cm4_reg");

        class InstNameCollector : public Inspector {
         public:
            std::unordered_set<std::string> names;
            bool preorder(const IR::Declaration_Instance* inst) override {
                if (inst) {
                    names.insert(inst->name.name.c_str());
                }
                return false;
            }
        };
        if (slicedProgram) {
            InstNameCollector col;
            slicedProgram->apply(col);
            expect(col.names.count("cm3_reg_0") > 0, "expected sliced IR contains Declaration_Instance cm3_reg_0");
            expect(col.names.count("cm4_reg_0") > 0, "expected sliced IR contains Declaration_Instance cm4_reg_0");
        }
    } else if (caseName == "distcache_parser_select") {
        // DistCache parser slicing regression: parser select expressions use header fields (e.g.,
        // hdr.vallen_hdr.vallen, hdr.shadowtype_hdr.shadowtype). If the slicer prunes parser
        // extract statements or drops these select fields from keepVarNames, the Boogie
        // translation becomes ill-typed (undeclared identifiers) and can introduce spurious
        // behaviors due to unconstrained header fields.
        expect(_setContains(sres.keepVarNames, "hdr.vallen_hdr.vallen"),
               "expected keepVarNames contains hdr.vallen_hdr.vallen");
        expect(_setContains(sres.keepVarNames, "hdr.shadowtype_hdr.shadowtype"),
               "expected keepVarNames contains hdr.shadowtype_hdr.shadowtype");
    } else if (caseName == "recirc_meta_flow") {
        // Cross-stage slicing regression: Ingress defines metadata that Egress reads.
        //
        // This case expects a P4 program where:
        //   - MyIngress assigns meta.do_recirculate (e.g., 0/1)
        //   - MyEgress reads meta.do_recirculate to decide recirculation
        //
        // Slicing must not delete the ingress assignment when the egress read is kept,
        // otherwise meta.do_recirculate becomes an unconstrained input and the model
        // is no longer faithful.
        expect(_setContains(sres.keepVarNames, "meta.do_recirculate"),
               "expected keepVarNames contains meta.do_recirculate");

        if (slicedProgram) {
            class IngressMetaAssignFinder : public Inspector {
             public:
                bool inIngress = false;
                bool foundAssign = false;

                bool preorder(const IR::P4Control* ctrl) override {
                    inIngress = (ctrl && ctrl->name.name == "MyIngress");
                    return inIngress;
                }

                bool preorder(const IR::AssignmentStatement* stmt) override {
                    if (!inIngress || !stmt || !stmt->left) {
                        return false;
                    }
                    auto member = stmt->left->to<IR::Member>();
                    if (!member || member->member.name != "do_recirculate") {
                        return false;
                    }
                    auto base = member->expr->to<IR::PathExpression>();
                    if (base && base->path && base->path->name.name == "meta") {
                        foundAssign = true;
                    }
                    return false;
                }
            };

            IngressMetaAssignFinder finder;
            slicedProgram->apply(finder);
            expect(finder.foundAssign,
                   "expected sliced IR retains at least one assignment to meta.do_recirculate in MyIngress");
        }
    } else if (caseName == "netchain_pop_front") {
        // Header-stack slicing regression: preserve hdr.overlay.pop_front(1) when
        // slicing for stack elements (e.g., hdr.overlay.0.swip). pop_front is a
        // semantic write to the whole header stack and must not be dropped as
        // "side-effect free" with respect to per-index fields.

        expect(_setContains(sres.keepVarNames, "hdr.overlay.0.swip"),
               "expected keepVarNames contains hdr.overlay.0.swip");
        // pop_front shifts validity/fields across the whole stack. If slicing does not model
        // these implicit dependencies, the pruned program can still translate into Boogie that
        // references missing stack element declarations (ill-typed Boogie).
        for (int i = 0; i < 10; ++i) {
            const std::string ref = std::string("hdr.overlay.") + std::to_string(i);
            expect(_setContains(sres.keepVarNames, ref.c_str()),
                   "expected keepVarNames contains " + ref);
            const std::string swip = ref + ".swip";
            expect(_setContains(sres.keepVarNames, swip.c_str()),
                   "expected keepVarNames contains " + swip);
        }

        if (slicedProgram) {
            class PopFrontFinder : public Inspector {
             public:
                bool found = false;

                bool preorder(const IR::MethodCallExpression* call) override {
                    if (!call || !call->method) {
                        return false;
                    }
                    auto member = call->method->to<IR::Member>();
                    if (!member || member->member.name != "pop_front") {
                        return false;
                    }
                    auto receiver = member->expr->to<IR::Member>();
                    if (!receiver || receiver->member.name != "overlay") {
                        return false;
                    }
                    auto base = receiver->expr->to<IR::PathExpression>();
                    if (base && base->path && base->path->name.name == "hdr") {
                        found = true;
                    }
                    return false;
                }
            };

            PopFrontFinder finder;
            slicedProgram->apply(finder);
            expect(finder.found,
                   "expected sliced IR retains hdr.overlay.pop_front(...) method call");
        }
    } else if (caseName == "frr_pkt_par_write") {
        // FRR slicing regression (stateful writes kept for multi-step semantics):
        //
        // Seed: meta.local_metadata.out_port, meta.local_metadata.pkt_par.
        //
        // Expected effects:
        //  - keep the stateful register write sites `pkt_par.write(...)` that store pkt_par,
        //    even though they do not directly define the seed fields in the same action.
        expect(_setContains(sres.keepVarNames, "meta.local_metadata.out_port"),
               "expected keepVarNames contains meta.local_metadata.out_port");
        expect(_setContains(sres.keepVarNames, "meta.local_metadata.pkt_par"),
               "expected keepVarNames contains meta.local_metadata.pkt_par");

        if (slicedProgram) {
            class PktParWriteCollector : public Inspector {
             public:
                bool found = false;
                bool preorder(const IR::MethodCallStatement* mcs) override {
                    if (!mcs || !mcs->methodCall || !mcs->methodCall->method) {
                        return false;
                    }
                    const auto* member = mcs->methodCall->method->to<IR::Member>();
                    if (!member || member->member != "write") {
                        return false;
                    }
                    const auto* recv = member->expr ? member->expr->to<IR::PathExpression>() : nullptr;
                    if (!recv || !recv->path) {
                        return false;
                    }
                    const std::string name = recv->path->name.toString().c_str();
                    if (name.rfind("pkt_par", 0) == 0) {
                        found = true;
                    }
                    return false;
                }
            };
            PktParWriteCollector col;
            slicedProgram->apply(col);
            expect(col.found, "expected sliced IR contains pkt_par.write(...) method call");
        }
    } else if (caseName == "flowdos_hash_index_dependency") {
        // FlowDoS regression: counter_filter is indexed by counter_pos, which
        // is produced in compute_hash() via v1model hash(...). Slicing must not
        // keep the register update while dropping this index producer.
        expect(_setContains(sres.keepVarNames, "counter_pos"),
               "expected keepVarNames contains counter_pos");
        expect(_setContains(sres.keepVarNames, "counter_val"),
               "expected keepVarNames contains counter_val");
        expect(_setContains(sres.keepVarNames, "counter_filter") ||
                   _setContains(sres.keepVarNames, "counter_filter_0"),
               "expected keepVarNames contains counter_filter");

        if (slicedProgram) {
            class ComputeHashFinder : public Inspector {
             public:
                bool inComputeHash = false;
                bool foundHashCall = false;

                bool preorder(const IR::P4Action* action) override {
                    inComputeHash = action && action->name.name == "compute_hash";
                    return inComputeHash;
                }

                void postorder(const IR::P4Action* action) override {
                    if (action && action->name.name == "compute_hash") {
                        inComputeHash = false;
                    }
                }

                bool preorder(const IR::MethodCallExpression* call) override {
                    if (!inComputeHash || !call || !call->method) {
                        return true;
                    }
                    if (auto pe = call->method->to<IR::PathExpression>()) {
                        if (pe->path && pe->path->name.name == "hash") {
                            foundHashCall = true;
                        }
                    }
                    return true;
                }
            };

            ComputeHashFinder finder;
            slicedProgram->apply(finder);
            expect(finder.foundHashCall,
                   "expected sliced IR retains hash(...) inside compute_hash action");
        }
    } else if (caseName == "netlock_pushback_underflow") {
        // NetLock slicing regression: ensure register-action execute inside assignments is not dropped.
        //
        // Seed: slots_two_sides_register[0]
        //
        // Expected:
        //  - keep acquire-lock path that updates empty slots
        //  - keep regMaxIndex(slots_two_sides_register) == 0
        expect(_setContains(sres.keepTables, "SwitchIngress.acquire_lock.dec_empty_slots_table"),
               "expected keepTables contains SwitchIngress.acquire_lock.dec_empty_slots_table");

        int maxIdx = -1;
        const bool hasReg = _mapTryGet(sres.regMaxIndex, "slots_two_sides_register", maxIdx) ||
                            _mapTryGet(sres.regMaxIndex, "slots_two_sides_register_0", maxIdx);
        expect(hasReg, "expected regMaxIndex contains slots_two_sides_register (or slots_two_sides_register_0)");
        if (hasReg) {
            expect(maxIdx == 0, "expected regMaxIndex(slots_two_sides_register) == 0");
        }

        if (slicedProgram) {
            class TableCollector : public Inspector {
             public:
                bool found = false;
                bool preorder(const IR::P4Table* t) override {
                    if (t) {
                        cstring cp = t->controlPlaneName();
                        if (!cp.isNullOrEmpty() &&
                            cp == "SwitchIngress.acquire_lock.dec_empty_slots_table") {
                            found = true;
                        }
                    }
                    if (t && t->name.name == "SwitchIngress_acquire_lock_dec_empty_slots_table") {
                        found = true;
                    }
                    return false;
                }
            };
            TableCollector col;
            slicedProgram->apply(col);
            expect(col.found,
                   "expected sliced IR retains P4Table SwitchIngress.acquire_lock.dec_empty_slots_table");
        }
    } else if (caseName == "etc_pkt_len_target_prefix") {
        // ETC_NOMS_2024 target-write slicing regression:
        // `hdr.recirc` is a normal header name and must not be mistaken for the
        // recirculate extern. For a write-site seed on reg_pkt_len_total, slicing
        // should keep the target-flow/table prefix and the packet-length register
        // update path, but it should not keep later feature/classification suffixes.
        expect(_setContains(sres.keepTables, "Ingress.target_flows_table"),
               "expected keepTables contains Ingress.target_flows_table");
        expect(!_setContains(sres.keepTables, "Ingress.code_table0"),
               "expected keepTables does NOT contain Ingress.code_table0");
        expect(!_setContains(sres.keepTables, "Ingress.voting_table"),
               "expected keepTables does NOT contain Ingress.voting_table");
        expect(!_setContains(sres.keepVarNames, "read_flow_iat_min.execute"),
               "expected keepVarNames does NOT contain read_flow_iat_min.execute");
        expect(!_setContains(sres.keepVarNames, "read_flow_iat_max.execute"),
               "expected keepVarNames does NOT contain read_flow_iat_max.execute");
        expect(!_setContains(sres.keepVarNames, "read_pkt_count.execute"),
               "expected keepVarNames does NOT contain read_pkt_count.execute");
        expect(!_setContains(sres.keepVarNames, "read_pkt_len_max.execute"),
               "expected keepVarNames does NOT contain read_pkt_len_max.execute");
        expect(!_setContains(sres.keepVarNames, "read_time_last_pkt.execute"),
               "expected keepVarNames does NOT contain read_time_last_pkt.execute");
        expect(_setContains(sres.keepVarNames, "read_pkt_len_total.execute"),
               "expected keepVarNames contains read_pkt_len_total.execute");
        expect(_setContains(sres.keepVarNames, "read_reg_status.execute"),
               "expected keepVarNames contains read_reg_status.execute");
        expect(_setContains(sres.keepVarNames, "read_only_flow_ID.execute"),
               "expected keepVarNames contains read_only_flow_ID.execute");
        expect(_setContains(sres.keepVarNames, "update_flow_ID.execute"),
               "expected keepVarNames contains update_flow_ID.execute");
        int maxIdx = -1;
        if (_mapTryGet(sres.regMaxIndex, "Ingress_reg_pkt_len_total", maxIdx)) {
            expect(maxIdx == 0, "expected regMaxIndex(Ingress_reg_pkt_len_total) == 0");
            expect(_mapTryGet(sres.regMaxIndex, "Ingress_reg_status", maxIdx),
                   "expected same-index propagation to Ingress_reg_status");
            expect(maxIdx == 0, "expected regMaxIndex(Ingress_reg_status) == 0");
            expect(_mapTryGet(sres.regMaxIndex, "Ingress_reg_flow_ID", maxIdx),
                   "expected same-index propagation to Ingress_reg_flow_ID");
            expect(maxIdx == 0, "expected regMaxIndex(Ingress_reg_flow_ID) == 0");
        }
    }

    if (ok) {
        std::cerr << "[SELFTEST] PASS: " << caseName << "\n";
        return 0;
    }
    return 1;
}


}  // namespace P4Verify
