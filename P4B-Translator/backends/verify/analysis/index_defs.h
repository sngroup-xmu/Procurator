#ifndef BACKENDS_VERIFY_ANALYSIS_INDEX_DEFS_H_
#define BACKENDS_VERIFY_ANALYSIS_INDEX_DEFS_H_

#include "ir/ir.h"

namespace P4 {
class ReferenceMap;
class TypeMap;
}  // namespace P4

class P4VerifyOptions;

namespace P4Verify {

// Post-slicing analysis: export deterministic P4-local definitions for metadata
// variables commonly used as register indices, e.g.
//   meta.register_index = idx_calc.get(...)
// Downstream system-level tooling can consume this structured meta instead of
// recovering the same fact from generated Boogie text.
void analyzeIndexDefinitions(const IR::P4Program* program,
                             P4::ReferenceMap* refMap,
                             P4::TypeMap* typeMap,
                             P4VerifyOptions* options);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_ANALYSIS_INDEX_DEFS_H_
