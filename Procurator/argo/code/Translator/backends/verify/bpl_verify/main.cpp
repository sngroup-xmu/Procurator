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
#include "frontends/p4/frontend.h"


// #include "ir/ir.h"
#include "ir/json_loader.h"
#include "lib/gc.h"
#include "lib/crash.h"
#include "lib/nullstream.h"
#include "backends/verify/translate/options.h"
#include "backends/verify/translate/version.h"
#include "backends/verify/translate/translate.h"
#include "backends/verify/translate/bmv2.h"
#include "backends/verify/translate/bf4_assertion.h"
#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/parseInput.h"
#include <time.h>
#include <common/constantFolding.h>
#include <common/resolveReferences/resolveReferences.h>
// #include "verify/control_flow_analysis/control_flow_extractor.h"
#include "verify/control_flow_analysis/pdg_compute.h"
#include "verify/control_flow_analysis/test/test_slicing.h"
#include "verify/to_dsl/variable_collector.h"
#include "verify/control_flow_analysis/slicing_pruner.h"


void collectVariables(const IR::P4Program* program, const std::string& outputFileName) {
    VariableCollector collector;
    program->apply(collector);

    // 将变量列表输出到 CSV 文件
    std::ofstream varOut(outputFileName.c_str());
    if (varOut.is_open()) {
        // 写入 CSV 文件头
        varOut << "Name,Type,Scope,IsParameter,IsGlobal\n";
        for (const auto& varInfo : collector.variableList) {
            varOut << varInfo.name << ","
                   << varInfo.type << ","
                   << varInfo.scope << ","
                   << (varInfo.isParameter ? "true" : "false") << ","
                   << (varInfo.isGlobal ? "true" : "false") << "\n";
        }
        varOut.close();
        std::cout << "Variable list has been written to " << outputFileName << std::endl;
    } else {
        std::cerr << "Unable to open file to write variable list.\n";
    }
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
    if (::errorCount() > 0)
        return 1;
    const IR::P4Program *program = nullptr;
    auto hook = options.getDebugHook();
    if (options.loadIRFromJson == false) {
        program = P4::parseP4File(options);
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
    // collectVariables(program, options.outputFile_variable_list.c_str());

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

    // 创建 ReferenceMap 和 TypeMap
    P4::ReferenceMap refMap;
    P4::TypeMap typeMap;
    refMap.setIsV1(options.langVersion == CompilerOptions::FrontendVersion::P4_14);

    // 创建 PassManager 并添加 Pass
    PassManager passes = {
        new P4::ResolveReferences(&refMap),
        new P4::ConstantFolding(&refMap, &typeMap),
        new P4::TypeInference(&refMap, &typeMap, true),
        // 根据需要添加其他 Pass
    };

    // 运行 PassManager
    program = program->apply(passes);
    if (::errorCount() > 0)
        return 1;

    ControlFlowExtractor cfgExtractor(&refMap, &typeMap, options, bMV2CmdsAnalyzer);

    program->apply(cfgExtractor); // 先遍历程序，构建 CFG
    cfgExtractor.buildDataDependencies(); // 然后建立数据依赖
    cfgExtractor.outputCFGAsJson(options.outputFile_cfg); // 输出 CFG
    cfgExtractor.outputCFGAsDot(options.outputFile_cfg);

    std::vector<CFGEdge> edgeVector;
    std::unordered_set<CFGEdge, CFGEdgeHash, CFGEdgeEq> dataEdges;
    std::cout << "dataEdges size: " << cfgExtractor.dataEdges.size() << std::endl;
    for(auto& edge : cfgExtractor.edges){
        if (edge.type == "control") {
            edgeVector.push_back(edge);
        }
    }
    for (auto& edge : cfgExtractor.dataEdges) {
        dataEdges.insert(edge);
    }

    std::unordered_set<int> removeIds;
    const std::set<int> sliceIds;

    if (options.slicingVarNames.size() > 0) {
        std::vector<cstring> varNames;
        for (auto& var : options.slicingVarNames) {
            varNames.push_back(var);
        }
        varNames.push_back("standard_metadata.egress_port");
        varNames.push_back("standard_metadata.egress_spec");

        std::vector<CFGEdge> edgeVec;
        edgeVec.assign(dataEdges.begin(), dataEdges.end());
        PDGCompute pdgComp(cfgExtractor.nodes, edgeVec, edgeVector);
        pdgComp.buildPDG();
        const std::set<int> sliceIds = pdgComp.slice(varNames, false);
        pdgComp.exportSliceToDot(sliceIds, options.output_dir + "pdg.dot");

        for (auto id : sliceIds) {
            std::cout << "Sliced Node " << id
                      << " => " << cfgExtractor.nodes.at(id).code << std::endl;
        }

        // PDGCompute::runAllPDGTests();

        std::unordered_set<int> usedSet;
        for (auto &node: cfgExtractor.nodes) {
            if (sliceIds.count(node.first)) {
                for (auto &item : cfgExtractor.irNodeIds[node.first]) {
                    usedSet.insert(item);
                }
            }
        }

        for (auto &node: cfgExtractor.nodes) {
            // 如果节点不在切片结果中，就删除
            if (sliceIds.count(node.first) == 0) {
                for (auto &item : cfgExtractor.irNodeIds[node.first]) {
                    if (usedSet.count(item) == 0) {
                        removeIds.insert(item);
                    }
                }
            }
        }
    }

    for (auto item : removeIds) {
        // item 即 nodeId
        // 这里可以拿到 CFGNode
        if (cfgExtractor.nodes.find(item) != cfgExtractor.nodes.end()) {
            auto &rmNode = cfgExtractor.nodes.at(item);
            std::cout << "Remove NodeId=" << item
                      << ", Name=\"" << rmNode.name
                      << ", Code=\"" << rmNode.code << "\"\n";
        } else {
            std::cout << "Remove NodeId=" << item << " (not found in nodes?)\n";
        }
    }

    JSONGenerator(*openFile(options.output_dir+"ir.json", true)) << program << std::endl;
    if(options.bf4Assertion) {
        P4::ReferenceMap refMap;
        P4::TypeMap typeMap;
        cstring testFileName = "instrumentP4.p4";
        auto assertionGenerator = new GenerateAssertions(
            &refMap, &typeMap
        );
        auto testP = program->apply(*assertionGenerator);
        std::cout << "Instrumenting bf4Assert...\n";
        std::ostream* testOut = openFile(testFileName, false);
        if (testOut != nullptr) {
            // (*testOut) << testP->toString();
            // testOut->flush();
            testP->dbprint(*testOut);
            std::cout << "Writing instrument result to " + testFileName + ".\n";
        }
        // std::cout << "Test done.\n";
        // return 0;
        program = testP;
    }

    std::ostream* out_typedef = openFile(options.outputFile_typedef, false); // for typedef code
    std::ostream* out = openFile(options.outputFile, false); // for other code except typedef
    if (out != nullptr) {
        Translator translator(*out_typedef, *out, options, bMV2CmdsAnalyzer);
        translator.setRemoveIds(removeIds);

        if(options.p4invSpec){
            std::ifstream fin(options.p4invFile);

            if(fin){
                std::string s;
                while(getline(fin, s)){
                    cstring key = nullptr;
                    // std::cout << s << std::endl;
                    for(int i = 0; i < P4INV_KEYS.size(); i++){
                        int idx = s.find(P4INV_KEYS[i]);
                        if(idx != -1){
                            s = s.substr(idx+P4INV_KEYS[i].size());
                            key = P4INV_KEYS[i];
                            break;
                        }
                    }
                    if(key == nullptr) continue;
                    //#reg_write
                    if(key == P4INV_KEYS[0]){
                        translator.addRegWrite(s);
                        continue;
                    }
                }
            }
        }

        translator.translate(program);
        // if(options.addInvariant) {
        //     unsigned int traverseTimes = translator.expectedTraverseTimes;
        //     while(--traverseTimes)
        //         translator.translate(program);
        // }
        translator.writeToFile();
        out_typedef->flush();
        out->flush();
    }

    backend_end = clock();
    backend_cpu_time_used = ((double) (backend_end - backend_start)) / CLOCKS_PER_SEC;
    program_cpu_time_used = ((double) (backend_end - program_start)) / CLOCKS_PER_SEC;
    // std::cout << "backend done in " << DURATION(front)/1000.0 << " s\n";
    std::cout << "backend cpu time " << backend_cpu_time_used << " s\n";
    std::cout << "program cpu time " << program_cpu_time_used << " s\n";
    return 0;
}


