// Frontend loading and normalization for the verify backend.
#ifndef BACKENDS_VERIFY_BPL_VERIFY_FRONTEND_H_
#define BACKENDS_VERIFY_BPL_VERIFY_FRONTEND_H_

#include "backends/verify/translate/options.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"

namespace P4Verify {

struct LoadedProgram {
    const IR::P4Program* program = nullptr;
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
};

bool loadFrontendProgram(P4VerifyOptions& options, LoadedProgram* loaded);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_BPL_VERIFY_FRONTEND_H_
