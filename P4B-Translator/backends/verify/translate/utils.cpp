#include "utils.h"

#include <cstdio>
#include <cstdlib>

bool isNumber(std::string str){
	int size = str.size();
	for(int i = 0; i < size; i++){
		if(!('0' <= str[i] && str[i] <= '9')){
			return false;
		}
	}
	return true;
}

bool isNumber(cstring str){
	return isNumber(std::string(str.c_str()));
}

bool isSame(std::string s1, std::string s2){
	if(s1.size() < s2.size()){
		cstring tmp = s1;
		s1 = s2;
		s2 = tmp;
	}

	if(s1 == s2){
		return true;
	}
	else if(s1.find(s2) != std::string::npos){
		std::string::size_type idx = s1.find(s2+"_") + s2.size() + 1;
		if(isNumber(s1.substr(idx)))
			return true;
	}
	return false;
}

bool isSame(cstring s1, cstring s2){
	if(s1.size() < s2.size()){
		cstring tmp = s1;
		s1 = s2;
		s2 = tmp;
	}
	if(s1 == s2){
		return true;
	}
	else {
		std::string s = s1.c_str();
		std::string t = s2.c_str();
		if(s.find(t) == std::string::npos){
			return false;
		}
    	std::string::size_type idx = s.find((t+"_").c_str()) + 
    		    						s2.size()+1;
		if(isNumber(s.substr(idx))){
			return true;
		}
	}
	return false;
}

int TempVariable::cnt = 0;

int TempVariable::getCnt(){
	return cnt++;
}

cstring TempVariable::getPrefix(){
	std::stringstream ss;
    ss << getCnt();
    return TEMP_PREFIX+ss.str();
}

cstring TempVariable::getPrefix(cstring prefix){
	std::stringstream ss;
    ss << getCnt();
    return prefix+ss.str();
}

std::vector<std::string> split(const std::string& str, const std::string& delimiter) {
	std::vector<std::string> parts;
	if (delimiter.empty()) {
		parts.push_back(str);
		return parts;
	}
	size_t start = 0;
	while (start <= str.size()) {
		size_t pos = str.find(delimiter, start);
		if (pos == std::string::npos) {
			pos = str.size();
		}
		parts.push_back(str.substr(start, pos - start));
		start = pos + delimiter.size();
	}
	return parts;
}

uint64_t mac2int(cstring mac_addr) {
	unsigned u[6];
	int c = sscanf(mac_addr.c_str(), "%x:%x:%x:%x:%x:%x", u, u + 1, u + 2, u + 3, u + 4, u + 5);
	if (c != 6) {
		return 0;
	}
	uint64_t r = 0;
	for (int i = 0; i < 6; i++) {
		r = (r << 8) + u[i];
	}
	return r;
}

uint32_t ip2int(cstring ip) {
	unsigned u[4];
	int c = sscanf(ip.c_str(), "%u.%u.%u.%u", u, u + 1, u + 2, u + 3);
	if (c != 4) {
		return 0;
	}
	uint32_t r = 0;
	for (int i = 0; i < 4; i++) {
		r = (r << 8) + u[i];
	}
	return r;
}

cstring str2num(cstring str) {
	if (str == nullptr) {
		return str;
	}
	std::string s = str.c_str();
	if (s.find('.') != std::string::npos) {
		return cstring::to_cstring(ip2int(str));
	}
	if (s.find(':') != std::string::npos) {
		return cstring::to_cstring(mac2int(str));
	}
	if (s.rfind("0x", 0) == 0 || s.rfind("0X", 0) == 0) {
		return cstring::to_cstring(strtoull(s.c_str(), nullptr, 16));
	}
	if (s.rfind("0b", 0) == 0 || s.rfind("0B", 0) == 0) {
		return cstring::to_cstring(strtoull(s.c_str() + 2, nullptr, 2));
	}
	return str;
}
