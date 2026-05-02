// Sliced IR pruning and declaration cleanup.
#include "slicer.h"

#include "backends/verify/slicing/collectors/register_decl.h"
#include "frontends/common/resolveReferences/referenceMap.h"

namespace P4Verify {

using namespace slicing_internal;

namespace {

bool isNoOpStatement(const IR::Statement* statement) {
    if (statement == nullptr) {
        return true;
    }
    if (statement->is<IR::EmptyStatement>()) {
        return true;
    }
    if (auto block = statement->to<IR::BlockStatement>()) {
        for (auto component : block->components) {
            auto nested = component->to<IR::Statement>();
            if (nested == nullptr || !isNoOpStatement(nested)) {
                return false;
            }
        }
        return true;
    }
    return false;
}

}  // namespace

class SlicePruner : public Transform {
 public:
    explicit SlicePruner(const std::unordered_set<int>& keepIds) : keepIds(keepIds) {
        setName("SlicePruner");
    }

    const IR::Node* postorder(IR::AssignmentStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::MethodCallStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::IfStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        if (isNoOpStatement(statement->ifTrue) && isNoOpStatement(statement->ifFalse)) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::SwitchStatement* statement) override {
        if (!shouldKeep(getOriginal())) {
            return new IR::EmptyStatement();
        }
        return statement;
    }

    const IR::Node* postorder(IR::BlockStatement* statement) override {
        return statement;
    }

 private:
    const std::unordered_set<int>& keepIds;

    bool shouldKeep(const IR::Node* original) const {
        if (!original) {
            return true;
        }
        return keepIds.count(original->id) > 0;
    }
};

class SliceRegisterDeclPruner : public Transform {
 public:
    SliceRegisterDeclPruner(const std::set<std::string>& allRegs,
                            const std::unordered_set<std::string>& keepRegs)
        : allRegs(allRegs), keepRegs(keepRegs) {
        setName("SliceRegisterDeclPruner");
    }

    const IR::Node* postorder(IR::Declaration_Instance* inst) override {
        if (!inst) {
            return inst;
        }
        std::string name = inst->name.name.c_str();
        if (allRegs.count(name) > 0 && keepRegs.count(name) == 0) {
            return nullptr;
        }
        return inst;
    }

 private:
    const std::set<std::string>& allRegs;
    const std::unordered_set<std::string>& keepRegs;
};

class SliceRegisterUseCollector : public Inspector {
 public:
    SliceRegisterUseCollector(const std::set<std::string>& regs, P4::ReferenceMap* refMap)
        : declRegs(regs), refMap(refMap) {}

    std::unordered_set<std::string> used;

    bool preorder(const IR::PathExpression* pe) override {
        if (!pe || !pe->path) {
            return false;
        }
        std::string name;
        if (refMap) {
            if (auto decl = refMap->getDeclaration(pe->path, false)) {
                name = decl->getName().name.c_str();
            }
        }
        if (name.empty()) {
            name = pe->path->name.toString().c_str();
        }
        if (declRegs.count(name) > 0) {
            used.insert(name);
            return false;
        }
        std::string withSuffix = name + "_0";
        if (declRegs.count(withSuffix) > 0) {
            used.insert(withSuffix);
            return false;
        }
        if (name.size() > 2 && name.rfind("_0") == name.size() - 2) {
            std::string trimmed = name.substr(0, name.size() - 2);
            if (declRegs.count(trimmed) > 0) {
                used.insert(trimmed);
            }
        }
        return false;
    }

 private:
    const std::set<std::string>& declRegs;
    P4::ReferenceMap* refMap;
};

const IR::P4Program* applySlice(const IR::P4Program* program,
                                const std::unordered_set<int>& keepStatementIds,
                                P4::ReferenceMap* refMap,
                                const std::unordered_set<cstring>* keepVarNames,
                                bool pruneEmptySlice) {
    if (keepStatementIds.empty() && !pruneEmptySlice) {
        return program;
    }
    SlicePruner pruner(keepStatementIds);
    const IR::P4Program* sliced = program->apply(pruner)->to<IR::P4Program>();
    if (!sliced) {
        return sliced;
    }

    // Slicing prunes statements by replacing them with EmptyStatement, but leaves
    // Register Declaration_Instance nodes intact. Those dead declarations lead to
    // large Boogie state spaces (vars + init axioms + helper procs).
    //
    // Conservatively prune register declarations that are no longer referenced by
    // any remaining method call on that register in the sliced IR.
    RegisterDeclCollector regDeclCollector;
    sliced->apply(regDeclCollector);
    if (regDeclCollector.regs.empty()) {
        return sliced;
    }

    SliceRegisterUseCollector regUseCollector(regDeclCollector.regs, refMap);
    sliced->apply(regUseCollector);

    std::unordered_set<std::string> keepRegs = std::move(regUseCollector.used);
    if (keepVarNames != nullptr) {
        for (const auto& v : *keepVarNames) {
            std::string name = v.c_str();
            if (regDeclCollector.regs.count(name) > 0) {
                keepRegs.insert(name);
                continue;
            }
            auto aliasIt = regDeclCollector.controlToInternal.find(name);
            if (aliasIt != regDeclCollector.controlToInternal.end() && !aliasIt->second.empty() &&
                regDeclCollector.regs.count(aliasIt->second) > 0) {
                keepRegs.insert(aliasIt->second);
                continue;
            }
            std::string withSuffix = name + "_0";
            if (regDeclCollector.regs.count(withSuffix) > 0) {
                keepRegs.insert(withSuffix);
                continue;
            }
            if (name.size() > 2 && name.rfind("_0") == name.size() - 2) {
                std::string trimmed = name.substr(0, name.size() - 2);
                if (regDeclCollector.regs.count(trimmed) > 0) {
                    keepRegs.insert(trimmed);
                }
            }
        }
    }
    if (keepRegs.size() >= regDeclCollector.regs.size()) {
        return sliced;
    }

    SliceRegisterDeclPruner declPruner(regDeclCollector.regs, keepRegs);
    return sliced->apply(declPruner)->to<IR::P4Program>();
}
}  // namespace P4Verify
