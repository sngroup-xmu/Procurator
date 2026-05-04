#ifndef BACKENDS_VERIFY_VERIFY_COMPAT_H_
#define BACKENDS_VERIFY_VERIFY_COMPAT_H_

#include <filesystem>

#include "frontends/common/options.h"
#include "frontends/common/parser_options.h"
#include "ir/ir.h"
#include "ir/visitor.h"
#include "lib/compile_context.h"
#include "lib/crash.h"
#include "lib/error_catalog.h"
#include "lib/big_int.h"
#include "lib/cstring.h"
#include "lib/error.h"
#include "lib/nullstream.h"

using P4::big_int;
using P4::CompilerOptions;
using P4::cstring;
using P4::error;
using P4::errorCount;
using P4::ErrorType;
using P4::Inspector;
using P4::openFile;
using P4::P4CContextWithOptions;
using P4::PassManager;
using P4::Transform;
using P4::setup_signals;
using P4::AutoCompileContext;
namespace Util = P4::Util;

namespace IR = P4::IR;

namespace P4VerifyCompat {

inline const IR::Type_Array *asHeaderStackType(const IR::Type *type) {
    auto array = type ? type->to<IR::Type_Array>() : nullptr;
    if (array == nullptr) {
        return nullptr;
    }
    // Newer p4c frontends often leave header-stack element types as Type_Name
    // until consumers resolve them through ReferenceMap/TypeMap.  The verify
    // backend does that resolution at the call site (translator
    // resolveHeaderType, slicer TypeMap lookups), so accepting Type_Array here
    // preserves header-stack lowering without forcing this compatibility shim
    // to own name resolution.
    return array;
}

inline bool isHeaderStackType(const IR::Type *type) {
    return asHeaderStackType(type) != nullptr;
}

inline bool hasPath(const std::filesystem::path &path) {
    return !path.empty();
}

inline std::string pathToString(const std::filesystem::path &path) {
    return path.string();
}

inline cstring pathToCstring(const std::filesystem::path &path) {
    return cstring(pathToString(path).c_str());
}

}  // namespace P4VerifyCompat

#endif  // BACKENDS_VERIFY_VERIFY_COMPAT_H_
