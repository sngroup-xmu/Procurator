#ifndef BACKENDS_VERIFY_TRANSLATE_OPTIONS_H_
#define BACKENDS_VERIFY_TRANSLATE_OPTIONS_H_

#include <getopt.h>
#include <regex>

#include "frontends/common/options.h"
#include "utils.h"

const std::vector<cstring> P4INV_KEYS = {"//#register_write"};

// 如果 var 是 sequence_reg[0] or sequence_reg[any], 统一成 sequence_reg[]
// 如果 var 没有下标，就原样返回
static cstring unifyArrayIndex(const cstring& var) {
    // 匹配形如 name[...] 的模式
    // 你可以用正则或者手工解析，这里给出正则示例：
    // 注意：如果 var 里有多个 [ ] 也要全部去除
    // e.g. "sequence_reg[0]" => "sequence_reg[]"
    //      "sequence_reg[meta.location.index]" => "sequence_reg[]"
    //      "some_reg[2][3]" => "some_reg[][]" (若有多重数组)

    // 这里用一个简单的思路：把所有 [.*?] 都替换为 []
    std::string s{var.c_str()};
    // 用一个简单的 C++17 风格
    static std::regex arrayIdx("\\[.*?\\]");
    s = std::regex_replace(s, arrayIdx, "[]");

    return s.c_str();
}

class P4VerifyOptions : public CompilerOptions {
 public:
    bool translateOnly = false;
    bool addValidityAssertion = false;
    bool addForwardingAssertion = false;
    bool addBoundAssertion = false;
    bool useHeaderRef = false;
    
    bool loadIRFromJson = false;
    bool whileLoop = false;
    bool havocStatefulElements = false;
    bool addInvariant = false;

    cstring output_dir = nullptr;
    cstring outputFile_typedef = nullptr;
    cstring outputFile_cfg = nullptr;
    cstring outputFile_cfg_diagram = nullptr;
    cstring outputFile_variable_list = nullptr;
    cstring outputFile = nullptr;
    
    bool p4invSpec = false;
    cstring p4invFile = nullptr;

    bool bmv2cmds = false;
    cstring cmdFile = nullptr;

    bool gotoOrIf = false; // 1:goto, 0:if

    bool bv2int = false;
    bool bitBlasting = false;

    bool CpiIfElse = false;
    bool bf4Assertion = false;
    bool simpleConjecture = false;
    cstring inlineFunction = "{:inline 1}";
    // bool statelessVerify = false;
    std::vector<cstring> slicingVarNames;
    cstring switchID;
    std::map<std::string, std::string> port_dst = {}; // port, dst

    P4VerifyOptions() {
        registerOption("--switchID", "id",
                       [this](const char* arg) {
                           switchID = arg;
                           return true; },
                       "Switch id for distinguishing processes.");

        registerOption("--port_dst", "m",
                        [this](const char* arg) {
                            // arg format: port:dst_id [,port:dst_id]
                            std::vector<std::string> maps = split(arg, ",");
                            for (auto port_and_dst : maps) {
                                std::vector<std::string> arr =  split(port_and_dst, ":");
                                std::string port = arr[0];
                                std::string dst = arr[1];
                                port_dst[port] = dst;
                            }
                            return true; },
                        "Mappings to indicate which destination each port connects to.");
        
        registerOption("--simpleConjecture", nullptr,
                       [this](const char*) {
                           simpleConjecture = true;
                           return true; },
                       "Experimental: Only generate simple conjecture.");
        registerOption("--bf4Assert", nullptr,
                       [this](const char*) {
                           bf4Assertion = true;
                           addInvariant = true;
                        //    whileLoop = true;
                        //    inlineFunction = "";
                        //    statelessVerify = true;
                           return true; },
                       "Generate assertion in bf4 style.");
        registerOption("--translate-only", nullptr,
                       [this](const char*) {
                           translateOnly = true;
                           return true; },
                       "only translate the P4 input into Boogie program");
        registerOption("-o", "outfile",
                      [this](const char* arg) { 
                        outputFile = arg; 
                        auto idx = ((std::string) arg).rfind("/");
                        cstring dir = outputFile.substr(0, idx+1);
                        output_dir = dir;
                        outputFile_typedef = dir + switchID + "_type.pml"; 
                        outputFile_cfg = dir;
                        outputFile_cfg_diagram = dir + "cfg_diag.dot";
                        outputFile_variable_list = dir + "variable_list.csv";
                        return true; },
                      "Write translation result to outfile");
        registerOption("--fromJSON", "file",
                       [this](const char* arg) {
                           loadIRFromJson = true;
                           file = arg;
                           return true;
                       },
                       "read previously dumped json instead of P4 source code");
        registerOption("--bmv2cmds", "file",
                       [this](const char* arg) {
                           bmv2cmds = true;
                           cmdFile = arg;
                           return true;
                       },
                       "read static bmv2 CLI commands together with the P4 program");
        registerOption("--assert-validity", nullptr,
                       [this](const char*) {
                           addValidityAssertion = true;
                           return true; },
                       "add assertions for header accessing");
        registerOption("--assert-forward", nullptr,
                       [this](const char*) {
                           addForwardingAssertion = true;
                           return true; },
                       "add assertions for egress_spec assignment");
        registerOption("--assert-bound", nullptr,
                       [this](const char*) {
                           addBoundAssertion = true;
                           return true; },
                       "add assertions for header stack out-of-bounds");
        registerOption("--ref", nullptr,
                       [this](const char*) {
                           useHeaderRef = true;
                           return true; },
                       "use header reference to access header fields instead of fields variables");
        
        /*
          Some Boogie compiler/verifier does not support goto statements.
          If so, use if-else statements instead.
        */
        registerOption("--gotoOrIf", nullptr,
                       [this](const char*) {
                           gotoOrIf = true;
                           return true; },
                       "1:goto, 0:if (default:0)");

        /*
          Some verifier does not support bit-vector theory.
          Use integer instead of bitvector
        */
        registerOption("--bv2int", nullptr,
                       [this](const char*) {
                           bv2int = true;
                           return true; },
                       "use integer instead of bitvector");

        /*
          Using integer is time-costing.
          Use bit-blasting algorithm instead.
        */
        registerOption("--bitBlasting", nullptr,
                       [this](const char*) {
                           bitBlasting = true;
                           return true; },
                       "use bit-blasting instead of bitvector");

        /*
          Use inv generator as backend
        */
       registerOption("--p4Inv", nullptr,
                       [this](const char*) {
                           whileLoop = true;
                           CpiIfElse = true;
                           addInvariant = true;
                           return true; },
                       "use invariant generator as backend");
        
        /*
          Use Boogie as backend
        */
       registerOption("--boogie", nullptr,
                       [this](const char*) {
                           whileLoop = true;
                           CpiIfElse = true;
                           return true; },
                       "use invariant generator as backend");

        registerOption("--p4invSpec", "file",
                      [this](const char* arg) { 
                          p4invFile = arg;
                          p4invSpec = true;
                          return true; },
                      "P4INV specification for the P4 program");

        /*
          Options for invariant generation
        */
        registerOption("--whileloop", nullptr,
                       [this](const char*) {
                           whileLoop = true;
                           return true; },
                       "consider the P4 program as a while loop with condition TRUE");
        registerOption("--add-invariant", nullptr,
                       [this](const char*) {
                           addInvariant = true;
                           return true; },
                       "add invariant for the while loop");
        registerOption("--infer-inv", nullptr,
                       [this](const char*) {
                           whileLoop = true;
                           addInvariant = true;
                           return true; },
                       "add required components for infering invariants");
        
        /*
          Add havoc statements at the enter of the while loop
          Used to show the method of traditional tools
          The stateful elements have to be random (without invariants)
        */
        registerOption("--havoc-se", nullptr,
                       [this](const char*) {
                           havocStatefulElements = true;
                           return true; },
                       "havoc stateful elements (counter, register, meter)");

        registerOption("--slicing-vars", "vars",
            [this](const char* arg) {
                        // "vars" 的形式可以是: "hdr.ipv4.dstAddr,meta.location.index,hdr.nc_hdr.value"
                        // 我们将它切分成若干 cstring
                        auto parts = split(arg, ",");
                        for (auto &p : parts) {
                            // 转成 cstring 并 push_back
                            cstring unified = unifyArrayIndex(p.c_str());
                            slicingVarNames.emplace_back(unified);
                        }
                            return true; // 表示成功解析
                        },
                                "Comma-separated list of variables for slicing. e.g. --slicing-vars=hdr.ipv4.dstAddr,meta.location.index"
);
    }
};


using P4VerifyContext = P4CContextWithOptions<P4VerifyOptions>;

#endif