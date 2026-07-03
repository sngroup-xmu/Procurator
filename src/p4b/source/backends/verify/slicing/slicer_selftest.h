// Slicer regression selftests used by p4c-translator --slicing-selftest.
#ifndef BACKENDS_VERIFY_SLICING_SLICER_SELFTEST_H_
#define BACKENDS_VERIFY_SLICING_SLICER_SELFTEST_H_

#include "backends/verify/slicing/slicer.h"

namespace P4Verify {

int runSlicingSelftest(cstring caseName,
                       const SliceResult& sres,
                       const IR::P4Program* slicedProgram);

}  // namespace P4Verify

#endif  // BACKENDS_VERIFY_SLICING_SLICER_SELFTEST_H_
