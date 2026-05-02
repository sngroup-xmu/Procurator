#ifndef BACKENDS_VERIFY_TRANSLATE_OPTIONS_H_
#define BACKENDS_VERIFY_TRANSLATE_OPTIONS_H_

#include <getopt.h>
#include <map>
#include <set>
#include <string>
#include <unordered_set>
#include <vector>
#include "frontends/common/options.h"
#include "backends/verify/translate/utils.h"

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
    cstring outputBplFile = nullptr;
    cstring outputMetaFile = nullptr;

    bool p4ltlSpec = false;
    cstring p4ltlFile = nullptr;

    bool bmv2cmds = false;
    cstring cmdFile = nullptr;

    bool gotoOrIf = false; // 1:goto, 0:if

    bool bv2int = false;
    bool ultimateAutomizer = false;
    bool bitBlasting = false;

    bool CpiIfElse = false;

    bool tna = false;

    std::vector<cstring> slicingVarNames;
    std::vector<cstring> slicingKeepVarNames;
    bool slicingEnabled = false;
    bool slicingDebug = false;
    cstring slicingDotDir = nullptr;
    bool slicingSelftest = false;
    cstring slicingSelftestCase = nullptr;
    std::unordered_set<cstring> slicingKeepVars;
    std::unordered_set<cstring> slicingKeepTables;
    bool slicingFilterTables = false;
    std::map<cstring, int> slicingRegMaxIndex;
    std::set<cstring> slicingRegHasNonConst;
    bool slicingRegPrune = true;
    bool slicingControlSeeds = true;

    std::vector<cstring> rwReads;
    std::vector<cstring> rwWrites;
    std::vector<cstring> rwStatefulObjects;

    struct WraparoundRegisterInfo {
        cstring internal_name = nullptr;  // IR/p4c name (e.g., leafload_reg_0)
        cstring boogie_name = nullptr;    // control-plane / translated name (e.g., partitionswitchIngress_leafload_reg)
        int value_width = -1;             // bitwidth of register element (bits), -1 if unknown
        int index_width = 32;             // bitwidth of index (bits), default 32
    };

    struct WraparoundUpdate {
        cstring reg_internal = nullptr;
        cstring reg_boogie = nullptr;
        std::vector<cstring> idx_vars;
        int idx_const = -1;               // >=0 if constant index could be extracted
        cstring idx_expr = nullptr;       // best-effort Boogie index expression (unprefixed), empty if unknown
        cstring value_var = nullptr;      // variable written (best-effort dotted path), nullptr if complex
        cstring op = nullptr;             // "add" | "sub"
        bool delta_is_const = false;
        cstring delta_const = nullptr;    // decimal string when delta_is_const
        bool delta_is_odd = false;        // only meaningful when delta_is_const and value_width known
        int value_width = -1;
        int index_width = 32;
        cstring context = nullptr;        // action/control name (best-effort)
    };

    struct IndexDefinition {
        cstring target_var = nullptr;      // dotted P4-local target (e.g., meta.register_index)
        cstring expr = nullptr;            // best-effort Boogie expression in P4-local namespace
        std::vector<cstring> deps;         // dotted source variables referenced by expr
        cstring context = nullptr;         // action/control/parser name (best-effort)
    };

    struct FailFastRegisterAssert {
        cstring reg_boogie = nullptr;
        cstring mode = nullptr;             // "any" | "slot0"
        cstring constant = nullptr;         // typed Boogie literal, e.g. 0bv16
    };

    // Post-slicing analysis results (filled by analysis passes, emitted via --meta-out).
    std::vector<WraparoundRegisterInfo> wraparound_registers;
    std::vector<WraparoundUpdate> wraparound_updates;
    std::vector<IndexDefinition> index_definitions;
    std::vector<FailFastRegisterAssert> fail_fast_register_asserts;

    P4VerifyOptions() {
        registerOption("--translate-only", nullptr,
                       [this](const char*) {
                           translateOnly = true;
                           return true; },
                       "only translate the P4 input into Boogie program");
        registerOption("-o", "outfile",
                      [this](const char* arg) { outputBplFile = arg; return true; },
                      "Write translation result to outfile");
        registerOption("--meta-out", "metafile",
                      [this](const char* arg) { outputMetaFile = arg; return true; },
                      "Write translation metadata (types/symbols) to metafile as JSON");
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

        registerOption("--goto", nullptr,
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
          Use Ultimate Automizer as backend
        */
        // registerOption("--ua", nullptr,
        //                [this](const char*) {
        //                    ultimateAutomizer = true;
        //                    bv2int = true;
        //                    gotoOrIf = false;
        //                    whileLoop = true;
        //                    bitBlasting = true;
        //                    return true; },
        //                "use Ultimate Automizer as the backend");
        registerOption("--ua", nullptr,
                       [this](const char*) {
                           ultimateAutomizer = true;
                           bv2int = true;
                           gotoOrIf = false;
                           whileLoop = true;
                           bitBlasting = false;
                           CpiIfElse = true;
                           return true; },
                       "use Ultimate Automizer as the backend");

        registerOption("--ua2", nullptr,
                       [this](const char*) {
                           ultimateAutomizer = true;
                           bv2int = true;
                           gotoOrIf = false;
                           whileLoop = true;
                           bitBlasting = false;
                           CpiIfElse = true;
                           return true; },
                       "use Ultimate Automizer as the backend");

        registerOption("--ua3", nullptr,
                       [this](const char*) {
                           ultimateAutomizer = true;
                           bv2int = true;
                           gotoOrIf = false;
                           whileLoop = false;
                           bitBlasting = false;
                           return true; },
                       "use Ultimate Automizer as the backend");

        registerOption("--tna", nullptr,
                       [this](const char*) {
                           tna = true;
                           return true; },
                       "use Ultimate Automizer as the backend");

        registerOption("--slicing-vars", "vars",
                       [this](const char* arg) {
                           auto parts = split(std::string(arg), ",");
                           for (auto &p : parts) {
                               slicingVarNames.emplace_back(p);
                           }
                           slicingEnabled = true;
                           return true;
                       },
                       "Comma-separated list of variables for slicing.");

        registerOption("--slicing-keep-vars", "vars",
                       [this](const char* arg) {
                           auto parts = split(std::string(arg), ",");
                           for (auto &p : parts) {
                               slicingKeepVarNames.emplace_back(p);
                           }
                           return true;
                       },
                       "Comma-separated variables to keep in sliced output without using them as slicing roots.");

        registerOption("--fail-fast-register-assert", "reg:mode:constant",
                       [this](const char* arg) {
                           auto parts = split(std::string(arg), ":");
                           if (parts.size() != 3) {
                               return false;
                           }
                           FailFastRegisterAssert item;
                           item.reg_boogie = parts[0].c_str();
                           item.mode = parts[1].c_str();
                           item.constant = parts[2].c_str();
                           if (item.mode != "any" && item.mode != "slot0") {
                               return false;
                           }
                           fail_fast_register_asserts.push_back(item);
                           return true;
                       },
                       "Add an immediate mirror-only assertion after register writes (reg:any|slot0:typed_literal).");

        registerOption("--no-slicing", nullptr,
                       [this](const char*) {
                           slicingEnabled = false;
                           slicingVarNames.clear();
                           return true;
                       },
                       "Disable slicing even if slicing vars are provided.");

        registerOption("--slicing-debug", nullptr,
                       [this](const char*) {
                           slicingDebug = true;
                           return true;
                       },
                       "Enable slicing debug output.");

        registerOption("--slicing-dot-dir", "dir",
                       [this](const char* arg) {
                           slicingDotDir = arg;
                           return true;
                       },
                       "Write CFG/CDG/DDG dot files to directory (must exist).");

        registerOption("--slicing-selftest", "case",
                       [this](const char* arg) {
                           slicingSelftest = true;
                           slicingSelftestCase = arg;
                           return true;
                       },
                       "Run a built-in slicer selftest and exit (e.g., --slicing-selftest=netchain_seq).");

        registerOption("--no-slicing-reg-prune", nullptr,
                       [this](const char*) {
                           slicingRegPrune = false;
                           return true;
                       },
                       "Disable register index pruning during slicing.");

        registerOption("--no-slicing-control-seeds", nullptr,
                       [this](const char*) {
                           slicingControlSeeds = false;
                           return true;
                       },
                       "Disable implicit forwarding/drop/clone/recirc control seeds in the slicer.");

        /*
        */
        registerOption("--p4ltl", "file",
                      [this](const char* arg) { 
                          p4ltlFile = arg;
                          p4ltlSpec = true;
                          return true; },
                      "P4LTL specification for the P4 program");

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
    }
};

using P4VerifyContext = P4CContextWithOptions<P4VerifyOptions>;

#endif
