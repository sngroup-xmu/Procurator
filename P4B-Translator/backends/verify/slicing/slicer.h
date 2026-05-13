// Semantic-aware slicing for P4 IR (CFG + DDG + control dependencies).
#ifndef BACKENDS_VERIFY_SLICING_SLICER_H_
#define BACKENDS_VERIFY_SLICING_SLICER_H_

#include <map>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "frontends/common/resolveReferences/referenceMap.h"
#include "frontends/p4/typeMap.h"
#include "backends/verify/verify_compat.h"

class BMV2CmdsAnalyzer;

namespace P4Verify {

struct SliceOptions {
    std::vector<cstring> seedVars;
    bool enable = false;
    bool collectRw = false;
    // Optional control-plane context: if provided, slicing can use bmv2 CLI commands to
    // restrict table action choices / match-key relevance (e.g., fixed table_set_default).
    const BMV2CmdsAnalyzer* bmv2Analyzer = nullptr;
    // When true, treat forwarding/drop/clone/recirc control variables as implicit seeds.
    // This is a conservative default for single-program verification; system-level tools
    // (e.g., dslc) may disable it and supply the required control seeds explicitly.
    bool keepControlSeeds = true;
    bool debug = false;
    std::string dotDir;
};

struct SliceResult {
    std::unordered_set<int> keepStatementIds;
    std::unordered_set<cstring> keepVarNames;
    std::unordered_set<cstring> keepTables;
    bool filterTables = false;
    std::map<cstring, int> regMaxIndex;
    std::set<cstring> regHasNonConst;
    // Compatibility name: true means a cross-pass event was detected
    // (recirculate/resubmit/clone/mirror), not only recirculation.
    bool hasRecirculation = false;
    std::vector<cstring> rwReads;
    std::vector<cstring> rwWrites;
    std::vector<cstring> rwStatefulObjects;
};

class Slicer {
 public:
    Slicer(const IR::P4Program* program, P4::ReferenceMap* refMap, P4::TypeMap* typeMap);
    SliceResult run(const SliceOptions& opts);

 private:
    const IR::P4Program* program;
    P4::ReferenceMap* refMap;
    P4::TypeMap* typeMap;
};

const IR::P4Program* applySlice(const IR::P4Program* program,
                                const std::unordered_set<int>& keepStatementIds,
                                P4::ReferenceMap* refMap = nullptr,
                                const std::unordered_set<cstring>* keepVarNames = nullptr,
                                bool pruneEmptySlice = false);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_SLICING_SLICER_H_
