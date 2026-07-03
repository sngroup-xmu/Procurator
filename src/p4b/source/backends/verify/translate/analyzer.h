#ifndef BACKENDS_VERIFY_TRANSLATE_ANALYZER_H_ 
#define BACKENDS_VERIFY_TRANSLATE_ANALYZER_H_

#include <queue>
#include <map>
#include "backends/verify/verify_compat.h"

/* 
  used to analyze P4 programs

*/
class Analyzer{
private:

public:
	Analyzer();	
	void analyzeP4Program(const IR::P4Program *program);
	void analyzeP4Parser(const IR::P4Parser *parser);
};

#endif
