// Verify backend pipeline: slicing, analyses, Boogie lowering, and meta output.
#ifndef BACKENDS_VERIFY_BPL_VERIFY_PIPELINE_H_
#define BACKENDS_VERIFY_BPL_VERIFY_PIPELINE_H_

#include "backends/verify/translate/options.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "ir/ir.h"

namespace P4Verify {

int runVerifyBackend(const IR::P4Program* program,
                     P4::ReferenceMap* refMap,
                     P4::TypeMap* typeMap,
                     P4VerifyOptions& options,
                     double* backendCpuSeconds);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_BPL_VERIFY_PIPELINE_H_
