/*
Copyright 2013-present Barefoot Networks, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

#include <ctime>
#include <iostream>

#include "backends/verify/bpl_verify/frontend.h"
#include "backends/verify/bpl_verify/pipeline.h"
#include "backends/verify/translate/options.h"
#include "backends/verify/translate/version.h"
#include "lib/crash.h"
#include "lib/error.h"
#include "lib/gc.h"

int main(int argc, char *const argv[]) {
    const clock_t programStart = clock();
    setup_gc_logging();
    setup_signals();

    AutoCompileContext autoP4VerifyContext(new P4VerifyContext);
    auto& options = P4VerifyContext::get().options();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.compilerVersion = P4VERIFY_VERSION_STRING;

    if (options.process(argc, argv) != nullptr) {
        if (options.loadIRFromJson == false) {
            options.setInputFile();
        }
    }
    if (::errorCount() > 0) {
        return 1;
    }

    try {
        P4Verify::LoadedProgram loaded;
        if (!P4Verify::loadFrontendProgram(options, &loaded)) {
            return 1;
        }

        double backendCpuSeconds = 0.0;
        const int rc = P4Verify::runVerifyBackend(
            loaded.program, &loaded.refMap, &loaded.typeMap, options, &backendCpuSeconds);
        if (options.slicingSelftest) {
            return rc;
        }

        const double programCpuSeconds =
            (static_cast<double>(clock() - programStart)) / CLOCKS_PER_SEC;
        std::cout << "backend cpu time " << backendCpuSeconds << " s\n";
        std::cout << "program cpu time " << programCpuSeconds << " s\n";
        return rc;
    } catch (const std::exception& bug) {
        std::cerr << bug.what() << std::endl;
        return 1;
    }
}
