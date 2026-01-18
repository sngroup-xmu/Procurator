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

#include <stdio.h>
#include <string>
#include <iostream>
#include <fstream>
#include <sstream>
#include <regex>
#include <unistd.h>
#include <vector>
#include <unordered_set>
#include <map>

#include "ir/ir.h"
#include "ir/json_loader.h"
#include "ir/visitor.h"
#include "lib/gc.h"
#include "lib/crash.h"
#include "lib/nullstream.h"
#include "backends/verify/translate/options.h"
#include "backends/verify/translate/version.h"
#include "backends/verify/translate/translate.h"
#include "backends/verify/translate/analyzer.h"
#include "backends/verify/translate/bmv2.h"
#include "backends/verify/analysis/monotonic.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "frontends/common/constantFolding.h"
#include "frontends/p4/simplifyDefUse.h"
#include "ir/pass_manager.h"
#include "midend/local_copyprop.h"
#include "frontends/parsers/p4ltl/p4ltlast.hpp"
#include "frontends/parsers/p4ltl/p4ltlparser.hpp"
#include "frontends/parsers/p4ltl/p4ltllexer.hpp"
#include "backends/verify/slicing/slicer.h"
#include <time.h>

static bool _setContains(const std::unordered_set<cstring>& set, const char* value) {
    return set.count(cstring(value)) > 0;
}

static bool _mapTryGet(const std::map<cstring, int>& map, const char* key, int& out) {
    auto it = map.find(cstring(key));
    if (it == map.end()) {
        return false;
    }
    out = it->second;
    return true;
}

static int _runSlicingSelftest(const P4VerifyOptions& options,
                               const P4Verify::SliceResult& sres,
                               const IR::P4Program* slicedProgram) {
    const std::string caseName = options.slicingSelftestCase ? options.slicingSelftestCase.c_str() : "";
    if (caseName.empty()) {
        std::cerr << "[SELFTEST] missing --slicing-selftest=<case>\n";
        return 2;
    }

    if (caseName != "netchain_seq" && caseName != "distcache_reg_alias") {
        std::cerr << "[SELFTEST] unknown case: " << caseName << "\n";
        return 2;
    }

    bool ok = true;
    auto expect = [&](bool cond, const std::string& msg) {
        if (!cond) {
            ok = false;
            std::cerr << "[SELFTEST] FAIL: " << msg << "\n";
        }
    };

    if (caseName == "netchain_seq") {
        // Netchain slicing regression (field-sensitive headers):
        // Seed: sequence_reg_0[0] (sequence register only). Expected effects:
        //  - keep write path (assign_value/maintain_sequence/get_sequence)
        //  - drop value_reg / nc_hdr.value dependent path (read_value)
        //  - prune register index domain to {0} for sequence_reg
        expect(_setContains(sres.keepTables, "assign_value_0"), "expected keepTables contains assign_value_0");
        expect(_setContains(sres.keepTables, "maintain_sequence_0"),
               "expected keepTables contains maintain_sequence_0");
        expect(_setContains(sres.keepTables, "get_sequence_0"), "expected keepTables contains get_sequence_0");
        expect(!_setContains(sres.keepTables, "read_value_0"), "expected keepTables does NOT contain read_value_0");

        expect(_setContains(sres.keepVarNames, "hdr.nc_hdr.seq"), "expected keepVarNames contains hdr.nc_hdr.seq");
        expect(!_setContains(sres.keepVarNames, "hdr.nc_hdr.value"),
               "expected keepVarNames does NOT contain hdr.nc_hdr.value");

        int maxIdx = -1;
        const bool hasSeq = _mapTryGet(sres.regMaxIndex, "sequence_reg", maxIdx) ||
                            _mapTryGet(sres.regMaxIndex, "sequence_reg_0", maxIdx);
        expect(hasSeq, "expected regMaxIndex contains sequence_reg (or sequence_reg_0)");
        if (hasSeq) {
            expect(maxIdx == 0, "expected regMaxIndex(sequence_reg) == 0");
        }
        expect(!_setContains(sres.keepVarNames, "value_reg"), "expected keepVarNames does NOT contain value_reg");
        expect(!_setContains(sres.keepVarNames, "value_reg_0"), "expected keepVarNames does NOT contain value_reg_0");
    } else if (caseName == "distcache_reg_alias") {
        // DistCache slicing regression: allow dslc to seed slicing using Boogie-level register names
        // (sanitized control-plane names), even when the IR instance name differs.
        //
        // Expected: seed `netcacheEgress_cm3_reg` maps to internal `cm3_reg_0`, and we keep both
        // names so translation can retain the Boogie-level declaration while slicing reasons about
        // the IR name.
        expect(_setContains(sres.keepVarNames, "cm3_reg_0"), "expected keepVarNames contains cm3_reg_0");
        expect(_setContains(sres.keepVarNames, "netcacheEgress_cm3_reg"),
               "expected keepVarNames contains netcacheEgress_cm3_reg");
        expect(_setContains(sres.keepVarNames, "cm4_reg_0"), "expected keepVarNames contains cm4_reg_0");
        expect(_setContains(sres.keepVarNames, "netcacheEgress_cm4_reg"),
               "expected keepVarNames contains netcacheEgress_cm4_reg");

        class InstNameCollector : public Inspector {
         public:
            std::unordered_set<std::string> names;
            bool preorder(const IR::Declaration_Instance* inst) override {
                if (inst) {
                    names.insert(inst->name.name.c_str());
                }
                return false;
            }
        };
        if (slicedProgram) {
            InstNameCollector col;
            slicedProgram->apply(col);
            expect(col.names.count("cm3_reg_0") > 0, "expected sliced IR contains Declaration_Instance cm3_reg_0");
            expect(col.names.count("cm4_reg_0") > 0, "expected sliced IR contains Declaration_Instance cm4_reg_0");
        }
    }

    if (ok) {
        std::cerr << "[SELFTEST] PASS: " << caseName << "\n";
        return 0;
    }
    return 1;
}

int main(int argc, char *const argv[]) {
    clock_t program_start = clock(), program_end;
    double program_cpu_time_used;
    setup_gc_logging();
    setup_signals();

    AutoCompileContext autoP4VerifyContext(new P4VerifyContext);
    auto& options = P4VerifyContext::get().options();
    options.langVersion = CompilerOptions::FrontendVersion::P4_16;
    options.compilerVersion = P4VERIFY_VERSION_STRING;

    if (options.process(argc, argv) != nullptr) {
            if (options.loadIRFromJson == false)
                    options.setInputFile();
    }
    if (!options.loadIRFromJson && options.file != nullptr) {
        const std::string inputPath = options.file.c_str();
        if (inputPath.size() >= 5 && inputPath.rfind(".json") == inputPath.size() - 5) {
            options.loadIRFromJson = true;
        }
    }
    if (::errorCount() > 0)
        return 1;
    const IR::P4Program *program = nullptr;
    auto hook = options.getDebugHook();
    if (options.loadIRFromJson == false) {
        std::string sanitizedPath;
        if (options.file != nullptr) {
            std::ifstream in(options.file);
            if (in) {
                std::ostringstream buf;
                buf << in.rdbuf();
                std::string content = buf.str();
                const bool hasAssert = content.find("@assert") != std::string::npos;
                const bool hasAssume = content.find("@assume") != std::string::npos;
                if (hasAssert || hasAssume) {
                    // Strip non-standard annotations that P4C may not recognize.
                    std::string sanitized = content;
                    if (hasAssert) {
                        sanitized = std::regex_replace(sanitized, std::regex(R"(@assert\s*\[[^\]]*\])"), "");
                    }
                    if (hasAssume) {
                        sanitized = std::regex_replace(sanitized, std::regex(R"(@assume\s*\[[^\]]*\])"), "");
                    }
                    if (sanitized != content) {
                        std::string inputPath = options.file.c_str();
                        std::string dir = ".";
                        const auto slash = inputPath.find_last_of("/\\");
                        if (slash != std::string::npos) {
                            dir = inputPath.substr(0, slash);
                        }
                        std::string tmplStr = dir + "/.p4b_sanitized_XXXXXX.p4";
                        std::vector<char> tmpl(tmplStr.begin(), tmplStr.end());
                        tmpl.push_back('\0');
                        const int fd = mkstemps(tmpl.data(), 3);
                        if (fd != -1) {
                            std::ofstream out(tmpl.data());
                            if (out) {
                                out << sanitized;
                                sanitizedPath = tmpl.data();
                                options.file = sanitizedPath;
                            }
                            close(fd);
                        }
                    }
                }
            }
        }
        program = P4::parseP4File(options);
        // std::cout << "parse time " << ((double) (clock() - program_start)) / CLOCKS_PER_SEC << " s\n";
        if (program == nullptr || ::errorCount() > 0)
            return 1;
        try {
            P4::P4COptionPragmaParser optionsPragmaParser;
            program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

            P4::FrontEnd frontend;
            frontend.addDebugHook(hook);
            program = frontend.run(options, program);
        } catch (const std::exception &bug) {
            std::cerr << bug.what() << std::endl;
            return 1;
        }
    if (program == nullptr || ::errorCount() > 0)
        return 1;
    } else{
        std::ifstream json(options.file);
        if (json) {
            JSONLoader loader(json);
            const IR::Node* node = nullptr;
            loader >> node;
            if (!(program = node->to<IR::P4Program>()))
                error(ErrorType::ERR_INVALID, "%s is not a P4Program in json format", options.file);
        } else {
            error(ErrorType::ERR_IO, "Can't open %s", options.file); }
    }

    if (options.loadIRFromJson && options.slicingEnabled && !options.slicingVarNames.empty()) {
        // Normalize JSON IR to improve slicing precision while keeping source paths unchanged.
        P4::ReferenceMap normRefMap;
        P4::TypeMap normTypeMap;
        PassManager normalizer;
        normalizer.addPasses({
            new P4::TypeChecking(&normRefMap, &normTypeMap),
            new P4::SimplifyDefUse(&normRefMap, &normTypeMap),
            new P4::LocalCopyPropagation(&normRefMap, &normTypeMap),
            new P4::ConstantFolding(&normRefMap, &normTypeMap),
        });
        program = program->apply(normalizer)->to<IR::P4Program>();
        if (program == nullptr || ::errorCount() > 0) {
            return 1;
        }
    }

    // Build reference and type maps for slicing (kept local to avoid global state).
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
    P4::TypeChecking typeChecking(&refMap, &typeMap);
    program = program->apply(typeChecking)->to<IR::P4Program>();
    if (program == nullptr || ::errorCount() > 0)
        return 1;

    // cstring p4ltl1 = "[](AP(drop))";
    // cstring p4ltl2 = "Error!!!";
    // cstring p4ltl3 = "[](AP(!drop) ==> AP((old(hdr.ipv4.ttl) != 0 && hdr.ipv4.ttl == old(hdr.ipv4.ttl) - 1) || (old(hdr.ipv4.ttl) == 0 && hdr.ipv4.ttl == 255)))";
    // std::vector<cstring> strings = {p4ltl1, p4ltl2, p4ltl3};
    // // processing
    // for(int j = 0; j < strings.size(); ++j)
    // {
    //     std::cout << "\n======= Processing string " << j + 1 << "=======" << std::endl;
    //     // init scanner and parser
    //     std::stringstream inputStringStream;
    //     inputStringStream << strings[j];
    //     // std::istringstream inputStringStream(strings[j]);
    //     P4LTL::Scanner scanner{ inputStringStream, std::cerr };
    //     P4LTL::AstNode* root = nullptr;    // root is the parse result
    //     P4LTL::P4LTLParser parser{ scanner, root};
    //     int result = parser.parse();
    //     if(result == 0 && root)
    //     {
    //         std::cout << "Gotcha! Here is the parse result: ";
    //         std::cout << root->toString() << std::endl;
    //         std::cout << "Now here's another example for getting all the atomic proposition: " << std::endl;
    //         // example of getting all the aps
    //         std::vector<P4LTL::P4LTLAtomicProposition*> result = getAllAP(root);
    //         for(int i = 0; i < result.size(); ++i)
    //         {
    //             std::cout << "AP" << i + 1 << ": " + result[i]->toString() << std::endl;
    //         }
    //     }
    //     else
    //         std::cout << "Can't get root/Root is empty, maybe a parse error." << std::endl;
    // }


    clock_t backend_start, backend_end;
    double backend_cpu_time_used;
    backend_start = clock();

    std::ifstream bmv2cmds(options.cmdFile);
    BMV2CmdsAnalyzer* bMV2CmdsAnalyzer = nullptr;
    if(bmv2cmds){
        try{
            bMV2CmdsAnalyzer = new BMV2CmdsAnalyzer(&bmv2cmds);
        } catch (const char* msg) {
            std::cerr << msg << std::endl;
            return 1;
        }
    }

    const bool doSlicing = options.slicingEnabled && !options.slicingVarNames.empty();
    const bool needRw = options.outputMetaFile != nullptr;
    if (doSlicing || needRw) {
        P4Verify::SliceOptions sopts;
        sopts.seedVars = options.slicingVarNames;
        sopts.enable = doSlicing;
        sopts.collectRw = needRw;
        sopts.bmv2Analyzer = bMV2CmdsAnalyzer;
        sopts.keepControlSeeds = options.slicingControlSeeds;
        sopts.debug = options.slicingDebug;
        if (options.slicingDotDir) {
            sopts.dotDir = options.slicingDotDir.c_str();
        }
        P4Verify::Slicer slicer(program, &refMap, &typeMap);
        auto sres = slicer.run(sopts);
        if (doSlicing) {
            if (!sres.keepStatementIds.empty()) {
                if (!options.loadIRFromJson) {
                    program = P4Verify::applySlice(program, sres.keepStatementIds, &sres.keepVarNames);
                } else if (options.slicingDebug) {
                    std::cerr << "[slicer] skipping statement pruning for JSON IR\n";
                }
            }
            if (!sres.keepVarNames.empty()) {
                options.slicingKeepVars = sres.keepVarNames;
            }
            if (!sres.keepTables.empty()) {
                options.slicingKeepTables = sres.keepTables;
            }
            if (!sres.regMaxIndex.empty()) {
                options.slicingRegMaxIndex = sres.regMaxIndex;
            }
            if (!sres.regHasNonConst.empty()) {
                options.slicingRegHasNonConst = sres.regHasNonConst;
            }
            if (options.loadIRFromJson) {
                if (options.slicingDebug) {
                    std::cerr << "[slicer] json-safe: disabling var/table filtering\n";
                }
                options.slicingKeepVars.clear();
                options.slicingKeepTables.clear();
            }
        }
        if (needRw) {
            options.rwReads = sres.rwReads;
            options.rwWrites = sres.rwWrites;
            options.rwStatefulObjects = sres.rwStatefulObjects;
        }

        if (options.slicingSelftest) {
            return _runSlicingSelftest(options, sres, program);
        }
    }

    // Post-slicing analysis (for meta consumers like dslc): summarize monotonic/affine
    // register updates that may lead to wrap-around bugs.
    if (options.outputMetaFile != nullptr) {
        P4Verify::analyzeWraparoundMonotonicity(program, &refMap, &typeMap, &options);
    }

    std::ostream* out = openFile(options.outputBplFile, false);
    if (out != nullptr) {
        Translator translator(*out, options, bMV2CmdsAnalyzer);

        if(options.p4ltlSpec){
            std::ifstream fin(options.p4ltlFile);
            
            if(fin){
                std::string s;
                while(getline(fin, s)){
                    cstring key = nullptr;
                    // std::cout << s << std::endl;
                    for(int i = 0; i < P4LTL_KEYS.size(); i++){
                        int idx = s.find(P4LTL_KEYS[i]);
                        if(idx != -1){
                            s = s.substr(idx+P4LTL_KEYS[i].size());
                            key = P4LTL_KEYS[i];
                            break;
                        }
                    }
                    if(key == nullptr) continue;
                    if(key == P4LTL_KEYS[0]){
                        translator.setP4LTLFreeVars(s);
                        continue;
                    }
                    std::istringstream p4ltlSpec(s);
                    P4LTL::Scanner scanner{ p4ltlSpec, std::cerr };
                    P4LTL::AstNode* root = nullptr;
                    P4LTL::P4LTLParser parser{ scanner, root};
                    int result = parser.parse();
                    if(result == 0 && root){
                        std::cout << "P4LTL parsing result: ";
                        std::cout << root->toString() << std::endl;
                        translator.setP4LTLSpec(key, root);
                        std::cout << std::endl;
                    }
                }
            }
        }

        translator.translate(program);
        translator.writeToFile();
        out->flush();

        if (options.outputMetaFile != nullptr) {
            std::ostream *metaOut = openFile(options.outputMetaFile, false);
            if (metaOut != nullptr) {
                translator.writeMetaToFile(*metaOut);
                metaOut->flush();
            }
        }
        // Analyzer analyzer;
        // analyzer.analyzeP4Program(program);
    }
    backend_end = clock();
    backend_cpu_time_used = ((double) (backend_end - backend_start)) / CLOCKS_PER_SEC;
    program_cpu_time_used = ((double) (backend_end - program_start)) / CLOCKS_PER_SEC;
    // std::cout << "backend done in " << DURATION(front)/1000.0 << " s\n";
    std::cout << "backend cpu time " << backend_cpu_time_used << " s\n";
    std::cout << "program cpu time " << program_cpu_time_used << " s\n";
    return 0;
}
