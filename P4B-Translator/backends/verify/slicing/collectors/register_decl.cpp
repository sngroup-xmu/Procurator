#include "backends/verify/slicing/collectors/register_decl.h"

#include "lib/cstring.h"

namespace P4Verify {
namespace slicing_internal {

bool RegisterDeclCollector::preorder(const IR::Declaration_Instance* inst) {
    if (!inst || !inst->type) {
        return false;
    }
    std::string extName;
    if (!lookupExternName(inst->type, extName)) {
        return false;
    }
    std::string extLower;
    extLower.reserve(extName.size());
    for (char c : extName) {
        if (c >= 'A' && c <= 'Z') {
            extLower.push_back(static_cast<char>(c - 'A' + 'a'));
        } else {
            extLower.push_back(c);
        }
    }
    if (extLower.find("register") != std::string::npos) {
        std::string internal = inst->name.name.c_str();
        regs.insert(internal);

        cstring cp = inst->controlPlaneName();
        if (!cp.isNullOrEmpty()) {
            std::string sanitized = sanitizeDeclName(cp.c_str());
            if (!sanitized.empty()) {
                auto it = controlToInternal.find(sanitized);
                if (it == controlToInternal.end()) {
                    controlToInternal.emplace(sanitized, internal);
                    internalToControl.emplace(internal, sanitized);
                } else if (it->second != internal) {
                    // Ambiguous: keep no mapping.
                    if (!it->second.empty()) {
                        internalToControl.erase(it->second);
                    }
                    it->second.clear();
                }
            }
        }
    }
    return false;
}

std::string RegisterDeclCollector::sanitizeDeclName(const std::string& raw) {
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
}

bool RegisterDeclCollector::lookupExternName(const IR::Type* type, std::string& out) {
    if (!type) {
        return false;
    }
    if (auto ext = type->to<IR::Type_Extern>()) {
        out = ext->name.name.c_str();
        return true;
    }
    if (auto spec = type->to<IR::Type_Specialized>()) {
        return lookupExternName(spec->baseType, out);
    }
    if (auto name = type->to<IR::Type_Name>()) {
        if (name->path) {
            out = name->path->name.name.c_str();
            return true;
        }
    }
    return false;
}

}  // namespace slicing_internal
}  // namespace P4Verify
