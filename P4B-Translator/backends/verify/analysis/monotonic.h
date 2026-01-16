#ifndef BACKENDS_VERIFY_ANALYSIS_MONOTONIC_H_
#define BACKENDS_VERIFY_ANALYSIS_MONOTONIC_H_

#include "ir/ir.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

class P4VerifyOptions;

namespace P4Verify {

// Post-slicing analysis: detect register updates that look like monotonic/affine
// counter steps (e.g., x := x + k, x := x - k) and export them into meta.
void analyzeWraparoundMonotonicity(const IR::P4Program* program,
                                   P4::ReferenceMap* refMap,
                                   P4::TypeMap* typeMap,
                                   P4VerifyOptions* options);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_ANALYSIS_MONOTONIC_H_
