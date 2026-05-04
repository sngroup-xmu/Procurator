#ifndef BACKENDS_VERIFY_TRANSLATEP4LTL_P4LTL_UTILS_H_ 
#define BACKENDS_VERIFY_TRANSLATEP4LTL_P4LTL_UTILS_H_

#include <vector>
#include <map>
#include <set>
#include "backends/verify/verify_compat.h"
#ifdef P4VERIFY_ENABLE_P4LTL
#include "frontends/parsers/p4ltl/p4ltlast.hpp"
#endif
#include "backends/verify/translate/translate.h"
#include "backends/verify/translate/utils.h"

/*
	## AST Node Types ##
	
	BinOpNode
	- BinaryTemporalOperator
	- ExtendedComparativeOperator
	- BinaryPredicateOperator
	- BinaryTermOperator

	UOpNode
	- UnaryTemporalOperator
	- UnaryPredicateOperator

	P4LTLAtomicProposition

	Predicate
	- Drop
	- Forward
	- Valid
	- Apply

	IntLiteral

	BooleanLiteral

	Name
	- OldExpression

	Key

	ArrayAccessExprssion
*/

const std::vector<cstring> P4LTL_KEYS = {"//#LTLVariables:", "//#LTLProperty:", "//#LTLFairness:", 
										"//#CPI:", "//#CPI_MODEL:", "//#CPI_SPEC:"};
const cstring P4LTL_KEYS_VAR = "//#LTLVariables:";
const cstring P4LTL_KEYS_SPEC = "//#LTLProperty:";
const cstring P4LTL_KEYS_FAIR = "//#LTLFairness:";
const cstring P4LTL_KEYS_CPI = "//#CPI:";
const cstring P4LTL_KEYS_CPI_MODEL = "//#CPI_MODEL:";
const cstring P4LTL_KEYS_CPI_SPEC = "//#CPI_SPEC:";

class Translator;

namespace P4LTL {
#ifndef P4VERIFY_ENABLE_P4LTL
class AstNode {
 public:
	cstring toString() const { return ""; }
};
#endif
}

class CPIRule{
private:
	cstring table;
	std::map<cstring, cstring> keys;
	cstring action;
public:
	std::vector<cstring> params;
	CPIRule(){
		table = "";
		action = "";
	}
	void setTable(cstring _table){
		table = _table;
	}
	void addKey(cstring key, cstring value){
		keys[key] = value;
	}
	void addParam(cstring param){
		params.push_back(param);
	}
	void setAction(cstring _action){
		action = _action;
	}
	cstring getTable(){ return table; }
	cstring getAction(){ return action; }
	std::map<cstring, cstring> getKeys(){ return keys; }
	std::vector<cstring> getParams(){ return params; }
};

class P4LTLTranslator{
	Translator* p4Translator;
	std::vector<cstring> vars;
	std::vector<cstring> stmts;
	std::vector<cstring> declarations;
	std::map<cstring, cstring> freeVars;
	std::map<cstring, int> sizes;

	std::map<cstring, cstring> cache;

public:
	P4LTLTranslator(){
		p4Translator = nullptr;
	}
	P4LTLTranslator(Translator* translator){
		p4Translator = translator;
	}
#ifdef P4VERIFY_ENABLE_P4LTL
	cstring translateP4LTL(P4LTL::AstNode* node);
	cstring translateP4LTL(P4LTL::BinOpNode* node);
	cstring translateP4LTL(P4LTL::UOpNode* node);
	cstring translateP4LTL(P4LTL::P4LTLAtomicProposition* node);
	cstring translateP4LTL(P4LTL::Predicate* node);
	cstring translateP4LTL(P4LTL::IntLiteral* node);
	cstring translateP4LTL(P4LTL::BooleanLiteral* node);
	cstring translateP4LTL(P4LTL::Name* node);
	cstring translateP4LTL(P4LTL::Key* node);
	cstring translateP4LTL(P4LTL::ArrayAccessExprssion* node);

	void getAllNodes(std::vector<P4LTL::AstNode*>& nodes, P4LTL::AstNode* root);
	std::vector<P4LTL::AstNode*> getAllNodes(P4LTL::AstNode* root);

	std::set<cstring> getOldExprs(P4LTL::AstNode* root);
	std::map<cstring, std::set<cstring>> getOldArrays(P4LTL::AstNode* root);

	bool isActionApplied(P4LTL::AstNode* root, cstring action);
#else
	cstring translateP4LTL(P4LTL::AstNode*) { return ""; }
	std::set<cstring> getOldExprs(P4LTL::AstNode*) { return {}; }
	std::map<cstring, std::set<cstring>> getOldArrays(P4LTL::AstNode*) { return {}; }
	bool isActionApplied(P4LTL::AstNode*, cstring) { return false; }
#endif

	int getSize(cstring variable) {
		auto it = sizes.find(variable);
		return it == sizes.end() ? -1 : it->second;
	}

	bool isBvType(cstring type);
	int getBvLength(cstring type);

	std::map<cstring, cstring> getFreeVariables() { return freeVars; }
	void addFreeVariable(cstring variable);
#ifdef P4VERIFY_ENABLE_P4LTL
	void createFreeVariables(cstring decl);
#else
	void createFreeVariables(cstring) {}
#endif
	bool isFreeVariable(cstring variable);
	
	std::vector<cstring> getVariables() { return vars; }
	void addVariable(cstring stmt);

	std::vector<cstring> getStatements() { return stmts; }
	void addStatement(cstring stmt);

	std::vector<cstring> getDeclarations() { return declarations; }
	void addDeclaration(cstring declaration);

	bool alreadyDeclared(cstring expr);
	cstring getCacheVariable(cstring expr);

#ifdef P4VERIFY_ENABLE_P4LTL
	CPIRule* analyzeRule(P4LTL::AstNode* root);
#else
	CPIRule* analyzeRule(P4LTL::AstNode*) { return nullptr; }
#endif
};
#endif
