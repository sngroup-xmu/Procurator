#include "translate.h"

#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <functional>
#include <sstream>
#include <string>
#include <vector>

static std::string sanitizeHashSignaturePart(const std::string& raw) {
    std::string out;
    out.reserve(raw.size());
    for (char c : raw) {
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
            (c >= '0' && c <= '9')) {
            out.push_back(c);
        } else {
            out.push_back('_');
        }
    }
    if (out.empty()) {
        return "unit";
    }
    if (out[0] >= '0' && out[0] <= '9') {
        out.insert(out.begin(), '_');
    }
    return out;
}

static std::string lowerAscii(std::string s) {
    std::transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
        return static_cast<char>(std::tolower(c));
    });
    return s;
}

static bool hashAlgorithmIsIdentity(const cstring& algorithm) {
    std::string alg = lowerAscii(algorithm.c_str());
    return alg == "identity" || alg.find("identity") != std::string::npos;
}

static std::string hashAlgorithmModelName(const cstring& algorithm) {
    if (hashAlgorithmIsIdentity(algorithm)) {
        return "identity";
    }
    std::string alg = lowerAscii(algorithm.c_str());
    if (alg.find("crc32") != std::string::npos) {
        return "crc32_uf";
    }
    if (alg.find("crc16") != std::string::npos) {
        return "crc16_uf";
    }
    if (alg.find("toeplitz") != std::string::npos) {
        return "toeplitz_uf";
    }
    if (alg.find("csum16") != std::string::npos || alg.find("ones_complement16") != std::string::npos) {
        return "checksum16_uf";
    }
    return algorithm == "" ? "unknown_uf" : sanitizeHashSignaturePart(algorithm.c_str()) + "_uf";
}

static std::string hashAlgorithmMangleName(const cstring& algorithm) {
    std::string alg = algorithm.c_str();
    std::string sanitized = sanitizeHashSignaturePart(alg);
    const std::vector<std::string> prefixes = {
        "HashAlgorithm_",
        "HashAlgorithm_t_",
        "PSA_HashAlgorithm_t_",
        "PNA_HashAlgorithm_t_",
    };
    for (const auto& prefix : prefixes) {
        if (sanitized.rfind(prefix, 0) == 0 && sanitized.size() > prefix.size()) {
            return sanitized.substr(prefix.size());
        }
    }
    return sanitized;
}

static int bvTypeWidth(const cstring& bvType) {
    if (!bvType.startsWith("bv")) {
        return -1;
    }
    return atoi(bvType.c_str() + 2);
}

cstring Translator::translate(const IR::MethodCallExpression *methodCallExpression){
    cstring res = "";
    cstring method = translate(methodCallExpression->method);

    auto regIndexAssume = [&](const std::string& regName, const IR::Expression* idxExpr,
                              const std::string& idxStr) -> std::string {
        if (!options.slicingEnabled || !options.slicingRegPrune) {
            return "";
        }
        if (!idxExpr) {
            return "";
        }
        cstring key = regName.c_str();
        auto it = options.slicingRegMaxIndex.find(key);
        if (it == options.slicingRegMaxIndex.end()) {
            std::string withSuffix = regName + "_0";
            it = options.slicingRegMaxIndex.find(cstring(withSuffix.c_str()));
            if (it == options.slicingRegMaxIndex.end()) {
                return "";
            }
        }
        int maxIndex = it->second;
        if (maxIndex < 0) {
            return "";
        }
        std::string typeName = translate(idxExpr->type).c_str();
        if (typeName == "int") {
            return "(" + idxStr + " <= " + std::to_string(maxIndex) + ")";
        }
        if (typeName.rfind("bv", 0) == 0) {
            std::string lit = std::to_string(maxIndex) + typeName;
            if (maxIndex == 0) {
                return idxStr + " == " + lit;
            }
            addFunction("bule", "bvule", typeName.c_str(), "bool");
            std::string fn = "bule." + typeName;
            return fn + "(" + idxStr + ", " + lit + ")";
        }
        // Unknown index type; skip pruning rather than emitting ill-typed Boogie.
        return "";
    };

    if (auto member = methodCallExpression->method->to<IR::Member>()) {
        if (member->member == "execute" || member->member == "execute_log") {
            cstring base = translate(member->expr);
            auto it = registerActions.find(base);
            if (it == registerActions.end() && !isGlobalVariable(base)) {
                cstring raw = methodCallExpression->method->toString();
                std::string rawStr = raw.c_str();
                std::string needle = "." + member->member.toString();
                size_t pos = rawStr.find(needle);
                if (pos != std::string::npos) {
                    base = cstring(rawStr.substr(0, pos));
                    it = registerActions.find(base);
                }
            }
            if (it != registerActions.end()) {
                const RegisterActionInfo &info = it->second;
                const IR::Expression* idxExpr = nullptr;
                cstring idx = renderBoogieZeroLiteral(info.indexType);
                if (!info.direct && !methodCallExpression->arguments->empty()) {
                    idxExpr = (*methodCallExpression->arguments)[0]->expression;
                    idx = translate((*methodCallExpression->arguments)[0]);
                }
                std::string valName = "__ra_val_" + std::string(base.c_str());
                std::string retName = "__ra_ret_" + std::string(base.c_str());
                cstring valVar = getOrCreateNamedVar(valName, info.valueType);
                cstring retVar = getOrCreateNamedVar(retName, info.retType);
                currentProcedure->addModifiedGlobalVariables(valVar);
                currentProcedure->addModifiedGlobalVariables(retVar);
                std::string assumeExpr = regIndexAssume(info.regName.c_str(), idxExpr, idx.c_str());
                if (!assumeExpr.empty() && currentProcedure != nullptr) {
                    currentProcedure->addStatement(getIndent() + "assume (" + assumeExpr + ");\n");
                }
                currentProcedure->addStatement(getIndent()+valVar+" := "+info.regName+".read("+info.regName+", "+idx+");\n");
                if(info.applyParamCount <= 1){
                    if (info.hasReturn) {
                        currentProcedure->addStatement(getIndent()+"call "+valVar+", "+retVar+" := "+
                            info.applyName+"("+valVar+");\n");
                    } else {
                        currentProcedure->addStatement(getIndent()+"call "+valVar+" := "+info.applyName+"("+valVar+");\n");
                        currentProcedure->addStatement(getIndent()+retVar+" := "+valVar+";\n");
                    }
                }
                else if(info.applyParamCount == 2){
                    currentProcedure->addStatement(getIndent()+"call "+valVar+", "+retVar+" := "+
                        info.applyName+"("+valVar+", "+retVar+");\n");
                }
                else{
                    currentProcedure->addStatement(getIndent()+"call "+valVar+" := "+info.applyName+"("+valVar+");\n");
                    currentProcedure->addStatement(getIndent()+retVar+" := "+valVar+";\n");
                }
                currentProcedure->addStatement(getIndent()+"call "+info.regName+".write("+idx+", "+valVar+");\n");
                addRegisterWriteModifiedVariables(info.regName);
                return retVar;
            }
        }
    }

    if (auto member = methodCallExpression->method->to<IR::Member>()) {
        if (member->member == "count" || member->member == "increment" || member->member == "add") {
            cstring base = translate(member->expr);
            auto counterIt = counterExterns.find(base);
            if (counterIt != counterExterns.end()) {
                const CounterExternInfo& info = counterIt->second;
                cstring idx = renderBoogieZeroLiteral(info.indexType);
                cstring val = info.oneValue;
                if (methodCallExpression->arguments != nullptr &&
                    methodCallExpression->arguments->size() >= 1) {
                    idx = translate((*methodCallExpression->arguments)[0]);
                }
                if (member->member == "add" &&
                    methodCallExpression->arguments != nullptr &&
                    methodCallExpression->arguments->size() >= 2) {
                    val = translate((*methodCallExpression->arguments)[1]);
                }
                if (member->member == "add") {
                    res += base+".add("+idx+", "+val+")";
                } else if (member->member == "increment") {
                    res += base+".increment("+idx+")";
                } else {
                    res += base+".count("+idx+")";
                }
                currentProcedure->addModifiedGlobalVariables(base+"__counter");
                currentProcedure->addModifiedGlobalVariables(base+"__last_index");
                currentProcedure->addModifiedGlobalVariables(base+"__last_value");
                currentProcedure->addModifiedGlobalVariables(base+"__wrote_any");
                currentProcedure->addModifiedGlobalVariables(base+"__wrote_index0");
                currentProcedure->addModifiedGlobalVariables(base+"__last0_value");
                return res;
            }
        }
    }

    if (auto member = methodCallExpression->method->to<IR::Member>()) {
        if (member->member == "execute") {
            cstring base = translate(member->expr);
            auto meterIt = meterExterns.find(base);
            if (meterIt != meterExterns.end()) {
                const MeterExternInfo& info = meterIt->second;
                cstring idx = renderBoogieZeroLiteral(info.indexType);
                cstring colorArg = "";
                if (methodCallExpression->arguments != nullptr &&
                    methodCallExpression->arguments->size() >= 1) {
                    if (info.direct) {
                        colorArg = translate((*methodCallExpression->arguments)[0]);
                    } else {
                        idx = translate((*methodCallExpression->arguments)[0]);
                        if (methodCallExpression->arguments->size() >= 2) {
                            colorArg = translate((*methodCallExpression->arguments)[1]);
                        }
                    }
                }
                cstring tmp = getOrCreateFreshVar("meter_execute", info.colorType);
                if (currentProcedure != nullptr) {
                    if (colorArg != "") {
                        currentProcedure->addStatement(getIndent()+"call "+tmp+" := "+base+".execute_colored("+idx+", "+colorArg+");\n");
                    } else {
                        currentProcedure->addStatement(getIndent()+"call "+tmp+" := "+base+".execute("+idx+");\n");
                    }
                    currentProcedure->addModifiedGlobalVariables(tmp);
                    currentProcedure->addModifiedGlobalVariables(base+"__meter");
                    currentProcedure->addModifiedGlobalVariables(base+"__last_index");
                    currentProcedure->addModifiedGlobalVariables(base+"__last_color");
                    currentProcedure->addModifiedGlobalVariables(base+"__executed_any");
                    currentProcedure->addModifiedGlobalVariables(base+"__executed_index0");
                    currentProcedure->addModifiedGlobalVariables(base+"__last0_color");
                }
                return tmp;
            }
        }
    }

    if (auto member = methodCallExpression->method->to<IR::Member>()) {
        if ((member->member == "get" || member->member == "get_hash") &&
            methodCallExpression->arguments != nullptr &&
            methodCallExpression->arguments->size() > 0) {
            cstring base = translate(member->expr);
            auto hashIt = hashExternReturnTypes.find(base);
            if (hashIt != hashExternReturnTypes.end() && hashIt->second != "") {
                cstring retType = hashIt->second;
                auto unsupportedHashData = [&]() -> cstring {
                    cstring tmp = getOrCreateFreshVar("hash_get", retType);
                    if (currentProcedure != nullptr) {
                        currentProcedure->addStatement(getIndent()+"havoc "+tmp+";\n");
                        currentProcedure->addModifiedGlobalVariables(tmp);
                    }
                    return tmp;
                };
                std::vector<cstring> renderedArgs;
                std::vector<cstring> renderedArgTypes;
                std::vector<int> renderedArgWidths;
                cstring algorithm = "";
                cstring algorithmName = "";
                auto algIt = hashExternAlgorithms.find(base);
                if (algIt != hashExternAlgorithms.end()) {
                    algorithm = algIt->second;
                }
                auto algNameIt = hashExternAlgorithmNames.find(base);
                if (algNameIt != hashExternAlgorithmNames.end()) {
                    algorithmName = algNameIt->second;
                }
                cstring algorithmForModel = algorithmName != "" ? algorithmName : algorithm;
                auto markHashModel = [&](const std::string& model, const std::string& precision) {
                    if (currentProcedure != nullptr) {
                        cstring algText = algorithmForModel == "" ? cstring("unknown") : algorithmForModel;
                        currentProcedure->addStatement(
                            getIndent()+"// p4b_hash_model: extern base="+base+
                            " algorithm="+algText+
                            " model="+cstring(model.c_str())+
                            " precision="+cstring(precision.c_str())+"\n");
                    }
                };
                auto identityExpr = [&]() -> cstring {
                    const int retWidth = bvTypeWidth(retType);
                    if (retWidth <= 0 || renderedArgs.empty()) {
                        return "";
                    }
                    cstring combined = "";
                    int combinedWidth = 0;
                    for (size_t i = 0; i < renderedArgs.size(); ++i) {
                        int width = renderedArgWidths.size() > i ? renderedArgWidths[i] : -1;
                        if (width <= 0) {
                            return "";
                        }
                        if (combined == "") {
                            combined = renderedArgs[i];
                        } else {
                            combined += "++" + renderedArgs[i];
                        }
                        combinedWidth += width;
                    }
                    return coerceBitvectorExprWidth(combined, combinedWidth, retWidth);
                };
                std::function<bool(const IR::Expression*)> renderHashData =
                    [&](const IR::Expression* expr) -> bool {
                        if (expr == nullptr) {
                            return false;
                        }
                        if (auto listExpr = expr->to<IR::ListExpression>()) {
                            for (auto component : listExpr->components) {
                                if (!renderHashData(component)) {
                                    return false;
                                }
                            }
                            return true;
                        }
                        if (auto structExpr = expr->to<IR::StructExpression>()) {
                            for (auto component : structExpr->components) {
                                if (component == nullptr ||
                                    !renderHashData(component->expression)) {
                                    return false;
                                }
                            }
                            return true;
                        }

                        cstring rendered = translate(expr);
                        if (rendered == "") {
                            return false;
                        }
                        cstring argType = inferBoogieType(expr->type, rendered);
                        if (argType == "") {
                            if (rendered == "true" || rendered == "false") {
                                argType = "bool";
                            } else {
                                int width = getSize(rendered);
                                if (width > 0) {
                                    argType = "bv" + toString(width);
                                } else {
                                    argType = "int";
                                }
                            }
                        }
                        renderedArgs.push_back(rendered);
                        renderedArgTypes.push_back(argType);
                        renderedArgWidths.push_back(bvTypeWidth(argType));
                        return true;
                    };

                for (auto arg : *methodCallExpression->arguments) {
                    if (!renderHashData(arg->expression)) {
                        markHashModel("havoc_fallback", "weak");
                        return unsupportedHashData();
                    }
                }

                if (hashAlgorithmIsIdentity(algorithmForModel) &&
                    methodCallExpression->arguments->size() == 1) {
                    cstring exact = identityExpr();
                    if (exact != "") {
                        markHashModel("identity", "precise");
                        return exact;
                    }
                }

                std::string mangledMethod = method.c_str();
                mangledMethod += "$alg_";
                mangledMethod += hashAlgorithmMangleName(algorithmForModel);
                for (const auto& argType : renderedArgTypes) {
                    mangledMethod += "$";
                    mangledMethod += sanitizeHashSignaturePart(argType.c_str());
                }

                cstring hashMethod = cstring(mangledMethod);
                cstring decl = "function " + hashMethod + "(";
                for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                    if (i != 0) {
                        decl += ", ";
                    }
                    decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
                }
                decl += ") returns(" + retType + ");\n";
                addFunction(hashMethod, decl);
                markHashModel(hashAlgorithmModelName(algorithmForModel), "deterministic_uninterpreted");

                res += hashMethod+"(";
                for (size_t i = 0; i < renderedArgs.size(); ++i) {
                    if (i != 0) {
                        res += ", ";
                    }
                    res += renderedArgs[i];
                }
                res += ")";
                return res;
            }
        }
    }

    if(method=="lookahead")
        return "havoc";

    if(method=="mark_to_drop"){
        updateModifiedVariables("drop");
        return "mark_to_drop()";
    }

    if(!options.gotoOrIf && method.find("packet_in.extract")){
        cstring arg = "";
        for(auto argument:*methodCallExpression->arguments){
            arg = translate(argument);
            break;
        }
        if(arg.find(".next")) return "";
        res = arg+".valid := true;\n";
        currentProcedure->addModifiedGlobalVariables(arg+".valid");
        if(options.addValidityAssertion){
            cstring stmt = "assert("+arg+".valid);";
            if(currentProcedure->lastStatement().find(stmt.c_str())!= nullptr){
                currentProcedure->removeLastStatement();
            }
        } 
        return res;
    }

    if (auto member = methodCallExpression->method->to<IR::Member>()) {
        if (member->member == "read" &&
            methodCallExpression->arguments != nullptr &&
            methodCallExpression->arguments->size() == 0) {
            cstring base = translate(member->expr);
            auto randIt = randomExterns.find(base);
            if (randIt != randomExterns.end()) {
                const RandomExternInfo& info = randIt->second;
                cstring retType = info.retType != "" ? info.retType : inferBoogieType(methodCallExpression->type, "");
                if (retType == "") {
                    retType = "int";
                }
                cstring tmp = getOrCreateFreshVar("random_read", retType);
                if (currentProcedure != nullptr) {
                    currentProcedure->addStatement(getIndent()+"havoc "+tmp+";\n");
                    currentProcedure->addModifiedGlobalVariables(tmp);
                    if (info.lo != "" && info.hi != "") {
                        if (!options.ultimateAutomizer && retType.startsWith("bv")) {
                            addFunction("buge", "bvuge", retType, "bool");
                            addFunction("bule", "bvule", retType, "bool");
                            currentProcedure->addStatement(getIndent()+"assume(buge."+retType+"("+tmp+", "+info.lo+
                                ") && bule."+retType+"("+tmp+", "+info.hi+"));\n");
                        } else {
                            currentProcedure->addStatement(getIndent()+"assume(("+tmp+" >= "+info.lo+
                                ") && ("+info.hi+" >= "+tmp+"));\n");
                        }
                    }
                }
                return tmp;
            }
        }
    }

    // Register read (BMV2)
    if(method.find(".read")){
        // method = methodCallExpression->method->toString();
        std::string::size_type idx = ((std::string)method.c_str()).find(".read");
        cstring reg = ((std::string)method.c_str()).substr(0, idx);  // register
        if(!isGlobalVariable(reg)){
            method = methodCallExpression->method->toString();
            idx = ((std::string)method.c_str()).find(".read");
            reg = ((std::string)method.c_str()).substr(0, idx);
        }

        if((*methodCallExpression->arguments).size() == 1) {
            const auto *idxExpr = (*methodCallExpression->arguments)[0]->expression;
            cstring arg1 = translate((*methodCallExpression->arguments)[0]);
            std::string assumeExpr = regIndexAssume(reg.c_str(), idxExpr, arg1.c_str());
            if (!assumeExpr.empty() && currentProcedure != nullptr) {
                currentProcedure->addStatement(getIndent() + "assume (" + assumeExpr + ");\n");
            }
            res += method + "(" + reg + ", " + arg1 + ")";
            return res;
        }

        cstring arg0 = translate((*methodCallExpression->arguments)[0]);  // return addr

        currentProcedure->addModifiedGlobalVariables(arg0);
        const auto *idxExpr = (*methodCallExpression->arguments)[1]->expression;
        cstring arg1 = translate((*methodCallExpression->arguments)[1]);  // index
        std::string assumeExpr = regIndexAssume(reg.c_str(), idxExpr, arg1.c_str());
        if (!assumeExpr.empty()) {
            res += getIndent() + "assume (" + assumeExpr + ");\n";
        }
        res += arg0 + " := " + method + "(";
        res += reg + ", " + arg1 + ")";
        return res;
    }

    if(method.find(".write")){
        std::string::size_type idx = ((std::string)method.c_str()).find(".write");
        cstring reg = ((std::string)method.c_str()).substr(0, idx);  // register
        if(!isGlobalVariable(reg)){
            method = methodCallExpression->method->toString();
            idx = ((std::string)method.c_str()).find(".write");
            reg = ((std::string)method.c_str()).substr(0, idx);
        }
        if (isGlobalVariable(reg)) {
            addRegisterWriteModifiedVariables(reg);
        }
        if (methodCallExpression->arguments && methodCallExpression->arguments->size() >= 1) {
            const auto *idxExpr = (*methodCallExpression->arguments)[0]->expression;
            cstring arg0 = translate((*methodCallExpression->arguments)[0]);
            std::string assumeExpr = regIndexAssume(reg.c_str(), idxExpr, arg0.c_str());
            if (!assumeExpr.empty() && currentProcedure != nullptr) {
                currentProcedure->addStatement(getIndent() + "assume (" + assumeExpr + ");\n");
            }
        }
    }

    if(method=="hash"){
        if (methodCallExpression->arguments == nullptr ||
            methodCallExpression->arguments->size() < 3) {
            return "";
        }
        cstring arg0 = translate((*methodCallExpression->arguments)[0]);  // return addr
        cstring typeName = translate((*methodCallExpression->arguments)[0]->expression->type);

        cstring algorithm = translate((*methodCallExpression->arguments)[1]);
        cstring algorithmForModel = (*methodCallExpression->arguments)[1]->expression != nullptr
            ? (*methodCallExpression->arguments)[1]->expression->toString()
            : algorithm;

        if (typeDefs.find(typeName) != typeDefs.end()) {
            typeName = "bv" + toString(typeDefs[typeName]);
        }
        if (typeName == "") {
            typeName = kDefaultBv32Type;
        }
        bool isBv = typeName.find("bv") == 0;
        if (!isBv) {
            int sz = getSize(arg0);
            if (sz > 0) {
                typeName = "bv" + toString(sz);
                isBv = true;
            }
        }
        auto stripHashCasts = [](const IR::Expression* expr) {
            while (expr != nullptr) {
                if (auto cast = expr->to<IR::Cast>()) {
                    expr = cast->expr;
                    continue;
                }
                break;
            }
            return expr;
        };

        std::vector<cstring> renderedArgs;
        std::vector<cstring> renderedArgTypes;
        std::vector<int> renderedArgWidths;
        auto markV1HashModel = [&](const std::string& model, const std::string& precision) {
            if (currentProcedure != nullptr) {
                cstring algText = algorithmForModel == "" ? cstring("unknown") : algorithmForModel;
                currentProcedure->addStatement(
                    getIndent()+"// p4b_hash_model: builtin algorithm="+algText+
                    " model="+cstring(model.c_str())+
                    " precision="+cstring(precision.c_str())+"\n");
            }
        };
        auto identityExpr = [&](size_t beginArg, size_t endArg) -> cstring {
            const int retWidth = bvTypeWidth(typeName);
            if (retWidth <= 0 || beginArg >= endArg || endArg > renderedArgs.size()) {
                return "";
            }
            cstring combined = "";
            int combinedWidth = 0;
            for (size_t i = beginArg; i < endArg; ++i) {
                int width = renderedArgWidths.size() > i ? renderedArgWidths[i] : -1;
                if (width <= 0) {
                    return "";
                }
                if (combined == "") {
                    combined = renderedArgs[i];
                } else {
                    combined += "++" + renderedArgs[i];
                }
                combinedWidth += width;
            }
            return coerceBitvectorExprWidth(combined, combinedWidth, retWidth);
        };
        auto bvWidth = [](const cstring& bvType) -> int {
            if (!bvType.startsWith("bv")) {
                return -1;
            }
            return atoi(bvType.c_str() + 2);
        };
        auto coerceHashArgToType = [&](const IR::Expression* expr, cstring rendered,
                                       cstring srcType, cstring dstType) -> cstring {
            int dstWidth = bvWidth(dstType);
            if (dstWidth <= 0) {
                return rendered;
            }
            if (auto c = expr->to<IR::Constant>()) {
                std::stringstream ss;
                ss << c->value;
                return ss.str() + dstType;
            }
            int srcWidth = bvWidth(srcType);
            if (srcWidth <= 0) {
                int inferred = getSize(rendered);
                if (inferred > 0) {
                    srcWidth = inferred;
                }
            }
            if (srcWidth <= 0 || srcWidth == dstWidth) {
                return rendered;
            }
            if (srcWidth > dstWidth) {
                cstring base = rendered.find("++") != nullptr ? "(" + rendered + ")" : rendered;
                return base+"["+std::to_string(dstWidth)+":0]";
            }
            return "0bv"+std::to_string(dstWidth - srcWidth)+"++"+rendered;
        };
        auto renderHashArg = [&](const IR::Expression* expr, cstring forcedType) -> bool {
            if (expr == nullptr) {
                return false;
            }
            cstring rendered = translate(expr);
            if (rendered == "") {
                return false;
            }
            cstring argType = forcedType != "" ? forcedType : inferBoogieType(expr->type, rendered);
            if (argType == "") {
                if (rendered == "true" || rendered == "false") {
                    argType = "bool";
                } else {
                    int width = getSize(rendered);
                    argType = width > 0 ? "bv" + toString(width) : "int";
                }
            }
            if (forcedType != "" && forcedType.startsWith("bv")) {
                rendered = coerceHashArgToType(expr, rendered, argType, forcedType);
                argType = forcedType;
            } else if (argType.startsWith("bv")) {
                rendered = coerceHashArgToType(expr, rendered, argType, argType);
            }
            renderedArgs.push_back(rendered);
            renderedArgTypes.push_back(argType);
            renderedArgWidths.push_back(bvWidth(argType));
            return true;
        };
        std::function<bool(const IR::Expression*)> renderHashData =
            [&](const IR::Expression* expr) -> bool {
                if (expr == nullptr) {
                    return false;
                }
                if (auto listExpr = expr->to<IR::ListExpression>()) {
                    for (auto component : listExpr->components) {
                        if (!renderHashData(component)) {
                            return false;
                        }
                    }
                    return true;
                }
                if (auto structExpr = expr->to<IR::StructExpression>()) {
                    for (auto component : structExpr->components) {
                        if (component == nullptr || !renderHashData(component->expression)) {
                            return false;
                        }
                    }
                    return true;
                }
                return renderHashArg(expr, "");
            };

        if (methodCallExpression->arguments->size() == 3) {
            const auto *dataExpr = (*methodCallExpression->arguments)[2]->expression;
            if (!renderHashData(dataExpr)) {
                markV1HashModel("havoc_fallback", "weak");
                res += "havoc "+arg0+";\n";
            } else if (hashAlgorithmIsIdentity(algorithmForModel)) {
                cstring exact = identityExpr(0, renderedArgs.size());
                if (exact != "") {
                    markV1HashModel("identity", "precise");
                    res += arg0 + " := " + exact + ";\n";
                } else {
                    markV1HashModel("identity_uf", "deterministic_uninterpreted");
                    std::string mangledMethod = "hash";
                    if (algorithmForModel != "") {
                        mangledMethod += "_";
                        mangledMethod += hashAlgorithmMangleName(algorithmForModel);
                    }
                    for (const auto& argType : renderedArgTypes) {
                        mangledMethod += "$";
                        mangledMethod += sanitizeHashSignaturePart(argType.c_str());
                    }
                    cstring hashMethod = cstring(mangledMethod);
                    cstring decl = "function " + hashMethod + "(";
                    for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                        if (i != 0) {
                            decl += ", ";
                        }
                        decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
                    }
                    decl += ") returns(" + typeName + ");\n";
                    addFunction(hashMethod, decl);
                    res += arg0 + " := " + hashMethod + "(";
                    for (size_t i = 0; i < renderedArgs.size(); ++i) {
                        if (i != 0) {
                            res += ", ";
                        }
                        res += renderedArgs[i];
                    }
                    res += ");\n";
                }
            } else {
                std::string mangledMethod = "hash";
                if (algorithmForModel != "") {
                    mangledMethod += "_";
                    mangledMethod += hashAlgorithmMangleName(algorithmForModel);
                }
                for (const auto& argType : renderedArgTypes) {
                    mangledMethod += "$";
                    mangledMethod += sanitizeHashSignaturePart(argType.c_str());
                }
                cstring hashMethod = cstring(mangledMethod);
                cstring decl = "function " + hashMethod + "(";
                for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                    if (i != 0) {
                        decl += ", ";
                    }
                    decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
                }
                decl += ") returns(" + typeName + ");\n";
                addFunction(hashMethod, decl);
                markV1HashModel(hashAlgorithmModelName(algorithmForModel), "deterministic_uninterpreted");

                res += arg0 + " := " + hashMethod + "(";
                for (size_t i = 0; i < renderedArgs.size(); ++i) {
                    if (i != 0) {
                        res += ", ";
                    }
                    res += renderedArgs[i];
                }
                res += ");\n";
            }
            currentProcedure->addModifiedGlobalVariables(arg0);
            return res;
        }

        // v1model-style hash(result, algorithm, base, data, max).
        if (methodCallExpression->arguments->size() < 5) {
            return "";
        }
        const auto *arg2Expr = (*methodCallExpression->arguments)[2]->expression;
        const auto *arg3Expr = (*methodCallExpression->arguments)[3]->expression;
        const auto *arg4Expr = (*methodCallExpression->arguments)[4]->expression;

        // Keep v1model hash deterministic for a fixed algorithm/range/data tuple.
        // We still model the hash as uninterpreted, and retain the range assume below.
        cstring rangeFrom;
        cstring rangeTo;
        if (!renderHashArg(arg2Expr, typeName) || !renderHashData(arg3Expr) ||
            !renderHashArg(arg4Expr, typeName)) {
            markV1HashModel("havoc_fallback", "weak");
            res += "havoc "+arg0+";\n";
        } else {
            if (renderedArgs.size() >= 2) {
                rangeFrom = renderedArgs.front();
                rangeTo = renderedArgs.back();
            }
            std::string mangledMethod = "hash";
            if (algorithmForModel != "") {
                mangledMethod += "_";
                mangledMethod += hashAlgorithmMangleName(algorithmForModel);
            }
            for (const auto& argType : renderedArgTypes) {
                mangledMethod += "$";
                mangledMethod += sanitizeHashSignaturePart(argType.c_str());
            }
            cstring hashMethod = cstring(mangledMethod);
            cstring decl = "function " + hashMethod + "(";
            for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
                if (i != 0) {
                    decl += ", ";
                }
                decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
            }
            decl += ") returns(" + typeName + ");\n";
            addFunction(hashMethod, decl);
            markV1HashModel(hashAlgorithmModelName(algorithmForModel), "deterministic_uninterpreted");

            res += arg0 + " := " + hashMethod + "(";
            for (size_t i = 0; i < renderedArgs.size(); ++i) {
                if (i != 0) {
                    res += ", ";
                }
                res += renderedArgs[i];
            }
            res += ");\n";
        }

        cstring arg2 = rangeFrom != "" ? rangeFrom : translate(arg2Expr);
        cstring arg4 = rangeTo != "" ? rangeTo : translate(arg4Expr);
        if (isBv) {
            addFunction("buge", "bvuge", typeName, "bool");
            addFunction("bule", "bvule", typeName, "bool");
            auto hashUpperBound = [&](const IR::Expression* maxExpr, cstring renderedMax) -> cstring {
                const IR::Expression* stripped = stripHashCasts(maxExpr);
                if (auto c = stripped->to<IR::Constant>()) {
                    if (c->value == 0) {
                        return arg2;
                    }
                    std::stringstream ss;
                    ss << (c->value - 1);
                    return ss.str() + typeName;
                }
                addFunction("add", "bvadd", typeName, typeName);
                addFunction("sub", "bvsub", typeName, typeName);
                return "add."+typeName+"("+arg2+", sub."+typeName+"("+renderedMax+", 1"+typeName+"))";
            };
            if (rangeFrom == "") {
                if (auto c = stripHashCasts(arg2Expr)->to<IR::Constant>()) {
                    std::stringstream ss;
                    ss << c->value;
                    arg2 = ss.str() + typeName;
                }
            }
            if (rangeTo == "") {
                if (auto c = stripHashCasts(arg4Expr)->to<IR::Constant>()) {
                    std::stringstream ss;
                    ss << c->value;
                    arg4 = ss.str() + typeName;
                }
            }
            // v1model hash promises result in [base, base + max - 1] when max >= 1.
            // If max == 0, result is exactly base, so the upper bound is also base.
            arg4 = hashUpperBound(arg4Expr, arg4);
            res += getIndent()+"assume(buge."+typeName+"("+arg0+", "+arg2+
                ") && bule."+typeName+"("+arg0+", "+arg4+"));\n";
        } else {
            res += getIndent()+"assume(("+arg0+" >= "+arg2+
                ") && "+"("+arg4+" >= "+arg0+"));\n";
        }
        currentProcedure->addModifiedGlobalVariables(arg0);
        return res;
    }

    if(method=="verify"){
        cstring arg = translate((*methodCallExpression->arguments)[0]);
        res += "assert("+arg+")";
        return res;
    }

    if (method.find(".get") != nullptr && methodCallExpression->arguments->size() == 0) {
        cstring retType = translate(methodCallExpression->type);
        if (retType != "") {
            cstring decl = "function " + method + "() returns(" + retType + ");\n";
            addFunction(method, decl);
        }
        return method + "()";
    }

    std::string s = method.c_str();
    std::string::size_type idx = s.find("isValid");
    if(idx != std::string::npos){
        if(options.gotoOrIf)
            return "isValid["+s.substr(0, idx-1)+"]";
        else
            return s.substr(0, idx-1)+".valid";
    }
    if(method.find("setValid(") != nullptr || method.find("setInvalid(")){
        if(options.addValidityAssertion){
            if(currentProcedure->lastStatement().find("assert(")!= nullptr){
                currentProcedure->removeLastStatement();
            }
        }  
        updateModifiedVariables("isValid");
        return method;
    }

    if(methodCallExpression->arguments->size()>0){
        cstring argument = translate((*methodCallExpression->arguments)[0]);
        std::string s = argument.c_str();
        std::string::size_type idx = s.find("next");
        if(idx != std::string::npos){
            cstring succ = "packet_in.extract.headers.";
            succ += s.substr(4, idx-5)+".next";
            res = succ+"("+s.substr(0, idx-1)+")";
            currentProcedure->addSucc(succ);
            addPred(succ, currentProcedure->getName());
            return res;
        }
    }

    std::vector<cstring> renderedArgs;
    std::vector<cstring> renderedArgTypes;
    for (auto arg : *methodCallExpression->arguments) {
        cstring rendered = translate(arg);
        if (rendered != "") {
            renderedArgs.push_back(rendered);
            cstring argType = inferBoogieType(arg->expression->type, rendered);
            if (argType == "") {
                argType = "int";
            }
            renderedArgTypes.push_back(argType);
        }
        // packet_in.extract with multiple parameters (only consider the first param)
        if (method.find("extract") != nullptr) {
            break;
        }
    }
    cstring retType = "";
    if (methodCallExpression->typeArguments != nullptr &&
        methodCallExpression->typeArguments->size() > 0) {
        retType = inferBoogieType((*methodCallExpression->typeArguments)[0], "");
    }
    if (retType == "") {
        retType = inferBoogieType(methodCallExpression->type, "");
    }
    if (retType != "" && functions.find(method) == functions.end()
        && procedures.find(method) == procedures.end()) {
        cstring decl = "function " + method + "(";
        for (size_t i = 0; i < renderedArgTypes.size(); ++i) {
            if (i != 0) {
                decl += ", ";
            }
            decl += "arg"+toString(static_cast<int>(i))+":"+renderedArgTypes[i];
        }
        decl += ") returns(" + retType + ");\n";
        addFunction(method, decl);
    }

    currentProcedure->addSucc(method);
    addPred(method, currentProcedure->getName());

    res += method+"(";
    for (size_t i = 0; i < renderedArgs.size(); ++i) {
        if (i != 0) {
            res += ", ";
        }
        res += renderedArgs[i];
    }
    res += ")";
    return res;
}
