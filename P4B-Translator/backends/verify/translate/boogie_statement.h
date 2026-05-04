#ifndef BACKENDS_VERIFY_TRANSLATE_BOOGIE_STATEMENT_H_
#define BACKENDS_VERIFY_TRANSLATE_BOOGIE_STATEMENT_H_

#include "backends/verify/verify_compat.h"

class BoogieStatement{
private:
	cstring cont;
	bool hide;
public:
	BoogieStatement();
	BoogieStatement(const cstring &cont);
	cstring toString();
};

class CallStatement:BoogieStatement{
private:
public:
	CallStatement();
	cstring toString();
};

#endif
