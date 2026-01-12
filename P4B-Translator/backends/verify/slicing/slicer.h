// Semantic-aware slicing for P4 IR (CFG + DDG + control dependencies).
#ifndef BACKENDS_VERIFY_SLICING_SLICER_H_
#define BACKENDS_VERIFY_SLICING_SLICER_H_

#include <map>
#include <set>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "ir/ir.h"
#include "lib/cstring.h"

namespace P4Verify {

struct SliceOptions {
    std::vector<cstring> seedVars;
    bool enable = false;
    bool collectRw = false;
    bool debug = false;
    std::string dotDir;
};

struct SliceResult {
    std::unordered_set<int> keepStatementIds;
    std::unordered_set<cstring> keepVarNames;
    std::unordered_set<cstring> keepTables;
    std::map<cstring, int> regMaxIndex;
    std::set<cstring> regHasNonConst;
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
                                const std::unordered_set<int>& keepStatementIds);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_SLICING_SLICER_H_
