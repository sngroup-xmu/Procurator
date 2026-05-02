#include "translate.h"
#include "frontends/common/resolveReferences/referenceMap.h"
#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <limits>
#include <sstream>
#include <string>
#include <vector>

Translator::Translator(std::ostream &out, P4VerifyOptions &options,
                       BMV2CmdsAnalyzer* bMV2CmdsAnalyzer, P4::ReferenceMap* refMap)
    : out(out), options(options), bMV2CmdsAnalyzer(bMV2CmdsAnalyzer), refMap(refMap){
    // init main procedure
    currentReturnVar = "";
    inParser = false;
    cstring mainProcedureDeclaration;
    mainProcedure = BoogieProcedure("mainProcedure");
    mainProcedure.addDeclaration("procedure mainProcedure()\n");

    mainProcedure.setImplemented();

    if(options.ultimateAutomizer){
        BoogieProcedure ultimate = BoogieProcedure("ULTIMATE.start");
        ultimate.addDeclaration("procedure ULTIMATE.start()\n");
        ultimate.addStatement("    call mainProcedure();\n");
        ultimate.addSucc("mainProcedure");
        addPred("mainProcedure", "ULTIMATE.start");
        ultimate.setImplemented();
        addProcedure(ultimate);

    // function {:inline true} power_2_51() : int{power_2_50()*power_2_1()}
    }

    havocProcedure = BoogieProcedure("havocProcedure");
    havocProcedure.addDeclaration("procedure {:inline 1} havocProcedure()\n");
    havocProcedure.setImplemented();

    // procedures = std::vector<BoogieProcedure>();

    // declare necessary types and files
    declaration = cstring("type Ref;\n");
    if(options.ultimateAutomizer)
        declaration += cstring("type error=int;\n");
    else
        declaration += cstring("type error=bv1;\n");
    // declaration += "var Heap:HeapType;\n";
    // addGlobalVariables("Heap");
    declaration += "type HeaderStack = [int]Ref;\n";
    declaration += "var last:[HeaderStack]Ref;\n";
    addGlobalVariables("last");
    declaration += "var forward:bool;\n";
    addGlobalVariables("forward");
    declaration += "var isValid:[Ref]bool;\n";
    addGlobalVariables("isValid");
    declaration += "var emit:[Ref]bool;\n";
    addGlobalVariables("emit");
    declaration += "var stack.index:[HeaderStack]int;\n";
    addGlobalVariables("stack.index");
    declaration += "var size:[HeaderStack]int;\n";
    addGlobalVariables("size");
    declaration += "var drop:bool;\n";
    addGlobalVariables("drop");

    havocProcedure.addStatement("    drop := false;\n");
    havocProcedure.addModifiedGlobalVariables("drop");
    havocProcedure.addStatement("    forward := false;\n");
    havocProcedure.addModifiedGlobalVariables("forward");

    declaration += "var p4b_clone_i2e:bool;\n";
    addGlobalVariables("p4b_clone_i2e");
    declaration += "var p4b_clone_e2e:bool;\n";
    addGlobalVariables("p4b_clone_e2e");
    declaration += "var p4b_clone_i2i:bool;\n";
    addGlobalVariables("p4b_clone_i2i");
    declaration += "var p4b_recirculate:bool;\n";
    addGlobalVariables("p4b_recirculate");
    mainProcedure.addFrontStatement("    p4b_clone_i2e := false;\n");
    mainProcedure.addModifiedGlobalVariables("p4b_clone_i2e");
    mainProcedure.addFrontStatement("    p4b_clone_e2e := false;\n");
    mainProcedure.addModifiedGlobalVariables("p4b_clone_e2e");
    mainProcedure.addFrontStatement("    p4b_clone_i2i := false;\n");
    mainProcedure.addModifiedGlobalVariables("p4b_clone_i2i");
    mainProcedure.addFrontStatement("    p4b_recirculate := false;\n");
    mainProcedure.addModifiedGlobalVariables("p4b_recirculate");

    headers = std::map<cstring, const IR::Type_Header*>();
    structs = std::map<cstring, const IR::Type_Struct*>();
    tables = std::map<cstring, const IR::P4Table*>();
    instances = std::vector<const IR::Declaration_Instance*>();
    typeDefs = std::map<cstring, int>();
    // globalVariables = std::set<cstring>();

    maxBitvectorSize = -1;

    addNecessaryProcedures();

    ltlTranslator = new P4LTLTranslator(this);
}

BoogieProcedure Translator::getMainProcedure(){
    return mainProcedure;
}

void Translator::addNecessaryProcedures(){
    if(options.gotoOrIf){
        BoogieProcedure extract = BoogieProcedure("packet_in.extract");
        extract.addDeclaration("procedure packet_in.extract(header:Ref);\n");
        extract.addDeclaration("    ensures (isValid[header] == true);\n");
        extract.addModifiedGlobalVariables("isValid");
        addProcedure(extract);
    }

    BoogieProcedure setValid = BoogieProcedure("setValid");
    setValid.addDeclaration("procedure {:inline 1} setValid(header:Ref);\n");
    addProcedure(setValid);

    BoogieProcedure setInvalid = BoogieProcedure("setInvalid");
    setInvalid.addDeclaration("procedure {:inline 1} setInvalid(header:Ref);\n");
    setInvalid.addDeclaration("    ensures (isValid[header] == false);\n");
    setInvalid.addModifiedGlobalVariables("isValid");
    addProcedure(setInvalid);

    BoogieProcedure mark_to_drop = BoogieProcedure("mark_to_drop");
    mark_to_drop.addDeclaration("procedure mark_to_drop();\n");
    mark_to_drop.addDeclaration("    ensures drop==true;\n");
    mark_to_drop.addModifiedGlobalVariables("drop");
    addProcedure(mark_to_drop);

    // add accept & reject
    BoogieProcedure accept = BoogieProcedure("accept");
    accept.addDeclaration("procedure {:inline 1} accept()\n");
    accept.setImplemented();
    addProcedure(accept);

    BoogieProcedure reject = BoogieProcedure("reject");
    reject.addDeclaration("procedure reject();\n");
    reject.addDeclaration("    ensures drop==true;\n");
    reject.addModifiedGlobalVariables("drop");
    addProcedure(reject);

}

void Translator::addProcedure(BoogieProcedure procedure){
    if(procedures.find(procedure.getName()) != procedures.end())
        return;
    // procedures.push_back(&procedure);
    procedures[procedure.getName()] = procedure;
}

void Translator::addDeclaration(cstring decl){
    if (!options.slicingEnabled || options.slicingKeepVars.empty()) {
        declaration += decl;
        std::istringstream iss(decl.c_str());
        std::string line;
        while (std::getline(iss, line)) {
            size_t i = 0;
            while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) i++;
            if (line.compare(i, 4, "var ") == 0) {
                i += 4;
                size_t colon = line.find(':', i);
                if (colon != std::string::npos) {
                    std::string name = line.substr(i, colon - i);
                    while (!name.empty() && (name.back() == ' ' || name.back() == '\t')) name.pop_back();
                    if (!name.empty()) {
                        emittedVarDecls.insert(cstring(name));
                    }
                }
            }
        }
    } else {
        std::istringstream iss(decl.c_str());
        std::string line;
        std::string filtered;
        while (std::getline(iss, line)) {
            std::string orig = line;
            // Trim leading whitespace
            size_t i = 0;
            while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) i++;
            if (line.compare(i, 4, "var ") == 0) {
                i += 4;
                size_t colon = line.find(':', i);
                if (colon != std::string::npos) {
                    std::string name = line.substr(i, colon - i);
                    while (!name.empty() && (name.back() == ' ' || name.back() == '\t')) name.pop_back();
                    if (!shouldKeepVar(name)) {
                        continue;
                    }
                    if (!name.empty()) {
                        emittedVarDecls.insert(cstring(name));
                    }
                }
            }
            filtered += orig;
            filtered.push_back('\n');
        }
        declaration += filtered;
    }
    // Extract var decls: "var <name>:<type>;"
    // This allows external tools (dslc) to type-check DSL assumes/asserts without re-parsing Boogie.
    std::istringstream iss(decl.c_str());
    std::string line;
    while (std::getline(iss, line)) {
        // Trim leading whitespace
        size_t i = 0;
        while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) i++;
        if (line.compare(i, 4, "var ") != 0) continue;
        i += 4;
        // read name until ':'
        size_t colon = line.find(':', i);
        if (colon == std::string::npos) continue;
        std::string name = line.substr(i, colon - i);
        // strip trailing whitespace in name
        while (!name.empty() && (name.back() == ' ' || name.back() == '\t')) name.pop_back();
        // read type until ';'
        size_t semi = line.find(';', colon + 1);
        if (semi == std::string::npos) continue;
        std::string type = line.substr(colon + 1, semi - (colon + 1));
        // strip whitespace in type
        size_t ts = 0;
        while (ts < type.size() && (type[ts] == ' ' || type[ts] == '\t')) ts++;
        size_t te = type.size();
        while (te > ts && (type[te - 1] == ' ' || type[te - 1] == '\t')) te--;
        type = type.substr(ts, te - ts);
        if (!name.empty() && !type.empty()) {
            varTypes[cstring(name)] = cstring(type);
        }
    }
}

void Translator::addFunction(cstring op, cstring opbuiltin, cstring typeName, cstring returnType){
    cstring functionName = op+".";
    if(returnType!="bool")
        functionName += returnType;
    else
        functionName += typeName;
    if(functions.find(functionName)==functions.end()){
        functions.insert(functionName);
        cstring res;
        res = "\nfunction {:bvbuiltin \""+opbuiltin+"\"} "+functionName;
        if(returnType!="bool")
            res += "(left:"+returnType+", right:"+returnType+") returns("+returnType+");\n";
        else
            res += "(left:"+typeName+", right:"+typeName+") returns("+returnType+");\n";
        addDeclaration(res);
    }
}

void Translator::addFunction(cstring funcName, cstring func){
    if(functions.find(funcName)==functions.end()){
        functions.insert(funcName);
        addDeclaration(func);
    }
}

bool Translator::shouldKeepVar(const std::string& name) const {
    if (!options.slicingEnabled || options.slicingKeepVars.empty()) {
        return true;
    }
    if (forcedKeepVars.count(cstring(name)) > 0) {
        return true;
    }
    // Always keep core globals required by the Boogie model.
    static const std::set<std::string> always = {
        "forward",
        "drop",
        "isValid",
        "emit",
        "last",
        "stack.index",
        "size",
        "standard_metadata.egress_port",
        // TNA/TNA-like pipelines may gate mirroring on this intrinsic metadata field.
        // Keep it even when slicing criteria do not mention it, to avoid generating
        // ill-typed Boogie when the translator models `mirror.emit` using it.
        "ig_intr_dprsr_md.mirror_type"
    };
    if (always.count(name)) {
        return true;
    }
    if (name.rfind("__ra_", 0) == 0 || name.find("__unused") != std::string::npos) {
        return true;
    }
    if (name.find("ucast_egress_port") != std::string::npos ||
        name.find("egress_port") != std::string::npos) {
        return true;
    }
    if (options.slicingKeepVars.count(cstring(name)) > 0) {
        return true;
    }
    std::string nameStr = name;
    if (options.slicingKeepVars.count(cstring(nameStr + "_0")) > 0) {
        return true;
    }
    if (nameStr.size() > 2 && nameStr.rfind("_0") == nameStr.size() - 2) {
        std::string base = nameStr.substr(0, nameStr.size() - 2);
        if (options.slicingKeepVars.count(cstring(base)) > 0) {
            return true;
        }
    }
    // If slicing kept a base object (e.g., a header temporary like `mirror_md_0`),
    // conservatively keep all of its derived field/map declarations produced by
    // the Boogie lowering (e.g., `mirror_md_0.pkt_type`).
    //
    // The slicer works on P4 IR where fields are Member nodes rather than flat
    // variable names; it may keep the base but not record every lowered field
    // variable name. Dropping these declarations makes the generated Boogie
    // ill-typed even when the corresponding statements were kept.
    auto baseKept = [&](const std::string& base) -> bool {
        if (base.empty()) {
            return false;
        }
        if (options.slicingKeepVars.count(cstring(base)) > 0) {
            return true;
        }
        if (options.slicingKeepVars.count(cstring(base + "_0")) > 0) {
            return true;
        }
        if (base.size() > 2 && base.rfind("_0") == base.size() - 2) {
            std::string b = base.substr(0, base.size() - 2);
            if (options.slicingKeepVars.count(cstring(b)) > 0) {
                return true;
            }
        }
        return false;
    };
    {
        static const std::vector<std::string> registerMirrorSuffixes = {
            "__last_index",
            "__last_value",
            "__wrote_any",
            "__wrote_index0",
            "__last0_value"
        };
        for (const auto& suffix : registerMirrorSuffixes) {
            if (nameStr.size() <= suffix.size()) {
                continue;
            }
            if (nameStr.rfind(suffix) != nameStr.size() - suffix.size()) {
                continue;
            }
            std::string base = nameStr.substr(0, nameStr.size() - suffix.size());
            if (baseKept(base) ||
                options.slicingRegMaxIndex.find(cstring(base)) != options.slicingRegMaxIndex.end() ||
                options.slicingRegMaxIndex.find(cstring(base + "_0")) != options.slicingRegMaxIndex.end()) {
                return true;
            }
        }
    }
    {
        size_t dot = nameStr.find('.');
        if (dot != std::string::npos) {
            std::string base = nameStr.substr(0, dot);
            if (baseKept(base)) {
                return true;
            }
        }
        size_t bracket = nameStr.find('[');
        if (bracket != std::string::npos) {
            std::string base = nameStr.substr(0, bracket);
            if (baseKept(base)) {
                return true;
            }
        }
    }
    for (const auto& k : options.slicingKeepVars) {
        std::string key = k.c_str();
        if (key.empty()) {
            continue;
        }
        // Keep parent objects when one of their children is required (existing behavior).
        if (key.rfind(name + ".", 0) == 0) {
            return true;
        }
        if (key.rfind(name + "[", 0) == 0) {
            return true;
        }
        // Keep lowered child declarations when slicer keeps only a parent object
        // (common for JSON IR parser/header references, e.g., keep `hdr.albion_data`
        // should retain emitted `hdr.albion_data.data_*` fields).
        if (name.rfind(key + ".", 0) == 0) {
            return true;
        }
        if (name.rfind(key + "[", 0) == 0) {
            return true;
        }
    }
    if (options.slicingRegMaxIndex.find(cstring(name)) != options.slicingRegMaxIndex.end()) {
        return true;
    }
    if (options.slicingRegMaxIndex.find(cstring(nameStr + "_0")) != options.slicingRegMaxIndex.end()) {
        return true;
    }
    if (nameStr.size() > 2 && nameStr.rfind("_0") == nameStr.size() - 2) {
        std::string base = nameStr.substr(0, nameStr.size() - 2);
        if (options.slicingRegMaxIndex.find(cstring(base)) != options.slicingRegMaxIndex.end()) {
            return true;
        }
    }
    if (options.slicingRegHasNonConst.count(cstring(name)) > 0) {
        return true;
    }
    if (options.slicingRegHasNonConst.count(cstring(nameStr + "_0")) > 0) {
        return true;
    }
    if (nameStr.size() > 2 && nameStr.rfind("_0") == nameStr.size() - 2) {
        std::string base = nameStr.substr(0, nameStr.size() - 2);
        if (options.slicingRegHasNonConst.count(cstring(base)) > 0) {
            return true;
        }
    }
    for (const auto& table : options.slicingKeepTables) {
        std::string prefix = table.c_str();
        prefix.push_back('.');
        if (name.rfind(prefix, 0) == 0) {
            return true;
        }
    }
    for (const auto& k : options.slicingKeepVars) {
        std::string key = k.c_str();
        if (!key.empty() && name.size() > key.size() + 1 &&
            name.compare(name.size() - key.size(), key.size(), key) == 0 &&
            name[name.size() - key.size() - 1] == '_') {
            return true;
        }
    }
    return false;
}

static std::string sanitizeDeclName(const std::string &raw) {
    std::string out;
    out.reserve(raw.size());
    for (char c : raw) {
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9') || c == '_') {
            out.push_back(c);
        } else {
            out.push_back('_');
        }
    }
    if (out.empty()) {
        return out;
    }
    if (out[0] >= '0' && out[0] <= '9') {
        out.insert(out.begin(), '_');
    }
    return out;
}

void Translator::recordDeclName(const IR::IDeclaration* decl) {
    if (decl == nullptr) {
        return;
    }
    cstring orig = decl->getName().name;
    cstring control = decl->controlPlaneName();
    if (control.isNullOrEmpty()) {
        return;
    }
    std::string sanitized = sanitizeDeclName(control.c_str());
    if (sanitized.empty()) {
        return;
    }
    cstring renamed = cstring(sanitized);
    if (renamed == orig) {
        return;
    }
    if (declRenameTargets.count(renamed) > 0) {
        return;
    }
    declRenames[orig] = renamed;
    declRenameTargets.insert(renamed);
}

static std::string externBaseTypeName(const IR::Type* type) {
    if (type == nullptr) {
        return "";
    }
    if (auto typeName = type->to<IR::Type_Name>()) {
        return typeName->path->name.toString().c_str();
    }
    if (auto typeSpec = type->to<IR::Type_Specialized>()) {
        if (auto base = typeSpec->baseType->to<IR::Type_Name>()) {
            return base->path->name.toString().c_str();
        }
    }
    if (auto typeSpec = type->to<IR::Type_SpecializedCanonical>()) {
        if (auto base = typeSpec->baseType->to<IR::Type_Name>()) {
            return base->path->name.toString().c_str();
        }
    }
    if (auto typeExtern = type->to<IR::Type_Extern>()) {
        return typeExtern->name.toString().c_str();
    }
    return "";
}

static const IR::Type* specializedTypeArg(const IR::Type* type, size_t idx) {
    if (type == nullptr) {
        return nullptr;
    }
    if (auto typeSpec = type->to<IR::Type_Specialized>()) {
        if (typeSpec->arguments != nullptr && typeSpec->arguments->size() > idx) {
            return (*typeSpec->arguments)[idx];
        }
    }
    if (auto typeSpec = type->to<IR::Type_SpecializedCanonical>()) {
        if (typeSpec->arguments != nullptr && typeSpec->arguments->size() > idx) {
            return (*typeSpec->arguments)[idx];
        }
    }
    return nullptr;
}

void Translator::recordHashExtern(const IR::Declaration_Instance* instance, cstring name) {
    if (instance == nullptr || name == "") {
        return;
    }
    if (externBaseTypeName(instance->type) != "Hash") {
        return;
    }
    cstring retType = "";
    if (const IR::Type* arg0 = specializedTypeArg(instance->type, 0)) {
        retType = inferBoogieType(arg0, "");
        if (retType == "") {
            retType = translate(arg0);
        }
    }
    if (retType != "") {
        hashExternReturnTypes[name] = retType;
    }
}

void Translator::recordRandomExtern(const IR::Declaration_Instance* instance, cstring name) {
    if (instance == nullptr || name == "") {
        return;
    }
    if (externBaseTypeName(instance->type) != "Random") {
        return;
    }
    RandomExternInfo info;
    if (const IR::Type* arg0 = specializedTypeArg(instance->type, 0)) {
        info.retType = inferBoogieType(arg0, "");
        if (info.retType == "") {
            info.retType = translate(arg0);
        }
    }
    if (info.retType == "") {
        info.retType = "int";
    }
    if (instance->arguments != nullptr && instance->arguments->size() >= 2) {
        info.lo = translate((*instance->arguments)[0]);
        info.hi = translate((*instance->arguments)[1]);
    }
    randomExterns[name] = info;
}

void Translator::analyzeProgram(const IR::P4Program *program){
    auto recordStructValueType = [&](const IR::Type* type) {
        if (type == nullptr) {
            return;
        }
        if (auto typeName = type->to<IR::Type_Name>()) {
            cstring name = translate(typeName->path);
            if (structs.find(name) != structs.end()) {
                bitvectorStructs.insert(name);
            }
            return;
        }
        if (auto typeStruct = type->to<IR::Type_Struct>()) {
            bitvectorStructs.insert(typeStruct->name.toString());
        }
    };
    class TypeCollector : public Inspector {
     public:
        Translator* t;
        explicit TypeCollector(Translator* t) : t(t) {}
        bool preorder(const IR::Type_Header* typeHeader) override {
            t->headers[typeHeader->name.toString()] = typeHeader;
            return false;
        }
        bool preorder(const IR::Type_Struct* typeStruct) override {
            t->structs[typeStruct->name.toString()] = typeStruct;
            return false;
        }
    };
    TypeCollector collector(this);
    program->apply(collector);

    class DeclNameCollector : public Inspector {
     public:
        Translator* t;
        explicit DeclNameCollector(Translator* t) : t(t) {}
        bool preorder(const IR::Declaration_Instance* instance) override {
            t->recordDeclName(instance);
            return false;
        }
    };
    DeclNameCollector nameCollector(this);
    program->apply(nameCollector);

    for(auto obj:program->objects){
        if (auto typeHeader = obj->to<IR::Type_Header>()) {
            headers[typeHeader->name.toString()] = typeHeader;
        }
        else if (auto typeStruct = obj->to<IR::Type_Struct>()) {
            structs[typeStruct->name.toString()] = typeStruct;
        }
        else if (auto p4Control = obj->to<IR::P4Control>()){
            for(auto controlLocal:p4Control->controlLocals){
                if (auto p4Action = controlLocal->to<IR::P4Action>()){
                    recordDeclName(p4Action);
                    actions[translate(p4Action->name)] = p4Action;
                }
                else if(auto p4Table = controlLocal->to<IR::P4Table>()){
                    recordDeclName(p4Table);
                    tables[translate(p4Table->name)] = p4Table;
                }
                else if (auto inst = controlLocal->to<IR::Declaration_Instance>()) {
                    recordHashExtern(inst, translate(inst->getName()));
                    recordRandomExtern(inst, translate(inst->getName()));
                    std::string base = externBaseTypeName(inst->type);
                    if (base == "RegisterAction" || base == "DirectRegisterAction") {
                        if (!inst->arguments->empty()) {
                            if (auto argExpr = (*inst->arguments)[0]->expression->to<IR::PathExpression>()) {
                                forcedKeepVars.insert(translate(argExpr->path->name));
                            }
                        }
                    }
                    if (base == "register" || base == "Register" ||
                        base == "RegisterAction" || base == "DirectRegisterAction") {
                        if (auto typeSpec = inst->type->to<IR::Type_Specialized>()) {
                            if (!typeSpec->arguments->empty()) {
                                recordStructValueType((*typeSpec->arguments)[0]);
                            }
                        }
                    }
                }
            }
        }
        else if (auto instance = obj->to<IR::Declaration_Instance>()){
            instances.push_back(instance);
            recordDeclName(instance);
            recordHashExtern(instance, translate(instance->getName()));
            recordRandomExtern(instance, translate(instance->getName()));
            std::string base = externBaseTypeName(instance->type);
            if (base == "RegisterAction" || base == "DirectRegisterAction") {
                if (!instance->arguments->empty()) {
                    if (auto argExpr = (*instance->arguments)[0]->expression->to<IR::PathExpression>()) {
                        forcedKeepVars.insert(translate(argExpr->path->name));
                    }
                }
            }
            if (base == "register" || base == "Register" ||
                base == "RegisterAction" || base == "DirectRegisterAction") {
                if (auto typeSpec = instance->type->to<IR::Type_Specialized>()) {
                    if (!typeSpec->arguments->empty()) {
                        recordStructValueType((*typeSpec->arguments)[0]);
                    }
                }
            }
        }
    }

    // Precompute effective action parameter directions.
    //
    // Some P4 programs (e.g., DDOSD) use actions as helper “functions” that write to
    // their parameters (out/inout style). Depending on the p4c pipeline, those
    // directions may be dropped, but the action body still assigns to the parameter.
    // Ultimate’s Boogie frontend rejects assignments to in-parameters, so we
    // conservatively treat any parameter that is written in the action body as InOut.
    actionParamDirections.clear();
    class ActionWriteCollector : public Inspector {
     public:
        Translator* t;
        const std::unordered_set<cstring>* params;
        std::unordered_set<cstring> written;
        ActionWriteCollector(Translator* t, const std::unordered_set<cstring>* params)
            : t(t), params(params) {}

        void noteBaseIfParam(const IR::Expression* expr) {
            const IR::Expression* cur = expr;
            while (cur != nullptr) {
                if (auto pe = cur->to<IR::PathExpression>()) {
                    cstring base = t->translate(pe->path);
                    if (params->count(base) > 0) {
                        written.insert(base);
                    }
                    return;
                }
                if (auto member = cur->to<IR::Member>()) {
                    cur = member->expr;
                    continue;
                }
                if (auto arrayIndex = cur->to<IR::ArrayIndex>()) {
                    cur = arrayIndex->left;
                    continue;
                }
                if (auto cast = cur->to<IR::Cast>()) {
                    cur = cast->expr;
                    continue;
                }
                return;
            }
        }

        bool preorder(const IR::AssignmentStatement* stmt) override {
            noteBaseIfParam(stmt->left);
            return true;
        }
    };

    for (const auto& kv : actions) {
        const cstring actionName = kv.first;
        const IR::P4Action* action = kv.second;
        if (action == nullptr || action->parameters == nullptr) {
            continue;
        }

        std::unordered_set<cstring> paramNames;
        for (auto param : action->parameters->parameters) {
            paramNames.insert(translate(param->name));
        }
        ActionWriteCollector collector(this, &paramNames);
        if (action->body != nullptr) {
            action->body->apply(collector);
        }

        std::vector<IR::Direction> dirs;
        dirs.reserve(action->parameters->parameters.size());
        for (auto param : action->parameters->parameters) {
            IR::Direction dir = param->direction;
            cstring name = translate(param->name);
            if (dir != IR::Direction::Out && dir != IR::Direction::InOut &&
                collector.written.count(name) > 0) {
                dir = IR::Direction::InOut;
            }
            dirs.push_back(dir);
        }
        actionParamDirections[actionName] = std::move(dirs);
    }
}

cstring Translator::remapName(cstring name) const {
    auto it = declRenames.find(name);
    if (it != declRenames.end()) {
        return it->second;
    }
    return name;
}

const IR::Type_Header* Translator::resolveHeaderType(const IR::Type* type) const {
    if (type == nullptr) {
        return nullptr;
    }
    if (auto typeHeader = type->to<IR::Type_Header>()) {
        return typeHeader;
    }
    if (auto typeName = type->to<IR::Type_Name>()) {
        cstring rawName = typeName->path->name;
        auto it = headers.find(rawName);
        if (it != headers.end()) {
            return it->second;
        }
        cstring remapped = remapName(rawName);
        it = headers.find(remapped);
        if (it != headers.end()) {
            return it->second;
        }
        return nullptr;
    }
    if (auto typeTypedef = type->to<IR::Type_Typedef>()) {
        return resolveHeaderType(typeTypedef->type);
    }
    if (auto typeSpec = type->to<IR::Type_Specialized>()) {
        return resolveHeaderType(typeSpec->baseType);
    }
    if (auto typeSpec = type->to<IR::Type_SpecializedCanonical>()) {
        return resolveHeaderType(typeSpec->baseType);
    }
    return nullptr;
}

cstring Translator::translate(IR::ID id){
    return remapName(id.name);
}

void Translator::incIndent(){ indent++; }
void Translator::decIndent(){ if(indent>0) indent--; }
cstring Translator::getIndent(){
    cstring res("");
    for(int i = 0; i < indent; i++) res += "    ";
    return res;
}

void Translator::incSwitchStatementCount(){ switchStatementCount++; }
cstring Translator::getSwitchStatementCount(){
    std::stringstream ss;
    ss << switchStatementCount;
    return ss.str();
}

void Translator::addGlobalVariables(cstring variable){
    globalVariables.insert(variable);
}

bool Translator::isGlobalVariable(cstring variable){
    return globalVariables.find(variable)!=globalVariables.end();
}

void Translator::updateModifiedVariables(cstring variable){
    if (currentProcedure != nullptr) {
        cstring base = variable;
        std::string s = variable.c_str();
        size_t dot = s.find('.');
        size_t bracket = s.find('[');
        size_t cut = std::min(dot == std::string::npos ? s.size() : dot,
                              bracket == std::string::npos ? s.size() : bracket);
        if (cut < s.size()) {
            base = cstring(s.substr(0, cut));
        }
        if (currentProcedure->parameters.find(variable) != currentProcedure->parameters.end() ||
            currentProcedure->parameters.find(base) != currentProcedure->parameters.end() ||
            currentProcedure->declarationVariables.find(variable) != currentProcedure->declarationVariables.end() ||
            currentProcedure->declarationVariables.find(base) != currentProcedure->declarationVariables.end() ||
            currentProcedure->hasLocalVariables(variable) ||
            currentProcedure->hasLocalVariables(base)) {
            return;
        }
    }
    currentProcedure->addModifiedGlobalVariables(variable);
}

void Translator::addRegisterWriteModifiedVariables(const cstring& regName) {
    if (currentProcedure == nullptr || regName == "") {
        return;
    }
    currentProcedure->addModifiedGlobalVariables(regName);
    currentProcedure->addModifiedGlobalVariables(regName+"__last_index");
    currentProcedure->addModifiedGlobalVariables(regName+"__last_value");
    currentProcedure->addModifiedGlobalVariables(regName+"__wrote_any");
    currentProcedure->addModifiedGlobalVariables(regName+"__wrote_index0");
    currentProcedure->addModifiedGlobalVariables(regName+"__last0_value");
}

void Translator::addPred(cstring proc, cstring predProc){
    // if(pred[proc]==nullptr)
    //     pred[proc] = std::vector<cstring>(0);
    pred[proc].push_back(predProc);
}

void Translator::setP4LTLSpec(cstring key, P4LTL::AstNode* root){
    p4ltlSpec[key].push_back(root);
}

void Translator::setP4LTLFreeVars(cstring decl){
    ltlTranslator->createFreeVariables(decl);
}

void Translator::updateMaxBitvectorSize(int size){
    maxBitvectorSize = (maxBitvectorSize > size) ? maxBitvectorSize : size;
}

void Translator::updateMaxBitvectorSize(const IR::Type_Bits *typeBits){
    updateMaxBitvectorSize(typeBits->size);
}

void Translator::updateVariableSize(cstring name, int n){
    // std::cout << "update size: " << name << " " << n << std::endl;
    sizes[name] = n;
}

int Translator::getSize(cstring name){
    if(sizes.find(name) != sizes.end()) return sizes[name];
    if (currentProcedure != nullptr) {
        auto pit = currentProcedure->parameters.find(name);
        if (pit != currentProcedure->parameters.end()) {
            return pit->second;
        }
        auto vit = currentProcedure->declarationVariables.find(name);
        if (vit != currentProcedure->declarationVariables.end()) {
            return vit->second;
        }
    }
    return -1;
}

static std::string sanitizeTypeForVar(const std::string &typeName) {
    std::string out;
    out.reserve(typeName.size());
    for (char c : typeName) {
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9')) {
            out.push_back(c);
        } else {
            out.push_back('_');
        }
    }
    if (!out.empty() && out[0] >= '0' && out[0] <= '9') {
        out.insert(out.begin(), '_');
    }
    return out;
}

cstring Translator::inferBoogieType(const IR::Type *type, cstring exprText){
    cstring ret = "";
    if (type != nullptr) {
        ret = translate(type);
        if (ret == "") {
            if (type->to<IR::Type_Header>() != nullptr) {
                ret = "Ref";
            } else if (type->to<IR::Type_Stack>() != nullptr) {
                ret = "HeaderStack";
            } else if (type->to<IR::Type_Boolean>() != nullptr) {
                ret = "bool";
            }
        }
    }
    if (ret == "" && exprText != "" && varTypes.find(exprText) != varTypes.end()) {
        ret = varTypes[exprText];
    }
    return ret;
}

cstring Translator::getOrCreateUnusedVar(cstring typeName){
    std::string clean = sanitizeTypeForVar(typeName.c_str());
    cstring varName = "__unused_" + cstring(clean);
    if (!isGlobalVariable(varName)) {
        addDeclaration("var "+varName+":"+typeName+";\n");
        addGlobalVariables(varName);
        if (typeName == "bool") {
            updateVariableSize(varName, 0);
        } else if (typeName.find("bv") == 0) {
            std::string s = typeName.c_str();
            int size = 0;
            std::stringstream ss(s.substr(2));
            ss >> size;
            if (size > 0) {
                updateVariableSize(varName, size);
            }
        } else if (typeDefs.find(typeName) != typeDefs.end()) {
            updateVariableSize(varName, typeDefs[typeName]);
        }
    }
    return varName;
}

cstring Translator::getOrCreateNamedVar(const std::string& name, cstring typeName){
    cstring varName = cstring(name);
    if (!isGlobalVariable(varName)) {
        addDeclaration("var "+varName+":"+typeName+";\n");
        addGlobalVariables(varName);
        if (typeName == "bool") {
            updateVariableSize(varName, 0);
        } else if (typeName.find("bv") == 0) {
            std::string s = typeName.c_str();
            int size = 0;
            std::stringstream ss(s.substr(2));
            ss >> size;
            if (size > 0) {
                updateVariableSize(varName, size);
            }
        } else if (typeDefs.find(typeName) != typeDefs.end()) {
            updateVariableSize(varName, typeDefs[typeName]);
        }
    }
    return varName;
}

cstring Translator::getOrCreateFreshVar(const std::string& prefix, cstring typeName){
    std::string cleanPrefix = sanitizeTypeForVar(prefix);
    std::string name;
    do {
        name = "__" + cleanPrefix + "_" + std::to_string(freshVarCount++);
    } while (isGlobalVariable(cstring(name)));
    return getOrCreateNamedVar(name, typeName);
}

int Translator::getTypeBitwidth(const IR::Type *type) {
    if (type == nullptr) {
        return -1;
    }
    if (auto typeBits = type->to<IR::Type_Bits>()) {
        return typeBits->size;
    }
    if (auto typeBool = type->to<IR::Type_Boolean>()) {
        (void)typeBool;
        return 1;
    }
    if (auto typeName = type->to<IR::Type_Name>()) {
        cstring name = translate(typeName->path);
        auto it = typeDefs.find(name);
        if (it != typeDefs.end()) {
            return it->second;
        }
        auto sit = structBitwidths.find(name);
        if (sit != structBitwidths.end()) {
            return sit->second;
        }
        auto structIt = structs.find(name);
        if (structIt != structs.end()) {
            ensureStructLayout(structIt->second);
            auto sit2 = structBitwidths.find(name);
            if (sit2 != structBitwidths.end()) {
                return sit2->second;
            }
        }
    }
    if (auto typeStruct = type->to<IR::Type_Struct>()) {
        ensureStructLayout(typeStruct);
        auto it = structBitwidths.find(typeStruct->name.toString());
        if (it != structBitwidths.end()) {
            return it->second;
        }
    }
    return -1;
}

void Translator::ensureStructLayout(const IR::Type_Struct *typeStruct) {
    if (typeStruct == nullptr) {
        return;
    }
    cstring name = typeStruct->name.toString();
    if (bitvectorStructs.count(name) == 0) {
        return;
    }
    if (structBitwidths.find(name) != structBitwidths.end()) {
        return;
    }
    int total = 0;
    for (const auto field : typeStruct->fields) {
        int width = getTypeBitwidth(field->type);
        if (width <= 0) {
            width = 1;
        }
        total += width;
    }
    structBitwidths[name] = total;
    int offset = total;
    for (const auto field : typeStruct->fields) {
        int width = getTypeBitwidth(field->type);
        if (width <= 0) {
            width = 1;
        }
        offset -= width;
        structFieldRanges[name][field->name.toString()] = std::make_pair(offset + width - 1, offset);
    }
}

bool Translator::getStructFieldRange(const IR::Expression *baseExpr, const cstring &field,
                                     int &totalBits, int &hi, int &lo, cstring &baseName) {
    if (baseExpr == nullptr) {
        return false;
    }
    const IR::Type *baseType = baseExpr->type;
    cstring structName = nullptr;
    if (auto typeStruct = baseType->to<IR::Type_Struct>()) {
        structName = typeStruct->name.toString();
    } else if (auto typeName = baseType->to<IR::Type_Name>()) {
        structName = translate(typeName->path);
    }
    if (structName == nullptr) {
        return false;
    }
    if (bitvectorStructs.count(structName) == 0) {
        return false;
    }
    auto it = structs.find(structName);
    if (it == structs.end()) {
        return false;
    }
    ensureStructLayout(it->second);
    auto rangeIt = structFieldRanges.find(structName);
    if (rangeIt == structFieldRanges.end()) {
        return false;
    }
    auto fieldIt = rangeIt->second.find(field);
    if (fieldIt == rangeIt->second.end()) {
        return false;
    }
    auto totalIt = structBitwidths.find(structName);
    if (totalIt == structBitwidths.end()) {
        return false;
    }
    totalBits = totalIt->second;
    hi = fieldIt->second.first;
    lo = fieldIt->second.second;
    baseName = translate(baseExpr);
    return true;
}

bool Translator::getStructFieldRangeByName(const cstring &baseName, const cstring &structName,
                                           const cstring &field, int &totalBits, int &hi, int &lo) {
    if (baseName == nullptr || structName == nullptr) {
        return false;
    }
    if (bitvectorStructs.count(structName) == 0) {
        return false;
    }
    auto it = structs.find(structName);
    if (it == structs.end()) {
        return false;
    }
    ensureStructLayout(it->second);
    auto rangeIt = structFieldRanges.find(structName);
    if (rangeIt == structFieldRanges.end()) {
        return false;
    }
    auto fieldIt = rangeIt->second.find(field);
    if (fieldIt == rangeIt->second.end()) {
        return false;
    }
    auto totalIt = structBitwidths.find(structName);
    if (totalIt == structBitwidths.end()) {
        return false;
    }
    totalBits = totalIt->second;
    hi = fieldIt->second.first;
    lo = fieldIt->second.second;
    return true;
}

bool Translator::getParamStructName(const cstring &baseName, cstring &structName) const {
    if (currentProcedure == nullptr) {
        return false;
    }
    auto pit = procParamStructTypes.find(currentProcedure->getName());
    if (pit == procParamStructTypes.end()) {
        return false;
    }
    auto it = pit->second.find(baseName);
    if (it == pit->second.end()) {
        return false;
    }
    structName = it->second;
    return true;
}

const IR::Function* Translator::findRegisterActionApply(const IR::Declaration_Instance* instance) const {
    if (instance == nullptr || instance->initializer == nullptr) {
        return nullptr;
    }
    if (auto block = instance->initializer->to<IR::BlockStatement>()) {
        for (auto comp : block->components) {
            if (auto func = comp->to<IR::Function>()) {
                if (func->name == "apply") {
                    return func;
                }
            }
        }
    }
    return nullptr;
}

void Translator::translateRegisterActionApply(const IR::Function* func, const cstring& procName) {
    if (func == nullptr) {
        return;
    }
    BoogieProcedure applyProc = BoogieProcedure(procName);
    BoogieProcedure* prevProc = currentProcedure;
    currentProcedure = &applyProc;
    cstring prevReturnVar = currentReturnVar;
    currentReturnVar = "";
    applyProc.addDeclaration("\n// RegisterAction "+procName+"\n");
    std::vector<cstring> inNames;
    std::vector<cstring> outNames;
    std::vector<cstring> outTypes;
    std::vector<cstring> localNames;
    std::vector<cstring> localTypes;
    for (auto parameter : func->type->parameters->parameters) {
        cstring baseName = translate(parameter->name);
        cstring typeName = translate(parameter->type);
        cstring inName = baseName + "_in";
        cstring outName = baseName + "_out";
        inNames.push_back(inName);
        outNames.push_back(outName);
        outTypes.push_back(typeName);
        localNames.push_back(baseName);
        localTypes.push_back(typeName);
        if (auto typeBits = parameter->type->to<IR::Type_Bits>()) {
            updateMaxBitvectorSize(typeBits);
        }
        cstring structName = nullptr;
        if (auto typeStruct = parameter->type->to<IR::Type_Struct>()) {
            structName = typeStruct->name.toString();
        } else if (auto typeNameIR = parameter->type->to<IR::Type_Name>()) {
            cstring typeAlias = translate(typeNameIR->path);
            if (structs.find(typeAlias) != structs.end()) {
                structName = typeAlias;
            }
        }
        if (structName != nullptr && bitvectorStructs.count(structName) > 0) {
            procParamStructTypes[procName][baseName] = structName;
        }
    }
    if (func->type->returnType != nullptr && !func->type->returnType->is<IR::Type_Void>()) {
        cstring retTypeName = translate(func->type->returnType);
        cstring retOutName = "ret_out";
        outNames.push_back(retOutName);
        outTypes.push_back(retTypeName);
        currentReturnVar = retOutName;
        if (auto typeBits = func->type->returnType->to<IR::Type_Bits>()) {
            updateMaxBitvectorSize(typeBits);
        }
    }
    applyProc.addDeclaration("procedure {:inline 1} "+procName+"(");
    for (size_t i = 0; i < inNames.size(); i++) {
        applyProc.addDeclaration(inNames[i]+":"+localTypes[i]);
        int width = -1;
        if (localTypes[i] == "bool") {
            width = 0;
        } else if (localTypes[i].find("bv") == 0) {
            std::string typeStr = localTypes[i].c_str();
            std::stringstream ss(typeStr.substr(2));
            ss >> width;
        } else {
            auto typeIt = typeDefs.find(localTypes[i]);
            if (typeIt != typeDefs.end()) {
                width = typeIt->second;
            }
        }
        if (width >= 0) {
            applyProc.parameters[inNames[i]] = width;
        }
        applyProc.addLocalVariables(inNames[i]);
        if (i + 1 < inNames.size()) {
            applyProc.addDeclaration(", ");
        }
    }
    applyProc.addDeclaration(")");
    if (!outNames.empty()) {
        applyProc.addDeclaration(" returns (");
        for (size_t i = 0; i < outNames.size(); i++) {
            applyProc.addDeclaration(outNames[i]+":"+outTypes[i]);
            int width = -1;
            if (outTypes[i] == "bool") {
                width = 0;
            } else if (outTypes[i].find("bv") == 0) {
                std::string typeStr = outTypes[i].c_str();
                std::stringstream ss(typeStr.substr(2));
                ss >> width;
            } else {
                auto typeIt = typeDefs.find(outTypes[i]);
                if (typeIt != typeDefs.end()) {
                    width = typeIt->second;
                }
            }
            if (width >= 0) {
                applyProc.parameters[outNames[i]] = width;
            }
            applyProc.addLocalVariables(outNames[i]);
            if (i + 1 < outNames.size()) {
                applyProc.addDeclaration(", ");
            }
        }
        applyProc.addDeclaration(")");
    }
    applyProc.addDeclaration("\n");
    incIndent();
    for (size_t i = 0; i < localNames.size(); i++) {
        applyProc.addVariableDeclaration(getIndent()+"var "+localNames[i]+":"+localTypes[i]+";\n");
        int width = -1;
        if (localTypes[i] == "bool") {
            width = 0;
        } else if (localTypes[i].find("bv") == 0) {
            std::string typeStr = localTypes[i].c_str();
            std::stringstream ss(typeStr.substr(2));
            ss >> width;
        } else {
            auto typeIt = typeDefs.find(localTypes[i]);
            if (typeIt != typeDefs.end()) {
                width = typeIt->second;
            }
        }
        if (width >= 0) {
            applyProc.declarationVariables[localNames[i]] = width;
        }
        applyProc.addLocalVariables(localNames[i]);
        applyProc.addStatement(getIndent()+localNames[i]+" := "+inNames[i]+";\n");
    }
    if (func->body != nullptr) {
        for (auto statOrDecl : func->body->components) {
            applyProc.addStatement(translate(statOrDecl));
        }
    }
    for (size_t i = 0; i < localNames.size(); i++) {
        applyProc.addStatement(getIndent()+outNames[i]+" := "+localNames[i]+";\n");
    }
    decIndent();
    addProcedure(applyProc);
    currentProcedure = prevProc;
    currentReturnVar = prevReturnVar;
}

void Translator::addUAFunctions(){
    declaration += "function {:inline true} power_2_0() : int{1}\n";
    declaration += "function {:inline true} power_2_1() : int{2}\n";
    declaration += "function {:inline true} power_2_2() : int{4}\n";
    declaration += "function {:inline true} power_2_3() : int{8}\n";
    declaration += "function {:inline true} power_2_4() : int{16}\n";
    declaration += "function {:inline true} power_2_5() : int{32}\n";
    declaration += "function {:inline true} power_2_6() : int{64}\n";
    declaration += "function {:inline true} power_2_7() : int{128}\n";
    declaration += "function {:inline true} power_2_8() : int{256}\n";
    declaration += "function {:inline true} power_2_9() : int{512}\n";
    declaration += "function {:inline true} power_2_10() : int{1024}\n";

    declaration += "function {:inline true} power_2_11() : int{2048}\n";
    declaration += "function {:inline true} power_2_12() : int{4096}\n";
    declaration += "function {:inline true} power_2_13() : int{8192}\n";
    declaration += "function {:inline true} power_2_14() : int{16384}\n";
    declaration += "function {:inline true} power_2_15() : int{32768}\n";
    declaration += "function {:inline true} power_2_16() : int{65536}\n";
    declaration += "function {:inline true} power_2_17() : int{131072}\n";
    declaration += "function {:inline true} power_2_18() : int{262144}\n";
    declaration += "function {:inline true} power_2_19() : int{524288}\n";
    declaration += "function {:inline true} power_2_20() : int{1048576}\n";

    declaration += "function {:inline true} power_2_21() : int{2097152}\n";
    declaration += "function {:inline true} power_2_22() : int{4194304}\n";
    declaration += "function {:inline true} power_2_23() : int{8388608}\n";
    declaration += "function {:inline true} power_2_24() : int{16777216}\n";
    declaration += "function {:inline true} power_2_25() : int{33554432}\n";
    declaration += "function {:inline true} power_2_26() : int{67108864}\n";
    declaration += "function {:inline true} power_2_27() : int{134217728}\n";
    declaration += "function {:inline true} power_2_28() : int{268435456}\n";
    declaration += "function {:inline true} power_2_29() : int{536870912}\n";
    declaration += "function {:inline true} power_2_30() : int{1073741824}\n";

    declaration += "function {:inline true} power_2_31() : int{2147483648}\n";
    declaration += "function {:inline true} power_2_32() : int{4294967296}\n";
    declaration += "function {:inline true} power_2_33() : int{8589934592}\n";
    declaration += "function {:inline true} power_2_34() : int{17179869184}\n";
    declaration += "function {:inline true} power_2_35() : int{34359738368}\n";
    declaration += "function {:inline true} power_2_36() : int{68719476736}\n";
    declaration += "function {:inline true} power_2_37() : int{137438953472}\n";
    declaration += "function {:inline true} power_2_38() : int{274877906944}\n";
    declaration += "function {:inline true} power_2_39() : int{549755813888}\n";
    declaration += "function {:inline true} power_2_40() : int{1099511627776}\n";

    declaration += "function {:inline true} power_2_41() : int{2199023255552}\n";
    declaration += "function {:inline true} power_2_42() : int{4398046511104}\n";
    declaration += "function {:inline true} power_2_43() : int{8796093022208}\n";
    declaration += "function {:inline true} power_2_44() : int{17592186044416}\n";
    declaration += "function {:inline true} power_2_45() : int{35184372088832}\n";
    declaration += "function {:inline true} power_2_46() : int{70368744177664}\n";
    declaration += "function {:inline true} power_2_47() : int{140737488355328}\n";
    declaration += "function {:inline true} power_2_48() : int{281474976710656}\n";
    declaration += "function {:inline true} power_2_49() : int{562949953421312}\n";
    declaration += "function {:inline true} power_2_50() : int{1125899906842624}\n";

    if(maxBitvectorSize > 50){
        int tmp = -1;
        for(int i = 51; i <= maxBitvectorSize; i++){
            declaration += "function {:inline true} power_2_"+toString(i)+" () : int{";
            tmp = i;
            while(tmp > 50){
                declaration += "power_2_50()";
                tmp -= 50;
                if(tmp > 0) declaration += "*";
            }
            if(tmp > 0) declaration += "power_2_"+toString(tmp)+"() ";
            declaration += "}\n";
        }
    }

    declaration += "function {:inline true} band(left:int, right:int) : int{((left+right)-(left+right)\%2)/2}\n";
    // declaration += "function band(left:int, right:int) : int{if(left>0 && right>0) then 1 else 0}\n";
    declaration += "function {:inline true} bxor(left:int, right:int) : int{(left+right)\%2}\n";
    // declaration += "function bxor(left:int, right:int) : int{if((left==0&&right>0) || (left>0&&right==0)) then 1 else 0}\n";
    declaration += "function {:inline true} bor(left:int, right:int) : int{(left+right)\%2+((left+right)-((left+right)\%2))/2}\n";
    // declaration += "function bor(left:int, right:int) : int{if(left>0 || right>0) then 1 else 0}\n";
    declaration += "function {:inline true} bnot(num:int) : int{1-num\%2}\n";
    // declaration += "function bnot(num:int) : int{if(num == 0) then 1 else 0}\n";
    
}

void Translator::writeToFile(){
    if(options.p4ltlSpec){
        for(cstring str:P4LTL_KEYS){
            if(options.CpiIfElse && str == P4LTL_KEYS_CPI_MODEL)
                continue;
            if(p4ltlSpec.find(str) != p4ltlSpec.end()){
                for(auto spec:p4ltlSpec[str]){
                    cstring cont = ltlTranslator->translateP4LTL(spec);
                    std::cout << str << std::endl << " " << cont << std::endl;
                    if(str == P4LTL_KEYS_CPI_SPEC) out << P4LTL_KEYS_CPI;
                    else out << str;
                    out << " " << cont << "\n";
                }
            }
        }
        out << "\n";

        for(auto item:ltlTranslator->getFreeVariables()){
            if(isGlobalVariable(item.first)){
                std::cout << "ERROR: "+item.first+" is a global variable. Please change the name.\n";
                std::abort();
            }
            addGlobalVariables(item.second);
            // Add bv
            if(ltlTranslator->getSize(item.second) != -1){
                mainProcedure.addFrontStatement("    assume(0 <= "+item.second+" && "+
                        item.second + " < power_2_" +toString(ltlTranslator->getSize(item.second))
                        +"() );\n");
                // std::couts << item.second << " " << ltlTranslator->getSize(item.second) << std::endl;
            }

            // havocProcedure.addStatement("    havoc "+item.second+";\n");
            // havocProcedure.addModifiedGlobalVariables(item.second);
        }
        for(cstring variable:ltlTranslator->getVariables()){
            addGlobalVariables(variable);
            mainProcedure.addModifiedGlobalVariables(variable);
        }
        BoogieProcedure* main;
        if(procedures.find("main") != procedures.end()){
            main = &procedures["main"];
            for(cstring stmt:ltlTranslator->getStatements()){
                main->addStatement("    "+stmt);
            }
            for(cstring variable:ltlTranslator->getVariables()){
                main->addModifiedGlobalVariables(variable);
            }
        }
        else{
            cstring call = mainProcedure.lastStatement();
            mainProcedure.removeLastStatement();
            mainProcedure.addStatement("    while(true){\n");
            mainProcedure.addStatement(call);
            for(cstring stmt:ltlTranslator->getStatements()){
                mainProcedure.addStatement("        "+stmt);
            }
            mainProcedure.addStatement("    }\n");
        }
        
        for(cstring declaration:ltlTranslator->getDeclarations()){
            addDeclaration(declaration);
        }

        for(auto item:p4ltlSpec){
            for(auto spec:item.second){
                std::map<cstring, std::set<cstring>> oldArrays = ltlTranslator->getOldArrays(spec);
                for(auto oldArray:oldArrays){
                    cstring arrayName = oldArray.first;
                    cstring oldArrayName = "_old_"+oldArray.first;
                    addDeclaration("var "+oldArrayName+": [int]int;\n");
                    addGlobalVariables(oldArrayName);
                    for(cstring arrayIndex:oldArray.second){
                        havocProcedure.addModifiedGlobalVariables(oldArrayName);
                        havocProcedure.addStatement("    "+oldArrayName+"["+arrayIndex+
                            "] := "+ arrayName+"["+arrayIndex+"];\n");
                    }
                }
                // std::cout << oldArrays.size() << std::endl;
        //         if(oldExprs.find(fieldName) != oldExprs.end()){
        //             havocProcedure.addStatement("    "+oldFieldName+" := "+
        //                fieldName +";\n");
        //             havocProcedure.addModifiedGlobalVariables(oldFieldName);
        //             break;
        //         }
            }
        }
    }


    if(options.ultimateAutomizer && !options.bitBlasting){
        addUAFunctions();
    }

    addProcedure(mainProcedure);
    if(options.whileLoop)
        addProcedure(havocProcedure);
    std::queue<BoogieProcedure*> queue;
    // queue.push(&mainProcedure);
    for (std::map<cstring, BoogieProcedure>::iterator iter=procedures.begin();
        iter!=procedures.end(); iter++){
        for (std::set<cstring>::iterator iter2=iter->second.modifies.begin();
            iter2!=iter->second.modifies.end();){
            if(!isGlobalVariable(*iter2))
                iter->second.modifies.erase(iter2++);
            else
                ++iter2;
        }
        queue.push(&iter->second);
    }
    while(!queue.empty()){
        BoogieProcedure* procedure = queue.front();
        int szBefore = procedure->getModifiesSize();
        for(cstring succ:procedure->succ){
            for (std::set<cstring>::iterator iter=procedures[succ].modifies.begin();
                iter!=procedures[succ].modifies.end(); iter++){
                procedure->addModifiedGlobalVariables(*iter);
            }
        }
        int szAfter = procedure->getModifiesSize();
        if(szBefore!=szAfter){
            for(cstring predProc:pred[procedure->getName()]){
                queue.push(&procedures[predProc]);
            }
        }
        queue.pop();
    }

    // Ensure all variables in modifies clauses are declared, even if slicing filtered them out.
    for (auto& kv : procedures) {
        for (const auto& mod : kv.second.modifies) {
            if (emittedVarDecls.count(mod)) {
                continue;
            }
            auto it = varTypes.find(mod);
            if (it == varTypes.end()) {
                continue;
            }
            std::string decl = "var ";
            decl += mod.c_str();
            decl += ":";
            decl += it->second.c_str();
            decl += ";\n";
            declaration += decl.c_str();
            emittedVarDecls.insert(mod);
        }
    }


    out << declaration;
    // out << "\n";
    // out << mainProcedure.toString();
    // std::cout << mainProcedure.getName() << std::endl;
    // std::cout << "Succ:" << std::endl;
    // for(cstring succ:mainProcedure.succ){
    //     std::cout << "  " << succ << std::endl;
    // }
    // for(BoogieProcedure procedure:procedures){
    //     out << "\n";
    //     out << procedure.toString();
    // }
    std::map<cstring, BoogieProcedure>::iterator iter;
    for (iter=procedures.begin(); iter!=procedures.end(); iter++){
        if(iter->first != deparser){
            // std::cout << iter->first << std::endl;
            // std::cout << "Succ:" << std::endl;
            // for(cstring succ:iter->second.succ){
            //     std::cout << "  " << succ << std::endl;
            // }
            // std::cout << std::endl;
            // out << "\n";
            out << iter->second.toString();
        }
    }
}

cstring Translator::toString(int val){
    std::stringstream ss;
    ss << val;
    return ss.str();
}

cstring Translator::toString(const big_int& val){
    std::stringstream ss;
    ss << val;
    return ss.str();
}

cstring Translator::getTempPrefix(){
    return TempVariable::getPrefix();
}
