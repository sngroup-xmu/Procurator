#include "translate.h"

#include <cstdlib>
#include <sstream>
#include <string>

cstring Translator::translate(const IR::Operation_Binary *opBinary){
    if(options.bitBlasting){
        return bitBlasting(opBinary);
    }

    if(options.ultimateAutomizer){
        return translateUA(opBinary);
    }

    cstring typeName = translate(opBinary->left->type);
    cstring returnType = translate(opBinary->type);
    if (typeName != "" && !typeName.startsWith("bv") && typeDefs.find(typeName) == typeDefs.end()) {
        typeName = "";
    }
    if (typeName == "") {
        auto inferTypeName = [&](const IR::Expression *expr) -> cstring {
            if (expr == nullptr || expr->type == nullptr) return "";
            if (auto tb = expr->type->to<IR::Type_Bits>()) {
                return "bv" + toString(tb->size);
            }
            if (auto tn = expr->type->to<IR::Type_Name>()) {
                cstring name = translate(tn);
                if (typeDefs.find(name) != typeDefs.end()) {
                    return "bv" + toString(typeDefs[name]);
                }
                return name;
            }
            cstring name = translate(expr);
            int size = getSize(name);
            if (size > 0) return "bv" + toString(size);
            return "";
        };
        typeName = inferTypeName(opBinary->left);
        if (typeName == "") typeName = inferTypeName(opBinary->right);
        if (typeName == "") {
            if (maxBitvectorSize > 0)
                typeName = "bv" + toString(maxBitvectorSize);
            else
                typeName = kDefaultBv32Type;
        }
    }
    if (typeDefs.find(typeName) != typeDefs.end()) {
        typeName = "bv" + toString(typeDefs[typeName]);
    }

    auto bvWidth = [&](const cstring& bv) -> int {
        if (!bv.startsWith("bv")) {
            return -1;
        }
        return atoi(bv.c_str() + 2);
    };

    auto renderInfIntWithBvType = [&](const IR::Expression* expr, const cstring& bvType) -> cstring {
        if (expr == nullptr) {
            return "";
        }
        if (expr->type == nullptr || expr->type->to<IR::Type_InfInt>() == nullptr) {
            return translate(expr);
        }
        if (!bvType.startsWith("bv")) {
            return translate(expr);
        }
        if (auto constant = expr->to<IR::Constant>()) {
            const int width = bvWidth(bvType);
            if (width > 0) {
                const big_int mod = big_int(1) << width;
                big_int v = constant->value % mod;
                if (v < 0) {
                    v += mod;
                }
                return toString(v) + bvType;
            }
        }
        return translate(expr) + bvType;
    };

    auto bitWidthOf = [&](const IR::Expression* expr) -> int {
        if (expr == nullptr || expr->type == nullptr) {
            return -1;
        }
        if (auto tb = expr->type->to<IR::Type_Bits>()) {
            return tb->size;
        }
        if (auto tn = expr->type->to<IR::Type_Name>()) {
            cstring name = translate(tn);
            auto it = typeDefs.find(name);
            if (it != typeDefs.end()) {
                return it->second;
            }
        }
        cstring rendered = translate(expr);
        int inferred = getSize(rendered);
        return inferred > 0 ? inferred : -1;
    };

    auto renderShiftAmount = [&](const IR::Expression* expr, const cstring& bvType) -> cstring {
        cstring rendered = renderInfIntWithBvType(expr, bvType);
        const int dstWidth = bvWidth(bvType);
        if (expr == nullptr || expr->type == nullptr || dstWidth <= 0 ||
            expr->type->to<IR::Type_InfInt>() != nullptr) {
            return rendered;
        }
        return coerceBitvectorExprWidth(rendered, bitWidthOf(expr), dstWidth);
    };

    if (opBinary->is<IR::Shl>()) {
        addFunction("shl", "bvshl", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderShiftAmount(opBinary->right, returnType);
        return "shl."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::Shr>()) {
        addFunction("shr", "bvlshr", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderShiftAmount(opBinary->right, returnType);
        return "shr."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::Mul>()) {
        addFunction("mul", "bvmul", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "mul."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::Add>()) {
        addFunction("add", "bvadd", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "add."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::AddSat>()) {
        addFunction("add", "bvadd", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "add."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::Sub>()) {
        addFunction("sub", "bvsub", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "sub."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::SubSat>()) {
        addFunction("sub", "bvsub", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "sub."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::BAnd>()) {
        addFunction("band", "bvand", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "band."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::BOr>()) {
        addFunction("bor", "bvor", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "bor."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::BXor>()) {
        addFunction("bxor", "bvxor", typeName, returnType);
        cstring left = renderInfIntWithBvType(opBinary->left, returnType);
        cstring right = renderInfIntWithBvType(opBinary->right, returnType);
        return "bxor."+returnType+"("+left+", "+right+")";
    }
    else if (opBinary->is<IR::Geq>()) {
        cstring left = renderInfIntWithBvType(opBinary->left, typeName);
        cstring right = renderInfIntWithBvType(opBinary->right, typeName);

        // P4's bit<k> comparisons are unsigned. Use SMT bv* comparisons directly
        // instead of the old subtraction+slice encoding (which had off-by-one bugs
        // for the extended width and could lead to unsound results).
        if (typeName.startsWith("bv")) {
            addFunction("buge", "bvuge", typeName, "bool");
            return "buge."+typeName+"("+left+", "+right+")";
        }
        return "("+left+" >= "+right+")";
    }
    else if (opBinary->is<IR::Leq>()) {
        cstring left = renderInfIntWithBvType(opBinary->left, typeName);
        cstring right = renderInfIntWithBvType(opBinary->right, typeName);

        if (typeName.startsWith("bv")) {
            addFunction("bule", "bvule", typeName, "bool");
            return "bule."+typeName+"("+left+", "+right+")";
        }
        return "("+left+" <= "+right+")";
    }
    else if (opBinary->is<IR::Grt>()) {
        cstring left = renderInfIntWithBvType(opBinary->left, typeName);
        cstring right = renderInfIntWithBvType(opBinary->right, typeName);

        if (typeName.startsWith("bv")) {
            addFunction("bugt", "bvugt", typeName, "bool");
            return "bugt."+typeName+"("+left+", "+right+")";
        }
        return "("+left+" > "+right+")";
    }
    else if (opBinary->is<IR::Lss>()) {
        cstring left = renderInfIntWithBvType(opBinary->left, typeName);
        cstring right = renderInfIntWithBvType(opBinary->right, typeName);

        if (typeName.startsWith("bv")) {
            addFunction("bult", "bvult", typeName, "bool");
            return "bult."+typeName+"("+left+", "+right+")";
        }
        return "("+left+" < "+right+")";
    }
    else if (opBinary->is<IR::Equ>()) {
        return "(" + translate(opBinary->left) + " == " + translate(opBinary->right) + ")";
    }
    else if (opBinary->is<IR::Neq>()) {
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
    else if (auto member = opUnary->to<IR::Member>()){
        return translate(member);
    }
    else if (auto lnot = opUnary->to<IR::LNot>()){
        return translate(lnot);
    }
    else if (opUnary->is<IR::Cmpl>()) {
        if(auto typeBits = opUnary->type->to<IR::Type_Bits>()){
            if(options.ultimateAutomizer){
                cstring returnType = translate(opUnary->type);
                cstring powerFunc = "";
                cstring funcName = "bnot."+returnType;
                cstring function = "function {:inline true} "+funcName+"(num:int) : int{\n";
                int size = typeBits->size;

                for(int i = 0; i < size; i++){
                    powerFunc = "power_2_"+toString(i)+"()";
                    
                    // eg: bnot( ((num-num%power_2_0())/power_2_0())%2 ) * power_2_0()
                    function += "    bnot( ((num-num%"+powerFunc+")/"+powerFunc+")%2 ) * " + powerFunc;
                    
                    if(i < size-1)
                        function += " +";
                    function += "\n";
                }
                function += "}\n";

                addFunction(funcName, function);

                return funcName+"("+translate(opUnary->expr)+")";
            }
        }

        cstring returnType = translate(opUnary->type);
        cstring functionName = "bnot."+returnType;
        cstring opbuiltin = "bvnot";
        cstring res = "\nfunction {:bvbuiltin \""+opbuiltin+"\"} "+functionName;
        res += "(left:"+returnType+") returns("+returnType+");\n";
        // addDeclaration(res);

        if(functions.find(functionName)==functions.end()){
            functions.insert(functionName);
            addDeclaration(res);
        }
        return functionName+"("+translate(opUnary->expr)+")";
    }
    return "";
}
