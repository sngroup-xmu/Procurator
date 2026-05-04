// Register declaration collection shared by slicing analysis and slice application.
#ifndef BACKENDS_VERIFY_SLICING_COLLECTORS_REGISTER_DECL_H_
#define BACKENDS_VERIFY_SLICING_COLLECTORS_REGISTER_DECL_H_

#include <set>
#include <string>
#include <unordered_map>

#include "backends/verify/verify_compat.h"

namespace P4Verify {
namespace slicing_internal {

class RegisterDeclCollector : public Inspector {
 public:
    std::set<std::string> regs;
    // Map from sanitized control-plane name (Boogie-level) to IR instance name.
    // Empty value means ambiguous (multiple instances share the same sanitized name).
    std::unordered_map<std::string, std::string> controlToInternal;
    // Inverse map: IR instance name -> sanitized control-plane name.
    std::unordered_map<std::string, std::string> internalToControl;

    bool preorder(const IR::Declaration_Instance* inst) override;

 private:
    static std::string sanitizeDeclName(const std::string& raw);
    static bool lookupExternName(const IR::Type* type, std::string& out);
};

}  // namespace slicing_internal
}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_SLICING_COLLECTORS_REGISTER_DECL_H_
