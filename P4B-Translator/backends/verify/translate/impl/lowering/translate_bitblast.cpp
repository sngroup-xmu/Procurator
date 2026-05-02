#include "translate.h"

#include <sstream>
#include <string>

cstring Translator::bitBlastingTempDecl(const cstring &tmpPrefix, int size){
    for(int i = 0; i < size; i++){
        cstring tempVar = connect(tmpPrefix, i);
        addDeclaration("var "+tempVar+" : bool;\n");
        addGlobalVariables(tempVar);
        updateVariableSize(tempVar, 0);
        if(currentProcedure != nullptr)
            currentProcedure->addModifiedGlobalVariables(tempVar);
    }
}

cstring Translator::bitBlastingTempAssign(const cstring &tmpPrefix, int start, int end){
    for(int i = start; i <= end; i++){
        currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" := false;\n");
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
            currentProcedure->addStatement(getIndent()+connect(res, i)+" := true;\n");
        else
            currentProcedure->addStatement(getIndent()+connect(res, i)+" := false;\n");
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
        cstring typeName;
        if(auto typeBits = opBinary->left->type->to<IR::Type_Bits>()){
            size = typeBits->size;
            typeName = translate(opBinary->left->type);
        }
        else{
            size = currentProcedure->declarationVariables[translate(opBinary->left)];
            typeName = "bv"+toString(size);
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
                            +" := "+connect(left, i-right)+";\n");
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
                            +" := "+connect(left, i-right)+";\n");
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
            currentProcedure->addStatement(getIndent()+connect(tmpPrefix, 0)+" := "
                +exprXor(connect(left, 0), connect(right, 0))+";\n");
            currentProcedure->addStatement(getIndent()+connect(tmpPrefixes[0], 0)+" := "
                +connect(left, 0)+" && "+connect(right, 0)+";\n");
            for(int i = 1; i < size; i++){
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" := "
                    +exprXor(connect(left, i), connect(right, i), connect(tmpPrefixes[i-1], 0))+";\n");
                currentProcedure->addStatement(getIndent()+connect(tmpPrefixes[i], 0)+" := ("
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
            
            // negRight[0] := (!right[0])^true
            currentProcedure->addStatement(getIndent()+connect(negRight, 0)+" := "+
                exprXor("(!"+connect(right, 0)+")", "true")+";\n");
            // negRightTmp[0] := (!right[0])&true
            currentProcedure->addStatement(getIndent()+connect(negRightTmp, 0)+" := (!"+
                connect(right, 0)+") && true;\n");
            for(int i = 1; i < size; i++){
                // negRight[i] := (!right[i]) ^ negRightTmp[i-1]
                currentProcedure->addStatement(getIndent()+connect(negRight, i)+" := "+
                    exprXor("(!"+connect(right, i)+")", connect(negRightTmp, i-1))+";\n");
                // negRightTmp[i] := (!right[i]) & negRightTmp[i-1]
                currentProcedure->addStatement(getIndent()+connect(negRight, i)+" := (!"+
                    connect(right, i)+") && "+connect(negRightTmp, i-1)+";\n");
            }

            cstring resTmp = getTempPrefix();
            bitBlastingTempDecl(resTmp, size);
            // res[0] := left[0] ^ negRight[0]
            currentProcedure->addStatement(getIndent()+connect(tmpPrefix, 0)+" := "+
                exprXor(connect(left, 0), connect(negRight, 0))+";\n");
            // resTmp[0] := left[0] & negRight[0]
            currentProcedure->addStatement(getIndent()+connect(resTmp, 0)+" := "+
                connect(left, 0)+" && "+connect(negRight, 0)+";\n");
            for(int i = 1; i < size; i++){
                // res[i] := left[i] ^ negRight[i] ^ resTmp[i-1]
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" := "+
                    exprXor(connect(left, i), connect(negRight, i), connect(resTmp, i-1))+";\n");
                currentProcedure->addStatement(getIndent()+connect(resTmp, i)+" := ("+
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
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" := "
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
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" := "
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
                currentProcedure->addStatement(getIndent()+connect(tmpPrefix, i)+" := "
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
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " := ";
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
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " := ";
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
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " := ";
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
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " := ";
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
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " := ";
                for(int j = 0; j < i; j++){
                    stmt += "("+connect(left, size-1-j)+"=="+connect(right, size-1-j)+")";
                    if(j < i-1) stmt += " && ";
                }
                if(i != 0) stmt += " && ";
                stmt += "("+connect(left, size-1-i)+"&&"+"!"+connect(right, size-1-i)+");\n";
                currentProcedure->addStatement(stmt);
            }
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " := ";
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
                cstring stmt = getIndent()+connect(tmpPrefix2, i) + " := ";
                for(int j = 0; j < i; j++){
                    stmt += "("+connect(left, size-1-j)+"=="+connect(right, size-1-j)+")";
                    if(j < i-1) stmt += " && ";
                }
                if(i != 0) stmt += " && ";
                stmt += "(!"+connect(left, size-1-i)+"&&"+connect(right, size-1-i)+");\n";
                currentProcedure->addStatement(stmt);
            }
            cstring stmt = getIndent()+connect(tmpPrefix, 0) + " := ";
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

            cstring stmt = getIndent()+connect(tmpPrefix, 0)+ " := ";
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

            cstring stmt = getIndent()+connect(tmpPrefix, 0)+ " := ";
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
        std::cout << opBinary->left->type->toString() << std::endl;
        return "("+translate(opBinary->left)+") "+opBinary->getStringOp()+" ("+translate(opBinary->right)+")";
    }
    return "";
}

cstring Translator::translateUA(const IR::Operation_Binary *opBinary){
    if (auto arrayIndex = opBinary->to<IR::ArrayIndex>()) {
        return translate(arrayIndex);
    }
    else if (auto mask = opBinary->to<IR::Mask>()) {
        return translate(mask);
    }
    // currentProcedure->declarationVariables[translate(declVar->name)] = typeBits->size;
            // }
    // else if (auto typeBits = opBinary->left->type->to<IR::Type_Bits>()){
    else if (opBinary->left->type->to<IR::Type_Bits>() ||
        opBinary->right->type->to<IR::Type_Bits>() || 
        currentProcedure->declarationVariables.find(translate(opBinary->left)) != currentProcedure->declarationVariables.end()){
        int size;
        cstring typeName;
        if(auto typeBits = opBinary->left->type->to<IR::Type_Bits>()){
            size = typeBits->size;
            typeName = translate(opBinary->left->type);
        }
        else if(auto typeBits = opBinary->right->type->to<IR::Type_Bits>()){
            size = typeBits->size;
            typeName = translate(opBinary->right->type);
        }
        else{
            size = currentProcedure->declarationVariables[translate(opBinary->left)];
            typeName = "bv"+toString(size);
        }
        cstring function = "";
        if (auto shl = opBinary->to<IR::Shl>()){ 
            // the 2nd parameter must be constant integer
            if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>()){
                // eg: shl.bv8_2(num:int) : int {(num*power_2_2())%power_2_8()}
                cstring right = translate(opBinary->right);
                cstring powerFunc = "power_2_"+right+"()";
                cstring funcName = "shl."+typeName+"_"+right;

                function = "function {:inline true} "+funcName+"(num:int) : ";
                function += "int {(num*"+powerFunc+")\%"+powerFunc+"}\n";
                
                addFunction(funcName, function);

                return funcName+"("+translate(opBinary->left)+")";
            }
            else{
                cstring left = translate(opBinary->left);
                if(isNumber(left)){
                    cstring funcName = "shl."+typeName+"_"+left+"_n";
                    int leftNum = atoi(std::string(left.c_str()).c_str());

                    function = "function {:inline true} "+funcName+"(n:int) : ";
                    function += "int {\n";
                    function += "    if(n == 0) then "+left+"\n";
                    bool flag = false;
                    for(int i = 1; i < size; i++){
                        cstring shl_funcName = "shl."+typeName+"_"+toString(i);
                        function += "    else if(n == "+toString(i)+") then ";
                        long long tmp = leftNum;
                        tmp <<= i;
                        if(flag || tmp > 2147483647){
                            flag = true;
                            function += toString(leftNum)+"*power_2_"+toString(i)+"()\n";
                        }
                        else{
                            function += toString(leftNum << i)+"\n";
                        }
                        // function += shl_funcName+"(num)\n";
                    }
                    function += "    else 0\n";
                    function += "}\n";

                    addFunction(funcName, function);

                    return funcName+"("+translate(opBinary->right)+")";
                }
                else{
                    cstring funcName = "shl."+typeName+"_n";

                    for(int i = 1; i <= size; i++){
                        cstring shl_function = "";
                        cstring shl_funcName = "shl."+typeName+"_"+toString(i);
                        cstring shl_powerFunc = "power_2_"+toString(i)+"()";
                        shl_function = "function {:inline true} "+shl_funcName+"(num:int) : ";
                        shl_function += "int {(num*"+shl_powerFunc+")\%"+shl_powerFunc+"}\n";
                        addFunction(shl_funcName, shl_function);
                    }
                    function = "function {:inline true} "+funcName+"(num:int, n:int) : ";
                    function += "int {\n";
                    function += "    if(n == 0) then num\n";
                    for(int i = 1; i < size; i++){
                        cstring shl_funcName = "shl."+typeName+"_"+toString(i);
                        function += "    else if(n == "+toString(i)+") then ";
                        function += shl_funcName+"(num)\n";
                    }
                    function += "    else 0\n";
                    function += "}\n";

                    addFunction(funcName, function);

                    return funcName+"("+translate(opBinary->left)+","+translate(opBinary->right)+")";
                }
            }
        }
        else if (auto shr = opBinary->to<IR::Shr>()){
            // the 2nd parameter must be constant integer
            if(auto typeInfInt = opBinary->right->type->to<IR::Type_InfInt>()){
                // eg: shr.bv8_2(num:int) : int {(num-num%power_2_2())/power_2_2()}
                cstring right = translate(opBinary->right);
                cstring powerFunc = "power_2_"+right+"()";
                cstring funcName = "shr."+typeName+"_"+right;

                function = "function {:inline true} "+funcName+"(num:int) : ";
                function += "int {(num-num\%"+powerFunc+")/"+powerFunc+"}\n";
                
                addFunction(funcName, function);
                
                return funcName+"("+translate(opBinary->left)+")";
            }
            else{
                return "";
            }
        }
        else if (auto mul = opBinary->to<IR::Mul>()){
            cstring powerFunc = "power_2_"+toString(size)+"()";
            cstring funcName = "mul."+typeName;
            
            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{("+
                "(left\%"+powerFunc+")*(right\%"+powerFunc+"))\%"+powerFunc+"}\n";
            
            addFunction(funcName, function);
            
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto add = opBinary->to<IR::Add>()){
            // TODO: left/right may be integers
            cstring powerFunc = "power_2_"+toString(size)+"()";
            cstring funcName = "add."+typeName;

            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{("+
                "(left\%"+powerFunc+")+(right\%"+powerFunc+"))\%"+powerFunc+"}\n";
            
            addFunction(funcName, function);
            
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto addSat = opBinary->to<IR::AddSat>()) {
            // TODO: left/right may be integers
            cstring powerFunc = "power_2_"+toString(size)+"()";
            cstring funcName = "add."+typeName;

            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{("+
                "(left\%"+powerFunc+")+(right\%"+powerFunc+"))\%"+powerFunc+"}\n";
            
            addFunction(funcName, function);
            
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto sub = opBinary->to<IR::Sub>()) {
            // overflow???
            cstring powerFunc = "power_2_"+toString(size)+"()";
            cstring funcName = "sub."+typeName;

            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{("+
                powerFunc+" + (left\%"+powerFunc+") - (right\%"+powerFunc+"))\%"+powerFunc+"}\n";
            
            addFunction(funcName, function);

            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto subSat = opBinary->to<IR::SubSat>()) {
            // overflow???
            cstring powerFunc = "power_2_"+toString(size)+"()";
            cstring funcName = "sub."+typeName;

            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{("+
                powerFunc+" + (left\%"+powerFunc+") - (right\%"+powerFunc+"))\%"+powerFunc+"}\n";
            
            addFunction(funcName, function);

            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto bAnd = opBinary->to<IR::BAnd>()) {
            cstring powerFunc = "";
            cstring funcName = "band."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{\n";
            
            for(int i = 0; i < size; i++){
                powerFunc = "power_2_"+toString(i)+"()";
                
                // eg: band( ((left-left%power_2_0())/power_2_0())%2, 
                //           ((right-right%power_2_0())/power_2_0())%2 ) * power_2_0()
                function += "    band( ((left-left\%"+powerFunc+")/"+powerFunc+")\%2, "+
                    "((right-right\%"+powerFunc+")/"+powerFunc+")\%2 ) * " + powerFunc;
                
                if(i < size-1)
                    function += " +";
                function += "\n";
            }
            function += "}\n";

            addFunction(funcName, function);

            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto bOr = opBinary->to<IR::BOr>()) {
            cstring powerFunc = "";
            cstring funcName = "bor."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{\n";
            
            for(int i = 0; i < size; i++){
                powerFunc = "power_2_"+toString(i)+"()";

                // eg: bor( ((left-left%power_2_0())/power_2_0())%2, 
                //          ((right-right%power_2_0())/power_2_0())%2 ) * power_2_0()
                function += "    bor( ((left-left\%"+powerFunc+")/"+powerFunc+")\%2, "+
                    "((right-right\%"+powerFunc+")/"+powerFunc+")\%2 ) * " + powerFunc;
                
                if(i < size-1)
                    function += " +";
                function += "\n";
            }
            function += "}\n";

            addFunction(funcName, function);

            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto bXor = opBinary->to<IR::BXor>()) {
            cstring powerFunc = "";
            cstring funcName = "bxor."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : int{\n";
            
            for(int i = 0; i < size; i++){
                powerFunc = "power_2_"+toString(i)+"()";

                // eg: bor( ((left-left%power_2_0())/power_2_0())%2, 
                //          ((right-right%power_2_0())/power_2_0())%2 ) * power_2_0()
                function += "    bxor( ((left-left\%"+powerFunc+")/"+powerFunc+")\%2, "+
                    "((right-right\%"+powerFunc+")/"+powerFunc+")\%2 ) * " + powerFunc;
                
                if(i < size-1)
                    function += " +";
                function += "\n";
            }
            function += "}\n";

            addFunction(funcName, function);

            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto geq = opBinary->to<IR::Geq>()) {
            // eg: bsge.bv8(left:int, right:int) : bool{left >= right}
            cstring funcName = "bsge."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : bool{"
                + "left >= right" + "}\n";
            addFunction(funcName, function);
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto leq = opBinary->to<IR::Leq>()) {
            // eg: bsle.bv8(left:int, right:int) : bool{left <= right}
            cstring funcName = "bsle."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : bool{"
                + "left <= right" + "}\n";
            addFunction(funcName, function);
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto grt = opBinary->to<IR::Grt>()) {
            // eg: bugt.bv8(left:int, right:int) : bool{left > right}
            cstring funcName = "bugt."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : bool{"
                + "left > right" + "}\n";
            addFunction(funcName, function);
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto lss = opBinary->to<IR::Lss>()) {
            // eg: bult.bv8(left:int, right:int) : bool{left < right}
            cstring funcName = "bult."+typeName;
            function = "function {:inline true} "+funcName+"(left:int, right:int) : bool{"
                + "left < right" + "}\n";
            addFunction(funcName, function);
            return funcName+"("+translate(opBinary->left)+", "+translate(opBinary->right)+")";
        }
        else if (auto equ = opBinary->to<IR::Equ>()) {
            return "(" + translate(opBinary->left) + " == " + translate(opBinary->right) + ")";
        }
        else if (auto neq = opBinary->to<IR::Neq>()) {
            return "(" + translate(opBinary->left) + " != " + translate(opBinary->right) + ")";
        }
    }
    else{
        // std::cout << opBinary->node_type_name() << std::endl;
        // std::cout << opBinary << std::endl;
        // std::cout << opBinary->left->type << std::endl;
        // std::cout << opBinary->left->type->node_type_name() << std::endl;
        // std::cout << opBinary->right->type << std::endl;
        // std::cout << opBinary->right->type->node_type_name() << std::endl;
        // std::cout << std::endl;
        return "("+translate(opBinary->left)+") "+opBinary->getStringOp()+" ("+translate(opBinary->right)+")";
    }
    return "";
}
