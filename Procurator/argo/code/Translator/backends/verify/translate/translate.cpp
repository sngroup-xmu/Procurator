#include "translate.h"
#include <sstream>
#include <typeinfo>

cstring Translator::stringWithPrefix(const cstring& str) {
    if (str == "") return "";
    return options.switchID + "_" + str;
}

cstring Translator::removePrefix(const cstring& str) {
    if (!str.startsWith(options.switchID)) return str;
    auto idx = ((std::string)str.c_str()).find("_");
    return str.substr(idx+1);
}

cstring Translator::handle_keyword(cstring id) {
    if (promela_keyword.find(id) != promela_keyword.end()) {
        return "_" + id;
    }
    return id;
}

void Translator::setRemoveIds(std::unordered_set<int>& st) {
    if (st.size()) {
        removeIds = st;
        needPrune = true;
        std::cout << "setRemoveIds: " << st.size() << std::endl;
        std::cout << "needPrune:" << needPrune << std::endl;
    } else {
        needPrune = false;
    }
};

// initialization
Translator::Translator(std::ostream &out_typedef, std::ostream &out, P4VerifyOptions &options, BMV2CmdsAnalyzer* bMV2CmdsAnalyzer) 
    : out_typedef(out_typedef), out(out), options(options), bMV2CmdsAnalyzer(bMV2CmdsAnalyzer){
    header_extractor = ChanExtractor(options.output_dir + "headers.json", defList);
    field_mapping = FieldMapping(options.output_dir + "field_mapping.csv");
    
    // init main procedure
    cstring mainProcedureDeclaration;
    mainProcedure = BoogieProcedure(stringWithPrefix("mainProcedure"));
    mainProcedure.addDeclaration("proctype " + stringWithPrefix("mainProcedure()\n"));


    mainProcedure.setImplemented();
    havocProcedure = BoogieProcedure(stringWithPrefix("havocProcedure"));
    havocProcedure.addDeclaration("inline " + stringWithPrefix("havocProcedure()\n"));
    havocProcedure.setImplemented();

    type_define = "";

    // procedures = std::vector<BoogieProcedure>();

    // declare necessary types and files
    declaration = "";
    // declaration = cstring("type Ref;\n");
    type_define += cstring("#define " + stringWithPrefix("error") + " bit\n");

    type_define += "bool " + stringWithPrefix("_forward;\n");
    addGlobalVariables(stringWithPrefix("_forward"));

    type_define += "bool " + stringWithPrefix("_drop;\n");
    addGlobalVariables(stringWithPrefix("_drop"));


    type_define += "bool " + stringWithPrefix("packet_extract_accept = false;\n");
    addGlobalVariables(stringWithPrefix("packet_extract_accept"));

    type_define += "bool " + stringWithPrefix("V1_RECIRCULATE_FLAG = false;\n");
    addGlobalVariables(stringWithPrefix("V1_RECIRCULATE_FLAG"));
    type_define += "bool " + stringWithPrefix("V1_RESUBMIT_FLAG = false;\n");
    addGlobalVariables(stringWithPrefix("V1_RESUBMIT_FLAG"));
    // declaration += "inline mask(x, high, low) {\n    x = x & (((1 << (high - low + 1)) - 1) << low);\n}\n";

    havocProcedure.addStatement("    " + stringWithPrefix("_drop") + " = false;\n");
    havocProcedure.addModifiedGlobalVariables(stringWithPrefix("_drop"));
    havocProcedure.addStatement("    " + stringWithPrefix("_forward") + " = false;\n");
    havocProcedure.addModifiedGlobalVariables(stringWithPrefix("_forward"));

    headers = std::map<cstring, const IR::Type_Header*>();
    structs = std::map<cstring, const IR::Type_Struct*>();
    tables = std::map<cstring, const IR::P4Table*>();
    // instances = std::vector<const IR::Declaration_Instance*>();
    instances = std::unordered_map<cstring, const IR::Declaration_Instance*>();
    
    typeDefs = std::map<cstring, int>();
    // globalVariables = std::set<cstring>();

    maxBitvectorSize = -1;

    addNecessaryProcedures();
}

BoogieProcedure Translator::getMainProcedure(){
    return mainProcedure;
}

// build-in
void Translator::addNecessaryProcedures(){
    BoogieProcedure mark_to_drop = BoogieProcedure(stringWithPrefix("mark_to_drop"));
    mark_to_drop.addDeclaration("inline " + mark_to_drop.getName() + " (){\n    " + stringWithPrefix("_drop") + " = true;\n}\n");
    // mark_to_drop.addDeclaration("    ensures drop==true;\n");
    mark_to_drop.addModifiedGlobalVariables(stringWithPrefix("_drop"));
    addProcedure(mark_to_drop);

    // add accept & reject
    BoogieProcedure accept = BoogieProcedure(stringWithPrefix("accept"));
    accept.addDeclaration("inline " + accept.getName()+ "()\n");
    accept.addStatement("    " + stringWithPrefix("packet_extract_accept = true;\n"));
    accept.setImplemented();
    addProcedure(accept);

    BoogieProcedure reject = BoogieProcedure(stringWithPrefix("reject"));
    reject.addModifiedGlobalVariables(stringWithPrefix("_drop"));
    reject.addDeclaration("inline " + reject.getName()+ "() {\n    " + stringWithPrefix("_drop") + " = true;\n}\n");
    addProcedure(reject);

}

// 加在 egress 之前
void Translator::addTrafficManager(bool isTNA) {
    BoogieProcedure trafficManager = BoogieProcedure(stringWithPrefix("TrafficManager"));
    trafficManager.addDeclaration("inline " + trafficManager.getName()+ "()\n");

    auto label_ingress_parser = stringWithPrefix("label_ingress_parser");
    auto label_pipeline_end = stringWithPrefix("label_pipeline_end");

    auto ingressHeader = getHeaderName(options.switchID);
    auto egressChannel = getChannelName(options.switchID, true);
    
    if (isTNA) {
        // reset resubmit flag
        auto resubmit_flag =  stringWithPrefix("ig_intr_md.resubmit_flag");
        trafficManager.addStatement(getIndent() + resubmit_flag + " = 0;\n");

        trafficManager.addStatement(getIndent() + "if\n");
        // drop
        auto drop_ctl = stringWithPrefix("ig_intr_dprsr_md.drop_ctl");
        auto bypass_egress = stringWithPrefix("ig_intr_tm_md.bypass_egress");
        trafficManager.addStatement(getIndent() + ":: " + drop_ctl + " == 1 || " + bypass_egress + " == 1->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + drop_ctl + " = 0;\n");
        trafficManager.addStatement(getIndent() + bypass_egress + " = 0;\n");
        trafficManager.addStatement(getIndent() + "goto " + label_pipeline_end + ";\n");
        decIndent();
        //
        trafficManager.addStatement(getIndent() + ":: " + "else ->\n");
        incIndent();
        // resumit
        trafficManager.addStatement(getIndent() + "if\n");
        auto resumit = stringWithPrefix("ig_intr_dprsr_md.resubmit_type");
        trafficManager.addStatement(getIndent() + ":: " + resumit + " != 0 ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + resumit + " = 0;\n");
        trafficManager.addStatement(getIndent() + resubmit_flag + " = 1;\n"); // 
        trafficManager.addStatement(getIndent() + "goto " + label_ingress_parser + ";\n");
        decIndent();
        trafficManager.addStatement(getIndent() + ":: else -> skip;\n");
        trafficManager.addStatement(getIndent() + "fi\n");
        // mirror
        trafficManager.addStatement(getIndent() + "if\n");
        auto mirror = stringWithPrefix("ig_intr_dprsr_md.mirror_type");
        trafficManager.addStatement(getIndent() + ":: " + mirror + " != 0 ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + "// send mirror packet\n");
        trafficManager.addStatement(getIndent() + egressChannel + " ! " + ingressHeader + ";\n");
        trafficManager.addStatement(getIndent() + mirror + " = 0;\n");
        trafficManager.addStatement(getIndent() + "// 手动重置字段\n\n\n");  // 发完后重置字段（当原来的正常包）
        decIndent();
        trafficManager.addStatement(getIndent() + ":: else -> skip;\n");
        trafficManager.addStatement(getIndent() + "fi\n");
        // ucast
        trafficManager.addStatement(getIndent() + "if\n");
        auto ucast = stringWithPrefix("ig_intr_tm_md.ucast_egress_port");
        trafficManager.addStatement(getIndent() + stringWithPrefix("eg_intr_md.egress_port") + " = " + ucast + ";\n"); //
        trafficManager.addStatement(getIndent() + ":: " + ucast + " != 0 ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + ucast + " = 0;\n");
        trafficManager.addStatement(getIndent() + egressChannel + " ! " + ingressHeader + ";\n");
        decIndent();
        trafficManager.addStatement(getIndent() + ":: else -> skip;\n");
        trafficManager.addStatement(getIndent() + "fi\n");
        // TODO: other situations
        decIndent();
        trafficManager.addStatement(getIndent() + "fi\n");

    } else {
        trafficManager.addStatement(getIndent() + "if\n");
        // drop
        trafficManager.addStatement(getIndent() + ":: " + stringWithPrefix("_drop") + " == true ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + stringWithPrefix("_drop") + " = false;\n");
        trafficManager.addStatement(getIndent() + "goto " + label_pipeline_end + ";\n");
        decIndent();
        // 
        trafficManager.addStatement(getIndent() + ":: " + "else ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + "if\n");
        // resumit
        auto resumit = stringWithPrefix("V1_RESUBMIT_FLAG");
        trafficManager.addStatement(getIndent() + ":: " + resumit + " != 0 ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + resumit + " = 0;\n");
        trafficManager.addStatement(getIndent() + "goto " + label_ingress_parser + ";\n");
        decIndent();
        // clone
        
        // ucast
        auto egress_spec = stringWithPrefix("standard_metadata.egress_spec");
        trafficManager.addStatement(getIndent() + stringWithPrefix("standard_metadata.egress_port") + " = " + egress_spec + ";\n"); //
        trafficManager.addStatement(getIndent() + ":: " + egress_spec + " != 0 ->\n");
        incIndent();
        trafficManager.addStatement(getIndent() + egress_spec + " = 0;\n");
        trafficManager.addStatement(getIndent() + egressChannel + " ! " + ingressHeader + ";\n");
        decIndent();
        // TODO: other situations
        trafficManager.addStatement(getIndent() + ":: else -> skip;\n");
        trafficManager.addStatement(getIndent() + "fi\n");
        decIndent();
        trafficManager.addStatement(getIndent() + "fi\n");
    }

    addProcedure(trafficManager);
}

// 加在整个 pipeline 后面
void Translator::addForwarding(bool isTNA) {
    BoogieProcedure send_packet = BoogieProcedure(stringWithPrefix("pml_send_packet"));
    auto is_last_packet = "is_last_packet";
    send_packet.addDeclaration("inline " + send_packet.getName()+ "("+ is_last_packet +")\n");
    
    auto label_pipeline_end = stringWithPrefix("label_pipeline_end");

    send_packet.addStatement(getIndent() + "if\n");
    // drop
    if (isTNA) {
        send_packet.addStatement(getIndent() + ":: " + stringWithPrefix("eg_intr_dprsr_md.drop_ctl") + " == 1 ->\n");
        incIndent();
        send_packet.addStatement(getIndent() + "if\n");
        send_packet.addStatement(getIndent() + ":: " + is_last_packet + " ->\n");
        incIndent();
        send_packet.addStatement(getIndent() + stringWithPrefix("eg_intr_dprsr_md.drop_ctl") + " = 0;\n");
        decIndent();
        send_packet.addStatement(getIndent() + ":: else -> skip;\n");
        send_packet.addStatement(getIndent() + "fi\n");
        send_packet.addStatement(getIndent() + "goto " + label_pipeline_end + ";\n");
        decIndent();
    } else {
        send_packet.addStatement(getIndent() + ":: " + stringWithPrefix("_drop") + " == true ->\n");
        incIndent();
        send_packet.addStatement(getIndent() + stringWithPrefix("_drop") + " = false;\n");
        send_packet.addStatement(getIndent() + "goto " + label_pipeline_end + ";\n");
        decIndent();
    }

    auto headerName = getHeaderName(options.switchID, true);
    // forward
    send_packet.addStatement(getIndent() + ":: " + "else ->\n");
    incIndent();
    send_packet.addStatement(getIndent() + "if\n");
    // v1 forward by recirculate
    auto recirculate = stringWithPrefix("V1_RECIRCULATE_FLAG");
    send_packet.addStatement(getIndent() + ":: " + recirculate + " != 0 ->\n");
    incIndent();
    send_packet.addStatement(getIndent() + recirculate + " = 0;\n");
    send_packet.addStatement(getIndent() + getChannelName(options.switchID) + " ! " + headerName + ";\n");
    decIndent();
    // forward by port
    auto egressPort = isTNA ? stringWithPrefix("eg_intr_md.egress_port") : stringWithPrefix("standard_metadata.egress_port");
    send_packet.addStatement(getIndent() + ":: " + egressPort + " != 0 ->\n");
    incIndent();
    send_packet.addStatement(getIndent() + "if\n");
    if (options.port_dst.find("ALL") != options.port_dst.end()) { // default
        send_packet.addStatement(getIndent() + ":: " + getChannelName(options.port_dst["ALL"]) + " ! " + headerName + ";\n");
    } else {
        for (auto pair : options.port_dst) {
            send_packet.addStatement(getIndent() + ":: " + egressPort + " == " + cstring::to_cstring(pair.first) + " ->\n");
            send_packet.addStatement(getIndent() + "    " + getChannelName(pair.second) + " ! " + headerName + ";\n");
        }
        if (isTNA) { // recirculate
            send_packet.addStatement(getIndent() + ":: " + egressPort + " == 68 ->\n");
            send_packet.addStatement(getIndent() + "    " + getChannelName(options.switchID) + " ! " + headerName + ";\n");
            send_packet.addStatement(getIndent() + ":: " + egressPort + " == 196 ->\n");
            send_packet.addStatement(getIndent() + "    " + getChannelName(options.switchID) + " ! " + headerName + ";\n");
        }
        send_packet.addStatement(getIndent() + ":: else -> skip;\n");
    }
    send_packet.addStatement(getIndent() + "fi\n");
    send_packet.addStatement(getIndent() + "if\n");
    send_packet.addStatement(getIndent() + ":: " + is_last_packet + " ->\n");
    incIndent();
    send_packet.addStatement(getIndent() + egressPort + " = 0;\n");
    decIndent();
    send_packet.addStatement(getIndent() + ":: else -> skip;\n");
    send_packet.addStatement(getIndent() + "fi\n");
    decIndent();
    send_packet.addStatement(getIndent() + ":: else -> skip;\n");
    send_packet.addStatement(getIndent() + "fi\n");
    decIndent();
    send_packet.addStatement(getIndent() + "fi\n");

    addProcedure(send_packet);
}

void Translator::addProcedure(BoogieProcedure procedure){
    if(hasProcedure(procedure.getName()))
        return;
    // procedures.push_back(&procedure);
    procedures[procedure.getName()] = procedure;
}

bool Translator::hasProcedure(cstring procedure) {
    return procedures.find(procedure) != procedures.end();
}

void Translator::addDeclaration(cstring decl){
    declaration += decl;
}

void Translator::addTypeDef(cstring def){
    type_define += def;
}

void Translator::addFunction(cstring op, cstring opbuiltin, cstring typeName, cstring returnType){
    cstring functionName = op+".";
    if(returnType!="bool")
        functionName += returnType;
    else
        functionName += typeName;
    if(functions.find(functionName)==functions.end()){
        functions.insert(functionName);
        cstring res = "\ninline "+functionName;
        if(returnType!="bool")
            res += "(" + returnType + " left, " + returnType + " right)\n";
        else
            res += "(" + typeName + " left, " + typeName + " right)\n";
        
        addDeclaration(res);
    }
}

void Translator::addFunction(cstring funcName, cstring func){
    if(functions.find(funcName)==functions.end()){
        functions.insert(funcName);
        addDeclaration(func);
    }
}

void Translator::analyzeProgram(const IR::P4Program *program){
    for(auto obj:program->objects){
        if (auto enumType = obj->to<IR::Type_SerEnum>()){
            defList.insert( std::make_pair(enumType->name, enumType->type->width_bits()));
            // std::cout << " name:" << enumType->name << " ,bitWidth:" << enumType->type->width_bits() << std::endl;
        }
        else if (auto typeDef = obj->to<IR::Type_Typedef>()) {
            // std::cout << " name:" << typeDef->getName() << " ,bitWidth:" << typeDef->type->width_bits() << std::endl;
            defList.insert( std::make_pair(typeDef->getName(), typeDef->type->width_bits()));

        }
        else if (auto typeHeader = obj->to<IR::Type_Header>()) {
             headers[translate(typeHeader->name)] = typeHeader;
        }
        else if (auto typeStruct = obj->to<IR::Type_Struct>()) {
            structs[translate(typeStruct->name)] = typeStruct;
        }
        else if (auto p4Control = obj->to<IR::P4Control>()){
            for(auto controlLocal:p4Control->controlLocals){
                if (auto p4Action = controlLocal->to<IR::P4Action>()){
                    actions[translate(p4Action->name)] = p4Action;
                }
                else if(auto p4Table = controlLocal->to<IR::P4Table>()){
                    tables[translate(p4Table->name)] = p4Table;
                } else if (auto instance = controlLocal->to<IR::Declaration_Instance>()){ // register registerAction(tna)
                    instances[translate(instance->name)] = instance;
                }
            }
        }
        else if (auto instance = obj->to<IR::Declaration_Instance>()){
            // instances.push_back(instance);
        }
        else if (auto parser = obj->to<IR::P4Parser>()){
            for(auto state:parser->states){
                parserStates[translate(state->name)] = state;
                parserStateRenameTimes[translate(state->name)] = 0;
            }
        }
    }
}

cstring Translator::translate(IR::ID id){
    // std::cout << "debug id:" << id.name << ", originName: " << id.originalName << std::endl;
    return stringWithPrefix(id.name);
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

bool Translator::addGlobalVariables(cstring variable){
    auto result = globalVariables.insert(variable);
    return result.second;
}

bool Translator::isGlobalVariable(cstring variable){
    return globalVariables.find(variable)!=globalVariables.end();
}

void Translator::updateModifiedVariables(cstring variable){
    currentProcedure->addModifiedGlobalVariables(variable);
}

// dependency (predProc calls proc)
void Translator::addPred(cstring proc, cstring predProc){
    // if(pred[proc]==nullptr)
    //     pred[proc] = std::vector<cstring>(0);
    // pred[proc].push_back(predProc);
    pred[proc].insert(predProc);
}

// add regwrite spec
// <name> <index> <value>
void Translator::addRegWrite(cstring regWriteCmd) {
    std::string str = regWriteCmd.trim().c_str();
    // std::cout << "reg write str: " + str + "\n";
	// get reg_name
    int blankIdx = str.find(' ');
	if(blankIdx == -1)
		return;
    std::string reg_name = str.substr(0, blankIdx);
    // get reg_index
    str = str.substr(blankIdx + 1);
    blankIdx = str.find(' ');
	if(blankIdx == -1)
		return;
    std::string index = str.substr(0, blankIdx);
    // get reg_value
    str = str.substr(blankIdx + 1);
    if(str.empty())
        return;
    std::string value = str;

    // std::cout << "Intend to write " + reg_name + "[" + index + "] = " + value + "\n";
    reg4Init[reg_name].insert(IDX_VAL(index, value));

    return;
}

void Translator::initAtomAuxCollector() {
    collect += 1;
    // constant_collector.clear();
    // relevantVar_collector.clear();
}

void Translator::closeAtomAuxCollector() {
    collect -= 1;
    if(collect == 0) {
        constant_collector.clear();
        relevantVar_collector.clear();
    }
}

std::shared_ptr<Translator::REGIDXSET_TYPE> Translator::unionRegIdxSets(std::shared_ptr<REGIDXSET_TYPE> l, std::shared_ptr<REGIDXSET_TYPE> r)
{
    assert(l);
    if(!r || l == r)
        return l;

    auto sl = *l;
    auto sv = *r;
    std::set_union(sl.begin(), sl.end(), sv.begin(), sv.end(), std::inserter(sl, sl.begin()));
    return l;
}

std::shared_ptr<Translator::PREDICATESET_TYPE> Translator::unionPredicates(std::shared_ptr<PREDICATESET_TYPE> l, std::shared_ptr<PREDICATESET_TYPE> r)
{
    assert(l);
    if(!r || l == r)
        return l;

    auto sl = *l;
    auto sv = *r;
    std::set_union(sl.begin(), sl.end(), sv.begin(), sv.end(), std::inserter(sl, sl.begin()));
    return l;
}

void Translator::updateRelevantVars(cstring var, std::set<VAR_TYPE>& var_collector, std::set<VAR_TYPE>& const_collector, bool updateConsts) {
    auto recordSPtr = invVarCandidates[var];
    // update const set
    if(updateConsts)
        for(auto c: const_collector)
            for(auto record: *recordSPtr) {
                conjecture(record, c);
            }
    // update regIdx set
    for(auto v: var_collector) {
        if(v != var) {
            // union regIdx sets
            invVarCandidates[v] = unionRegIdxSets(recordSPtr, invVarCandidates[v]);
            // union const sets
            if(invVarCandidates[v]) {
                for(auto reg_idx: *invVarCandidates[v]) {
                    for(auto record: *recordSPtr) {
                        if(reg_idx == record) continue;
                        invPredicateCandidates[reg_idx] = unionPredicates(invPredicateCandidates[record], invPredicateCandidates[reg_idx]);
                    }
                }
            }
        }
    }
    
}

void Translator::generateBooleanAtom(const IR::Expression *expression, bool addReverse) {

    // do not update for it wont preseve collect count
        
    initAtomAuxCollector();
    cstring assertExpr = translate(expression);

    // generate atom
    bool everyVarIsRelevant = !relevantVar_collector.empty();   // if empty, then false, else true
    // for(auto dr: direct_relevantVar) {
    //     std::cout << "dR: " + dr.first + "\n";
    // }
    for(auto v: relevantVar_collector) {
        if(direct_relevantVar.find(v) == direct_relevantVar.end()) {
            everyVarIsRelevant = false;
            break;
        }
    }
    if(everyVarIsRelevant) {
        decltype(atom_collector) atoms;
        atoms.insert(assertExpr);
        for(auto v: relevantVar_collector) {
            // std::cout << "var: " + v + "\n";
            assert(direct_relevantVar.find(v) != direct_relevantVar.end());
            auto relevantRegIdxSet = *direct_relevantVar[v];
            decltype(atom_collector) tmpAtoms;
            // assert(!relevantRegIdxSet.empty());
            // auto realRelRegIdxSet = *reg2RegSet[*relevantRegIdxSet.begin()];
            for(auto reg_index: relevantRegIdxSet) {
            // for(auto reg_index: realRelRegIdxSet) {
                cstring reg = reg_index.first;
                cstring idx = std::to_string(reg_index.second) + regType[reg].indexType;
                cstring reg_index_string = reg + "[" + idx + "]";
                if(reg_index.second != -1) {
                    // std::cout << "reg string: " + reg_index_string + "\n";
                    for(auto a: atoms) {
                        tmpAtoms.insert(a.replace(v, reg_index_string));
                    }
                } else {
                    reg_index_string = reg + "[i]";
                    for(auto a: atoms) {
                        // we only consider 1 forall now
                        if(a.find("forall") == nullptr)
                            tmpAtoms.insert("(forall i:" + regType[reg].indexType + " :: (" + a.replace(v, reg_index_string) + "))");
                    }
                }
                break;
            }
            atoms = tmpAtoms;
        }
        std::set_union(atoms.begin(), atoms.end(), atom_collector.begin(), atom_collector.end(), std::inserter(atom_collector, atom_collector.begin()));
    }
    closeAtomAuxCollector();
}

void Translator::postProcessCandidate() {
    auto reg_idx2string = [this](REG_IDX reg_idx) {
        cstring reg = reg_idx.first;
        cstring idx = std::to_string(reg_idx.second);
        cstring idx_type = idx == "-1" ? "i" : idx + regType[reg].indexType;
        cstring reg_idx_string = reg + "[" + idx_type + "]";
        return reg_idx_string;
    };

    for(auto it = invPredicateCandidates.begin(); it != invPredicateCandidates.end(); ++it) {
        auto nextIt = it;
        ++nextIt;
        for(auto it2 = nextIt; nextIt != invPredicateCandidates.end(); ++nextIt) {
            auto kv1 = *it;
            auto kv2 = *nextIt;

            if(kv1.first != kv2.first) {
                if(kv1.second == kv2.second) { // points to the same set 
                    auto regType1 = regType[kv1.first.first];
                    auto regType2 = regType[kv2.first.first];
                    // if all -1 or all not -1
                    if( (kv1.first.second == -1 && kv2.first.second == -1) || (kv1.first.second != -1 && kv2.first.second != -1))
                    if(regType1.valType == regType2.valType)
                    if(regType1.size == regType2.size) // add compare
                    {
                        addFunction("bule", "bvule", regType1.valType, "bool");
                        addFunction("buge", "bvuge", regType1.valType, "bool");
                        // std::cout << "Kv1.first.second: " + std::to_string(kv1.first.second) + " Kv2.first.second: " + std::to_string(kv2.first.second) + "\n";
                        if(kv1.first.second == -1 && kv2.first.second == -1) {
                            // only in reange
                            addFunction("bult", "bvult", regType1.indexType, "bool");
                            
                            auto candidate1 = "(forall i:" + regType1.indexType + " :: (" 
                            + "bule." + regType1.valType + "(" + reg_idx2string(kv1.first) + ", " + reg_idx2string(kv2.first) + ")))";
                            auto candidate2 = "(forall i:" + regType1.indexType +  " :: (" 
                            + "buge." + regType1.valType + "(" + reg_idx2string(kv1.first) + ", " + reg_idx2string(kv2.first) + ")))";
                            atom_collector.insert(candidate1);
                            atom_collector.insert(candidate2);
                        }
                        else {
                            auto c1 = "bule." + regType1.valType + "(" + reg_idx2string(kv1.first) + ", " + reg_idx2string(kv2.first) + ")";
                            auto c2 = "buge." + regType1.valType + "(" + reg_idx2string(kv1.first) + ", " + reg_idx2string(kv2.first) + ")";
                            atom_collector.insert(c1);
                            atom_collector.insert(c2);
                        }
                        
                    }
                } 
            }
        }
    }

    for(auto it = invPredicateCandidates.begin(); it != invPredicateCandidates.end();) {
        if(!(*it).second) continue;

        auto& predicates = *(*it).second;
        cstring reg = (*it).first.first;
        for(auto i = predicates.begin(); i != predicates.end();) {
            cstring value = i->second;
            int size = atoi(regType[reg].valType.substr(2));
            // std::cout << "size: " + std::to_string((((unsigned long long int)1 << size) - 1)) << "\n";
            if(value == "0" || value == std::to_string((((unsigned long long int)1 << size) - 1)))
                i = predicates.erase(i);
            else
                ++i;
        }
        if(!predicates.empty())
            ++it;
        else
            it = invPredicateCandidates.erase(it);
    }
}

void Translator::conjecture(REG_IDX record, cstring constant) {
    if(!invPredicateCandidates[record])
        invPredicateCandidates[record] = std::make_shared<PREDICATESET_TYPE>();

    (*invPredicateCandidates[record]).insert(PREDICATE_TYPE(">=", constant));
    (*invPredicateCandidates[record]).insert(PREDICATE_TYPE("<=", constant));
}

cstring Translator::generateInvariant() {

    return "";
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
    else return -1;
}

void Translator::writeToFile(){
    if(options.p4invSpec){
        BoogieProcedure* main;
        if(procedures.find(stringWithPrefix("main")) != procedures.end()){
            main = &procedures["main"];
        }
        else{
            cstring call = mainProcedure.lastStatement();
            mainProcedure.removeLastStatement();
            mainProcedure.addStatement("    while(true){\n");
            mainProcedure.addStatement(call);
            mainProcedure.addStatement("    }\n");
        }
    }

    addProcedure(mainProcedure);
    // if(options.whileLoop)
    //     addProcedure(havocProcedure);
    std::queue<BoogieProcedure*> queue;
    // queue.push(&mainProcedure);
    for (std::map<cstring, BoogieProcedure>::iterator iter=procedures.begin();
        iter!=procedures.end(); iter++){
        // set RefCnt for later topology sort
        iter->second.setRefCnt(pred[iter->second.getName()].size());
        for (std::set<cstring>::iterator iter2=iter->second.modifies.begin();
            iter2!=iter->second.modifies.end();){
            if(!isGlobalVariable(*iter2))
                iter->second.modifies.erase(iter2++);
            else
                ++iter2;
        }
        queue.push(&iter->second);
    }
    // analyze procedure's variable modification by dependency
    while(!queue.empty()){
        BoogieProcedure* procedure = queue.front();
        int szBefore = procedure->getModifiesSize();
        for(cstring succ:procedure->succ){
            for (std::set<cstring>::iterator iter=procedures[succ].modifies.begin();
                iter!=procedures[succ].modifies.end(); iter++){
                // succ modifies *iter, procedure depends on (i.e. calls) succ, so add *iter into procedure's modifies
                procedure->addModifiedGlobalVariables(*iter);
            }
        }
        int szAfter = procedure->getModifiesSize();
        if(szBefore!=szAfter){
            for(cstring predProc:pred[procedure->getName()]){
                // procedure's modifies are changed, 
                // so other procedures that depends on (i.e. calls) this procedure also need to be changed
                queue.push(&procedures[predProc]);
            }
        }
        queue.pop();
    }

    // topo sort
    std::queue<BoogieProcedure> topo_sort_queue;
    std::stack<BoogieProcedure> topo_sort_stack;

    for (auto iter=procedures.begin(); iter!=procedures.end(); iter++) {
        if (iter->second.getRefCnt() == 0) {
            topo_sort_queue.push(iter->second);
            topo_sort_stack.push(iter->second);
        }
    }
    while (!topo_sort_queue.empty()) {
        auto proc = topo_sort_queue.front();
        topo_sort_queue.pop();
        for(cstring succ:proc.succ) {
            BoogieProcedure &succ_proc = procedures[succ];
            succ_proc.decRefCnt();
            if (succ_proc.getRefCnt() == 0) {
                topo_sort_queue.push(succ_proc);
                topo_sort_stack.push(succ_proc);
            }
        }
    }

    out_typedef << type_define;

    out << declaration;
    while (!topo_sort_stack.empty()) {
        auto proc = topo_sort_stack.top();
        topo_sort_stack.pop();
        //if (proc.getName() != deparser) {
             out << proc.toString();
        //}
    }

    header_extractor.generateJsonFile();
    field_mapping.writeToFile();
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

void Translator::translate(const IR::Node *node){
    if (auto typeStruct = node->to<IR::Type_Struct>()) {
        translate(typeStruct);
    }
    else if (auto typeError = node->to<IR::Type_Error>()) {
        translate(typeError);
    }
    else if (auto typeExtern = node->to<IR::Type_Extern>()) {
        translate(typeExtern);
    }
    else if (auto typeEnum = node->to<IR::Type_Enum>()) {
        translate(typeEnum);
    }
    else if (auto typeParser = node->to<IR::Type_Parser>()) {
        translate(typeParser);
    }
    else if (auto typeControl = node->to<IR::Type_Control>()) {
        translate(typeControl);
    }
    else if (auto typePackage = node->to<IR::Type_Package>()) {
        translate(typePackage);
    }
    else if (auto typeHeader = node->to<IR::Type_Header>()) {
        translate(typeHeader);
    }
    else if (auto p4Parser = node->to<IR::P4Parser>()) {
        translate(p4Parser);
    }
    else if (auto p4Control = node->to<IR::P4Control>()) {
        translate(p4Control);
    }
    else if (auto method = node->to<IR::Method>()) {
        translate(method);
    }
    else if (auto instance = node->to<IR::Declaration_Instance>()) {
        translate(instance);
    }
    else if (auto typeTypedef = node->to<IR::Type_Typedef>()) {
        translate(typeTypedef);
    }
    else{
        // std::cout << node->node_type_name() << std::endl;
        // translate(obj);
    }
}

void Translator::translate(const IR::Node *node, cstring arg){
    // std::cout << node->node_type_name() << std::endl;
}

cstring Translator::translate(const IR::StatOrDecl *statOrDecl){
    if (needPrune && removeIds.count(statOrDecl->id) > 0) {
        return "";
    }
    if (auto stat = statOrDecl->to<IR::Statement>()) {
        return translate(stat);
    }
    else if (auto decl = statOrDecl->to<IR::Declaration>()) {
        // if(decl->toString().find("hasReturned")) return "";
        return translate(decl);
    }
    return "";
}

cstring Translator::translate(const IR::Statement *stat, const bool firstIfStat){
    if (needPrune && removeIds.count(stat->id) > 0) {
        return "";
    }
    if (auto methodCall = stat->to<IR::MethodCallStatement>()){
        return translate(methodCall);
    }
    if (auto ifStatement = stat->to<IR::IfStatement>()){
        return translate(ifStatement, firstIfStat);
    }
    if (auto blockStatement = stat->to<IR::BlockStatement>()){
        return translate(blockStatement);
    }
    if (auto assignmentStatement = stat->to<IR::AssignmentStatement>()){
        return translate(assignmentStatement);
    }
    if (auto switchStatement = stat->to<IR::SwitchStatement>()){
        return translate(switchStatement);
    }
    return "";
}

cstring Translator::translate(const IR::ExitStatement *exitStatement){ return ""; }
cstring Translator::translate(const IR::ReturnStatement *returnStatement){ return ""; }
cstring Translator::translate(const IR::EmptyStatement *emptyStatement){ return ""; }

cstring Translator::translate(const IR::AssignmentStatement *assignmentStatement){
    if (needPrune && removeIds.count(assignmentStatement->id) > 0) {
        return "";
    }
    if(options.addInvariant) {
        cstring left = translate(assignmentStatement->left);
        if(invVarCandidates.find(left) != invVarCandidates.end()) {
            initAtomAuxCollector();
            cstring right = translate(assignmentStatement->right);
            if(!options.simpleConjecture)
                updateRelevantVars(left, relevantVar_collector, constant_collector, assignmentStatement->right->to<IR::Constant>());
            else
                updateRelevantVars(left, relevantVar_collector, constant_collector);
            closeAtomAuxCollector();
            // DR
            if (assignmentStatement->right->to<IR::Member>() || (assignmentStatement->right->to<IR::PathExpression>())) {
                if(direct_relevantVar.find(left) != direct_relevantVar.end()) {
                    // direct reg-reg
                    for(auto representativeLeft : *invVarCandidates[left]) {
                        if(invVarCandidates[right]) {
                            for(auto representativeRight : *invVarCandidates[right]) {
                                dir_reg_reach_reg_set[representativeRight] = 
                                unionRegIdxSets(dir_reg_reach_reg_set[representativeLeft], dir_reg_reach_reg_set[representativeRight]);
                                break;
                            }
                            break;
                        }
                    }
                    direct_relevantVar[right] = unionRegIdxSets(direct_relevantVar[left], direct_relevantVar[right]);
                }
            }
        }
    }

    if(auto slice = assignmentStatement->left->to<IR::Slice>()){
        cstring leftt = translate(assignmentStatement->left);
        cstring rightt = translate(assignmentStatement->right);
        // std::cout << "debug Assign " + leftt + "," + rightt + "\n";
        cstring res = "";
        cstring left = translate(slice->e0);
        updateModifiedVariables(left);
        res += getIndent()+left + " = ";
        if(auto typeBits = slice->e0->type->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(typeBits);

            int size, l, r;
            size = typeBits->size;
            std::stringstream ss;
            ss << translate(slice->e1);
            ss >> l;
            std::stringstream ss2;
            ss2 << translate(slice->e2);
            ss2 >> r;
            l++;
            if(l < size)
                res += leftt + " + ";//left+"["+std::to_string(size)+":"+std::to_string(l)+"]++";
            if(r > 0) {
                res += "(" + translate(assignmentStatement->right) + " << " + std::to_string(r) + ")";
                cstring mask = "((1 << " + std::to_string(r) + ") - 1)";
                res += " + (" + left + " & " + mask + ")"; //" + "+left+"["+std::to_string(r)+":0]";
            } else {
                res += translate(assignmentStatement->right);
            }
            res += ";\n";
            currentProcedure->addStatement(res);
            return "";
        }
        return "";
    }
    cstring res = "";
    cstring left = translate(assignmentStatement->left);
    cstring right = translate(assignmentStatement->right);
    // std::cout << "Assign left: " + left + "\tAssign Right: " + right + "\n";
    if(right=="havoc"){
        updateModifiedVariables(left);
        currentProcedure->addStatement(getIndent()+"havoc "+left+";\n");
        return "";
    }
    if(options.bitBlasting && assignmentStatement->left->type->to<IR::Type_Bits>()){
        auto typeBits = assignmentStatement->left->type->to<IR::Type_Bits>();
        int size = typeBits->size;
        for(int i = 0; i < size; i++){
            updateModifiedVariables(connect(left, i));
            currentProcedure->addStatement(getIndent()+connect(left, i)+" = "+
                connect(right, i)+";\n");
        }
        if(left==stringWithPrefix("standard_metadata.egress_spec")){
            for(int i = 0; i < EGRESS_SPEC_SIZE; i++){
                currentProcedure->addStatement(getIndent()+connect(stringWithPrefix("standard_metadata.egress_port"), i)+
                    " = "+connect(right, i)+";\n");
                currentProcedure->addModifiedGlobalVariables(connect(stringWithPrefix("standard_metadata.egress_port"), i));
            }
            res += getIndent()+"" + stringWithPrefix("_forward") + " = true;\n";
            currentProcedure->addModifiedGlobalVariables(stringWithPrefix("_forward"));
        }
    }
    else{
        updateModifiedVariables(left);
        res = getIndent()+left+" = " +right+";\n";

        // tna 对寄存器的读，是一个赋值操作
        if (right.find(".execute")) {
            res = getIndent()+ right.replace(".execute", "");
            res = res.replace("PLACEHOLDER_REGISTERACTION_RESULT", left);
            res += ";\n";
        }

        if(left==stringWithPrefix("standard_metadata.egress_spec")){
            res += getIndent()+stringWithPrefix("standard_metadata.egress_port") + " = " + right+";\n";
            res += getIndent()+"" + stringWithPrefix("_forward") + " = true;\n";
            currentProcedure->addModifiedGlobalVariables(stringWithPrefix("standard_metadata.egress_port"));
            currentProcedure->addModifiedGlobalVariables(stringWithPrefix("_forward"));
        }
        currentProcedure->addStatement(res);
    }
    return "";
}

void Translator::addAssertionStatements(){
    for(cstring stmt:assertionStatements){
        if(currentProcedure != nullptr)
            currentProcedure->addStatement(stmt);
    }
    assertionStatements.clear();
}

void Translator::storeAssertionStatement(cstring stmt){
    assertionStatements.insert(stmt);
}

cstring Translator::translate(const IR::IfStatement *ifStatement, const bool firstIfStat){
    if (needPrune && removeIds.count(ifStatement->id) > 0) {
        return "";
    }
    // all branch condition
    generateBooleanAtom(ifStatement->condition, true);

    cstring condition = firstIfStat ? getIndent() + "if\n" : "";
    if(options.addValidityAssertion) isIfStatement = true;
    condition += getIndent() + ":: " + translate(ifStatement->condition) + " -> \n";
    currentProcedure->addStatement(condition);

    if(options.addValidityAssertion) isIfStatement = false;
    if(options.addValidityAssertion) addAssertionStatements();
    
    incIndent();
    translate(ifStatement->ifTrue);
    decIndent();

    if(ifStatement->ifFalse!=nullptr){
        if (needPrune && removeIds.count(ifStatement->ifFalse->id) > 0) {
            return "";
        }
        // if (auto elseif = ifStatement->ifFalse->to<IR::IfStatement>()) {
            // std::cout << "elseif " << condition << std::endl;
            // translate(elseif, false);
        // } else {
            // std::cout << "last else " << condition << std::endl;
            currentProcedure->addStatement(getIndent()+":: else -> \n");
            incIndent();
            translate(ifStatement->ifFalse);
            decIndent();
            currentProcedure->addStatement(getIndent()+"fi\n");
        // }
    } else {
        currentProcedure->addStatement(getIndent()+":: else -> skip;\n");
        currentProcedure->addStatement(getIndent()+"fi\n");
    }
    return "";
}

cstring Translator::translate(const IR::BlockStatement *blockStatement){
    if (needPrune && removeIds.count(blockStatement->id) > 0) {
        return "";
    }
    cstring res = "";

    for(auto statOrDecl:blockStatement->components){
        currentProcedure->addStatement(translate(statOrDecl));
    }
    return res;
}

cstring Translator::translate(const IR::MethodCallStatement *methodCallStatement){
    if (needPrune && removeIds.count(methodCallStatement->id) > 0) {
        return "";
    }
    cstring expr = translate(methodCallStatement->methodCall->method); // methodCallStatement->methodCall->method 类型是 Member
    // std::cout << "debug MethodCallStatement:" << expr << std::endl;
    if(expr.find("verify_checksum") != nullptr){
        return "";//getIndent()+"// verify_checksum\n";
    }
    else if(expr.find("update_checksum") != nullptr){
        return "";//getIndent()+"// update_checksum\n";
    }
    else if(expr.find("clone3") != nullptr){
        return "";//getIndent()+"// clone\n";
    } else if (expr.find(".advance") || expr.find("lookahead")) {
        return "\n";
    }
    // else if(expr.find("hash") != nullptr){
    else if(expr==stringWithPrefix("hash")){
        currentProcedure->addStatement(getIndent()+"// hash\n");
        cstring expr2 = translate(methodCallStatement->methodCall);
        currentProcedure->addStatement(getIndent()+expr2);
        // currentProcedure->addStatement(getIndent()+expr2+";\n");
        return "";
    }
    else if(expr.find("digest") != nullptr){
        return "";//getIndent()+"// digest\n";
    }
    else if(expr.find(".count") != nullptr){
        return "";//getIndent()+"// count\n";
    }
    else if(expr.find(".write") != nullptr){
        currentProcedure->addStatement(getIndent()+"// write\n");
        cstring expr2 = translate(methodCallStatement->methodCall);
        currentProcedure->addStatement(getIndent()+expr2+";\n");
        return "";
    }
    else if(expr.find(".read") != nullptr){
        cstring expr2 = translate(methodCallStatement->methodCall);
        if(expr2 != ""){
            currentProcedure->addStatement(getIndent()+"// read\n");
            currentProcedure->addStatement(getIndent()+expr2+";\n");
        }
        return "";
    } else if (expr.find(".execute")) { // tna
        cstring expr2 = translate(methodCallStatement->methodCall);
        expr2 = expr2.replace(".execute", "");
        // 有时候，可以读的execute，也可能没有用到返回值
        auto v = stringWithPrefix("FAKE_VAR_FOR_REG_EXECUTE");
        if (!isGlobalVariable(v)) {
            type_define += "bit " + v + ";\n";
            addGlobalVariables(v);
        }
        expr2 = expr2.replace("PLACEHOLDER_REGISTERACTION_RESULT", v);
        currentProcedure->addStatement(getIndent()+"// write\n");
        currentProcedure->addStatement(getIndent()+expr2+";\n");
        return "";
    }
    else if(expr.find("random") != nullptr){
        return "";//getIndent()+"// random\n";
    }
    else if(expr.find(".push_front") != nullptr){
        cstring expr2 = translate(methodCallStatement->methodCall);
        return expr2;//getIndent()+"// push_front\n";
    }
    else if(expr.find(".pop_front") != nullptr){
        cstring expr2 = translate(methodCallStatement->methodCall);
        return expr2;//getIndent()+"// pop_front\n";
    }
    else if(expr.find(".execute_meter") != nullptr){
        return "";//getIndent()+"// execute_meter\n";
    }
    else if(expr.find("truncate") != nullptr){
        return "";//getIndent()+"// truncate\n";
    }
    else if(expr.find("recirculate") != nullptr){
        auto recirculate = stringWithPrefix("V1_RECIRCULATE_FLAG");
        currentProcedure->addStatement(getIndent()+recirculate+" = 1;\n");
        return "";//getIndent()+"// recirculate\n";
    }
    else if(expr == "verify"){
        currentProcedure->addStatement(getIndent()+"// verify\n");
        cstring expr2 = translate(methodCallStatement->methodCall);
        currentProcedure->addStatement(getIndent()+expr2+";\n");
        return "";
    } else if (expr.find("packet_in.extract")) {
        return translate(methodCallStatement->methodCall);
    }
    else if (expr.find(".emit")) {
        cstring expr2 = getIndent() + translate(methodCallStatement->methodCall);
        currentProcedure->addStatement(expr2);
        return expr2;
    }
    else if(expr.find("resubmit") != nullptr){
        auto resubmit = stringWithPrefix("V1_RESUBMIT_FLAG");
        currentProcedure->addStatement(getIndent()+resubmit+" = 1;\n");
        return "";//getIndent()+"// resubmit\n";
    }
    cstring expr2 = translate(methodCallStatement->methodCall);
    if(expr2.find(";\n")){
        currentProcedure->addStatement(getIndent()+expr2);
    }
    else if(expr2 != ""){
        currentProcedure->addStatement(getIndent()+expr2+";\n");
    }
    return "";
}

cstring Translator::translate(const IR::SwitchStatement *switchStatement){
    if (needPrune && removeIds.count(switchStatement->id) > 0) {
        return "";
    }
    cstring res = "";
    cstring expr = translate(switchStatement->expression);
    if(auto actionEnum = switchStatement->expression->type->to<IR::Type_ActionEnum>()){

            cstring tableName;
            std::string s = expr.c_str();
            std::string::size_type idx = s.find(".apply()");
            if(idx != std::string::npos){
                int i = idx;
                tableName = s.substr(0, idx);
            }
            // get the corresponding table
            const IR::P4Table* p4Table = tables[tableName];
            currentProcedure->addStatement(getIndent()+tableName+"_apply();\n");
            bool firstAction = true;

            bool fallThrough = false;
            bool caseCnt = 0;
            for(auto switchCase:switchStatement->cases){
                caseCnt++;
                if (auto defaultExpression = switchCase->label->to<IR::DefaultExpression>()){}
                else{
                    // no fall through
                    if(!fallThrough){
                        if(firstAction){
                            currentProcedure->addStatement(getIndent()+"if\n" + getIndent()+":: (");
                            firstAction = false;
                        }
                        else{
                            currentProcedure->addStatement(getIndent()+":: (");
                        }
                    }
                    else
                        currentProcedure->addStatement(" || ");
                    
                    // get the corresponding action
                    cstring actionName = translate(switchCase->label);
                    currentProcedure->addStatement(tableName+"_action_run == "+tableName+"_action_"+actionName);
                    if(switchCase->statement != nullptr){
                        fallThrough = false;
                        currentProcedure->addStatement(") -> \n");
                        incIndent();
                        currentProcedure->addStatement(translate(switchCase->statement));
                        decIndent();
                        // currentProcedure->addStatement(getIndent()+"}\n");
                    }
                    else{
                        fallThrough = true;
                        if(caseCnt == switchStatement->cases.size()){
                            currentProcedure->addStatement(") -> \n");
                            currentProcedure->addStatement(getIndent()+"skip\n");
                        }
                    }
                }
            }
            currentProcedure->addStatement(getIndent()+"fi\n");
        // }
    }

    // TODO consider ordinary switch expression (value)
    // testcase: testdata/p4_16_samples/switch-expression.p4
    currentProcedure->addStatement(res);
    return "";
}

cstring Translator::translate(const IR::Expression *expression){
    if (auto methodCall = expression->to<IR::MethodCallStatement>()){
        if (needPrune && removeIds.count(methodCall->id) > 0) {
            return "";
        }
        return translate(methodCall);
    }
    else if (auto member = expression->to<IR::Member>()){
        auto a = translate(member);
        return a;
    }
    else if (auto pathExpression = expression->to<IR::PathExpression>()){
        auto a = translate(pathExpression);
        return a;
    }
    else if (auto methodCallExpression = expression->to<IR::MethodCallExpression>()){
        return translate(methodCallExpression);
    }
    else if (auto opBinary = expression->to<IR::Operation_Binary>()){
        return translate(opBinary);
    }
    else if (auto constant = expression->to<IR::Constant>()){
        return translate(constant);
    }
    else if (auto boolLiteral = expression->to<IR::BoolLiteral>()){
        return translate(boolLiteral);
    }
    else if (auto constructorCallExpression = expression->to<IR::ConstructorCallExpression>()){
        return translate(constructorCallExpression);
    }
    else if (auto slice = expression->to<IR::Slice>()){
        return translate(slice);
    }
    else if (auto opUnary = expression->to<IR::Operation_Unary>()){
        return translate(opUnary);
    } else if (auto structExpression = expression->to<IR::StructExpression>()) {
        return translate(structExpression);
    }
    else if (auto defaultExpression = expression->to<IR::DefaultExpression>()){
        return "default";
    }
    return "";
}


cstring Translator::translate(const IR::NamedExpression* namedExpression) { 
    auto name = namedExpression->name;
    auto value = translate(namedExpression->expression);
    return name + " = " + value;
}

// 结构体初始化 {value for field1, value for field2, ...}
cstring Translator::translate(const IR::StructExpression* structExpression) {
    auto structTypeName = translate(structExpression->structType);
    // 不知道赋值给谁，因为硬件只管把这些值放到比特流里。
    // 这边只能先不填，等手动改成真的变量
    auto variableName = "手动改";

    cstring res = "";
    for (auto field : structExpression->components) {
        auto assignment = translate(field);
        res += getIndent() + variableName + "." + assignment + ";\n";
    }
    return res;
}

cstring Translator::translate(const IR::MethodCallExpression *methodCallExpression){
    if (needPrune && removeIds.count(methodCallExpression->id) > 0) {
        return "";
    }
    cstring res = "";
    cstring method = translate(methodCallExpression->method); // 调用了 methodCallExpression->method 是 Member 类型

    if(method==stringWithPrefix("mark_to_drop")){
        updateModifiedVariables(stringWithPrefix("_drop"));
        currentProcedure->addSucc(method);
        addPred(method, currentProcedure->getName());
        return stringWithPrefix("mark_to_drop()");
    }

    if(method.find("packet_in.extract")){
        cstring arg = "";
        for(auto argument:*methodCallExpression->arguments){
            arg = translate(argument);
            break;
        }
        
        if(arg.find(".next")) { // header stack
            std::string::size_type idx = ((std::string)arg.c_str()).find(".next");
            cstring header = arg.substr(0, idx);

            res += header + ".last = " + header + ".last + 1;\n    ";
            // arg = header + ".elements[" + header + ".last]";
            arg = header;
        }
         
        res += arg+".valid = true;\n";
        currentProcedure->addModifiedGlobalVariables(arg+".valid");
        if(options.addValidityAssertion){
            cstring stmt = "assert("+arg+".valid);";
            if(currentProcedure->lastStatement().find(stmt)!= nullptr){
                currentProcedure->removeLastStatement();
            }
        } 
        return res;
    }

    if(method.find(".emit")){ // packet.emit, mirror.emit, resumbit.emit
        auto type = methodCallExpression->method->to<IR::Member>()->expr->type->to<IR::Type_Extern>()->name;
        if (type == "packet_out") {
            cstring hdr_name = translate((*methodCallExpression->arguments)[0]); // e.g., s1_hdr.ipv4
            res += get_emit_var_name(hdr_name.replace(".", "_")) + " = true;\n";
        } else if (type == "Mirror") {
            // mirror.emit(session_id)  或有参数 mirror.emit<mirror_h>(session_id, {field list})
            auto typeArguments = *methodCallExpression->typeArguments;
            auto mirrorHeaderType = "";
            if (typeArguments.size() > 0) {
                mirrorHeaderType = translate(typeArguments[0]);
            }
            auto arguments = *methodCallExpression->arguments;
            auto mirror_session_id = translate(arguments[0]);
            auto fieldAssignemts = "";
            if (arguments.size() > 1) {
                fieldAssignemts = translate(arguments[1]);
            }

            auto v = stringWithPrefix("mirror_id"); // 硬件处理，没法拿数据，只能自己存
            if (!isGlobalVariable(v)) {
                type_define += "byte " + v + ";\n";
                addGlobalVariables(v);
            }

            res += getIndent() + v + " = " + mirror_session_id + ";\n";
            // 赋值给 mirro header
            res += fieldAssignemts;
        } else if (type == "Resubmit") {
            res = "// resubmit";
        }
        return res;
    }

    if (method.find(".apply")) {
         method = method.replace('.', '_');
    }

    // Register read (BMV2)
    if(method.find(".read")){
        // method = methodCallExpression->method->toString();
        std::string::size_type idx = ((std::string)method.c_str()).find(".read");
        cstring reg = ((std::string)method.c_str()).substr(0, idx);  // register
        if(!isGlobalVariable(reg)){
            method = translate(methodCallExpression->method);
            idx = ((std::string)method.c_str()).find(".read");
            reg = ((std::string)method.c_str()).substr(0, idx);
        }
        method = method.replace('.', '_');

        if((*methodCallExpression->arguments).size() == 1) return "";

        cstring arg0 = translate((*methodCallExpression->arguments)[0]);  // return addr

        currentProcedure->addModifiedGlobalVariables(arg0);
        cstring arg1 = translate((*methodCallExpression->arguments)[1]);  // index

        currentProcedure->addSucc(method);
        addPred(method, currentProcedure->getName());
        res += method + "(" + arg1  + "," + arg0 + ")";
        return res;
    }


    if(method.find(".write")){
        std::string::size_type idx = ((std::string)method.c_str()).find(".write");
        cstring reg = ((std::string)method.c_str()).substr(0, idx);  // register
        if(!isGlobalVariable(reg)){
            method = translate(methodCallExpression->method);
        }
        method = method.replace('.', '_');

        currentProcedure->addSucc(method);
        addPred(method, currentProcedure->getName());

    }

    // tna register action
    if (method.find(".execute")) {
        auto registerActionName = method.replace(".execute", "");

        auto argument = methodCallExpression->arguments;
        auto idx = "";
        if (argument->size() > 0) {
            idx = translate((*argument)[0]);
        } else { // 存在重命名后，导致ir里 arguments 是没数据的
            auto sourceInfo = methodCallExpression->srcInfo.srcBrief;
            auto i = ((std::string)sourceInfo.c_str()).find(")");
            idx = sourceInfo.substr(i-1, 1);
        }
        // get info related to this registerAction
        auto instance = instances[registerActionName];
        auto registerName = translate((*instance->arguments)[0]->expression);
        
        res = method + "(" + registerName + "[" + idx + "]";
        // 两个参数，一个inout，一个out，是读（注意，在里面也可有写操作
        // 否则是写操作
        auto function = instance->initializer->components[0]->to<IR::Function>();
        int paraCount = (function->type->parameters->parameters).size();
        if (paraCount == 2) {
            res += ", PLACEHOLDER_REGISTERACTION_RESULT"; // 留一个标志，给AssignmentStatement处理
        }
        
        res += ")";
        // std::cout << "debug execute:" << res << std::endl;
        currentProcedure->addSucc(registerActionName);
        addPred(registerActionName, currentProcedure->getName());

        return res;
    }

    if(method=="hash"){
        cstring arg0 = translate((*methodCallExpression->arguments)[0]);  // return addr

        res += "havoc "+arg0+";\n";
        currentProcedure->addModifiedGlobalVariables(arg0);
        return res;
    }

    if(method=="verify"){
        cstring arg = translate((*methodCallExpression->arguments)[0]);
        res += "assert("+arg+")";
        return res;
    }

    if (method.find(".push_front")) {
        std::string::size_type idx = ((std::string)method.c_str()).find(".push_front");
        cstring header = method.substr(0, idx);
        
        cstring arg0 = translate((*methodCallExpression->arguments)[0]); // todo: 

        res += getIndent() + header + ".last = " + header + ".last+1;\n";
        // res += getIndent() + header + ".elements[" + header + ".last].valid = false;\n";
        cstring push_front_func = "push_front_" +header.replace(".", "_");
        res += getIndent() + push_front_func +"();\n";
        currentProcedure->addSucc(push_front_func);
        addPred(push_front_func, currentProcedure->getName());
        return res;
    }

    if (method.find(".pop_front")) {
        std::string::size_type idx = ((std::string)method.c_str()).find(".pop_front");
        cstring header = method.substr(0, idx);
        
        cstring arg0 = translate((*methodCallExpression->arguments)[0]); // todo: 

        // res += getIndent() + header + ".elements[" + header + ".last].valid = false;\n";
        cstring pop_front_func = "pop_front_" +header.replace(".", "_");
        res += getIndent() + pop_front_func +"();\n";
        currentProcedure->addSucc(pop_front_func);
        addPred(pop_front_func, currentProcedure->getName());
        res += getIndent() + header + ".last = " + header + ".last - 1;\n";
        return res;
    }

    std::string s = method.c_str();
    std::string::size_type idx = s.find("isValid");
    if(idx != std::string::npos){
        int i = idx;

        return s.substr(0, idx-1)+".valid";

    }

    if(method.find("setValid(") != nullptr || method.find("setInvalid(")){
        if(options.addValidityAssertion){
            if(currentProcedure->lastStatement().find("assert(")!= nullptr){
                currentProcedure->removeLastStatement();
            }
        }
        bool valid = method.find("setValid(") != nullptr;
        cstring arg0 = translate(methodCallExpression->method->to<IR::Member>()->expr) + ".valid";
        // cstring arg0 = (valid ? method.substr(cstring("setValid(").size(), method.size()-cstring("setValid(").size()-1) : method.substr(cstring("setInvalid(").size(), method.size()-cstring("setInvalid(").size()-1)) \
        // + ".valid";
        updateModifiedVariables(arg0);
        cstring validValue = valid ? "true" : "false";
        cstring setStmt = arg0 + " = " + validValue + ";\n";
        return setStmt;
    }

    if(methodCallExpression->arguments->size()>0){
        cstring argument = translate((*methodCallExpression->arguments)[0]);
        std::string s = argument.c_str();
        std::string::size_type idx = s.find("next"); //todo ?
        if(idx != std::string::npos){
            int i = idx;
            cstring succ = "packet_in.extract.headers.";
            succ += s.substr(4, idx-5)+".next";
            res = succ+"("+s.substr(0, idx-1)+")";
            currentProcedure->addSucc(succ);
            addPred(succ, currentProcedure->getName());

            return res;
        }
    }

    currentProcedure->addSucc(method);
    addPred(method, currentProcedure->getName());

    res += method+"(";
    int cnt = methodCallExpression->arguments->size();
    for(auto arg:*methodCallExpression->arguments){
        res += translate(arg);
        cnt--;
        
        // packet_in.extract with multiple parameters (only consider the first param)
        if(method.find("extract") != nullptr){
            break;
        }

        if(cnt != 0)
            res += ", ";
    }
    res += ")";
    return res;
}

cstring Translator::translate(const IR::Member *member){
    // std::cout << "member: " << member->member.toString() << std::endl;
    if(member->member.toString()=="extract")
        return stringWithPrefix("packet_in.extract");
    if(member->member.toString()=="lookahead")
        return stringWithPrefix("lookahead");
    if(member->member.toString()=="setValid")
        return "setValid("+translate(member->expr)+")";
    if(member->member.toString()=="setInvalid")
        return "setInvalid("+translate(member->expr)+")";
    // TODO: NoAction should not be considered
    if(member->member.toString()=="hit"){
        cstring expr = translate(member->expr);
        std::string s = expr.c_str();
        std::string::size_type idx = s.find(".apply()");
        if(idx != std::string::npos){
            int i = idx;
            cstring tableName = s.substr(0, idx);
            currentProcedure->addStatement(getIndent()+tableName+"_apply();\n");
            currentProcedure->addSucc(tableName+"_apply");
            addPred(tableName+"_apply", currentProcedure->getName());
            // IR::P4Table* p4Table = tables[tableName];
            return tableName+"_hit";
        }
        // std::cout << translate(member->expr).find(".apply()") << std::endl;
        // std::cout << translate(member->expr) << std::endl;
        // std::cout << member << std::endl;
    }

    // For header stack
    if(auto arrayIndex = member->expr->to<IR::ArrayIndex>()){
        if(options.addBoundAssertion){
            if(auto typeStack = arrayIndex->left->type->to<IR::Type_Stack>()){
                currentProcedure->addStatement(getIndent()+"assert ("
                                                +translate(arrayIndex->right)+ "<" +
                                                translate(typeStack->size)+");\n");
                }
            // }
        }
        // return translate(arrayIndex->left)+"."+translate(arrayIndex->right)+"."+handle_keyword(member->member.toString());
        cstring left = translate(arrayIndex->left);
        // cstring index = left + ".last - " + translate(arrayIndex->right);
        // return left + ".elements["+index+"]."+handle_keyword(member->member.toString());
        cstring index = translate(arrayIndex->right);
        return left + ".element_"+index+"."+handle_keyword(member->member.toString());
    }

    if(auto typeHeader = member->type->to<IR::Type_Header>()){
        cstring hdr = translate(member->expr)+"."+handle_keyword(member->member.toString());
        // cstring stmt = getIndent()+"assert(isValid["+hdr+"]);\n";
        cstring stmt = getIndent()+"assert("+hdr+".valid);\n";
        if(options.addValidityAssertion){
            if(hdr.find(".next") == nullptr && hdr.find(".last") == nullptr){
                if(currentProcedure->lastStatement() == "" || 
                    (currentProcedure->lastStatement() != stmt 
                        && stmt.find(currentProcedure->lastStatement()) == nullptr)){
                    if(isIfStatement) storeAssertionStatement(stmt);
                    else currentProcedure->addStatement(stmt);

                }
                else{

                }
            }
        }
        return hdr;
    }

    // collect relevant var
    auto result = translate(member->expr)+"."+handle_keyword(member->member.toString()); // path.member, e.g., reg.read
    if(collect != 0)
        relevantVar_collector.insert(result);
    return result;
}

cstring Translator::translate(const IR::PathExpression *pathExpression){
    return translate(pathExpression->path);
}

cstring Translator::translate(const IR::Path *path){
    // collect var name(not member)
     if(collect != 0)
        relevantVar_collector.insert(path->name);
    return translate(path->name);
}

cstring Translator::translate(const IR::Declaration *decl){
    if (needPrune && removeIds.count(decl->id) > 0) {
        return "";
    }
    if (auto p4Action = decl->to<IR::P4Action>()){
        translate(p4Action);
    }
    else if (auto p4Table = decl->to<IR::P4Table>()){
        translate(p4Table);
    }
    else if (auto declVar = decl->to<IR::Declaration_Variable>()){
        return translate(declVar);
    }
    else if (auto instance = decl->to<IR::Declaration_Instance>()){
        translate(instance);
    }
    return "";
}

cstring Translator::translate(const IR::Declaration_Variable *declVar){ 
    // Should be declared as global variables
    // Variables have been renamed by p4c

    cstring res = "";
    bool result = addGlobalVariables(translate(declVar->name));

    // std::cout << "debug: varname: " + declVar->name << std::endl;
    
    if(result) {
        if(auto typeBits = declVar->type->to<IR::Type_Bits>()){
            // addDeclaration("var "+translate(declVar->name)+":"+translate(declVar->type)+";\n");
            addDeclaration(translate(declVar->type) + " "+translate(declVar->name)+";\n");
        }
        else if(auto typeName = declVar->type->to<IR::Type_Name>()){
            if(headers.find(translate(typeName)) != headers.end())
                translate(headers[translate(typeName)], translate(declVar->name));
            else 
                // addDeclaration("var "+translate(declVar->name)+":"+translate(declVar->type)+";\n");
                addDeclaration(translate(declVar->type) + " "+translate(declVar->name)+";\n");
        }
        else
            // addDeclaration("var "+translate(declVar->name)+":"+translate(declVar->type)+";\n");
            addDeclaration(translate(declVar->type) + " "+translate(declVar->name)+";\n");
    }
   
    if(declVar->initializer == nullptr){
        if(currentProcedure != nullptr){
            // For Type_Unknown
            // Record the types of local variables
            if(auto typeBits = declVar->type->to<IR::Type_Bits>()){
                updateMaxBitvectorSize(typeBits);
                currentProcedure->declarationVariables[translate(declVar->name)] = typeBits->size;
            }
        }
    }
    else{
        if(currentProcedure != nullptr){
            currentProcedure->addStatement(BoogieStatement(getIndent()+translate(declVar->name)+" = "+translate(declVar->initializer)+";\n"));
            if(auto typeBits = declVar->type->to<IR::Type_Bits>()){
                updateMaxBitvectorSize(typeBits);
                currentProcedure->declarationVariables[translate(declVar->name)] = typeBits->size;
            }
        }
    }
    return res;


}

cstring Translator::translate(const IR::SelectExpression *selectExpression, cstring stateName, cstring localDeclArg){
    cstring res = "";

        cstring defaultCondition = "";
        cstring defaultBlock = "";
        bool flag = false;  // avoid multiple default cases
        // int cnt = selectExpression->selectCases.size();
        int cnt = 0;
        for(auto selectCase:selectExpression->selectCases){
            if (auto defaultExpression = selectCase->keyset->to<IR::DefaultExpression>()){
                if(flag)
                    continue;
                flag = true;
                cstring nextState = translate(selectCase->state);
                // std::cout << "debug currentProcedure111: "<< currentProcedure->getName() << ", nextState: " << nextState << std::endl;
                if (nextState == stateName) {
                    // defaultBlock = "goto " + stateName + "_label;\n"; // parser loop
                    int times = parserStateRenameTimes[nextState];
                    // avoid cyclic inline
                    nextState = times == 0 ? stringWithPrefix("accept") : nextState + "_"  + cstring::to_cstring(times);
                } // else {
                    defaultBlock += nextState+"("+localDeclArg+");\n";
                    currentProcedure->addSucc(nextState);
                    addPred(nextState, currentProcedure->getName());
                // }
                // std::cout << "debug currentProcedure222: "<< currentProcedure->getName()<< ", nextState: " << nextState << std::endl;
            }
            else{
                if(options.addValidityAssertion) isIfStatement = true;
                cstring condition = "";
                cstring nextState = translate(selectCase->state);
                int sz = selectExpression->select->components.size();
                int cnt2 = 0;
                for(auto expr:selectExpression->select->components){
                    if(auto constant = selectCase->keyset->to<IR::Constant>()){
                        condition += translate(expr);
                        condition += " == ";
                        // std::stringstream ss;
                        // ss << constant->value;
                        // condition += ss.str()+translate(constant->type);
                        condition += translate(constant);
                    }
                    else if(auto mask = selectCase->keyset->to<IR::Mask>()){
                        // cstring functionName = translate(mask);
                        cstring maskLeft = translate(mask->left);
                        cstring maskRight = translate(mask->right);
                        // condition += functionName+"("+translate(expr)+", "+maskRight+") == ";
                        // condition += functionName+"("+maskLeft+", "+maskRight+")";
                        condition += "((" + translate(expr) + " & " + maskRight + ") == " + "(" + maskLeft + " & " + maskRight + "))";
                    }
                    else if(auto listExpression = selectCase->keyset->to<IR::ListExpression>()){
                        if(auto mask = listExpression->components.at(cnt2)->to<IR::Mask>()){
                            // cstring functionName = translate(mask);
                            cstring maskLeft = translate(mask->left);
                            cstring maskRight = translate(mask->right);
                            // condition += functionName+"("+translate(expr)+", "+maskRight+") == ";
                            // condition += functionName+"("+maskLeft+", "+maskRight+")";
                            condition += "((" + translate(expr) + " & " + maskRight + ") == " + "(" + maskLeft + " & " + maskRight + "))";
                        }
                        else{
                            condition += translate(expr)+" == ";
                            condition += translate(listExpression->components.at(cnt2));
                        }
                    }
                    cnt2++;
                    if(cnt2 < sz)
                        condition += " && ";
                }

                // transition select(hdr.overlay.last.swip)
                if (condition.find(".last.") != nullptr) {
                    std::string::size_type idx = ((std::string)condition.c_str()).find(".last");
                    cstring header = condition.substr(0, idx);
                    // condition = header + ".elements[" + header + ".last]" + condition.substr(idx+5);
                    std::string::size_type idx_2 = ((std::string)currentProcedure->getName().c_str()).find_last_of("_");
                    cstring last = currentProcedure->getName().substr(idx_2+1);
                    condition = header + ".element_" + (isNumber(last)? last : "0") + condition.substr(idx+5);
                }

                if(cnt == 0)
                    currentProcedure->addStatement(getIndent() + "if\n" + getIndent() + ":: " + condition + " -> \n");
                else 
                    currentProcedure->addStatement(getIndent() + ":: " + condition + " -> \n");
                incIndent();
                if(options.addValidityAssertion) isIfStatement = false;
                if(options.addValidityAssertion) addAssertionStatements();
                currentProcedure->addStatement(getIndent()+nextState+"("+localDeclArg+");\n");
                decIndent();
                cnt++;
                // currentProcedure->addStatement(getIndent()+"}\n");
                currentProcedure->addSucc(nextState);
                addPred(nextState, currentProcedure->getName());
            }            
        }
        if(defaultBlock.size()>0){
            currentProcedure->addStatement(getIndent()+":: else ->\n");
            incIndent();
            currentProcedure->addStatement(getIndent()+defaultBlock);
            decIndent();
            // currentProcedure->addStatement(getIndent()+"}\n");
        } else {
            currentProcedure->addStatement(getIndent()+":: else -> skip;\n");
        }
        currentProcedure->addStatement(getIndent()+"fi\n");
    // }
    return res;
}

cstring Translator::translate(const IR::Argument *argument){
    return translate(argument->expression);
}

cstring Translator::translate(const IR::Constant *constant){
    std::stringstream ss;
    ss << constant->value;
    // collect constant
    if(collect != 0)
        constant_collector.insert(std::to_string(constant->asUint64()));
    return ss.str();//+translate(constant->type);
}

cstring Translator::translate(const IR::ConstructorCallExpression *constructorCallExpression){
    return translate(constructorCallExpression->constructedType);
}

cstring Translator::translate(const IR::Cast *cast){
    if (cast->destType->to<IR::Type_Bits>() || cast->destType->to<IR::Type_Name>()){
        // std::cout << "CAST: " << cast->destType->toString() << "\n";
    // if (auto destType = cast->destType->to<IR::Type_Bits>()){
        int dstSize = -1, srcSize = -1;
        if(auto destType = cast->destType->to<IR::Type_Bits>()){
            dstSize = destType->size;
            updateMaxBitvectorSize(destType);
        }
        else if(auto destType = cast->destType->to<IR::Type_Name>()){
            cstring name = translate(destType);
            if(typeDefs.find(name) != typeDefs.end())
                dstSize = typeDefs[name];
            else return "";
        }

        cstring expr = translate(cast->expr);
        // std::cout << "CAST EXPR: " << expr << "\n";
        // std::cout << "CAST EXPR TYPE: " << cast->expr->type << "\n";
        if(auto srcType = cast->expr->type->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(srcType);
            srcSize = srcType->size;
        }
        else if(auto srcType = cast->expr->type->to<IR::Type_Unknown>()){
            // for(auto it: currentProcedure->parameters) {
            //     std::cout << "CURRENT Parra: " << it.first << "\n";
            // }

            if(currentProcedure->parameters.find(expr)!=
                currentProcedure->parameters.end()){
                srcSize = currentProcedure->parameters[expr];
                // std::cout << "FIND IT?: " << expr << "\n";
            }
            else if(currentProcedure->declarationVariables.find(expr)!=
                currentProcedure->declarationVariables.end()){
                srcSize = currentProcedure->declarationVariables[expr];
            }
        }

            return expr;
        // }

    }
    return "";
}

cstring Translator::translate(const IR::Slice *slice){
    cstring res = "";
    cstring high = translate(slice->e1), low = translate(slice->e2);
    int high_ = atoi(high), low_ = atoi(low);
    cstring mask = "(((1 << " + std::to_string(high_ - low_ + 1) + ") - 1) << " + low + ")";
    res += "(" + translate(slice->e0) + " & " + mask + ")";
    // res += "mask(" + translate(slice->e0) + ", " + high + ", " + low + ")";
    return res;
}

cstring Translator::translate(const IR::LNot *lnot){
    return "!("+translate(lnot->expr)+")";
}

// todo
cstring Translator::translate(const IR::Mask *mask){
    cstring res = "";
    if (auto typeSet = mask->type->to<IR::Type_Set>()){
        if (auto typeBits = typeSet->elementType->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(typeBits);
            cstring returnType = translate(typeBits);
            cstring functionName = "band."+returnType;
            addFunction("band", "bvand", returnType, returnType);
            return functionName;
        }
    }
    return res;
}

cstring Translator::translate(const IR::ArrayIndex *arrayIndex){
    cstring res = "";
    res += translate(arrayIndex->left);
    // res += "."+translate(arrayIndex->right);
    // std::cout << "debug ArrayIndex:" << res << std::endl;
    res += "["+translate(arrayIndex->right)+"]";
    return res;
}

cstring Translator::translate(const IR::BoolLiteral *boolLiteral){
    return boolLiteral->toString();
}

cstring Translator::translate(const IR::Type *type){
    if (auto typeBits = type->to<IR::Type_Bits>()){
        return translate(typeBits);
    }
    else if (auto typeBoolean = type->to<IR::Type_Boolean>()){
        return translate(typeBoolean);
    }
    else if (auto typeSpecialized = type->to<IR::Type_Specialized>()){
        return translate(typeSpecialized);
    }
    else if (auto typeName = type->to<IR::Type_Name>()){
        return translate(typeName);
    }
    else if (auto typeTypedef = type->to<IR::Type_Typedef>()){
        return translate(typeTypedef);
    } else if (auto typeStack = type->to<IR::Type_Stack>()){
        return translate(typeStack->elementType) + "_hs";
    }
    return "";
}

cstring Translator::translate(const IR::Type_Bits *typeBits){
    updateMaxBitvectorSize(typeBits);
    std::stringstream ss;
    //todo: ss << "unsigned " << typeBits->size;
    if (typeBits->size == 1)
        ss << "bit";
    else if (typeBits->size <= 8)
        ss << "byte";
    else if (typeBits->size <= 16)
        ss << "short";
    else
        ss << "int";
    return ss.str();
}

cstring Translator::translate(const IR::Type_Boolean *typeBoolean){
    return "bool";
}

cstring Translator::translate(const IR::Type_Specialized *typeSpecialized){
    return typeSpecialized->baseType->toString();
}

cstring Translator::translate(const IR::Type_Name *typeName){
    return translate(typeName->path);
}




void Translator::generate_struct_assign_method(cstring typeName, const IR::IndexedVector<IR::StructField> fields) {
    cstring proc_name = struct_assign_method(typeName);
    BoogieProcedure assign_struct = BoogieProcedure(proc_name);
    assign_struct.addDeclaration("inline "+proc_name+"(s1, s2)\n");
    incIndent();
    assign_struct.addStatement(getIndent() + "s1.valid = s2.valid;\n");
    for(const IR::StructField* field : fields){
        cstring fieldName = handle_keyword(field->name.toString());
        assign_struct.addStatement(getIndent() + "s1." + fieldName + " = s2." + fieldName + ";\n");
    }
    decIndent();
    addProcedure(assign_struct);
}


void Translator::generate_struct_reset_method(cstring typeName, const IR::IndexedVector<IR::StructField> fields) {
    cstring proc_name = struct_reset_method(typeName);
    BoogieProcedure reset_struct = BoogieProcedure(proc_name);
    reset_struct.addDeclaration("inline "+proc_name+"(s1)\n");
    incIndent();
    reset_struct.addStatement(getIndent() + "s1.valid = 0;\n");
    for(const IR::StructField* field : fields){
        cstring fieldName = handle_keyword(field->name.toString());
        reset_struct.addStatement(getIndent() + "s1." + fieldName + " = 0;\n");
    }
    decIndent();
    addProcedure(reset_struct);
}


cstring Translator::translate(const IR::Type_Stack *typeStack, cstring arg){
    const IR::Type_Header* typeHeader = headers[translate(typeStack->elementType)];
    if(typeHeader!=nullptr && stacks.find(arg)==stacks.end()){
        stacks.insert(arg);

        translate(typeHeader, arg);

        // promela can not assign a struct to another struct;
        cstring type_name = translate(typeStack->elementType);
        generate_struct_assign_method(type_name, typeHeader->fields);
    }
    return "";
}

cstring Translator::translate(const IR::Type_Typedef *typeTypedef){
    cstring name = translate(typeTypedef->name);
    if(currentTraverseTimes > 1)
        return "";

    if(auto typeBits = typeTypedef->type->to<IR::Type_Bits>()){
        typeDefs[name] = typeBits->size;
    }
    addTypeDef("#define "+name+" "+translate(typeTypedef->type)+"\n");
    
    return "";
}

cstring Translator::bitBlastingTempDecl(const cstring &tmpPrefix, int size){
    for(int i = 0; i < size; i++){
        cstring tempVar = connect(tmpPrefix, i);
        // addDeclaration("var "+tempVar+" : bool;\n");
        addDeclaration("bool "+tempVar+";\n");
        addGlobalVariables(tempVar);
        updateVariableSize(tempVar, 0);
        if(currentProcedure != nullptr)
            currentProcedure->addModifiedGlobalVariables(tempVar);
    }
}

cstring Translator::bitBlastingTempAssign(const cstring &tmpPrefix, int start, int end){
    for(int i = start; i <= end; i++){
        currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" = false;\n");
    }
}

cstring Translator::exprXor(const cstring &a, const cstring &b){
    // (!a&&b || a&&!b)
    return "(!"+a+" && "+b+") || ("+a+" && !"+b+")";
}

cstring Translator::exprXor(const cstring &a, const cstring &b, const cstring &c){
    // (!a&&!b&&c || !a&&b&&!c || a&&!b&&!c || a&&b&&c)
    return "(!"+a+" && !"+b+" && "+c+") || (!"+a+" && "+b+" && !"+c+") || ("+
           a+" && !"+b+" && !"+c+ ") || ("+a+" && "+b+" && "+c+")";
}

cstring Translator::connect(const cstring &expr, int idx){
    return expr+SPLIT+toString(idx);
}

cstring Translator::integerBitBlasting(int num, int size){
    cstring res = getTempPrefix();
    bitBlastingTempDecl(res, size);
    for(int i = 0; i < size; i++){
        bool bit = num&1;
        num >>= 1;
        if(bit)
            currentProcedure->addStatement(getIndent()+connect(res, i)+" = true;\n");
        else
            currentProcedure->addStatement(getIndent()+connect(res, i)+" = false;\n");
    }
    return res;
}

cstring Translator::bitBlasting(const IR::Operation_Binary *opBinary){
    if (auto arrayIndex = opBinary->to<IR::ArrayIndex>()) {
        return translate(arrayIndex);
    }
    else if (auto mask = opBinary->to<IR::Mask>()) {
        return translate(mask);
    }
    else if (opBinary->left->type->to<IR::Type_Bits>() || 
        currentProcedure->declarationVariables.find(translate(opBinary->left)) != currentProcedure->declarationVariables.end()){
        int size;
        // cstring typeName;
        if(auto typeBits = opBinary->left->type->to<IR::Type_Bits>()){
            size = typeBits->size;
            // typeName = translate(opBinary->left->type);
        }
        else{
            size = currentProcedure->declarationVariables[translate(opBinary->left)];
            //typeName = "bv"+toString(size);
        }
        if (auto shl = opBinary->to<IR::Shl>()){ 
            // the 2nd parameter must be constant integer
            if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>()){
                cstring tmpPrefix = getTempPrefix();
                bitBlastingTempDecl(tmpPrefix, size);

                int right = atoi(translate(opBinary->right));
                cstring left = translate(opBinary->left);

                if(right >= size) bitBlastingTempAssign(tmpPrefix, 0, size-1);
                else{
                    bitBlastingTempAssign(tmpPrefix, size-right, size-1);
                    for(int i = 0; i < size-right; i++){
                        currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)
                            +" = "+connect(left, i-right)+";\n");
                    }
                }
                return tmpPrefix;
            }
            return "";
        }
        else if (auto shr = opBinary->to<IR::Shr>()){
            // the 2nd parameter must be constant integer
            if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>()){
                cstring tmpPrefix = getTempPrefix();
                bitBlastingTempDecl(tmpPrefix, size);

                int right = atoi(translate(opBinary->right));
                cstring left = translate(opBinary->left);

                if(right >= size) bitBlastingTempAssign(tmpPrefix, 0, size-1);
                else{
                    bitBlastingTempAssign(tmpPrefix, 0, right-1);
                    for(int i = right; i < size; i++){
                        currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)
                            +" = "+connect(left, i-right)+";\n");
                    }
                }
                return tmpPrefix;
            }
            return "";
        }
        else if (auto mul = opBinary->to<IR::Mul>()){
            return "";
        }
        else if (auto add = opBinary->to<IR::Add>()){
            /*  Example:
                    vector<bool> res(a.size(), false);
                    res[0] = a[0]^b[0];        bool tmp1 = a[0]&b[0];
                    res[1] = a[1]^b[1]^tmp1;   bool tmp2 = a[1]&b[1] || a[1]&tmp1 || b[1]&tmp1;
                    res[2] = a[2]^b[2]^tmp2;   bool tmp3 = a[2]&b[2] || a[2]&tmp1 || b[2]&tmp2;
                    return res;
                Note that:
                    a[0]^b[0] = a[0]&!b[0] || !a[0]&b[0]
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, size);

            std::vector<cstring> tmpPrefixes;
            for(int i = 0; i < size; i++){
                tmpPrefixes.push_back(getTempPrefix());
                bitBlastingTempDecl(tmpPrefixes.back(), 1);
            }

            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }
            currentProcedure->addStatement(getIndent()+connect(tmpPrefix, 0)+" ="
                +exprXor(connect(left, 0), connect(right, 0))+";\n");
            currentProcedure->addStatement(getIndent()+connect(tmpPrefixes[0], 0)+" ="
                +connect(left, 0)+" && "+connect(right, 0)+";\n");
            for(int i = 1; i < size; i++){
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" ="
                    +exprXor(connect(left, i), connect(right, i), connect(tmpPrefixes[i-1], 0))+";\n");
                currentProcedure->addStatement(getIndent()+connect(tmpPrefixes[i], 0)+" =("
                    +connect(left, i)+" && "+connect(right, i)+ ") || ("
                    +connect(left, i)+" && "+connect(tmpPrefixes[i-1], 0)+") || ("
                    +connect(right, i)+" && "+connect(tmpPrefixes[i-1], 0)+");\n");
            }
            return tmpPrefix;
        }
        else if (auto addSat = opBinary->to<IR::AddSat>()) {
            return "";
        }
        else if (auto sub = opBinary->to<IR::Sub>()) {
            /*  Example:
                vector<bool> tmp(b.size()), res(b.size());
                // tmp = ~b+1
                tmp[0] = (!b[0])^1;     bool tmp1 = (!b[0])&1;
                tmp[1] = (!b[1])^tmp1;  bool tmp2 = (!b[1])&tmp1;
                tmp[2] = (!b[2])^tmp2;  bool tmp3 = (!b[2])&tmp2;
                // a + tmp
                res[0] = a[0]^tmp[0];        bool tmp4 = a[0]&tmp[0];
                res[1] = a[1]^tmp[1]^tmp4;   bool tmp5 = a[1]&tmp[1] || a[1]&tmp4 || tmp[1]&tmp4;
                res[2] = a[2]^tmp[2]^tmp5;   bool tmp6 = a[2]&tmp[2] || a[2]&tmp5 || tmp[2]&tmp5;
                return res;
            */

            // res = left-right
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, size);

            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            // -right
            cstring negRight = getTempPrefix();
            bitBlastingTempDecl(negRight, size);

            cstring negRightTmp = getTempPrefix();
            bitBlastingTempDecl(negRightTmp, size);
            
            // negRight[0] = (!right[0])^true
            currentProcedure->addStatement(getIndent()+connect(negRight, 0)+" ="+
                exprXor("(!"+connect(right, 0)+")", "true")+";\n");
            // negRightTmp[0] = (!right[0])&true
            currentProcedure->addStatement(getIndent()+connect(negRightTmp, 0)+" =(!"+
                connect(right, 0)+") && true;\n");
            for(int i = 1; i < size; i++){
                // negRight[i] = (!right[i]) ^ negRightTmp[i-1]
                currentProcedure->addStatement(getIndent()+connect(negRight, i)+" = "+
                    exprXor("(!"+connect(right, i)+")", connect(negRightTmp, i-1))+";\n");
                // negRightTmp[i] = (!right[i]) & negRightTmp[i-1]
                currentProcedure->addStatement(getIndent()+connect(negRight, i)+" = (!"+
                    connect(right, i)+") && "+connect(negRightTmp, i-1)+";\n");
            }

            cstring resTmp = getTempPrefix();
            bitBlastingTempDecl(resTmp, size);
            // res[0] = left[0] ^ negRight[0]
            currentProcedure->addStatement(getIndent()+connect(tmpPrefix, 0)+" = "+
                exprXor(connect(left, 0), connect(negRight, 0))+";\n");
            // resTmp[0] = left[0] & negRight[0]
            currentProcedure->addStatement(getIndent()+connect(resTmp, 0)+" = "+
                connect(left, 0)+" && "+connect(negRight, 0)+";\n");
            for(int i = 1; i < size; i++){
                // res[i] = left[i] ^ negRight[i] ^ resTmp[i-1]
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" = "+
                    exprXor(connect(left, i), connect(negRight, i), connect(resTmp, i-1))+";\n");
                currentProcedure->addStatement(getIndent()+connect(resTmp, i)+" = ("+
                    connect(left, i)+" && "+connect(right, i)+") || ("+
                    connect(left, i)+" && "+connect(resTmp, i-1)+") || ("+
                    connect(right, i)+" && "+connect(resTmp, i-1)+");\n");
            }

            return tmpPrefix;
        }
        else if (auto subSat = opBinary->to<IR::SubSat>()) {
            return "";
        }
        else if (auto bAnd = opBinary->to<IR::BAnd>()) {
            /*  Example:
                    vector<bool> res(a.size(), false);
                    res[0] = a[0]&b[0];
                    res[1] = a[1]&b[1];
                    res[2] = a[2]&b[2];
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, size);
            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i < size; i++){
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" = "
                    +connect(left, i)+" && "+connect(right, i)+";\n");
            }
            
            return tmpPrefix;
        }
        else if (auto bOr = opBinary->to<IR::BAnd>()) {
            /*  Example:
                    vector<bool> res(a.size(), false);
                    res[0] = a[0]|b[0];
                    res[1] = a[1]|b[1];
                    res[2] = a[2]|b[2];
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, size);
            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i < size; i++){
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" = "
                    +connect(left, i)+" || "+connect(right, i)+";\n");
            }
            
            return tmpPrefix;
        }
        else if (auto bXor = opBinary->to<IR::BXor>()) {
            /*  Example:
                    vector<bool> res(a.size(), false);
                    res[0] = a[0]^b[0];
                    res[1] = a[1]^b[1];
                    res[2] = a[2]^b[2];
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, size);
            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i < size; i++){
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" = "
                    +exprXor(connect(left, i), connect(right, i))+";\n");
            }
            
            return tmpPrefix;
        }
        else if (auto geq = opBinary->to<IR::Geq>()) {
            /*  Example:
                    bool tmp1 = a[2] && !b[2];
                    bool tmp2 = (a[2] == b[2]) && (a[1] && !b[1]);
                    bool tmp3 = (a[2] == b[2]) && (a[1] == b[1]) && (a[0] && !b[0]);
                    bool tmp4 = (a[2] == b[2]) && (a[1] == b[1]) && (a[0] == b[0]);
                    bool res = tmp1 || tmp2 || tmp3 || tmp4;
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, 1);

            cstring tmpPrefix2 = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix2, size+1);

            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i <= size; i++){
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " = ";
                for(int j = 0; j < i; j++){
                    stmt += "("+connect(left, size-1-j)+"=="+connect(right, size-1-j)+")";
                    if(j < i-1) stmt += " && ";
                }
                if(i == size){
                    stmt += ";\n";
                }
                else{
                    if(i != 0) stmt += " && ";
                    stmt += "("+connect(left, size-1-i)+"&&"+"!"+connect(right, size-1-i)+");\n";
                }
                currentProcedure->addStatement(stmt);
            }
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " = ";
            for(int i = 0; i <= size; i++){
                stmt += connect(tmpPrefix2, i);
                if(i < size) stmt += " || ";
            }
            stmt += ";\n";
            currentProcedure->addStatement(stmt);
            return connect(tmpPrefix, 0);
        }
        else if (auto leq = opBinary->to<IR::Leq>()) {
            /*  Example:
                    bool tmp1 = !a[2] && b[2];
                    bool tmp2 = (a[2] == b[2]) && (!a[1] && b[1]);
                    bool tmp3 = (a[2] == b[2]) && (a[1] == b[1]) && (!a[0] && b[0]);
                    bool tmp4 = (a[2] == b[2]) && (a[1] == b[1]) && (a[0] == b[0]);
                    bool res = tmp1 || tmp2 || tmp3 || tmp4;
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, 1);

            cstring tmpPrefix2 = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix2, size+1);

            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i <= size; i++){
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " = ";
                for(int j = 0; j < i; j++){
                    stmt += "("+connect(left, size-1-j)+"=="+connect(right, size-1-j)+")";
                    if(j < i-1) stmt += " && ";
                }
                if(i == size){
                    stmt += ";\n";
                }
                else{
                    if(i != 0) stmt += " && ";
                    stmt += "(!"+connect(left, size-1-i)+"&&"+connect(right, size-1-i)+");\n";
                }
                currentProcedure->addStatement(stmt);
            }
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " = ";
            for(int i = 0; i <= size; i++){
                stmt += connect(tmpPrefix2, i);
                if(i < size) stmt += " || ";
            }
            stmt += ";\n";
            currentProcedure->addStatement(stmt);
            return connect(tmpPrefix, 0);
        }
        else if (auto grt = opBinary->to<IR::Grt>()) {
            /*  Example:
                    bool tmp1 = a[2] && !b[2];
                    bool tmp2 = (a[2] == b[2]) && (a[1] && !b[1]);
                    bool tmp3 = (a[2] == b[2]) && (a[1] == b[1]) && (a[0] && !b[0]);
                    bool res = tmp1 || tmp2 || tmp3;
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, 1);

            cstring tmpPrefix2 = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix2, size);

            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i < size; i++){
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " = ";
                for(int j = 0; j < i; j++){
                    stmt += "("+connect(left, size-1-j)+"=="+connect(right, size-1-j)+")";
                    if(j < i-1) stmt += " && ";
                }
                if(i != 0) stmt += " && ";
                stmt += "("+connect(left, size-1-i)+"&&"+"!"+connect(right, size-1-i)+");\n";
                currentProcedure->addStatement(stmt);
            }
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " = ";
            for(int i = 0; i < size; i++){
                stmt += connect(tmpPrefix2, i);
                if(i < size-1) stmt += " || ";
            }
            stmt += ";\n";
            currentProcedure->addStatement(stmt);
            return connect(tmpPrefix, 0);
        }
        else if (auto lss = opBinary->to<IR::Lss>()) {
            /*  Example:
                    bool tmp1 = !a[2] && b[2];
                    bool tmp2 = (a[2] == b[2]) && (!a[1] && b[1]);
                    bool tmp3 = (a[2] == b[2]) && (a[1] == b[1]) && (!a[0] && b[0]);
                    bool res = tmp1 || tmp2 || tmp3;
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, 1);

            cstring tmpPrefix2 = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix2, size);

            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            for(int i = 0; i < size; i++){
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " = ";
                for(int j = 0; j < i; j++){
                    stmt += "("+connect(left, size-1-j)+"=="+connect(right, size-1-j)+")";
                    if(j < i-1) stmt += " && ";
                }
                if(i != 0) stmt += " && ";
                stmt += "(!"+connect(left, size-1-i)+"&&"+connect(right, size-1-i)+");\n";
                currentProcedure->addStatement(stmt);
            }
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " = ";
            for(int i = 0; i < size; i++){
                stmt += connect(tmpPrefix2, i);
                if(i < size-1) stmt += " || ";
            }
            stmt += ";\n";
            currentProcedure->addStatement(stmt);
            return connect(tmpPrefix, 0);
        }
        else if (auto equ = opBinary->to<IR::Equ>()) {
            /*  Example:
                    bool res;
                    res = a[0]==b[0] && a[1]==b[1] && a[2]==b[2];
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, 1);
            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            cstring stmt = getIndent()+connect(tmpPrefix, 0)+ " = ";
            for(int i = 0; i < size; i++){
                stmt += "("+connect(left, i)+"=="+connect(right, i)+")";
                if(i != size-1) stmt += " && ";
            }
            stmt += ";\n";
            currentProcedure->addStatement(stmt);
            return connect(tmpPrefix, 0);
        }
        else if (auto neq = opBinary->to<IR::Neq>()) {
            /*  Example:
                    bool res;
                    res = a[0]!=b[0] && a[1]!=b[1] && a[2]!=b[2];
                    return res;
            */
            cstring tmpPrefix = getTempPrefix();
            bitBlastingTempDecl(tmpPrefix, 1);
            cstring left = translate(opBinary->left), right = translate(opBinary->right);
            if(isNumber(left)){
                left = integerBitBlasting(atoi(left), size);
            }
            if(isNumber(right)){
                right = integerBitBlasting(atoi(right), size);
            }

            cstring stmt = getIndent()+connect(tmpPrefix, 0)+ " = ";
            for(int i = 0; i < size; i++){
                stmt += "("+connect(left, i)+"!="+connect(right, i)+")";
                if(i != size-1) stmt += " || ";
            }
            stmt += ";\n";
            currentProcedure->addStatement(stmt);
            return connect(tmpPrefix, 0);
        }
    }
    else if (opBinary->left->type->to<IR::Type_Boolean>()){
        // std::cout << opBinary->left->type->toString() << std::endl;
        return "("+translate(opBinary->left)+") "+opBinary->getStringOp()+" ("+translate(opBinary->right)+")";
    }
    return "";
}

cstring Translator::translate(const IR::Operation_Binary *opBinary){
    if(options.addInvariant && opBinary->to<IR::Operation_Relation>()) {
        cstring left = translate(opBinary->left);
        cstring right = translate(opBinary->right);
        auto minus1Const = [](const std::set<CONSTANT_TYPE>& const_collector) {
            auto result = std::set<CONSTANT_TYPE>();
            // auto result = std::set<CONSTANT_TYPE>(const_collector);
            for(auto it = const_collector.begin(); it != const_collector.end(); ++it) {
                auto c = *it;
                auto newConst = std::to_string(atoi(c) - 1);
                result.insert(newConst);
            }
            return result;
        }; 
        // collect left
        initAtomAuxCollector();
        translate(opBinary->left);
        auto leftVars = relevantVar_collector;
        auto leftConsts = constant_collector;
        if(opBinary->to<IR::Leq>())
            leftConsts = minus1Const(leftConsts);
        closeAtomAuxCollector();
        // collect right
        initAtomAuxCollector();
        translate(opBinary->right);
        auto rightVars = relevantVar_collector;
        auto rightConsts = constant_collector;
        if(opBinary->to<IR::Geq>())
            rightConsts = minus1Const(rightConsts);
        closeAtomAuxCollector();

        // is there any relevant
        cstring representative = "__NOTAVAR__";
        for(auto v: leftVars) {
            if(invVarCandidates.find(v) != invVarCandidates.end()) {
                representative = v;
                break;
            }
        }
        for(auto v: rightVars) {
            if(invVarCandidates.find(v) != invVarCandidates.end()) {
                representative = v;
                break;
            }
        }

        // if there is relevant, first use rep link all relevant, then link all constants
        if(representative != "__NOTAVAR__" && collect == 0) {
            updateRelevantVars(representative, leftVars, leftConsts);
            updateRelevantVars(representative, rightVars, rightConsts);
            // std::cout << "Done Left: " << left << " right: " + right + " op: " + opBinary->getStringOp() << "\n";
        }
    }


    if(options.bitBlasting){
        return bitBlasting(opBinary);
    }


    // cstring returnType = translate(opBinary->type);
    if (auto shl = opBinary->to<IR::Shl>()) {
        //addFunction("shl", "bvshl", typeName, returnType);
        cstring right = translate(opBinary->right);
        // if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>())
        //     right += returnType;
        // return "shl."+returnType+"("+translate(opBinary->left)+", "+right+")";
        return "("+ translate(opBinary->left) + " << " + right+")";
    }
    else if (auto shr = opBinary->to<IR::Shr>()) {
        // addFunction("shr", "bvlshr", typeName, returnType);
        // tmp close aux for bit operation
        auto tmpConst = constant_collector;
        auto tmpVar = relevantVar_collector;
        auto tmpCollect = collect;
        collect = 0;
        relevantVar_collector.clear();
        constant_collector.clear();

        cstring right = translate(opBinary->right);
        // if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>())
        //     right += returnType;

        constant_collector = tmpConst;
        relevantVar_collector = tmpVar;
        collect = tmpCollect;
        return "("+ translate(opBinary->left) + " >> " + right+")";
        // return "shr."+returnType+"("+translate(opBinary->left)+", "+right+")";
    }
    else if (auto mul = opBinary->to<IR::Mul>()) {
        // addFunction("mul", "bvmul", typeName, returnType);
        cstring right = translate(opBinary->right);
        // if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>())
        //     right += returnType;
        // return "mul."+returnType+"("+translate(opBinary->left)+", "+right+")";
        return "("+ translate(opBinary->left) + " * " + right+")";
    }
    else if (auto add = opBinary->to<IR::Add>()) {
        // addFunction("add", "bvadd", typeName, returnType);
        cstring right = translate(opBinary->right);
        // if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>())
        //     right += returnType;
        // return "add."+returnType+"("+translate(opBinary->left)+", "+right+")";
        return "("+ translate(opBinary->left) + " + " + right+")";
    }
    else if (auto addSat = opBinary->to<IR::AddSat>()) {
        // addFunction("add", "bvadd", typeName, returnType);
        cstring right = translate(opBinary->right);
        // if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>())
        //     right += returnType;
        // return "add."+returnType+"("+translate(opBinary->left)+", "+right+")";
        return "("+ translate(opBinary->left) + " + " + right+")";
    }
    else if (auto sub = opBinary->to<IR::Sub>()) {
        // addFunction("sub", "bvsub", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " - " + right+")";
    }
    else if (auto subSat = opBinary->to<IR::SubSat>()) {
        // addFunction("sub", "bvsub", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " - " + right+")";
    }
    else if (auto bAnd = opBinary->to<IR::BAnd>()) {
        // addFunction("band", "bvand", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " & " + right+")";
    }
    else if (auto bOr = opBinary->to<IR::BOr>()) {
        // addFunction("bor", "bvor", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " | " + right+")";
    }
    else if (auto bXor = opBinary->to<IR::BXor>()) {
        // addFunction("bxor", "bvxor", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " ^ " + right+")";
    }
    else if (auto geq = opBinary->to<IR::Geq>()) {

        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " >= " + right+")";
    }
    else if (auto leq = opBinary->to<IR::Leq>()) {
        // addFunction("bule", "bvule", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " <= " + right+")";
    }
    else if (auto grt = opBinary->to<IR::Grt>()) {
        // addFunction("bugt", "bvugt", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " > " + right+")";
    }
    else if (auto lss = opBinary->to<IR::Lss>()) {
        // addFunction("bult", "bvult", typeName, returnType);
        cstring right = translate(opBinary->right);

        return "("+ translate(opBinary->left) + " < " + right+")";
    }
    else if (auto equ = opBinary->to<IR::Equ>()) {
        return "(" + translate(opBinary->left) + " == " + translate(opBinary->right) + ")";
    }
    else if (auto equ = opBinary->to<IR::Neq>()) {
        return "(" + translate(opBinary->left) + " != " + translate(opBinary->right) + ")";
    }
    else if (auto arrayIndex = opBinary->to<IR::ArrayIndex>()) {
        return translate(arrayIndex);
    }
    else if (auto mask = opBinary->to<IR::Mask>()) {
        return translate(mask);
    }
    else
        return "("+translate(opBinary->left)+") "+opBinary->getStringOp()+" ("+translate(opBinary->right)+")";
}

cstring Translator::translate(const IR::Operation_Unary *opUnary){
    if (auto cast = opUnary->to<IR::Cast>()){
        return translate(cast);
    }
    if (auto member = opUnary->to<IR::Member>()){
        return translate(member);
    }
    if (auto lnot = opUnary->to<IR::LNot>()){
        return translate(lnot);
    }
    if (auto cmpl = opUnary->to<IR::Cmpl>()) {

        return "~(" + translate(opUnary->expr) + ")";
    }
    return "";
}

void Translator::translate(const IR::P4Program *program){
    ++currentTraverseTimes;
    analyzeProgram(program);
    // Translate objects
    for(auto obj:program->objects){
        translate(obj);
    }
    if(options.addForwardingAssertion){
        mainProcedure.addStatement("    assert(forward || drop);\n");
    }
}

void Translator::translate(const IR::Type_Error *typeError){

}

void Translator::translate(const IR::Type_Extern *typeExtern){
    // std::cout << "translate Type_Extern" << std::endl;
}

void Translator::translate(const IR::Type_Enum *typeEnum){

    // std::cout << "translate Type_Enum" << std::endl;
}

void Translator::translate(const IR::Declaration_Instance *instance, cstring instanceName){
    cstring typeName = translate(instance->type);
    cstring name = translate(instance->name);
    if(instanceName != "") name = instanceName;
    // std::cout << "Declaration_Instance: " << typeName << std::endl;
    if(typeName=="V1Switch" || typeName=="Pipeline"){ // v1 || tna
        bool isTNA = typeName == "Pipeline";
        BoogieProcedure main = BoogieProcedure(name);
        main.addDeclaration("inline "+name+"()\n");
        incIndent();
        main.addStatement(getIndent() + "do\n");
        main.addStatement(getIndent() + ":: " + getChannelName(options.switchID) + " ? " + stringWithPrefix("hdr") + " -> atomic {\n");
        
        // labels
        auto label_ingress_parser = stringWithPrefix("label_ingress_parser");
        auto label_egress_parser =  stringWithPrefix("label_egress_parser");
        auto label_pipeline_end = stringWithPrefix("label_pipeline_end");
        // 
        auto egressChannelName = getChannelName(options.switchID, true);

        main.addStatement(getIndent() + "skip;\n");
        main.addStatement(getIndent() + label_ingress_parser + ":\n");
        incIndent();

        int cnt = 0;
        for(auto argument:*instance->arguments){
            cnt++;
            cstring procName = translate(argument);
            main.addStatement(getIndent()+procName+"();\n");
            main.addSucc(procName);
            addPred(procName, name);

            // v1model: Parser, VerifyChecksum, Ingress, Egress, ComputeChecksum, Deparser
            // tna: ingress_parser, ingress, ingress_deparser, egress_parser, egress, egress_deparser
            if (translate(argument->expression->type) == "Type_Parser") {
                // main.addStatement(getIndent() + "if\n");
                // main.addStatement(getIndent() + ":: " + stringWithPrefix("packet_extract_accept == true ->\n"));  // parser 成功了再执行后面的
                // incIndent();
            } else if (cnt == 5 || (isTNA && cnt == 2) ) { // 在 deparser 之前
                cstring reset_emit_flag = stringWithPrefix("reset_emit_flag");
                main.addStatement(getIndent() + reset_emit_flag + "();\n");
                main.addSucc(reset_emit_flag);
                addPred(reset_emit_flag, name);
                if (cnt == 2) {
                    main.addStatement(getIndent() + label_egress_parser + ":\n");
                }
            } else if (cnt == 6 || (isTNA && cnt == 3)) { // deparser 之后
                cstring handle_header_emit = stringWithPrefix("handle_header_emit");
                main.addStatement(getIndent() + handle_header_emit + "();\n");
                main.addSucc(handle_header_emit);
                addPred(handle_header_emit, name);
            }

            if (cnt == 3) { // traffic manager
                addTrafficManager(isTNA);
                cstring trafficManager = stringWithPrefix("TrafficManager");
                main.addStatement(getIndent() + trafficManager + "();\n");
                main.addSucc(trafficManager);
                addPred(trafficManager, name);
                // if (isTNA) { // egress 也先收包（因为 mirror）
                    main.addStatement(getIndent() + "do\n");
                    main.addStatement(getIndent() + ":: nempty(" + egressChannelName  + ") -> atomic {\n");
                    incIndent();
                    auto egressHeaderName = getHeaderName(options.switchID, true);
                    main.addStatement(getIndent() + egressChannelName + " ? " + egressHeaderName + ";\n");
                // }
            } else if (cnt == 6) { // forward
                addForwarding(isTNA);
                cstring pml_send_packet = stringWithPrefix("pml_send_packet");
                auto para = "len(" + egressChannelName + ") == 0";
                main.addStatement(getIndent() + pml_send_packet + "(" + para + ");\n");
                main.addSucc(pml_send_packet);
                addPred(pml_send_packet, name);

                // if (isTNA) {
                    decIndent();
                    main.addStatement(getIndent() + "}\n");
                    main.addStatement(getIndent() + ":: empty(" + egressChannelName  + ") -> break;\n");
                    main.addStatement(getIndent() + "od\n");
                // }
            }
        }
        decIndent();
        main.addStatement(getIndent() + label_pipeline_end + ":\n");
        main.addStatement(getIndent() + "}\n");
        main.addStatement(getIndent() + "od\n");
        decIndent();


        // add children
        addProcedure(main);

            incIndent();
            mainProcedure.addStatement(getIndent() +name+"();\n");
            decIndent();
        // }
        
        mainProcedure.addSucc(name);
        addPred(name, mainProcedure.getName());
    }

    // TOFO: rename
    // std::cout << "name: " << name << std::endl;
    if(typeName == "register" || typeName == "Register"){ // v1model || tna
        if(isGlobalVariable(name))
            return;

        // size
        auto constant = (*instance->arguments)[0]->expression->to<IR::Constant>();
        cstring size = toString(constant->value);

        // value type
        auto valueType = instance->type->to<IR::Type_Specialized>();
        cstring valueTypeName = translate((*valueType->arguments)[0]);

        // size
        cstring indexTypeName;
        if((*valueType->arguments).size() > 1){
            indexTypeName = translate((*valueType->arguments)[1]);
        }
        else{
            indexTypeName = "int";
        }

        indexTypeName = "int";

        addDeclaration("\n// Register "+name+"\n");
        field_mapping.addVariableMapping(instance->name, removePrefix(name));

        addDeclaration(valueTypeName + " " + name + "[" + size + "];\n");

        addGlobalVariables(name);

        regType[name] = REG_TYPE(indexTypeName, valueTypeName, size);
        if(reg4Init.find(name) != reg4Init.end()) {
            auto& idx_vals = reg4Init[name];
            incIndent();
            for(auto idx_val: idx_vals) {
                cstring index = idx_val.first;// + indexTypeName;
                cstring value = idx_val.second;// + valueTypeName;
                cstring cmd;
                if(idx_val.first != "-1")   // not forall initilize
                {
                    cmd = getIndent() + name + "_write(" + index + ", " + value + ");\n";
                    // std::cout << "Initalizing " + name + "[" + index + "] to " + value + ".\n";
                } 
                else    // for all init
                {
                    // cmd = "    assume (forall i:" + indexTypeName + " :: (" + name + "[i] == " + value + "));\n";
                    cmd = getIndent() + "for (i : 1.." + size + ") {\n";
                    incIndent();
                    cmd += getIndent() + name + "_write(i, " + value + ");\n";
                    decIndent();
                    cmd += getIndent() + "}\n";
                    // std::cout << "Initalizing all element of " + name + " to " + value + "\n";
                }

                // write assignment
                cstring regInit = stringWithPrefix("regInit");
                if(!hasProcedure(regInit)) {
                    BoogieProcedure regInitProcedure = BoogieProcedure(regInit);
                    regInitProcedure.addDeclaration("inline " + regInit + "()\n");
                    regInitProcedure.addModifiedGlobalVariables(name);
                    regInitProcedure.addStatement(cmd);
                    addProcedure(regInitProcedure);
                } else {
                    BoogieProcedure& regInitProcedure = procedures[regInit];
                    regInitProcedure.addModifiedGlobalVariables(name);
                    regInitProcedure.addStatement(cmd);
                }

                // gen candidate invaraiant from user initialization
                if(options.addInvariant) {
                    IDX_TYPE regIndex = std::stoi(idx_val.first.c_str());
                    // CONSTANT_TYPE constant = std::stoull(idx_val.second.c_str());
                    CONSTANT_TYPE constant = idx_val.second;
                    REG_IDX record(name, regIndex);
                    conjecture(record, constant);
                    // invPredicateCandidates[record].insert(PREDICATE_TYPE(">=", constant));
                    // invPredicateCandidates[record].insert(PREDICATE_TYPE("<=", constant));
                }
            }
            decIndent();
            reg4Init.erase(name);
        }

        if (typeName == "register") {// v1model
            // read function
            BoogieProcedure read = BoogieProcedure(name+"_read");
            // one parameter, return reg[index]
            read.addDeclaration("inline "+ read.getName() + "(idx, var) {\n    var = " + name + "[idx];\n}\n");
            addProcedure(read);

            // write function
            BoogieProcedure write = BoogieProcedure(name+"_write");
            // two parameters, reg[index] = value
            write.addDeclaration("inline "+ write.getName() + "(idx, a_val)");
            incIndent();
            write.addStatement(getIndent()+name+"[idx] = a_val;\n");
            decIndent();
            write.addModifiedGlobalVariables(name);
            addProcedure(write);
        }
    }

    // tna
    if (typeName == "RegisterAction") {
        auto action = BoogieProcedure(name);
        currentProcedure = &action;
        auto registerName = translate((*instance->arguments)[0]->expression);

        auto function = instance->initializer->components[0]->to<IR::Function>();
        auto paras = translate(function->type);

        action.addDeclaration("inline " + action.getName() + "(" + paras + ")");
        incIndent();
        translate(function->body); // 语句
        decIndent();
        action.addModifiedGlobalVariables(registerName);
        addProcedure(action);
    }

}

cstring Translator::translate(const IR::Type_Method *method) {
    cstring paras = "";
    for (auto para : method->parameters->parameters) {
        paras += ", " + translate(para);
    }
    return paras.substr(2);
}


void Translator::translate(const IR::Type_Struct *typeStruct){
    cstring structName = translate(typeStruct->name);//typeStruct->name.toString();
    if(currentTraverseTimes > 1)
        return;

    addTypeDef("\n// Struct "+structName+"\n");

    if (typeStruct->fields.empty())
        return;

    // std::cout << "structName " << structName << std::endl;
    // 元数据 变量名取固定
    std::unordered_map<cstring, std::string> variableName = {
        // v1model
        {stringWithPrefix("metadata"), "meta"},
        {stringWithPrefix("standard_metadata_t"), "standard_metadata"},

        // tna
        // {stringWithPrefix("ingress_intrinsic_metadata_t"), "ig_intr_md"},
        {stringWithPrefix("ingress_intrinsic_metadata_from_parser_t"), "ig_intr_prsr_md"},
        {stringWithPrefix("ingress_intrinsic_metadata_for_deparser_t"), "ig_intr_dprsr_md"},
        {stringWithPrefix("ingress_intrinsic_metadata_for_tm_t"), "ig_intr_tm_md"},
        // {stringWithPrefix("egress_intrinsic_metadata_t"), "eg_intr_md"},
        {stringWithPrefix("egress_intrinsic_metadata_for_deparser_t"), "eg_intr_dprsr_md"},

        {stringWithPrefix("ig_metadata_t"), "ig_md"},
        {stringWithPrefix("eg_metadata_t"), "eg_md"}
    };

    if(structName==stringWithPrefix("headers")){
        translate(typeStruct, structName);
        
        // addTypeDef("\ntypedef " + structName + " {\n");
        // incIndent();
        // for(const IR::StructField* field:typeStruct->fields){
        //     auto typeName = translate(field->type);
        //     addTypeDef(getIndent() + typeName + " " + field->name + ";\n");
        // }
        // decIndent();
        // addTypeDef("};\n");
        // addDeclaration(structName + " " + stringWithPrefix("hdr;\n"));
        addDeclaration(removePrefix(structName) + " " + stringWithPrefix("hdr;\n"));

        // for deparser
        BoogieProcedure reset_emit_flag = BoogieProcedure(stringWithPrefix("reset_emit_flag"));
        reset_emit_flag.addDeclaration("inline " + reset_emit_flag.getName() + "()");
        BoogieProcedure handle_header_emit = BoogieProcedure(stringWithPrefix("handle_header_emit"));
        handle_header_emit.addDeclaration("inline " + handle_header_emit.getName() + "()");
        incIndent();
        for(const IR::StructField* field:typeStruct->fields){
            auto typeName = translate(field->type);
            handle_header_emit.addStatement(getIndent() + "if\n");
            cstring emit_var_name = get_emit_var_name(stringWithPrefix("hdr_") + field->name);
            reset_emit_flag.addStatement(getIndent() + emit_var_name + " = false;\n"); //
            handle_header_emit.addStatement(getIndent() + ":: !" + emit_var_name + " ->\n");
            cstring reset = struct_reset_method(typeName);
            handle_header_emit.addStatement(getIndent() + getIndent() + reset + "(" + stringWithPrefix("hdr.") + field->name + ");\n");
            handle_header_emit.addSucc(reset);
            addPred(reset, handle_header_emit.getName());
            handle_header_emit.addStatement(getIndent() + ":: else -> skip;\n");
            handle_header_emit.addStatement(getIndent() + "fi\n");
        }
        decIndent();
        addProcedure(handle_header_emit);
        addProcedure(reset_emit_flag);
    }
    else if (variableName.find(structName) != variableName.end()) {
        addTypeDef("typedef " + structName + " {\n");
        incIndent();
        translate(typeStruct, structName);
        decIndent();
        addTypeDef("};\n");
        addDeclaration(structName + " " + stringWithPrefix(variableName[structName]) + ";\n");
    } 
    else{
        addTypeDef("typedef " + structName + " {\n");
        incIndent();
        translate(typeStruct, structName);
        decIndent();
        addTypeDef("};\n");
    }
}

void Translator::translate(const IR::Type_Struct *typeStruct, cstring arg){
    for(const IR::StructField* field:typeStruct->fields){
        translate(field, arg);
    }
}

void Translator::translate(const IR::StructField *field){
    // std::cout << "translate StructField" << std::endl;
}

void Translator::translate(const IR::StructField *field, cstring arg){
    if(field->type->node_type_name() == "Type_Name"){
        cstring typeName = translate(field->type);
        cstring field_name = handle_keyword(field->name.toString());
        std::map<cstring, const IR::Type_Header*>::iterator iter1 = headers.find(typeName);
        std::map<cstring, const IR::Type_Struct*>::iterator iter2 = structs.find(typeName);
        if(iter1!=headers.end()){
            // std::cout << "header_instances <" << typeName << " " << field_name << "> of headers struct " << arg  << std::endl;
            header_extractor.addHeaderInstance(removePrefix(typeName).c_str(), field_name.c_str());

            // if (typeName.find("bit")) {
            //     header_extractor.addHeaderInstance(removePrefix(typeName).c_str(), field_name.c_str());
            // } else {
            //     header_extractor.addHeaderInstance((removePrefix("bit<" + defList[typeName]) + ">").c_str(), field_name.c_str());
            // }
            translate(iter1->second, typeName);
            addDeclaration("bool " + get_emit_var_name(stringWithPrefix("hdr_") + field_name) + " = false;\n");
        }
        else if(iter2!=structs.end()){ // 
            addTypeDef(getIndent() + typeName + " " + field_name + ";\n");
            //std::cout << "struct_instances <" << typeName << " " << field_name << "> of struct " << arg  << std::endl;
        }
        // else: typeDef
        else{
            auto typeName = field->type->to<IR::Type_Name>();
            cstring name = translate(typeName->path);
            cstring fieldName = arg+"."+field_name;
            if(isGlobalVariable(fieldName)) return;
            // std::cout << "field with user-defined type <" << name << " " << field_name << "> of header or struct " << arg  << std::endl;
            if(!header_extractor.isHeader(removePrefix(arg).c_str())){
                addTypeDef(getIndent() + name + " " + field_name + ";\n");
                addGlobalVariables(fieldName);
            } else {
                if (!(name.find("bit") || name.find("short") || name.find("int") || name.find("byte"))) {
                    std::string bitWidth = std::to_string(defList[removePrefix(name)]);
                    auto typeString = std::string{"bit<"} + bitWidth + std::string{">"};
                    header_extractor.addFieldForHeader(removePrefix(arg).c_str(), std::string{name}, field_name.c_str());
                } else {
                    header_extractor.addFieldForHeader(removePrefix(arg).c_str(), removePrefix(name).c_str(), field_name.c_str());
                }
            }
            field_mapping.addVariableMapping(field->name, field_name);

            if(fieldName.startsWith(stringWithPrefix("standard_metadata."))){
                std::set<cstring> havocSet = {"ingress_port", "instance_type", "packet_length", 
                                              "enq_timestamp", "deq_timedelta", "deq_qdepth",
                                              "ingress_global_timestamp", "egress_global_timestamp"
                                             };
                if(havocSet.find(field->name) != havocSet.end()){
                    havocProcedure.addStatement("    havoc "+fieldName+";\n");
                }
                else{
                    if(fieldName == stringWithPrefix("standard_metadata.egress_spec") 
                        || fieldName == stringWithPrefix("standard_metadata.egress_port"))
                        havocProcedure.addStatement("    "+fieldName+" = 0;\n");
                    else
                        havocProcedure.addStatement("    "+fieldName+" = 0;\n");
                }
                havocProcedure.addModifiedGlobalVariables(fieldName);
            }
        }

        // std::cout << (headers.find(fieldName)!=headers.end()) << std::endl;
        // std::cout << (structs.find(fieldName)!=structs.end()) << std::endl;
    }
    else if(field->type->node_type_name() == "Type_Bits"){
        auto typeBits = field->type->to<IR::Type_Bits>();
        updateMaxBitvectorSize(typeBits);
        cstring field_name = handle_keyword(field->name.toString());
        cstring fieldName = arg+"."+field_name;
        if(isGlobalVariable(fieldName)) return;
        if(options.bitBlasting){
            bitBlastingTempDecl(fieldName, typeBits->size);
        } else if (!header_extractor.isHeader(removePrefix(arg).c_str())) {
            addTypeDef(getIndent() + translate(typeBits) + " " + field_name +";\n");
        } else {
            header_extractor.addFieldForHeader(removePrefix(arg).c_str(), translate(typeBits).c_str(), field_name.c_str());
        }
        field_mapping.addVariableMapping(field->name, field_name);

        addGlobalVariables(fieldName);
        updateVariableSize(fieldName, typeBits->size);
        if(fieldName.startsWith(stringWithPrefix("meta.")) 
            || fieldName.startsWith(stringWithPrefix("standard_metadata."))){

            std::set<cstring> havocSet = {"ingress_port", "instance_type", "packet_length", 
                                          "enq_timestamp", "deq_timedelta", "deq_qdepth",
                                          "ingress_global_timestamp", "egress_global_timestamp"
                                         };

            if(havocSet.find(field->name) != havocSet.end()){
                havocProcedure.addStatement("    havoc "+fieldName+";\n");
            }
            else{
                havocProcedure.addStatement("    "+fieldName+" = 0;\n");
            }
            havocProcedure.addModifiedGlobalVariables(fieldName);
        }
    }
    else if(field->type->node_type_name() == "Type_Varbits"){
        auto typeVarbits = field->type->to<IR::Type_Varbits>();
        cstring fieldName = stringWithPrefix(arg+"."+field->name);
        // std::cout << "Type_Varbits " << typeVarbits->size << std::endl;
        // updateMaxBitvectorSize(typeVarbits->size);
        if(isGlobalVariable(fieldName)) return;
        if(options.bitBlasting){
            bitBlastingTempDecl(fieldName, typeVarbits->size);
        }
        else
            addTypeDef("unsigned "+fieldName+" : "+std::to_string(typeVarbits->size)+";\n");
        addGlobalVariables(fieldName);
        // updateVariableSize(arg+"."+field->name, typeVarbits->size);
    }
    else if(field->type->node_type_name() == "Type_Stack"){
        
        auto typeStack = field->type->to<IR::Type_Stack>();
        cstring typeName = translate(typeStack->elementType);
        header_extractor.addHeaderInstance(removePrefix(typeName).c_str(), ""); //
        // if (typeName.find("bit")) {
            // header_extractor.addHeaderInstance(removePrefix(typeName).c_str(), "");
        // } else {
            // header_extractor.addHeaderInstance((removePrefix("bit<" + defList[typeName]) + ">").c_str(), "");
        // }
        cstring size = translate(typeStack->size);

        cstring hdr = stringWithPrefix("hdr.") + field->name;
        int size_ = std::stoi(size.c_str());
        stackSize[hdr] = std::min(size_, MAX_INLINE_DEPTH);

        cstring headerStackType = removePrefix(typeName) + "_hs";
        header_extractor.addHeaderInstance(headerStackType.c_str(), field->name.name.c_str());
        // if (typeName.find("bit")) {
            // header_extractor.addHeaderInstance(removePrefix(headerStackType).c_str(), field->name.name.c_str());
        // } else {
            // header_extractor.addHeaderInstance((removePrefix("bit<" + defList[headerStackType]) + ">").c_str(), field->name.name.c_str());
        // }
        translate(typeStack, typeName);
        
        addDeclaration("bool " + get_emit_var_name(stringWithPrefix("hdr_") + field->name) + " = false;\n");

        // addTypeDef("typedef " + headerStackType + " {\n"); // header stack
        
        BoogieProcedure reset_header_stack = BoogieProcedure(struct_reset_method(typeName + "_hs"));
        reset_header_stack.addDeclaration("inline " + reset_header_stack.getName() + "(s1)");
        cstring reset_element = struct_reset_method(typeName);
        reset_header_stack.addSucc(reset_element);
        addPred(reset_element, reset_header_stack.getName());

        incIndent();
        // addTypeDef(getIndent() + "int size = " + size + "\n");
        // addTypeDef(getIndent() + "int last = -1;\n");

        header_extractor.addFieldForHeader(headerStackType.c_str(), "int", "size");
        header_extractor.addFieldForHeader(headerStackType.c_str(), "int", "last");
        for (int i = 0; i < stackSize[hdr]; ++i) {
            cstring element = "element_" + cstring::to_cstring(i);
            // addTypeDef(getIndent() +  + typeName + " " + element + ";\n");
            // if (!(translate(removePrefix(typeName).c_str()).find("bit") || translate(removePrefix(typeName).c_str()).find("short") || translate(removePrefix(typeName).c_str()).find("int"))) {
            //     header_extractor.addFieldForHeader(removePrefix(arg).c_str(),"bit<" + std::string{(char)defList[removePrefix(typeName).c_str()]} + ">", field_name.c_str());
            //
            //     // header_extractor.addFieldForHeader(removePrefix(arg).c_str(), "short", element.c_str());
            // } else {
            //     header_extractor.addFieldForHeader(removePrefix(arg).c_str(), removePrefix(translate(removePrefix(typeName).c_str())).c_str(), element.c_str());
            // }
            header_extractor.addFieldForHeader(headerStackType.c_str(), removePrefix(typeName).c_str(), element.c_str());
            reset_header_stack.addStatement(getIndent() + reset_element + "(s1." + element + ");\n");
        }
        decIndent();
        // addTypeDef("}\n");
        addProcedure(reset_header_stack);

        // pop_front
        cstring name = "pop_front_" + hdr.replace(".", "_");
        BoogieProcedure pop_front = BoogieProcedure(name);
        pop_front.addDeclaration("inline "+name+"()\n");
        incIndent();
        cstring assign_func = struct_assign_method(typeName);
        cstring element_prefix =  hdr + ".element_";
        for (int i = 0; i < stackSize[hdr]-1; ++i) {
            cstring e1 = element_prefix + cstring::to_cstring(i);
            cstring e2 = element_prefix + cstring::to_cstring(i+1);
            pop_front.addStatement(getIndent() + assign_func + "(" + e1 + ", " + e2 + ");\n");
        }
        pop_front.addStatement(getIndent() + hdr + ".element_" + cstring::to_cstring(stackSize[hdr]-1) + ".valid = false;\n");
        pop_front.addSucc(assign_func);
        addPred(assign_func, name);
        decIndent();
        addProcedure(pop_front);

        // push_front
        cstring name_push = "push_front_" + hdr.replace(".", "_");
        BoogieProcedure push_front = BoogieProcedure(name_push);
        push_front.addDeclaration("inline "+name_push+"()\n");
        incIndent();
        for (int i = stackSize[hdr]-1; i > 0; --i) {
            cstring e1 = element_prefix + cstring::to_cstring(i);
            cstring e2 = element_prefix + cstring::to_cstring(i-1);
            push_front.addStatement(getIndent() + assign_func + "(" + e1 + ", " + e2 + ");\n");
        }
        push_front.addStatement(getIndent() + element_prefix + "0.valid = false;\n");
        push_front.addSucc(assign_func);
        addPred(assign_func, name_push);
        decIndent();
        addProcedure(push_front);
    }
    else if (field->type->node_type_name() == "Type_Boolean") {
        cstring field_name = handle_keyword(field->name.toString());
        cstring fieldName = arg+"."+field_name;
        if (!header_extractor.isHeader(removePrefix(arg).c_str())) {
            addTypeDef(getIndent() + "bool " + field_name +";\n");
        } else {
            header_extractor.addFieldForHeader(removePrefix(arg).c_str(), "bool", field_name.c_str());
        }
        field_mapping.addVariableMapping(field->name, field_name);
    }
    else if(field->type->node_type_name() == "Type_Typedef"){
        // std::cout << "debug: nothing" << std::endl;
    }
}

void Translator::translate(const IR::Type_Header *typeHeader){
    cstring structName = translate(typeHeader->name);
    std::unordered_map<cstring, std::string> variableName = {
        // tna 这两个是header类型。。
        {stringWithPrefix("ingress_intrinsic_metadata_t"), "ig_intr_md"},
        {stringWithPrefix("egress_intrinsic_metadata_t"), "eg_intr_md"},
    };
    if (variableName.find(structName) != variableName.end()) {
        addTypeDef("typedef " + structName + " {\n");
        incIndent();
        addTypeDef(getIndent() + "bool valid = false;\n");
        for(const IR::StructField* field:typeHeader->fields){
            translate(field, structName);
        }
        decIndent();
        addTypeDef("};\n");
        addDeclaration(structName + " " + stringWithPrefix(variableName[structName]) + ";\n");
    }
}

void Translator::translate(const IR::Type_Header *typeHeader, cstring arg){
    if(isGlobalVariable(arg))
        return;

    generate_struct_reset_method(arg, typeHeader->fields);

    // addTypeDef("\n// Header "+arg+"\n");
    addGlobalVariables(arg);
    addGlobalVariables(arg+".valid");
    updateVariableSize(arg+".valid", 0);
    // addTypeDef("typedef " + arg + " {\n");
    incIndent();
    // addTypeDef(getIndent() + "bool valid = false;\n");
    header_extractor.addFieldForHeader(removePrefix(arg).c_str(), "bool", "valid");

    havocProcedure.addStatement("    "+arg+".valid = false;\n");
    havocProcedure.addModifiedGlobalVariables(arg+".valid");
    // havocProcedure.addStatement("    isValid["+arg+"] := false;\n");
    // havocProcedure.addModifiedGlobalVariables("isValid");
    if(currentProcedure==nullptr || currentProcedure->getName().find("_parser_") == nullptr){
        havocProcedure.addStatement("    emit["+arg+"] = false;\n");
        havocProcedure.addModifiedGlobalVariables("emit");
    }
    for(const IR::StructField* field:typeHeader->fields){
        translate(field, arg);
        cstring fieldName = arg + "." + handle_keyword(field->name.toString());

        cstring oldFieldName = "_old_"+fieldName;

        if(options.bitBlasting){
            if(auto typeBits = field->type->to<IR::Type_Bits>()){
                for(int i = 0; i < typeBits->size; i++){
                    havocProcedure.addStatement("    havoc "+connect(fieldName, i)+";\n");
                    havocProcedure.addModifiedGlobalVariables(connect(fieldName, i));
                }
                for(int i = 0; i < typeBits->size; i++){
                    havocProcedure.addStatement("    "+connect(oldFieldName, i)+" = "+
                        connect(fieldName, i) +";\n");
                    havocProcedure.addModifiedGlobalVariables(connect(oldFieldName, i));
                }
            }
        }
        else{
            if(currentProcedure==nullptr || currentProcedure->getName().find("_parser_") == nullptr){
                havocProcedure.addStatement("    havoc "+fieldName+";\n");
                havocProcedure.addModifiedGlobalVariables(fieldName);
            }

            if(options.p4invSpec){
            }
            else{
                // havocProcedure.addStatement("    "+oldFieldName+" := "+
                //    fieldName +";\n");
                // havocProcedure.addModifiedGlobalVariables(oldFieldName);
            }
        }
    }

    decIndent();
    // addTypeDef("};\n");
}

void Translator::translate(const IR::Type_Parser *typeParser){
    // std::cout << "translate Parser" << std::endl;
}

void Translator::translate(const IR::Type_Control *typeControl){
    // std::cout << "translate Control" << std::endl;
}

void Translator::translate(const IR::Type_Package *typePackage){
    // std::cout << "translate package" << std::endl;
}

void Translator::translate(const IR::P4Parser *p4Parser){
    cstring parserName = translate(p4Parser->name);
    BoogieProcedure parser = BoogieProcedure(parserName);
    currentProcedure = &parser;
    parser.addDeclaration("\n// Parser "+parserName+"\n");
    //parser.addDeclaration("procedure " + options.inlineFunction + " "+parserName+"()\n");
    parser.addDeclaration("inline " + parserName + "()\n");
    incIndent();
    cstring localDecl = "";
    cstring localDeclArg = "";
    int cnt = p4Parser->parserLocals.size();
    for(auto parserLocal:p4Parser->parserLocals){
        cnt--;
        parser.addStatement(translate(parserLocal));
    }

        cstring start = parserName + "_start"; // 区分 tna ingressParser、egressParser
        parser.addStatement(getIndent() + start +"();\n");
        parser.addSucc(start);
        addPred(start, parserName);

        decIndent();
        addProcedure(parser);
        for(auto state:p4Parser->states){
            do {
                currentProcedure = &parser;
                translate(state);
            } while (parserStateRenameTimes[translate(state->name)] > 0); // for header stack
            // translate(state, localDecl, localDeclArg);
        }
    // }
    // TODO: parser local variables
}

void Translator::translate(const IR::ParserState *parserState, cstring localDecl, cstring localDeclArg){
    if (needPrune && removeIds.count(parserState->id) > 0) {
        return ;
    }
    cstring originalStateName = translate(parserState->name);
    int times = parserStateRenameTimes[originalStateName];

    if (parserState->name == "start") {
        originalStateName = currentProcedure->getName() + "_start";
    }

    cstring stateName = originalStateName + (times == 0 ? "" : "_" + cstring::to_cstring(times));

    BoogieProcedure state = BoogieProcedure(stateName);
    state.isParserState = true;
    currentProcedure = &state;
    state.addDeclaration("\n//Parser State "+stateName+"\n");
    // state.addDeclaration("procedure " + options.inlineFunction + " "+stateName+"()\n");
    state.addDeclaration("inline " + stateName + "()\n");
    incIndent();

    for(auto statOrDecl:parserState->components){
        cstring stat = translate(statOrDecl);
        if (stat == "")
            continue;
        if (stat.find(".last + 1;") && stat.find(".valid = true")) {
            std::string::size_type idx_1 = ((std::string)stat.c_str()).find("    ");
            std::string::size_type idx_2 = ((std::string)stat.c_str()).find(".valid = true");
            cstring hdr = stat.substr(idx_1+4, idx_2-idx_1-4);
            // stat = stat.substr(0, idx_1) + getIndent() + hdr + ".element_" + cstring::to_cstring(stackSize[hdr]-1-times) + stat.substr(idx_2);
            stat = stat.substr(0, idx_1) + getIndent() + hdr + ".element_" + cstring::to_cstring(times) + stat.substr(idx_2);

            stackSize[originalStateName] = stackSize[hdr]; // for convenience

            int size = stackSize[hdr];
            if (times == size-1) {
                parserStateRenameTimes[originalStateName] = 0; // last turn
            } else {
                parserStateRenameTimes[originalStateName] += 1;
            }
        }
        currentProcedure->addStatement(getIndent() + stat);
    }
    if(parserState->selectExpression!=nullptr){
        if (auto pathExpression = parserState->selectExpression->to<IR::PathExpression>()){
            cstring nextState = translate(pathExpression);
            // state.addStatement(getIndent()+"call "+fnextState+"("+localDeclArg+");\n");
            state.addStatement(getIndent() + nextState+"();\n");
            state.addSucc(nextState);
            addPred(nextState, stateName);
        }
        else if(auto selectExpression = parserState->selectExpression->to<IR::SelectExpression>()){
            currentProcedure->addStatement(translate(selectExpression, originalStateName, localDeclArg));
        }
    }
    // decIndent();
    // currentProcedure->addStatement(getIndent() + "}\n");

    decIndent();
    addProcedure(state);
    // }
}

void Translator::translate(const IR::P4Control *p4Control){
    cstring controlName = translate(p4Control->name);
    bool firstTranslate = !hasProcedure(controlName); 
    if(firstTranslate) {
        BoogieProcedure control = BoogieProcedure(controlName);
        control.setImplemented();
        addProcedure(control);

        std::vector<cstring> declarations;
        for(auto declaration:*p4Control->getDeclarations()){
            if(declaration->to<IR::Declaration_Instance>())
                declarations.push_back(translate(declaration->getName()));
            // std::cout << "**declaration: " << translate(declaration->getName()) << std::endl;
        }
        currentProcedure = &procedures[controlName];

        for(auto controlLocal:p4Control->controlLocals){
            currentProcedure = &procedures[controlName]; // reset, avoid being overrided
            if(auto instance = controlLocal->to<IR::Declaration_Instance>()){ // register, tna RegisterAction,
                cstring instanceName = translate(instance->getName());
                cstring renamedInstance = "";
                for(cstring declaration:declarations){
                    if(declaration.find(instanceName)!=nullptr 
                        && declaration.size()>renamedInstance.size()){
                        int idx = instanceName.size()+1;
                        bool digit = true;
                        for(int i = idx; i < declaration.size(); i++){
                            if(!(declaration[i] >= '0' && declaration[i] <= '9')){
                                digit = false;
                            }   
                        }
                        if(digit)
                            renamedInstance = declaration;
                    }
                }
                translate(instance, renamedInstance);
            }
            else{ // table, action, variable, etc.
                // can be declared as global variables
                // p4c has finished renaming
                // std::cout << "debug control: " << currentProcedure->getName() << std::endl;
                translate(controlLocal);
            }
        }
    }

    if(firstTranslate) {
        currentProcedure = &procedures[controlName];
        currentProcedure->addDeclaration("\n// Control "+controlName+"\n");
        currentProcedure->addDeclaration("inline " + controlName+"()\n");
    } else {
        BoogieProcedure Dummy = BoogieProcedure("Dummy");
        currentProcedure = &Dummy;
    }
    incIndent();
    for(auto statOrDecl:p4Control->body->components){
        currentProcedure->addStatement(translate(statOrDecl));
    }
    decIndent();
}

void Translator::translate(const IR::Method *method){
    // std::cout << "translate method" << std::endl;
}

void Translator::translate(const IR::P4Action *p4Action){
    if (needPrune && removeIds.count(p4Action->id) > 0) {
        return ;
    }
    cstring actionName = translate(p4Action->name);
    // if (isGlobalVariable(actionName)) {
    //     actionName = "_" + actionName;
    // }
    // std::cout << "debug actionName1111111: " << actionName << std::endl;
    BoogieProcedure action = BoogieProcedure(actionName);
    currentProcedure = &action;
    action.addDeclaration("\n// Action "+actionName+"\n");
    action.addDeclaration("inline " + actionName + "(");
    int cnt = p4Action->parameters->parameters.size();
    for(auto parameter:p4Action->parameters->parameters){
        action.addDeclaration(translate(parameter, "action"));
        cnt--;
        if(cnt != 0)
            action.addDeclaration(", ");
    }
    action.addDeclaration(")\n");
    incIndent();

    action.addStatement(translate(p4Action->body));
    decIndent();
    addProcedure(action);
}

void Translator::translate(const IR::P4Table *p4Table){
    if (needPrune && removeIds.count(p4Table->id) > 0) {
        return ;
    }
    cstring name = translate(p4Table->name);
    cstring tableName = name+"_apply";
    if (tableName.find("dmac")) {
        ::warning("find dmac");
    }
    BoogieProcedure table = BoogieProcedure(tableName);
    currentProcedure = &table;
    table.addDeclaration("\n// Table "+name+"\n");
    table.addDeclaration("inline " + tableName + "()\n");
    table.setImplemented();
    addDeclaration("\n// Table "+name+" Actionlist Declaration\n");
    // addDeclaration("type "+name+".action;\n");
    incIndent();
    // Consider keys
    // Keys are not changed and this is only for key access validity checking
    std::vector<cstring> keys;
    for(auto property:p4Table->properties->properties){
        if (auto key = property->value->to<IR::Key>()) {
            for(auto keyElement:key->keyElements){
                cstring expr = translate(keyElement->expression);
                if(expr!=nullptr && expr.find("[")==nullptr && expr.find("(")==nullptr) {
                    keys.push_back(expr);
                    std::string stmt(getIndent());
                    stmt += expr;
                    stmt += " = ";
                    stmt += expr;
                    stmt += ";\n";
                    table.addStatement(stmt);
                    table.addModifiedGlobalVariables(expr);
                    // std::cout << expr << std::endl;
                }
            }
        }
    }

    bool ruleExist = false;

    table.addStatement(getIndent()+"if\n");
    if(!ruleExist) {

        // std::cout << tableName << std::endl;
        // cstring gotoStmt = getIndent()+"goto ";

        for(auto property:p4Table->properties->properties){
            if (auto actionList = property->value->to<IR::ActionList>()) {
                // add local variables
                for(auto actionElement:actionList->actionList){
                    if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                        cstring actionName = translate(actionCallExpr->method);
                        const IR::P4Action* action = actions[actionName];
                        for(auto parameter:action->parameters->parameters){
                            cstring parameterName = name+"_"+actionName+"_"+translate(parameter->name);
                            // table.addFrontStatement("    var "+actionName+"."+translate(parameter)+";\n");
                            // addDeclaration("var "+name+"."+actionName+"."+translate(parameter)+";\n");
                            cstring type = translate(parameter->type);
                            addDeclaration(type + " " + parameterName + ";\n");
                            addGlobalVariables(parameterName);
                            havocProcedure.addModifiedGlobalVariables(parameterName);
                            havocProcedure.addStatement("    havoc "+parameterName+";\n");
                        }
                    }
                }

                // add action declaration
                translate(actionList, name+"_action");

                if(bMV2CmdsAnalyzer== nullptr){
                    int cnt = actionList->actionList.size();

                    bool firstAction = true;
                    // std::cout << tableName << " " << cnt << std::endl;
                    for(auto actionElement:actionList->actionList){

                        cnt--;
                        // if(cnt == 0)
                        //     break;
                        // std::cout << "action: " << actionElement->expression->toString() << std::endl;
                        if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
                            cstring actionName = translate(actionCallExpr->method);

                                table.addStatement(getIndent() + ":: \n");
                                incIndent();
                            // }
                            
                            const IR::P4Action* action = actions[actionName];
                            table.addStatement(getIndent()+actionName+"(");
                            table.addSucc(actionName);
                            addPred(actionName, tableName);
                            int cnt2 = action->parameters->parameters.size();
                            for(auto parameter:action->parameters->parameters){
                                cnt2--;
                                cstring parameterName = name+"_"+actionName+"_"+translate(parameter->name);
                                table.addStatement(parameterName);
                                if(cnt2 != 0)
                                    table.addStatement(", ");
                            }
                            table.addStatement(");\n");
                            // if(options.gotoOrIf){
                            //     table.addStatement(getIndent()+"goto Exit;\n");
                            // }
                            // else{
                                decIndent();
                                // table.addStatement(getIndent()+"}\n");
                            // }
                            // decIndent();
                        }
                    }
                    // // add action declaration
                    // translate(actionList, name+"_action");
                }
                /* handle table add commands, i.e., table rules
                    1. find the rules of the current table (from BMV2CmdsAnalyzer)
                    2. add condition statements (according to keys and priority)
                    3. assign parameters
                    4. call the corresponding actions
                    5. if no matching rules, consider the default action
                */
                else if (bMV2CmdsAnalyzer->hasTableAddCmds(removePrefix(name))) {
                    std::vector<TableAdd*> rules = bMV2CmdsAnalyzer->getTableAddCmds(removePrefix(name));
                    for (auto rule : rules) {
                        cstring actionName = stringWithPrefix(rule->action);
                        // condition
                        cstring condition = rule->getCondition(keys);
                        table.addStatement(getIndent() + ":: (" + condition + ") ->\n");
                        incIndent();
                        // action call
                        cstring action_call = actionName + rule->getParas();
                        table.addStatement(getIndent()+ action_call + ";\n");
                        table.addSucc(actionName);
                        addPred(actionName, tableName);
                        decIndent();
                    }
                }
            }
        }

        // if(options.gotoOrIf){
        //     // table.addStatement("\n    Exit:\n");
        //     // table.addStatement("        call "+tableName+"_table_exit();\n");
        // }
        addDeclaration("int "+name+"_action_run;\n");
        addGlobalVariables(name+"_action_run");
        havocProcedure.addStatement("    havoc "+name+"_action_run;\n");
        havocProcedure.addModifiedGlobalVariables(name+"_action_run");
        addDeclaration("bool "+name+"_hit;\n");
    }

    bool hasDefault = false;
    if (bMV2CmdsAnalyzer && bMV2CmdsAnalyzer->hasTableSetDefaultCmd(name)) {
        hasDefault = true;
        TableSetDefault* rule = bMV2CmdsAnalyzer->getTableSetCmd(name);
        cstring actionName = stringWithPrefix(rule->action);
        table.addStatement(getIndent()+":: else -> \n");
        incIndent();
        // action call
        cstring action_call = actionName + rule->getParas();
        table.addStatement(getIndent()+ action_call + ";\n");
        table.addSucc(actionName);
        addPred(actionName, tableName);
        decIndent();
    } else {
        // default action
        for(auto property:p4Table->properties->properties){
            if (auto value = property->value->to<IR::ExpressionValue>()){
                if(property->getName() == "default_action"){
                    hasDefault = true;
                    table.addStatement(getIndent()+":: else -> \n");
                    incIndent();
                    cstring default_action = translate(value->expression);
                    std::string::size_type idx = ((std::string)default_action.c_str()).find("()");
                    cstring default_action_name = ((std::string)default_action.c_str()).substr(0, idx);
                    table.addStatement(getIndent()+default_action+";\n");
                    decIndent();
                    // table.addStatement(getIndent()+"}\n");
                    table.addSucc(default_action_name);
                    addPred(default_action_name, tableName);
                }
            }
        }
    }

    if (!hasDefault) {
        table.addStatement(getIndent()+":: else -> skip;\n"); // avoid blocking
    }
    
    table.addStatement(getIndent()+"fi\n");

    decIndent();
    addProcedure(table);
}

cstring Translator::translate(const IR::Parameter *parameter, cstring arg){
    cstring name = translate(parameter->name);
    cstring type = translate(parameter->type);
    // std::cout << "debug parameter: " << type << " " << name << std::endl;
    if(arg == "action"){
        if(auto typeBits = parameter->type->to<IR::Type_Bits>()){
            updateMaxBitvectorSize(typeBits);
            currentProcedure->parameters[name] = typeBits->size;
        }
        else if(auto typeName = parameter->type->to<IR::Type_Name>()){
            cstring _name = translate(typeName);
            // std::cout << "TYPE NAME: " << _name << "\n";
            // for(auto it: typeDefs) {
            //     std::cout << "typeDefs: " << it.first << "\n";
            // }
            if(typeDefs.find(_name) != typeDefs.end()){
                currentProcedure->parameters[name] = typeDefs[_name];
            }
        }
    }
    // return type + " " + name;
    return name;
}

void Translator::translate(const IR::ActionList *actionList, cstring arg){
    int cnt = actionList->actionList.size();
    // if(cnt == 0 || cnt == 1) limit.addDeclaration("true");
    for(auto actionElement:actionList->actionList){
        cnt--;
        if (needPrune && removeIds.count(actionElement->id) > 0) {
            return;
        }
        if(auto actionCallExpr = actionElement->expression->to<IR::MethodCallExpression>()){
            cstring actionName = translate(actionCallExpr->method);
            // addDeclaration("const unique "+arg+"."+actionName+" : "+arg+";\n");
            addDeclaration("#define "+arg+"_"+actionName+ " " + std::to_string(cnt) +"\n");
            // limit.addDeclaration(arg+"_run=="+arg+"."+actionName);
        }
    }
}
