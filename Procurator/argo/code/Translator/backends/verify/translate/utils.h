#ifndef BACKENDS_VERIFY_TRANSLATE_UTILS_H_ 
#define BACKENDS_VERIFY_TRANSLATE_UTILS_H_

#include "lib/cstring.h"
#include <cstdint>
#include <vector>

bool isNumber(std::string str);

bool isNumber(cstring str);

// xxx is same as (xxx_ + number), i.e., renaming
bool isSame(std::string s1, std::string s2);

bool isSame(cstring s1, cstring s2);

const cstring TEMP_PREFIX = "$tmp$";

const cstring SPLIT = "$";

const int EGRESS_SPEC_SIZE = 9;

class TempVariable{
public:
	static int cnt;
	static int getCnt();
	static cstring getPrefix();
	static cstring getPrefix(cstring prefix);
};

uint64_t mac2int(cstring mac_addr);
uint32_t ip2int(cstring ip);
cstring str2num(cstring str);

std::vector<std::string> split(const std::string& str, const std::string& delimiter);

// methods related to format with prefix, suffix, etc.
cstring get_emit_var_name(cstring header_name);
cstring struct_reset_method(cstring typeName);
cstring struct_assign_method(cstring typeName);

//
cstring getChannelName(cstring switchID, bool isEgress = false);
cstring getHeaderName(cstring switchID, bool isEgress = false);

#endif
