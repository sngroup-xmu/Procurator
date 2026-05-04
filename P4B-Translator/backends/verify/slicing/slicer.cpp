// Semantic-aware slicing for P4 IR.
#include "slicer.h"
#include "slicer_internal.h"

namespace P4Verify {

using namespace slicing_internal;

Slicer::Slicer(const IR::P4Program* program, P4::ReferenceMap* refMap, P4::TypeMap* typeMap)
    : program(program), refMap(refMap), typeMap(typeMap) {
    CHECK_NULL(program);
    CHECK_NULL(refMap);
    CHECK_NULL(typeMap);
}

SliceResult Slicer::run(const SliceOptions& opts) {
    SliceResult result;
    std::vector<cstring> seedInputs = opts.seedVars;
    if (opts.bmv2Analyzer) {
        for (const auto* rw : opts.bmv2Analyzer->getRegisterWriteCmds()) {
            if (!rw) {
                continue;
            }
            if (rw->reg != nullptr && rw->reg != "") {
                seedInputs.push_back(rw->reg);
            }
            if (rw->control != nullptr && rw->control != "" && rw->reg != nullptr && rw->reg != "") {
                std::string qualified = rw->control.c_str();
                qualified += "_";
                qualified += rw->reg.c_str();
                seedInputs.push_back(cstring(qualified.c_str()));
            }
        }
    }
    bool doSlicing = opts.enable && !seedInputs.empty();
    if (!doSlicing && !opts.collectRw) {
        return result;
    }

    if (opts.debug) {
        std::cerr << "[slicer] start\n";
    }

    ActionTableCollector collector;
    program->apply(collector);
    std::unordered_map<cstring, UsesDefs> actionUsesDefs;
    std::unordered_map<cstring, UsesDefs> tableUsesDefs;
    std::unordered_map<cstring, std::unordered_set<int>> actionStmtIds;
    std::unordered_map<cstring, UsesDefs> regActionUsesDefs;
    std::unordered_map<cstring, std::unordered_set<int>> regActionStmtIds;
    std::unordered_map<cstring, cstring> regActionRegs;
    auto sanitizeDeclName = [](const std::string& raw) -> std::string {
        std::string out;
        out.reserve(raw.size());
        for (char c : raw) {
            if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '_') {
                out.push_back(c);
            } else {
                out.push_back('_');
            }
        }
        if (!out.empty() && out[0] >= '0' && out[0] <= '9') {
            out.insert(out.begin(), '_');
        }
        return out;
    };
    auto addRegActionRegAlias = [&](const IR::Declaration_Instance* inst, cstring actionName,
                                    cstring regName) {
        if (actionName == nullptr || actionName == "" || regName == nullptr || regName == "") {
            return;
        }
        regActionRegs[actionName] = regName;
        if (inst) {
            cstring cp = inst->controlPlaneName();
            if (!cp.isNullOrEmpty()) {
                std::string sanitized = sanitizeDeclName(cp.c_str());
                if (!sanitized.empty()) {
                    regActionRegs[cstring(sanitized)] = regName;
                }
                auto dot = sanitized.rfind('_');
                if (dot != std::string::npos && dot + 1 < sanitized.size()) {
                    regActionRegs[cstring(sanitized.substr(dot + 1))] = regName;
                }
            }
        }
    };
    for (const auto& kv : collector.regActions) {
        const IR::Declaration_Instance* inst = kv.second;
        const IR::Function* applyFunc = findRegisterActionApply(inst);
        if (!applyFunc || !applyFunc->body) {
            continue;
	        }
	        UsesDefs ud;
	        collectStmtUsesDefs(applyFunc->body, ud, typeMap, nullptr, refMap);
        // RegisterAction.apply bodies do not explicitly mention the underlying register object.
        // Conservatively model each RegisterAction instance as reading+writing its register argument.
        if (inst && inst->arguments && inst->arguments->size() > 0) {
            if (auto arg0 = (*inst->arguments)[0]) {
                if (arg0->expression) {
                    collectExprKeys(arg0->expression, ud.uses, typeMap);
                    collectExprKeys(arg0->expression, ud.defs, typeMap);
                    VarKey regKey;
                    if (buildVarKey(arg0->expression, regKey) && !regKey.base.empty()) {
                        addRegActionRegAlias(inst, kv.first, cstring(varKeyToString(regKey)));
                    }
                }
            }
        }
        regActionUsesDefs.emplace(kv.first, std::move(ud));
        std::unordered_set<int> ids;
        collectStmtIds(applyFunc->body, ids);
        regActionStmtIds.emplace(kv.first, std::move(ids));
    }
	    for (const auto& kv : collector.actions) {
	        UsesDefs ud;
	        collectStmtUsesDefs(kv.second->body, ud, typeMap, &regActionUsesDefs, refMap);
	        actionUsesDefs.emplace(kv.first, std::move(ud));
        std::unordered_set<int> ids;
        collectStmtIds(kv.second->body, ids);
        actionStmtIds.emplace(kv.first, std::move(ids));
    }

    // Control-plane-aware table slicing: if we have bmv2 commands, restrict action choices for
    // tables that have explicit rules/defaults. This helps avoid slicing blowups caused by
    // conservatively treating all table actions and match keys as relevant.
    struct TableCpInfo {
        bool fixedDefault = false;  // fixed by table_set_default with no table_add rules
        bool hasRules = false;
        std::set<cstring> allowedActions;  // rules + (explicit default) + (P4 default fallback when needed)
    };
    std::unordered_map<cstring, TableCpInfo> tableCp;
    if (opts.bmv2Analyzer) {
        auto p4DefaultActionName = [](const IR::Expression* defAct) -> cstring {
            if (!defAct) {
                return nullptr;
            }
            if (auto pe = defAct->to<IR::PathExpression>()) {
                return pe->path->name;
            }
            if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto m = mce->method->to<IR::PathExpression>()) {
                    return m->path->name;
                }
            }
            return nullptr;
        };
        for (const auto& kv : collector.tables) {
            const IR::P4Table* table = kv.second;
            if (!table) {
                continue;
            }
            TableCpInfo info;
            info.hasRules = opts.bmv2Analyzer->hasTableAddCmds(kv.first);
            TableSetDefault* defCmd = opts.bmv2Analyzer->getTableSetDefaultCmd(kv.first);
            if (defCmd != nullptr) {
                info.allowedActions.insert(defCmd->action);
                if (!info.hasRules) {
                    info.fixedDefault = true;
                }
            }
            if (info.hasRules) {
                for (auto rule : opts.bmv2Analyzer->getTableAddCmds(kv.first)) {
                    if (rule) {
                        info.allowedActions.insert(rule->action);
                    }
                }
                // If there are rules but no explicit default, bmv2 falls back to the P4 default action.
                if (defCmd == nullptr) {
                    if (auto p4def = p4DefaultActionName(table->getDefaultAction())) {
                        info.allowedActions.insert(p4def);
                    }
                }
            }
            tableCp.emplace(kv.first, std::move(info));
        }
    }

    auto actionAllowed = [&](cstring tableName, cstring actionName) -> bool {
        if (!opts.bmv2Analyzer) {
            return true;
        }
        auto it = tableCp.find(tableName);
        if (it == tableCp.end() || it->second.allowedActions.empty()) {
            return true;
        }
        for (const auto& allowed : it->second.allowedActions) {
            if (isSame(actionName, allowed)) {
                return true;
            }
        }
        return false;
    };
    auto buildTableUsesDefs =
        [&](const std::unordered_map<cstring, UsesDefs>& currentActionUsesDefs)
        -> std::unordered_map<cstring, UsesDefs> {
        std::unordered_map<cstring, UsesDefs> out;
        for (const auto& kv : collector.tables) {
            const IR::P4Table* table = kv.second;
            UsesDefs ud;
            bool fixedDefault = false;
            if (opts.bmv2Analyzer) {
                auto it = tableCp.find(kv.first);
                if (it != tableCp.end()) {
                    fixedDefault = it->second.fixedDefault;
                }
            }
            if (!fixedDefault) {
                // Table action selection is modeled via action_run.
                VarKey actionRun;
                actionRun.base = kv.first.c_str();
                actionRun.segs.push_back("action_run");
                addVarKey(ud.defs, actionRun);
                if (auto key = table->getKey()) {
                    for (auto ke : key->keyElements) {
                        if (ke && ke->expression) {
                            collectExprKeys(ke->expression, ud.uses, typeMap);
                        }
                    }
                }
            }
            if (auto al = table->getActionList()) {
                for (auto a : al->actionList) {
                    if (!a) {
                        continue;
                    }
                    auto path = a->getPath();
                    if (!path) {
                        continue;
                    }
                    const bool allowed = actionAllowed(kv.first, path->name);
                    auto it = currentActionUsesDefs.find(path->name);
                    if (!allowed) {
                        continue;
                    }
                    if (it != currentActionUsesDefs.end()) {
                        mergeSets(ud.uses, it->second.uses);
                        mergeSets(ud.defs, it->second.defs);
                    }
                }
            }
            if (auto defAct = table->getDefaultAction()) {
                if (auto pe = defAct->to<IR::PathExpression>()) {
                    if (!actionAllowed(kv.first, pe->path->name)) {
                        // For rule-based tables without explicit defaults, we add P4's default to allowedActions above.
                        // Otherwise, treat non-allowed defaults as irrelevant for the configured control plane.
                        goto default_done;
                    }
                    auto it = currentActionUsesDefs.find(pe->path->name);
                    if (it != currentActionUsesDefs.end()) {
                        mergeSets(ud.uses, it->second.uses);
                        mergeSets(ud.defs, it->second.defs);
                    }
                } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                    if (auto m = mce->method->to<IR::PathExpression>()) {
                        if (!actionAllowed(kv.first, m->path->name)) {
                            goto default_done;
                        }
                        auto it = currentActionUsesDefs.find(m->path->name);
                        if (it != currentActionUsesDefs.end()) {
                            mergeSets(ud.uses, it->second.uses);
                            mergeSets(ud.defs, it->second.defs);
                        }
                    }
                }
default_done:
                ;
            }
            out.emplace(kv.first, std::move(ud));
        }
        return out;
    };

    tableUsesDefs = buildTableUsesDefs(actionUsesDefs);

    StatefulDeclCollector statefulDeclCollector;
    program->apply(statefulDeclCollector);

    if (opts.collectRw) {
        UsesDefs rw;
        for (auto obj : program->objects) {
            if (auto control = obj->to<IR::P4Control>()) {
                collectStmtUsesDefs(control->body, rw, typeMap, &regActionUsesDefs, refMap);
            }
        }
        std::set<std::string> reads;
        std::set<std::string> writes;
        auto canonicalizeStateful = [&](const VarKey& v, VarKey& out) -> bool {
            out = v;
            if (statefulDeclCollector.objects.count(v.base)) {
                return true;
            }
            std::string base = v.base.c_str();
            std::string withSuffix = base + "_0";
            if (statefulDeclCollector.objects.count(withSuffix)) {
                out.base = withSuffix.c_str();
                return true;
            }
            if (base.size() > 2 && base.rfind("_0") == base.size() - 2) {
                std::string trimmed = base.substr(0, base.size() - 2);
                if (statefulDeclCollector.objects.count(trimmed)) {
                    out.base = trimmed.c_str();
                    return true;
                }
            }
            return false;
        };
        for (const auto& v : rw.uses) {
            VarKey canon;
            if (canonicalizeStateful(v, canon)) {
                reads.insert(varKeyToString(canon));
            }
        }
        for (const auto& v : rw.defs) {
            VarKey canon;
            if (canonicalizeStateful(v, canon)) {
                writes.insert(varKeyToString(canon));
            }
        }
        std::set<std::string> touchedObjs;
        auto markTouched = [&](const std::string& s) {
            auto pos = s.find('.');
            if (pos == std::string::npos) {
                touchedObjs.insert(s);
            } else {
                touchedObjs.insert(s.substr(0, pos));
            }
        };
        for (const auto& v : reads) {
            markTouched(v);
        }
        for (const auto& v : writes) {
            markTouched(v);
        }
        for (const auto& obj : statefulDeclCollector.objects) {
            std::string name = obj.c_str();
            if (!touchedObjs.count(name)) {
                reads.insert(name);
                writes.insert(name);
            }
        }
        for (const auto& v : reads) {
            result.rwReads.push_back(cstring(v.c_str()));
        }
        for (const auto& v : writes) {
            result.rwWrites.push_back(cstring(v.c_str()));
        }
        for (const auto& obj : statefulDeclCollector.objects) {
            result.rwStatefulObjects.push_back(cstring(obj.c_str()));
        }
    }

    if (!doSlicing) {
        return result;
    }

    CFGBuilder cfg(refMap, typeMap);
    cfg.build(program);
    if (opts.debug) {
        std::cerr << "[slicer] CFG built, nodes=" << cfg.nodes.size() << "\n";
    }

    RegisterDeclCollector regDeclCollector;
    program->apply(regDeclCollector);
    std::set<VarKey, VarKeyLess> seedVars =
        normalizeSeeds(seedInputs, &regDeclCollector.regs, &regDeclCollector.controlToInternal);
    std::set<VarKey, VarKeyLess> explicitSeedVars =
        normalizeSeeds(opts.seedVars, &regDeclCollector.regs, &regDeclCollector.controlToInternal);
    auto tableDefinesSeed = [&](cstring tableName, const IR::P4Table* table) -> bool {
        if (!table) {
            return false;
        }
        auto hasSeedDef = [&](const cstring& actName) -> bool {
            auto it = actionUsesDefs.find(actName);
            if (it == actionUsesDefs.end()) {
                return false;
            }
            for (const auto& d : it->second.defs) {
                if (seedVars.count(d)) {
                    return true;
                }
            }
            return false;
        };
        if (auto al = table->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (path && actionAllowed(tableName, path->name) && hasSeedDef(path->name)) {
                    return true;
                }
            }
        }
        if (auto defAct = table->getDefaultAction()) {
            if (auto pe = defAct->to<IR::PathExpression>()) {
                if (actionAllowed(tableName, pe->path->name) && hasSeedDef(pe->path->name)) {
                    return true;
                }
            } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto pe = mce->method->to<IR::PathExpression>()) {
                    if (actionAllowed(tableName, pe->path->name) && hasSeedDef(pe->path->name)) {
                        return true;
                    }
                }
            }
        }
        return false;
    };
    // Seed action_run only for tables whose actions can define seed variables.
    for (const auto& kv : collector.tables) {
        bool fixedDefault = false;
        if (opts.bmv2Analyzer) {
            auto it = tableCp.find(kv.first);
            if (it != tableCp.end()) {
                fixedDefault = it->second.fixedDefault;
            }
        }
        if (fixedDefault) {
            continue;
        }
        if (!tableDefinesSeed(kv.first, kv.second)) {
            continue;
        }
        VarKey actionRun;
        actionRun.base = kv.first.c_str();
        actionRun.segs.push_back("action_run");
        addVarKey(seedVars, actionRun);
    }
    std::set<std::string> packetCarriedBases = collectPacketCarriedBases(program, refMap);
    // Optionally keep forwarding/drop/clone/recirc control variables as implicit seeds.
    // This is conservative (prevents slicing away control effects that can change
    // communication behavior), but may keep large parts of the pipeline for systems
    // where the property does not observe forwarding/egress behavior.
    if (opts.keepControlSeeds) {
        AllVarCollector allVars(typeMap);
        program->apply(allVars);
        const std::set<std::string> controlSegs = {
            "egress_port",
            "egress_spec",
            "ucast_egress_port",
            "forward",
            "drop",
            "p4b_clone_i2e",
            "p4b_clone_e2e",
            "p4b_clone_i2i",
            "p4b_recirculate"
        };
        for (const auto& v : allVars.vars) {
            if (controlSegs.count(v.base)) {
                seedVars.insert(v);
                continue;
            }
            if (!v.segs.empty() && controlSegs.count(v.segs.back())) {
                seedVars.insert(v);
            }
        }
        // `p4b_*` flags are synthetic (introduced by our semantic modeling of externs
        // like recirculate/clone) and may not appear as real IR variables. Seed them
        // explicitly so that control-effecting extern calls are not sliced away.
        for (const auto& base : {"p4b_recirculate", "p4b_clone_i2e", "p4b_clone_e2e", "p4b_clone_i2i"}) {
            VarKey key;
            key.base = base;
            seedVars.insert(key);
        }
    }
    // If a table's actions can define a seed-relevant variable, treat its match keys as seeds too.
    for (const auto& kv : collector.tables) {
        const IR::P4Table* table = kv.second;
        if (!table) {
            continue;
        }
        bool fixedDefault = false;
        if (opts.bmv2Analyzer) {
            auto it = tableCp.find(kv.first);
            if (it != tableCp.end()) {
                fixedDefault = it->second.fixedDefault;
            }
        }
        if (fixedDefault) {
            continue;
        }
        bool touchesSeed = false;
        if (auto al = table->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (!path) {
                    continue;
                }
                if (!actionAllowed(kv.first, path->name)) {
                    continue;
                }
                auto it = actionUsesDefs.find(path->name);
                if (it == actionUsesDefs.end()) {
                    continue;
                }
                for (const auto& d : it->second.defs) {
                    if (seedVars.count(d)) {
                        touchesSeed = true;
                        break;
                    }
                }
                if (touchesSeed) {
                    break;
                }
            }
        }
        if (!touchesSeed) {
            if (auto defAct = table->getDefaultAction()) {
                if (auto pe = defAct->to<IR::PathExpression>()) {
                    if (!actionAllowed(kv.first, pe->path->name)) {
                        goto def_done;
                    }
                    auto it = actionUsesDefs.find(pe->path->name);
                    if (it != actionUsesDefs.end()) {
                        for (const auto& d : it->second.defs) {
                            if (seedVars.count(d)) {
                                touchesSeed = true;
                                break;
                            }
                        }
                    }
                } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                    if (auto mpe = mce->method->to<IR::PathExpression>()) {
                        if (!actionAllowed(kv.first, mpe->path->name)) {
                            goto def_done;
                        }
                        auto it = actionUsesDefs.find(mpe->path->name);
                        if (it != actionUsesDefs.end()) {
                            for (const auto& d : it->second.defs) {
                                if (seedVars.count(d)) {
                                    touchesSeed = true;
                                    break;
                                }
                            }
                        }
                    }
                }
            }
        }
def_done:
        ;
        if (!touchesSeed) {
            continue;
        }
        if (auto key = table->getKey()) {
            for (auto ke : key->keyElements) {
                if (ke && ke->expression) {
                    std::set<VarKey, VarKeyLess> keyUses;
                    collectExprKeys(ke->expression, keyUses, typeMap);
                    for (const auto& u : keyUses) {
                        addSeedVarKey(seedVars, u);
                    }
                }
            }
        }
    }
    std::map<std::string, int> seedRegMaxIndex;
    for (auto s : seedInputs) {
        std::string base;
        int idx = -1;
        if (extractSeedIndex(s.c_str(), base, idx)) {
            auto it = seedRegMaxIndex.find(base);
            if (it == seedRegMaxIndex.end() || idx > it->second) {
                seedRegMaxIndex[base] = idx;
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] seeds=" << seedVars.size() << "\n";
        for (const auto& v : seedVars) {
            std::cerr << "  [slicer] seed " << varKeyToString(v) << "\n";
        }
    }
    auto keepNodeIsTargetRegisterWrite = [&](const NodeInfo& node) -> bool {
        if (!node.stmt) {
            return false;
        }
        cstring callee = nullptr;
        std::string methodName;
        if (auto as = node.stmt->to<IR::AssignmentStatement>()) {
            methodCallExprName(as->right, callee, methodName, refMap);
        } else if (auto mcs = node.stmt->to<IR::MethodCallStatement>()) {
            methodCallExprName(mcs->methodCall, callee, methodName, refMap);
        }
        if (callee == nullptr || (methodName != "write" && methodName != "execute")) {
            return false;
        }
        auto rit = regActionUsesDefs.find(callee);
        if (rit != regActionUsesDefs.end()) {
            for (const auto& d : rit->second.defs) {
                if (seedVars.count(d)) {
                    return true;
                }
            }
        }
        for (const auto& d : node.defs) {
            if (seedVars.count(d)) {
                return true;
            }
        }
        return false;
    };
    auto keepNodeDefinesExplicitSeed = [&](const NodeInfo& node) -> bool {
        for (const auto& d : node.defs) {
            for (const auto& seed : explicitSeedVars) {
                if (varKeyIsPrefix(d, seed) || varKeyIsPrefix(seed, d)) {
                    return true;
                }
            }
        }
        return false;
    };

    std::unordered_map<std::string, std::vector<VarKey>> extractSeedFields;
    auto isIndexLike = [](const std::string& s) {
        if (s == "next" || s == "last") {
            return true;
        }
        if (s.empty()) {
            return false;
        }
        for (char c : s) {
            if (c < '0' || c > '9') {
                return false;
            }
        }
        return true;
    };
    for (const auto& v : seedVars) {
        if (v.segs.size() < 2) {
            continue;
        }
        VarKey hdr;
        hdr.base = v.base;
        hdr.segs.push_back(v.segs[0]);
        extractSeedFields[varKeyToString(hdr)].push_back(v);
        if (v.segs.size() >= 3 && isIndexLike(v.segs[1])) {
            VarKey hdrIdx = hdr;
            hdrIdx.segs.push_back(v.segs[1]);
            extractSeedFields[varKeyToString(hdrIdx)].push_back(v);
        }
    }

    constexpr int kFixpointMaxIterations = 3;
    std::unordered_set<int> prevKeepStmtIds;
    std::unordered_set<int> keepStmtIds;
    std::unordered_set<cstring> keepActions;
    std::unordered_set<cstring> keepTables;
    std::set<VarKey, VarKeyLess> parserVars;

    for (int iter = 0; iter < kFixpointMaxIterations; ++iter) {
        // Run a small fixpoint between CFG slicing and action-body slicing.
        // The first pass uses coarse action/table summaries, and later passes
        // refine those summaries based on the sliced action bodies.
        tableUsesDefs = buildTableUsesDefs(actionUsesDefs);

        keepStmtIds.clear();
        keepActions.clear();
        keepTables.clear();
        parserVars.clear();

        result.hasRecirculation = false;
        for (auto& kv : cfg.nodes) {
            kv.second.uses.clear();
            kv.second.defs.clear();
        }

        // Fill use/def sets.
        for (auto& kv : cfg.nodes) {
            int id = kv.first;
            NodeInfo& node = kv.second;
            if (!node.stmt) {
                continue;
            }
            if (opts.debug) {
                std::cerr << "[slicer] node " << id << " type=" << node.stmt->node_type_name() << "\n";
            }
            fillNodeUsesDefs(node,
                             typeMap,
                             tableUsesDefs,
                             actionUsesDefs,
                             regActionUsesDefs,
                             &result.hasRecirculation,
                             opts.debug,
                             &extractSeedFields,
                             &seedVars,
                             refMap);
        }
        if (opts.debug) {
            std::cerr << "[slicer] use/def sets filled\n";
        }

    // Reaching definitions dataflow (two-pass to model cross-pass deps).
    auto buildAllDefs = [](const std::unordered_map<int, NodeInfo>& nodes) {
        std::map<VarKey, std::set<std::pair<int, VarKey>>, VarKeyLess> defs;
        for (const auto& kv : nodes) {
            for (const auto& v : kv.second.defs) {
                defs[v].insert({kv.first, v});
            }
        }
        return defs;
    };

    auto computeReaching =
        [&](const std::unordered_map<int, NodeInfo>& nodes,
            const std::map<VarKey, std::set<std::pair<int, VarKey>>, VarKeyLess>& allDefs,
            std::unordered_map<int, std::set<std::pair<int, VarKey>>>& in,
            std::unordered_map<int, std::set<std::pair<int, VarKey>>>& out) {
            bool changed = true;
            while (changed) {
                changed = false;
                for (const auto& kv : nodes) {
                    int id = kv.first;
                    const auto& node = kv.second;
                    std::set<std::pair<int, VarKey>> inSet;
                    for (int pred : node.preds) {
                        auto it = out.find(pred);
                        if (it != out.end()) {
                            inSet.insert(it->second.begin(), it->second.end());
                        }
                    }
                    std::set<std::pair<int, VarKey>> outSet = inSet;
                    for (const auto& d : node.defs) {
                        auto defIt = allDefs.find(d);
                        if (defIt != allDefs.end()) {
                            for (const auto& def : defIt->second) {
                                outSet.erase(def);
                            }
                        }
                    }
                    for (const auto& d : node.defs) {
                        outSet.insert({id, d});
                    }
                    if (in[id] != inSet || out[id] != outSet) {
                        in[id] = inSet;
                        out[id] = outSet;
                        changed = true;
                    }
                }
            }
        };

    std::unordered_map<int, std::set<std::pair<int, VarKey>>> in1, out1, in2, out2;
    auto allDefs1 = buildAllDefs(cfg.nodes);
    computeReaching(cfg.nodes, allDefs1, in1, out1);
    if (opts.debug) {
        std::cerr << "[slicer] reaching definitions done (pass 1)\n";
    }

    std::unordered_map<int, NodeInfo> nodes2 = cfg.nodes;
    if (result.hasRecirculation) {
        for (size_t i = 0; i < cfg.roots.size() && i < cfg.exits.size(); ++i) {
            int entry = cfg.roots[i];
            int exit = cfg.exits[i];
            if (entry != -1 && exit != -1) {
                nodes2[exit].succs.push_back(entry);
                nodes2[entry].preds.push_back(exit);
            }
        }
        if (opts.debug) {
            std::cerr << "[slicer] recirc edges done\n";
        }
        auto allDefs2 = buildAllDefs(nodes2);
        computeReaching(nodes2, allDefs2, in2, out2);
        if (opts.debug) {
            std::cerr << "[slicer] reaching definitions done (pass 2)\n";
        }
    }

    auto crossOk = [&](const VarKey& key) -> bool {
        if (packetCarriedBases.count(key.base)) {
            return true;
        }
        if (regDeclCollector.regs.count(key.base)) {
            return true;
        }
        std::string withSuffix = key.base + "_0";
        if (regDeclCollector.regs.count(withSuffix)) {
            return true;
        }
        return false;
    };
    auto isStatefulKey = [&](const VarKey& key) -> bool {
        if (regDeclCollector.regs.count(key.base)) {
            return true;
        }
        std::string withSuffix = key.base + "_0";
        if (regDeclCollector.regs.count(withSuffix)) {
            return true;
        }
        if (key.base.size() > 2 && key.base.rfind("_0") == key.base.size() - 2) {
            std::string trimmed = key.base.substr(0, key.base.size() - 2);
            if (regDeclCollector.regs.count(trimmed)) {
                return true;
            }
        }
        return false;
    };

    // Build data edges (add cross-pass edges only for CROSSOK variables).
    std::unordered_map<int, std::vector<int>> dataPreds;
    for (const auto& kv : cfg.nodes) {
        int id = kv.first;
        const auto& node = kv.second;
        for (const auto& use : node.uses) {
            auto it1 = in1.find(id);
            if (it1 != in1.end()) {
                for (const auto& def : it1->second) {
                    if (def.second == use) {
                        dataPreds[id].push_back(def.first);
                    }
                }
            }
            if (isStatefulKey(use)) {
                auto defIt = allDefs1.find(use);
                if (defIt != allDefs1.end()) {
                    for (const auto& def : defIt->second) {
                        dataPreds[id].push_back(def.first);
                    }
                }
            }
            if (result.hasRecirculation) {
                auto it2 = in2.find(id);
                if (it2 != in2.end()) {
                    for (const auto& def : it2->second) {
                        if (!(def.second == use)) {
                            continue;
                        }
                        bool inFirst = false;
                        if (it1 != in1.end()) {
                            inFirst = it1->second.count(def) > 0;
                        }
                        if (!inFirst && crossOk(use)) {
                            dataPreds[id].push_back(def.first);
                        }
                    }
                }
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] data edges done\n";
    }
    if (!opts.dotDir.empty()) {
        std::unordered_map<int, std::vector<int>> cfgEdges;
        std::unordered_map<int, std::vector<int>> cdgEdges;
        for (const auto& kv : cfg.nodes) {
            cfgEdges.emplace(kv.first, kv.second.succs);
            cdgEdges.emplace(kv.first, kv.second.ctrlSuccs);
        }
        std::string base = opts.dotDir;
        if (!base.empty() && base.back() != '/') {
            base.push_back('/');
        }
        writeDotGraph(base + "cfg.before.dot", cfg.nodes, cfgEdges, nullptr, "CFG_BEFORE");
        writeDotGraph(base + "cdg.before.dot", cfg.nodes, cdgEdges, nullptr, "CDG_BEFORE");
        writeDotGraph(base + "ddg.before.dot", cfg.nodes, dataPreds, nullptr, "DDG_BEFORE");
    }

    // Backward slice.
    std::unordered_map<std::string, std::vector<VarKey>> seedsByBase;
    for (const auto& v : seedVars) {
        seedsByBase[v.base].push_back(v);
    }
    std::unordered_map<std::string, std::vector<VarKey>> defsByBase;
    for (const auto& kv : allDefs1) {
        defsByBase[kv.first.base].push_back(kv.first);
    }
    std::unordered_map<std::string, std::vector<VarKey>> seedsNoDefByBase;
    for (const auto& kv : seedsByBase) {
        const auto& base = kv.first;
        const auto& seeds = kv.second;
        const auto& defs = defsByBase[base];
        for (const auto& seed : seeds) {
            bool hasDef = false;
            for (const auto& def : defs) {
                if (varKeyIsPrefix(def, seed)) {
                    hasDef = true;
                    break;
                }
            }
            if (!hasDef) {
                seedsNoDefByBase[base].push_back(seed);
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] seeds without defs=" << seedsNoDefByBase.size() << "\n";
        for (const auto& kv : seedsNoDefByBase) {
            for (const auto& seed : kv.second) {
                std::cerr << "  [slicer] seed_no_def " << varKeyToString(seed) << "\n";
            }
        }
    }

    std::unordered_set<int> work;
    for (auto& kv : cfg.nodes) {
        int id = kv.first;
        auto& node = kv.second;
        bool isSeed = false;
        for (auto& d : node.defs) {
            auto it = seedsByBase.find(d.base);
            if (it == seedsByBase.end()) {
                continue;
            }
            for (const auto& seed : it->second) {
                if (varKeyIsPrefix(d, seed)) {
                    isSeed = true;
                    break;
                }
            }
            if (isSeed) {
                break;
            }
        }
        if (!isSeed) {
            for (auto& u : node.uses) {
                auto it = seedsNoDefByBase.find(u.base);
                if (it == seedsNoDefByBase.end()) {
                    continue;
                }
                for (const auto& seed : it->second) {
                    if (u == seed) {
                        isSeed = true;
                        break;
                    }
                }
                if (isSeed) {
                    break;
                }
            }
        }
        if (isSeed) {
            work.insert(id);
        }
    }
    bool hasTargetRegisterWriteSeed = false;
    for (int id : work) {
        auto it = cfg.nodes.find(id);
        if (it != cfg.nodes.end() && keepNodeIsTargetRegisterWrite(it->second)) {
            hasTargetRegisterWriteSeed = true;
            break;
        }
    }
    if (hasTargetRegisterWriteSeed) {
        std::unordered_set<int> targetWork;
        for (int id : work) {
            auto it = cfg.nodes.find(id);
            if (it == cfg.nodes.end()) {
                continue;
            }
            if (keepNodeIsTargetRegisterWrite(it->second) ||
                keepNodeDefinesExplicitSeed(it->second)) {
                targetWork.insert(id);
            }
        }
        if (!targetWork.empty()) {
            if (opts.debug) {
                std::cerr << "[slicer] target-register-write seeds=" << targetWork.size() << "\n";
            }
            work = std::move(targetWork);
        }
    }

    std::deque<int> dq;
    for (int id : work) {
        dq.push_back(id);
    }

    std::unordered_set<int> keepNodes = work;
    while (!dq.empty()) {
        int cur = dq.front();
        dq.pop_front();
        auto it = dataPreds.find(cur);
        if (it != dataPreds.end()) {
            for (int pred : it->second) {
                if (!keepNodes.count(pred)) {
                    keepNodes.insert(pred);
                    dq.push_back(pred);
                }
            }
        }
        for (int pred : cfg.nodes[cur].ctrlPreds) {
            if (!keepNodes.count(pred)) {
                keepNodes.insert(pred);
                dq.push_back(pred);
            }
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] backward slice done\n";
    }
    if (!opts.dotDir.empty()) {
        std::unordered_map<int, std::vector<int>> cfgEdges;
        std::unordered_map<int, std::vector<int>> cdgEdges;
        for (const auto& kv : cfg.nodes) {
            cfgEdges.emplace(kv.first, kv.second.succs);
            cdgEdges.emplace(kv.first, kv.second.ctrlSuccs);
        }
        std::string base = opts.dotDir;
        if (!base.empty() && base.back() != '/') {
            base.push_back('/');
        }
        writeDotGraph(base + "cfg.after.dot", cfg.nodes, cfgEdges, &keepNodes, "CFG_AFTER");
        writeDotGraph(base + "cdg.after.dot", cfg.nodes, cdgEdges, &keepNodes, "CDG_AFTER");
        writeDotGraph(base + "ddg.after.dot", cfg.nodes, dataPreds, &keepNodes, "DDG_AFTER");
    }

    // Keep action bodies referenced by kept calls.
    std::unordered_set<int> extraKeep;
    std::unordered_set<cstring> keepRegActions;
    auto recordApplyCallee = [&](const cstring& callee) {
        auto tit = collector.tables.find(callee);
        if (tit != collector.tables.end()) {
            cstring tableName = tit->second->controlPlaneName();
            if (tableName.isNullOrEmpty()) {
                tableName = callee;
            }
            keepTables.insert(tableName);
            if (auto al = tit->second->getActionList()) {
                for (auto a : al->actionList) {
                    if (!a) {
                        continue;
                    }
                    auto path = a->getPath();
                    if (!path) {
                        continue;
                    }
                    if (!actionAllowed(tableName, path->name)) {
                        continue;
                    }
                    keepActions.insert(path->name);
                }
            }
            if (auto defAct = tit->second->getDefaultAction()) {
                if (auto pe = defAct->to<IR::PathExpression>()) {
                    if (actionAllowed(tableName, pe->path->name)) {
                        keepActions.insert(pe->path->name);
                    }
                } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                    if (auto mpe = mce->method->to<IR::PathExpression>()) {
                        if (actionAllowed(tableName, mpe->path->name)) {
                            keepActions.insert(mpe->path->name);
                        }
                    }
                }
            }
            return;
        }
        auto rit = regActionStmtIds.find(callee);
        if (rit != regActionStmtIds.end()) {
            extraKeep.insert(rit->second.begin(), rit->second.end());
            keepRegActions.insert(callee);
        }
    };
    auto recordExprCallees = [&](const IR::Expression* expr) {
        std::unordered_set<cstring> callees;
        collectApplyCalleesFromExpr(expr, callees, refMap);
        for (const auto& c : callees) {
            recordApplyCallee(c);
        }
    };
    for (auto& kv : cfg.nodes) {
        int id = kv.first;
        if (!keepNodes.count(id)) {
            continue;
        }
        auto* stmt = kv.second.stmt;
        if (!stmt) {
            continue;
        }
        if (auto ifs = stmt->to<IR::IfStatement>()) {
            recordExprCallees(ifs->condition);
        } else if (auto sw = stmt->to<IR::SwitchStatement>()) {
            recordExprCallees(sw->expression);
        } else if (auto as = stmt->to<IR::AssignmentStatement>()) {
            recordExprCallees(as->right);
        }
        if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
            auto expr = mcs->methodCall;
            if (!expr || !expr->method) {
                continue;
            }
            if (auto member = expr->method->to<IR::Member>()) {
                if (member->member == "apply" ||
                    member->member == "execute" ||
                    member->member == "execute_log") {
                    if (auto base = member->expr->to<IR::PathExpression>()) {
                        recordApplyCallee(resolvePathName(base, refMap));
                    }
                }
            } else if (auto pe = expr->method->to<IR::PathExpression>()) {
                keepActions.insert(resolvePathName(pe, refMap));
            }
	        }
	    }

    std::unordered_map<cstring, std::unordered_set<int>> actionSliceStmtIds;
    std::unordered_set<cstring> slicedActions;
    // Slicing action bodies needs an inter-action fixpoint: action A may compute
    // a variable used by action B, and B may be the one that (transitively)
    // defines seed variables. A naive "union all uses of kept call-sites"
    // over-approximates and can keep unrelated stateful logic (e.g., Netchain's
    // value_reg even when slicing for seq_reg only).
    //
    // We seed action slicing with:
    // - user/property seeds, and
    // - uses from kept *non-call* control statements (conditions/assignments),
    // - match-key uses of kept tables (affects action selection).
    //
    // Then we close under "needed inputs for relevant action outputs" by
    // iterating sliceActionStmt until the relevant set stabilizes.
    std::set<VarKey, VarKeyLess> actionRelevant = seedVars;
    for (const auto& kv : cfg.nodes) {
        if (!keepNodes.count(kv.first)) {
            continue;
        }
        const auto* stmt = kv.second.stmt;
        if (stmt && stmt->is<IR::MethodCallStatement>()) {
            // Direct action calls can define values that are used by later
            // kept statements, including dynamic register indices. Seed those
            // definitions into the action-body slicer; otherwise the call is
            // kept but the producer statement inside the action can still be
            // removed.
            if (auto mcs = stmt->to<IR::MethodCallStatement>()) {
                auto expr = mcs->methodCall;
                if (expr && expr->method && expr->method->is<IR::PathExpression>()) {
                    mergeVarSets(actionRelevant, kv.second.defs);
                }
            }
            continue;
        }
        mergeVarSets(actionRelevant, kv.second.uses);
    }
    for (const auto& t : keepTables) {
        bool fixedDefault = false;
        if (opts.bmv2Analyzer) {
            auto it = tableCp.find(t);
            if (it != tableCp.end()) {
                fixedDefault = it->second.fixedDefault;
            }
        }
        if (fixedDefault) {
            continue;
        }
        auto tit = collector.tables.find(t);
        if (tit == collector.tables.end()) {
            continue;
        }
        if (auto key = tit->second->getKey()) {
            for (auto ke : key->keyElements) {
                if (ke && ke->expression) {
                    std::set<VarKey, VarKeyLess> keyUses;
                    collectExprKeys(ke->expression, keyUses, typeMap);
                    mergeVarSets(actionRelevant, keyUses);
                }
            }
        }
    }

    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto& act : keepActions) {
            auto ait = collector.actions.find(act);
            if (ait == collector.actions.end()) {
                continue;
            }
            auto uit = actionUsesDefs.find(act);
            if (uit == actionUsesDefs.end()) {
                continue;
            }
            std::set<VarKey, VarKeyLess> actionSeeds;
            for (const auto& v : uit->second.defs) {
                if (actionRelevant.count(v)) {
                    insertVarKey(actionSeeds, v);
                }
            }
            slicedActions.insert(act);
            std::unordered_set<int> keepIds;
            std::set<VarKey, VarKeyLess> needed = actionSeeds;
            sliceActionStmt(ait->second->body, needed, keepIds, typeMap, &regActionUsesDefs, refMap);
            actionSliceStmtIds[act] = std::move(keepIds);

            size_t before = actionRelevant.size();
            mergeVarSets(actionRelevant, needed);
            if (actionRelevant.size() != before) {
                changed = true;
            }
        }
    }
    for (const auto& act : keepActions) {
        auto sit = actionSliceStmtIds.find(act);
        if (sit != actionSliceStmtIds.end()) {
            extraKeep.insert(sit->second.begin(), sit->second.end());
            continue;
        }
        if (slicedActions.count(act)) {
            continue;
        }
        auto ait = actionStmtIds.find(act);
        if (ait != actionStmtIds.end()) {
            extraKeep.insert(ait->second.begin(), ait->second.end());
        }
    }

    if (!opts.dotDir.empty() && !keepActions.empty()) {
        std::string base = opts.dotDir;
        if (!base.empty() && base.back() != '/') {
            base.push_back('/');
        }
        std::string actionDir = base + "actions";
        mkdir(actionDir.c_str(), 0755);
        actionDir.push_back('/');
        for (const auto& act : keepActions) {
            auto ait = collector.actions.find(act);
            if (ait == collector.actions.end()) {
                continue;
            }
            CFGBuilder actCfg(refMap, typeMap);
            CFGFragment frag = actCfg.buildStatement(ait->second->body);
            if (frag.entry == -1) {
                continue;
            }
            actCfg.roots.push_back(frag.entry);
            actCfg.exits.push_back(frag.exit);
            for (auto& kv : actCfg.nodes) {
                fillNodeUsesDefs(kv.second,
                                 typeMap,
                                 tableUsesDefs,
                                 actionUsesDefs,
                                 regActionUsesDefs,
                                 nullptr,
                                 false,
                                 nullptr,
                                 nullptr,
                                 refMap);
            }
            auto dataPreds = buildDataPredsNoRecirc(actCfg.nodes);
            std::unordered_map<int, std::vector<int>> cfgEdges;
            std::unordered_map<int, std::vector<int>> cdgEdges;
            for (const auto& kv : actCfg.nodes) {
                cfgEdges.emplace(kv.first, kv.second.succs);
                cdgEdges.emplace(kv.first, kv.second.ctrlSuccs);
            }
            std::string actName = dotSafeName(act.c_str());
            std::string actPrefix = actionDir + actName;
            writeDotGraph(actPrefix + ".cfg.before.dot", actCfg.nodes, cfgEdges, nullptr, "CFG_BEFORE");
            writeDotGraph(actPrefix + ".cdg.before.dot", actCfg.nodes, cdgEdges, nullptr, "CDG_BEFORE");
            writeDotGraph(actPrefix + ".ddg.before.dot", actCfg.nodes, dataPreds, nullptr, "DDG_BEFORE");
            const std::unordered_set<int>* keep = nullptr;
            auto sit = actionSliceStmtIds.find(act);
            if (sit != actionSliceStmtIds.end()) {
                keep = &sit->second;
            }
            writeDotGraph(actPrefix + ".cfg.after.dot", actCfg.nodes, cfgEdges, keep, "CFG_AFTER");
            writeDotGraph(actPrefix + ".cdg.after.dot", actCfg.nodes, cdgEdges, keep, "CDG_AFTER");
            writeDotGraph(actPrefix + ".ddg.after.dot", actCfg.nodes, dataPreds, keep, "DDG_AFTER");
        }
    }

    if (!keepActions.empty() && !regActionStmtIds.empty()) {
        class RegActionCallCollector : public Inspector {
         public:
            const std::unordered_map<cstring, std::unordered_set<int>>& regActionStmtIds;
            std::unordered_set<cstring>& keepRegActions;
            std::unordered_set<int>& extraKeep;
            P4::ReferenceMap* refMap;

            RegActionCallCollector(
                const std::unordered_map<cstring, std::unordered_set<int>>& regActionStmtIds,
                std::unordered_set<cstring>& keepRegActions,
                std::unordered_set<int>& extraKeep,
                P4::ReferenceMap* refMap)
                : regActionStmtIds(regActionStmtIds),
                  keepRegActions(keepRegActions),
                  extraKeep(extraKeep),
                  refMap(refMap) {}

            bool preorder(const IR::MethodCallExpression* mce) override {
                cstring name;
                if (!regActionCallName(mce, name, refMap)) {
                    return false;
                }
                auto it = regActionStmtIds.find(name);
                if (it == regActionStmtIds.end()) {
                    return false;
                }
                keepRegActions.insert(name);
                extraKeep.insert(it->second.begin(), it->second.end());
                return false;
            }
        };

        RegActionCallCollector regCollector(regActionStmtIds, keepRegActions, extraKeep, refMap);
        for (const auto& name : keepActions) {
            auto ait = collector.actions.find(name);
            if (ait == collector.actions.end()) {
                continue;
            }
            if (ait->second && ait->second->body) {
                ait->second->body->apply(regCollector);
            }
        }
    }
    keepStmtIds.insert(extraKeep.begin(), extraKeep.end());

    std::set<VarKey, VarKeyLess> parserSeedVars = seedVars;
    for (const auto& kv : cfg.nodes) {
        if (!keepNodes.count(kv.first)) {
            continue;
        }
        for (const auto& v : kv.second.uses) {
            addVarKey(parserSeedVars, v);
        }
        for (const auto& v : kv.second.defs) {
            addVarKey(parserSeedVars, v);
        }
    }
    for (const auto& t : keepTables) {
        auto tit = tableUsesDefs.find(t);
        if (tit == tableUsesDefs.end()) {
            continue;
        }
        for (const auto& v : tit->second.uses) {
            addVarKey(parserSeedVars, v);
        }
        for (const auto& v : tit->second.defs) {
            addVarKey(parserSeedVars, v);
        }
    }
    // Keep parser statements along paths that can reach seed-relevant headers.
    for (auto obj : program->objects) {
        auto parser = obj->to<IR::P4Parser>();
        if (!parser) {
            continue;
        }

        std::unordered_map<cstring, const IR::ParserState*> states;
        for (auto st : parser->states) {
            if (st) {
                states.emplace(st->name.name, st);
            }
        }
        if (states.empty()) {
            continue;
        }

        auto collectSelectUses = [&](const IR::Expression* sel, std::set<VarKey, VarKeyLess>& out) {
            if (!sel) {
                return;
            }
            if (auto pe = sel->to<IR::PathExpression>()) {
                VarKey key;
                key.base = pe->path->toString();
                addVarKey(out, key);
                return;
            }
            if (auto se = sel->to<IR::SelectExpression>()) {
                collectExprKeys(se->select, out, typeMap);
                return;
            }
            collectExprKeys(sel, out, typeMap);
        };

        std::unordered_map<cstring, std::vector<cstring>> succ;
        for (auto& kv : states) {
            auto st = kv.second;
            if (!st || !st->selectExpression) {
                continue;
            }
            if (auto pe = st->selectExpression->to<IR::PathExpression>()) {
                succ[kv.first].push_back(pe->path->name);
            } else if (auto se = st->selectExpression->to<IR::SelectExpression>()) {
                for (auto sc : se->selectCases) {
                    if (sc && sc->state) {
                        succ[kv.first].push_back(sc->state->path->name);
                    }
                }
            }
        }

        // Parser slicing is tricky: pruning only the parser statements (e.g., packet.extract)
        // while leaving the parser state machine structure intact can make header fields
        // unconstrained yet still used in select expressions, leading to ill-typed Boogie
        // and (worse) spurious behaviors. To keep the sliced model sound for bug-finding,
        // we conservatively keep all parser states that are reachable from the start state.
        std::unordered_set<cstring> keepStates;
        if (states.count("start")) {
            std::deque<cstring> todo;
            keepStates.insert("start");
            todo.push_back("start");
            while (!todo.empty()) {
                auto cur = todo.front();
                todo.pop_front();
                auto it = succ.find(cur);
                if (it == succ.end()) {
                    continue;
                }
                for (auto s : it->second) {
                    if (states.count(s) == 0) {
                        continue;
                    }
                    if (!keepStates.count(s)) {
                        keepStates.insert(s);
                        todo.push_back(s);
                    }
                }
            }
        } else {
            // Fallback: if no explicit start state exists, keep all parser states.
            for (const auto& kv : states) {
                keepStates.insert(kv.first);
            }
        }

        for (auto s : keepStates) {
            auto it = states.find(s);
            if (it == states.end()) {
                continue;
            }
            auto st = it->second;
            if (!st) {
                continue;
            }
            if (st->selectExpression) {
                collectSelectUses(st->selectExpression, parserVars);
            }
            for (auto comp : st->components) {
                auto stmt = comp->to<IR::Statement>();
                if (!stmt) {
                    continue;
                }
                collectStmtIds(stmt, keepStmtIds);
            }
        }
    }

    // Only keep real statements.
    for (auto& kv : cfg.nodes) {
        if (keepNodes.count(kv.first) && kv.second.stmt) {
            keepStmtIds.insert(kv.second.stmt->id);
        }
    }

    // Keep RegisterAction apply bodies only when referenced by kept calls.
    if (!keepRegActions.empty()) {
        for (const auto& name : keepRegActions) {
            auto it = regActionStmtIds.find(name);
            if (it != regActionStmtIds.end()) {
                keepStmtIds.insert(it->second.begin(), it->second.end());
            }
        }
    }
        if (iter > 0 && keepStmtIds == prevKeepStmtIds) {
            if (opts.debug) {
                std::cerr << "[slicer] fixpoint reached after " << (iter + 1) << " iterations\n";
            }
            break;
        }
        prevKeepStmtIds = keepStmtIds;

        if (iter + 1 < kFixpointMaxIterations) {
            // Recompute action summaries from the sliced IR to avoid summary pollution
            // (e.g., unrelated vars kept only because they appear in an unsliced action).
            const IR::P4Program* slicedForSummary = applySlice(program, keepStmtIds, refMap, nullptr, true);
            ActionTableCollector summaryCollector;
            slicedForSummary->apply(summaryCollector);

            std::unordered_map<cstring, UsesDefs> nextRegActionUsesDefs;
            for (const auto& kv : summaryCollector.regActions) {
                const IR::Declaration_Instance* inst = kv.second;
                const IR::Function* applyFunc = findRegisterActionApply(inst);
	                if (!applyFunc || !applyFunc->body) {
	                    continue;
	                }
	                UsesDefs ud;
	                collectStmtUsesDefs(applyFunc->body, ud, typeMap, nullptr, refMap);
                if (inst && inst->arguments && inst->arguments->size() > 0) {
                    if (auto arg0 = (*inst->arguments)[0]) {
                        if (arg0->expression) {
                            collectExprKeys(arg0->expression, ud.uses, typeMap);
                            collectExprKeys(arg0->expression, ud.defs, typeMap);
                        }
                    }
                }
                nextRegActionUsesDefs.emplace(kv.first, std::move(ud));
            }

	            std::unordered_map<cstring, UsesDefs> nextActionUsesDefs;
	            for (const auto& kv : summaryCollector.actions) {
	                UsesDefs ud;
	                collectStmtUsesDefs(kv.second->body, ud, typeMap, &nextRegActionUsesDefs, refMap);
	                nextActionUsesDefs.emplace(kv.first, std::move(ud));
	            }

            regActionUsesDefs = std::move(nextRegActionUsesDefs);
            actionUsesDefs = std::move(nextActionUsesDefs);
        }
    }

    result.keepStatementIds.insert(keepStmtIds.begin(), keepStmtIds.end());

    result.filterTables = true;

    std::unordered_set<std::string> forcedKeepNames;
    // Collect kept variables from kept statements and seeds.
    const IR::P4Program* slicedForVars = applySlice(program, keepStmtIds, refMap, nullptr, true);
    AllVarCollector varCollector(typeMap);
    slicedForVars->apply(varCollector);

    ActionTableCollector slicedCollector;
    slicedForVars->apply(slicedCollector);
    std::unordered_map<cstring, UsesDefs> slicedActionUsesDefs;
    std::unordered_map<cstring, UsesDefs> slicedTableUsesDefs;
    std::unordered_map<cstring, UsesDefs> slicedRegActionUsesDefs;
    for (const auto& kv : slicedCollector.regActions) {
        const IR::Declaration_Instance* inst = kv.second;
        const IR::Function* applyFunc = findRegisterActionApply(inst);
	        if (!applyFunc || !applyFunc->body) {
	            continue;
	        }
	        UsesDefs ud;
	        collectStmtUsesDefs(applyFunc->body, ud, typeMap, nullptr, refMap);
        if (inst && inst->arguments && inst->arguments->size() > 0) {
            if (auto arg0 = (*inst->arguments)[0]) {
                if (arg0->expression) {
                    collectExprKeys(arg0->expression, ud.uses, typeMap);
                    collectExprKeys(arg0->expression, ud.defs, typeMap);
                }
            }
        }
        slicedRegActionUsesDefs.emplace(kv.first, std::move(ud));
    }
	    for (const auto& kv : slicedCollector.actions) {
	        UsesDefs ud;
	        collectStmtUsesDefs(kv.second->body, ud, typeMap, &slicedRegActionUsesDefs, refMap);
	        slicedActionUsesDefs.emplace(kv.first, std::move(ud));
	    }
    for (const auto& kv : slicedCollector.tables) {
        const IR::P4Table* table = kv.second;
        UsesDefs ud;
        VarKey actionRun;
        actionRun.base = kv.first.c_str();
        actionRun.segs.push_back("action_run");
        addVarKey(ud.defs, actionRun);
        if (auto key = table->getKey()) {
            for (auto ke : key->keyElements) {
                if (ke && ke->expression) {
                    collectExprKeys(ke->expression, ud.uses, typeMap);
                }
            }
        }
        if (auto al = table->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (!path) {
                    continue;
                }
                auto it = slicedActionUsesDefs.find(path->name);
                if (it != slicedActionUsesDefs.end()) {
                    mergeSets(ud.uses, it->second.uses);
                    mergeSets(ud.defs, it->second.defs);
                }
            }
        }
        if (auto defAct = table->getDefaultAction()) {
            if (auto pe = defAct->to<IR::PathExpression>()) {
                auto it = slicedActionUsesDefs.find(pe->path->name);
                if (it != slicedActionUsesDefs.end()) {
                    mergeSets(ud.uses, it->second.uses);
                    mergeSets(ud.defs, it->second.defs);
                }
            } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto m = mce->method->to<IR::PathExpression>()) {
                    auto it = slicedActionUsesDefs.find(m->path->name);
                    if (it != slicedActionUsesDefs.end()) {
                        mergeSets(ud.uses, it->second.uses);
                        mergeSets(ud.defs, it->second.defs);
                    }
                }
            }
        }
        slicedTableUsesDefs.emplace(kv.first, std::move(ud));
    }
    if (opts.debug) {
        std::cerr << "[slicer] register declarations=" << regDeclCollector.regs.size() << "\n";
        for (const auto& r : regDeclCollector.regs) {
            std::cerr << "  [slicer] decl " << r << "\n";
        }
    }
    auto normalizeRegName = [&](const std::string& name) -> std::string {
        if (regDeclCollector.regs.count(name)) {
            return name;
        }
        auto ctrlIt = regDeclCollector.controlToInternal.find(name);
        if (ctrlIt != regDeclCollector.controlToInternal.end() && !ctrlIt->second.empty()) {
            return ctrlIt->second;
        }
        std::string withSuffix = name + "_0";
        if (regDeclCollector.regs.count(withSuffix)) {
            return withSuffix;
        }
        return name;
    };

    RegisterUseCollector regUseCollector(refMap);
    slicedForVars->apply(regUseCollector);
    if (opts.debug) {
        std::cerr << "[slicer] registers in kept slice=" << regUseCollector.regs.size() << "\n";
        for (const auto& r : regUseCollector.regs) {
            std::cerr << "  [slicer] reg " << r << "\n";
        }
    }
    for (const auto& r : regUseCollector.regs) {
        VarKey key;
        key.base = normalizeRegName(r);
        addVarKey(varCollector.vars, key);
    }
    for (const auto& v : seedVars) {
        addVarKey(varCollector.vars, v);
    }
    for (const auto& act : keepActions) {
        auto it = slicedActionUsesDefs.find(act);
        if (it == slicedActionUsesDefs.end()) {
            continue;
        }
        for (const auto& v : it->second.uses) {
            addVarKey(varCollector.vars, v);
        }
        for (const auto& v : it->second.defs) {
            addVarKey(varCollector.vars, v);
        }
    }
    for (const auto& tableName : keepTables) {
        auto tit = slicedCollector.tables.find(tableName);
        if (tit == slicedCollector.tables.end()) {
            continue;
        }
        VarKey actionRun;
        actionRun.base = tableName.c_str();
        actionRun.segs.push_back("action_run");
        addVarKey(varCollector.vars, actionRun);
        if (auto al = tit->second->getActionList()) {
            for (auto a : al->actionList) {
                if (!a) {
                    continue;
                }
                auto path = a->getPath();
                if (!path) {
                    continue;
                }
                auto ait = slicedCollector.actions.find(path->name);
                if (ait == slicedCollector.actions.end()) {
                    continue;
                }
                for (auto p : ait->second->parameters->parameters) {
                    if (!p) {
                        continue;
                    }
                    std::string name = tableName.c_str();
                    name += ".";
                    name += path->name.toString();
                    name += ".";
                    name += p->name.toString();
                    VarKey key;
                    if (parseVarKeyFromString(name, key)) {
                        addVarKey(varCollector.vars, key);
                    }
                    forcedKeepNames.insert(name);
                }
            }
        }
        if (auto defAct = tit->second->getDefaultAction()) {
            if (auto pe = defAct->to<IR::PathExpression>()) {
                auto ait = slicedCollector.actions.find(pe->path->name);
                if (ait != slicedCollector.actions.end()) {
                    for (auto p : ait->second->parameters->parameters) {
                        if (!p) {
                            continue;
                        }
                        std::string name = tableName.c_str();
                        name += ".";
                        name += pe->path->name.toString();
                        name += ".";
                        name += p->name.toString();
                        VarKey key;
                        if (parseVarKeyFromString(name, key)) {
                            addVarKey(varCollector.vars, key);
                        }
                    }
                }
            } else if (auto mce = defAct->to<IR::MethodCallExpression>()) {
                if (auto mpe = mce->method->to<IR::PathExpression>()) {
                    auto ait = slicedCollector.actions.find(mpe->path->name);
                    if (ait != slicedCollector.actions.end()) {
                        for (auto p : ait->second->parameters->parameters) {
                            if (!p) {
                                continue;
                            }
                            std::string name = tableName.c_str();
                            name += ".";
                            name += mpe->path->name.toString();
                            name += ".";
                            name += p->name.toString();
                            VarKey key;
                            if (parseVarKeyFromString(name, key)) {
                                addVarKey(varCollector.vars, key);
                            }
                            forcedKeepNames.insert(name);
                        }
                    }
                }
            }
        }
        auto uit = slicedTableUsesDefs.find(tableName);
        if (uit != slicedTableUsesDefs.end()) {
            for (const auto& v : uit->second.uses) {
                addVarKey(varCollector.vars, v);
            }
            for (const auto& v : uit->second.defs) {
                addVarKey(varCollector.vars, v);
            }
        }
    }
    for (const auto& v : varCollector.vars) {
        result.keepVarNames.insert(cstring(varKeyToString(v)));
    }
    for (const auto& v : parserVars) {
        result.keepVarNames.insert(cstring(varKeyToString(v)));
    }
    for (const auto& name : forcedKeepNames) {
        result.keepVarNames.insert(cstring(name));
    }
    // For registers, also keep the sanitized control-plane alias used by the Boogie translator.
    // This allows system-level tools (e.g., dslc) to seed slicing using Boogie-level names.
    for (const auto& kv : regDeclCollector.internalToControl) {
        if (result.keepVarNames.count(cstring(kv.first.c_str())) > 0) {
            result.keepVarNames.insert(cstring(kv.second.c_str()));
        }
    }
    for (const auto& t : keepTables) {
        result.keepTables.insert(t);
    }
    if (opts.debug) {
        std::cerr << "[slicer] keep vars=" << result.keepVarNames.size() << "\n";
        for (const auto& v : result.keepVarNames) {
            std::cerr << "  [slicer] var " << v << "\n";
        }
        std::cerr << "[slicer] keep tables=" << result.keepTables.size() << "\n";
        for (const auto& t : result.keepTables) {
            std::cerr << "  [slicer] table " << t << "\n";
        }
    }

    RegisterIndexCollector regCollector(result.keepStatementIds, &regDeclCollector.regs,
                                        &regActionRegs, refMap);
    program->apply(regCollector);
    std::map<std::string, int> effectiveRegMaxIndex;
    for (const auto& kv : regCollector.maxIndex) {
        std::string norm = normalizeRegName(kv.first);
        auto it = effectiveRegMaxIndex.find(norm);
        if (it == effectiveRegMaxIndex.end() || kv.second > it->second) {
            effectiveRegMaxIndex[norm] = kv.second;
        }
    }
    for (const auto& kv : seedRegMaxIndex) {
        std::string norm = normalizeRegName(kv.first);
        auto it = effectiveRegMaxIndex.find(norm);
        if (it == effectiveRegMaxIndex.end() || kv.second > it->second) {
            effectiveRegMaxIndex[norm] = kv.second;
        }
    }
    std::map<std::string, int> boundedIndexExprs;
    for (const auto& kv : regCollector.indexExprKeys) {
        std::string norm = normalizeRegName(kv.first);
        auto maxIt = effectiveRegMaxIndex.find(norm);
        if (maxIt == effectiveRegMaxIndex.end()) {
            continue;
        }
        for (const auto& exprKey : kv.second) {
            auto it = boundedIndexExprs.find(exprKey);
            if (it == boundedIndexExprs.end() || maxIt->second > it->second) {
                boundedIndexExprs[exprKey] = maxIt->second;
            }
        }
    }
    for (const auto& kv : regCollector.indexExprKeys) {
        std::string norm = normalizeRegName(kv.first);
        if (regCollector.hasUnkeyedNonConst.count(kv.first) > 0 ||
            regCollector.hasUnkeyedNonConst.count(norm) > 0) {
            continue;
        }
        int inferredMax = -1;
        bool allBounded = !kv.second.empty();
        for (const auto& exprKey : kv.second) {
            auto it = boundedIndexExprs.find(exprKey);
            if (it == boundedIndexExprs.end()) {
                allBounded = false;
                break;
            }
            if (it->second > inferredMax) {
                inferredMax = it->second;
            }
        }
        if (allBounded && inferredMax >= 0) {
            auto maxIt = effectiveRegMaxIndex.find(norm);
            if (maxIt == effectiveRegMaxIndex.end() || inferredMax > maxIt->second) {
                effectiveRegMaxIndex[norm] = inferredMax;
            }
        }
    }
    auto insertRegMaxIndexAliases = [&](const std::string& norm, int maxIdx) {
        result.regMaxIndex[cstring(norm)] = maxIdx;
        auto ctrlIt = regDeclCollector.internalToControl.find(norm);
        if (ctrlIt != regDeclCollector.internalToControl.end() && !ctrlIt->second.empty()) {
            result.regMaxIndex[cstring(ctrlIt->second)] = maxIdx;
        }
    };
    for (const auto& kv : effectiveRegMaxIndex) {
        insertRegMaxIndexAliases(kv.first, kv.second);
    }
    auto nonConstIndexesFullyBounded = [&](const std::string& rawName) -> bool {
        std::string norm = normalizeRegName(rawName);
        if (regCollector.hasUnkeyedNonConst.count(rawName) > 0 ||
            regCollector.hasUnkeyedNonConst.count(norm) > 0) {
            return false;
        }
        auto it = regCollector.indexExprKeys.find(rawName);
        if (it == regCollector.indexExprKeys.end()) {
            it = regCollector.indexExprKeys.find(norm);
        }
        if (it == regCollector.indexExprKeys.end()) {
            return true;
        }
        if (it->second.empty()) {
            return false;
        }
        for (const auto& exprKey : it->second) {
            if (boundedIndexExprs.find(exprKey) == boundedIndexExprs.end()) {
                return false;
            }
        }
        return true;
    };
    for (const auto& r : regCollector.hasNonConst) {
        std::string norm = normalizeRegName(r);
        if (effectiveRegMaxIndex.find(norm) == effectiveRegMaxIndex.end() ||
            !nonConstIndexesFullyBounded(r)) {
            result.regHasNonConst.insert(cstring(norm));
        }
    }
    if (opts.debug) {
        std::cerr << "[slicer] keep statements=" << result.keepStatementIds.size() << "\n";
    }
    return result;
}

}  // namespace P4Verify
