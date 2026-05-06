// Verify backend pipeline: slicing, analyses, Boogie lowering, and meta output.
#include "backends/verify/bpl_verify/pipeline.h"

#include <ctime>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <unordered_set>

#include "backends/verify/analysis/index_defs.h"
#include "backends/verify/analysis/monotonic.h"
#include "backends/verify/slicing/slicer.h"
#include "backends/verify/slicing/slicer_selftest.h"
#include "backends/verify/translate/bmv2.h"
#include "backends/verify/translate/translate.h"
#ifdef P4VERIFY_ENABLE_P4LTL
#include "frontends/parsers/p4ltl/p4ltlast.hpp"
#include "frontends/parsers/p4ltl/p4ltlparser.hpp"
#include "frontends/parsers/p4ltl/p4ltllexer.hpp"
#endif
#include "lib/nullstream.h"

namespace P4Verify {
namespace {

std::unique_ptr<BMV2CmdsAnalyzer> loadBmv2Commands(const P4VerifyOptions& options) {
    std::ifstream bmv2cmds(options.cmdFile.c_str());
    if (!bmv2cmds) {
        return nullptr;
    }
    try {
        return std::unique_ptr<BMV2CmdsAnalyzer>(new BMV2CmdsAnalyzer(&bmv2cmds));
    } catch (const char* msg) {
        std::cerr << msg << std::endl;
        return nullptr;
    }
}

cstring normalizeTableNameForBoogie(cstring tableName) {
    std::string norm = tableName.c_str();
    for (auto& ch : norm) {
        if (ch == '.') {
            ch = '_';
        }
    }
    return cstring(norm.c_str());
}

std::unordered_set<cstring> normalizeKeepVarNames(const std::vector<cstring>& names) {
    std::unordered_set<cstring> out;
    for (const auto& name : names) {
        if (name == nullptr || name == "") {
            continue;
        }
        out.insert(name);
        std::string s = name.c_str();
        std::string base = s;
        std::string idxSuffix;
        auto bracket = s.find('[');
        if (bracket != std::string::npos) {
            base = s.substr(0, bracket);
            idxSuffix = s.substr(bracket);
            if (!base.empty()) {
                out.insert(cstring(base.c_str()));
            }
        }
        if (base.size() > 2 && base.rfind("_0") == base.size() - 2) {
            std::string stripped = base.substr(0, base.size() - 2);
            if (!stripped.empty()) {
                out.insert(cstring(stripped.c_str()));
                if (!idxSuffix.empty()) {
                    out.insert(cstring((stripped + idxSuffix).c_str()));
                }
            }
        } else if (!base.empty()) {
            std::string withSuffix = base + "_0";
            out.insert(cstring(withSuffix.c_str()));
            if (!idxSuffix.empty()) {
                out.insert(cstring((withSuffix + idxSuffix).c_str()));
            }
        }
    }
    return out;
}

std::unordered_set<cstring> tableNamesFromKeepVars(const std::unordered_set<cstring>& keepVars) {
    std::unordered_set<cstring> out;
    const std::string actionRunSuffix = ".action_run";
    const std::string actionPrefix = ".action.";
    for (const auto& keep : keepVars) {
        if (keep == nullptr || keep == "") {
            continue;
        }
        std::string s = keep.c_str();
        auto actionRun = s.find(actionRunSuffix);
        if (actionRun != std::string::npos && actionRun + actionRunSuffix.size() == s.size()) {
            std::string table = s.substr(0, actionRun);
            if (!table.empty()) {
                out.insert(cstring(table.c_str()));
            }
            continue;
        }
        auto action = s.find(actionPrefix);
        if (action != std::string::npos) {
            std::string table = s.substr(0, action);
            if (!table.empty()) {
                out.insert(cstring(table.c_str()));
            }
        }
    }
    return out;
}

int runSlicingPipeline(const IR::P4Program** program,
                       P4::ReferenceMap* refMap,
                       P4::TypeMap* typeMap,
                       BMV2CmdsAnalyzer* bmv2Analyzer,
                       P4VerifyOptions& options) {
    const bool doSlicing = options.slicingEnabled && !options.slicingVarNames.empty();
    const bool needRw = options.outputMetaFile != nullptr;
    if (!doSlicing && !needRw) {
        return -1;
    }

    SliceOptions sopts;
    sopts.seedVars = options.slicingVarNames;
    sopts.enable = doSlicing;
    sopts.collectRw = needRw;
    sopts.bmv2Analyzer = bmv2Analyzer;
    sopts.keepControlSeeds = options.slicingControlSeeds;
    sopts.debug = options.slicingDebug;
    if (options.slicingDotDir) {
        sopts.dotDir = options.slicingDotDir.c_str();
    }

    Slicer slicer(*program, refMap, typeMap);
    auto sres = slicer.run(sopts);
    auto extraKeepVars = normalizeKeepVarNames(options.slicingKeepVarNames);
    auto extraKeepTables = tableNamesFromKeepVars(extraKeepVars);

    if (doSlicing) {
        if (!options.loadIRFromJson) {
            std::unordered_set<cstring> prunerKeepVars = sres.keepVarNames;
            prunerKeepVars.insert(extraKeepVars.begin(), extraKeepVars.end());
            *program = applySlice(*program, sres.keepStatementIds, refMap, &prunerKeepVars, true);
        } else if (!sres.keepStatementIds.empty()) {
            if (options.slicingDebug) {
                std::cerr << "[slicer] skipping statement pruning for JSON IR\n";
            }
        }
        if (!options.loadIRFromJson) {
            if (!sres.keepVarNames.empty()) {
                options.slicingKeepVars = sres.keepVarNames;
            }
            options.slicingKeepVars.insert(extraKeepVars.begin(), extraKeepVars.end());
            if (sres.filterTables) {
                // Slicer reports control-plane names, while Boogie lowering uses sanitized
                // procedure/table identifiers.  Keep the conversion at the pipeline boundary
                // until VerifyNameMap replaces this string protocol.
                options.slicingFilterTables = true;
                options.slicingKeepTables.clear();
                for (const auto& t : sres.keepTables) {
                    options.slicingKeepTables.insert(normalizeTableNameForBoogie(t));
                }
                for (const auto& t : extraKeepTables) {
                    options.slicingKeepTables.insert(normalizeTableNameForBoogie(t));
                }
            }
        }
        if (!sres.regMaxIndex.empty()) {
            options.slicingRegMaxIndex = sres.regMaxIndex;
        }
        if (!sres.regHasNonConst.empty()) {
            options.slicingRegHasNonConst = sres.regHasNonConst;
        }
        if (options.loadIRFromJson) {
            // JSON IR statement pruning is intentionally disabled.  Do not shrink
            // register domains either: the original, unpruned control flow can
            // still reference indices outside the seed slice.
            options.slicingKeepVars.clear();
            options.slicingKeepTables.clear();
            options.slicingFilterTables = false;
            options.slicingRegMaxIndex.clear();
            options.slicingRegHasNonConst.clear();
            if (options.slicingDebug) {
                std::cerr << "[slicer] json-safe: var/table filtering disabled "
                          << "and register index pruning disabled "
                          << "(statement pruning skipped)\n";
            }
        }
    }

    if (needRw) {
        options.rwReads = sres.rwReads;
        options.rwWrites = sres.rwWrites;
        options.rwStatefulObjects = sres.rwStatefulObjects;
    }

    if (options.slicingSelftest) {
        return runSlicingSelftest(options.slicingSelftestCase, sres, *program);
    }
    return -1;
}

void runPostSlicingAnalyses(const IR::P4Program* program,
                            P4::ReferenceMap* refMap,
                            P4::TypeMap* typeMap,
                            P4VerifyOptions& options) {
    if (options.outputMetaFile == nullptr) {
        return;
    }
    analyzeIndexDefinitions(program, refMap, typeMap, &options);
    analyzeWraparoundMonotonicity(program, refMap, typeMap, &options);
}

void loadP4LtlSpec(Translator* translator, const P4VerifyOptions& options) {
    if (!options.p4ltlSpec) {
        return;
    }
#ifndef P4VERIFY_ENABLE_P4LTL
    (void)translator;
    ::error("legacy --p4ltl support is unavailable in this p4c frontend sync; "
            "build with ENABLE_P4VERIFY_P4LTL after restoring the P4LTL parser");
    return;
#else
    std::ifstream fin(options.p4ltlFile.c_str());
    if (!fin) {
        return;
    }

    std::string s;
    while (getline(fin, s)) {
        cstring key = nullptr;
        for (size_t i = 0; i < P4LTL_KEYS.size(); i++) {
            const size_t idx = s.find(P4LTL_KEYS[i]);
            if (idx != std::string::npos) {
                s = s.substr(idx + P4LTL_KEYS[i].size());
                key = P4LTL_KEYS[i];
                break;
            }
        }
        if (key == nullptr) {
            continue;
        }
        if (key == P4LTL_KEYS[0]) {
            translator->setP4LTLFreeVars(s);
            continue;
        }
        std::istringstream p4ltlSpec(s);
        P4LTL::Scanner scanner{p4ltlSpec, std::cerr};
        P4LTL::AstNode* root = nullptr;
        P4LTL::P4LTLParser parser{scanner, root};
        int result = parser.parse();
        if (result == 0 && root) {
            if (std::getenv("P4VERIFY_DEBUG_P4LTL") != nullptr) {
                std::cerr << "[p4verify-p4ltl] parsing result: "
                          << root->toString() << std::endl;
            }
            translator->setP4LTLSpec(key, root);
        }
    }
#endif
}

bool emitBoogieAndMeta(const IR::P4Program* program,
                       BMV2CmdsAnalyzer* bmv2Analyzer,
                       P4::ReferenceMap* refMap,
                       P4VerifyOptions& options) {
    const bool debugJson = std::getenv("P4VERIFY_DEBUG_JSON_FRONTEND") != nullptr;
    if (debugJson) {
        std::cerr << "[p4verify-json] emitBoogieAndMeta begin" << std::endl;
    }
    auto out = openFile(options.outputBplFile.c_str(), false);
    if (out == nullptr) {
        return false;
    }

    if (debugJson) {
        std::cerr << "[p4verify-json] constructing translator" << std::endl;
    }
    Translator translator(*out, options, bmv2Analyzer, refMap);
    if (debugJson) {
        std::cerr << "[p4verify-json] loading p4ltl" << std::endl;
    }
    loadP4LtlSpec(&translator, options);
    if (debugJson) {
        std::cerr << "[p4verify-json] translating program" << std::endl;
    }
    translator.translate(program);
    if (debugJson) {
        std::cerr << "[p4verify-json] writing bpl" << std::endl;
    }
    translator.writeToFile();
    out->flush();

    if (options.outputMetaFile != nullptr) {
        auto metaOut = openFile(options.outputMetaFile.c_str(), false);
        if (metaOut == nullptr) {
            return false;
        }
        translator.writeMetaToFile(*metaOut);
        metaOut->flush();
    }
    return ::errorCount() == 0;
}

}  // namespace

int runVerifyBackend(const IR::P4Program* inputProgram,
                     P4::ReferenceMap* refMap,
                     P4::TypeMap* typeMap,
                     P4VerifyOptions& options,
                     double* backendCpuSeconds) {
    const clock_t backendStart = clock();
    const IR::P4Program* program = inputProgram;

    auto bmv2Analyzer = loadBmv2Commands(options);
    if (options.cmdFile != nullptr && bmv2Analyzer == nullptr) {
        std::ifstream probe(options.cmdFile.c_str());
        if (probe) {
            return 1;
        }
    }

    const int slicingExit = runSlicingPipeline(&program, refMap, typeMap, bmv2Analyzer.get(), options);
    if (slicingExit >= 0) {
        if (backendCpuSeconds != nullptr) {
            *backendCpuSeconds = (static_cast<double>(clock() - backendStart)) / CLOCKS_PER_SEC;
        }
        return slicingExit;
    }

    runPostSlicingAnalyses(program, refMap, typeMap, options);
    if (!emitBoogieAndMeta(program, bmv2Analyzer.get(), refMap, options)) {
        if (backendCpuSeconds != nullptr) {
            *backendCpuSeconds = (static_cast<double>(clock() - backendStart)) / CLOCKS_PER_SEC;
        }
        return 1;
    }

    if (backendCpuSeconds != nullptr) {
        *backendCpuSeconds = (static_cast<double>(clock() - backendStart)) / CLOCKS_PER_SEC;
    }
    return 0;
}

}  // namespace P4Verify
