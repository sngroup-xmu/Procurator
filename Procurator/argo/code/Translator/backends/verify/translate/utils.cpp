#include "utils.h"
#include <arpa/inet.h>

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
	else if(s1.find(s2) != nullptr){
		std::string s = s1.c_str();
    	std::string::size_type idx = s.find((s2+"_").c_str()) + 
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


uint64_t mac2int(cstring mac_addr) {
	unsigned u[6];
	int c=sscanf(mac_addr.c_str(),"%x:%x:%x:%x:%x:%x",u,u+1,u+2,u+3,u+4,u+5);
	if (c!=6) return 0;
	uint64_t r=0;
	for (int i=0;i<6;i++) r=(r<<8)+u[i];
	return r;
}

uint32_t ip2int(cstring ip) {
	unsigned u[5];
	int c=sscanf(ip.c_str(),"%d.%d.%d.%d",u,u+1,u+2,u+3);
	if (c!=4) return 0;
	uint32_t r=0;
	for (int i=0;i<4;i++) r=(r<<8)+u[i];
	return r;
}

cstring str2num(cstring str) {
	if (str.find(".")) {
		return cstring::to_cstring(ip2int(str));
	}

	if (str.startsWith("0x")) {
		return cstring::to_cstring(strtol(str.c_str(), 0, 16));
	}

	if (str.find(":")) {
		return cstring::to_cstring(mac2int(str));
	}

	return str;
}

std::vector<std::string> split(const std::string& str, const std::string& delimiter) {
    std::vector<std::string> tokens;
    std::string token;
    std::istringstream tokenStream(str);
    while (std::getline(tokenStream, token, delimiter[0])) {
        if (token != delimiter) {
            tokens.push_back(token);
        }
    }
    return tokens;
}



// methods related to format with prefix, suffix, etc.
cstring get_emit_var_name(cstring header_name) {
    return "emit_" + header_name;
}

cstring struct_reset_method(cstring typeName) {
    return "reset_struct_" + typeName;
}

cstring struct_assign_method(cstring typeName) {
    return "assign_struct_" + typeName;
}


cstring getChannelName(cstring switchID, bool isEgress) {
	return switchID + "_chan" + (isEgress ? "_eg" : "");
}

cstring getHeaderName(cstring switchID, bool isEgress) {
	//return switchID + "_hdr" + (isEgress ? "_eg" : ""); 
	return switchID + "_hdr";
}