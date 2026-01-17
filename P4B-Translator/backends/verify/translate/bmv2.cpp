#include "bmv2.h"

BMV2CmdsAnalyzer::BMV2CmdsAnalyzer(std::ifstream* fin){
	std::string s;

	while(getline(*fin, s)){
		cstring label = BMV2Cmd::splitFirst(s);
		if(label == TABLE_ADD){
			// std::cout << BMV2Cmd::splitFirst(s) << std::endl;
			BMV2Cmd* cmd = new TableAdd(s);
			cmds.push_back(cmd);
		}
		else if(label == TABLE_DELETE){

		}
		else if(label == TABLE_SET_DEFAULT){
			BMV2Cmd* cmd = new TableSetDefault(s);
			cmds.push_back(cmd);
		}
		else if(label == REGISTER_WRITE){
			// std::cout << BMV2Cmd::splitFirst(s) << std::endl;
			BMV2Cmd* cmd = new RegisterWrite(s);
			cmds.push_back(cmd);
		}
		else{
			// std::cout << BMV2Cmd::splitFirst(s) << std::endl;
		}
		// std::cout << s << std::endl;
	}

	// std::cout << hasTableAddCmds() << std::endl;

	// char *line = NULL;
	// size_t len = 0;
	// ssize_t read;

	// while ((read = getline(&line, &len, fin)) != -1){
	// 	std::cout << s << std::endl;
	// 	BMV2Cmd* cmd;
	// 	printf("%s", line);
	// }
}

std::vector<TableAdd*> BMV2CmdsAnalyzer::getTableAddCmds(cstring table) const{
	std::vector<TableAdd*> res;
	for(auto cmd:cmds){
		if(cmd->cmdType == NAME_TABLE_ADD){
			TableAdd* tableAdd = (TableAdd*)cmd;
			if(isSame(table, tableAdd->table)){
				res.push_back(tableAdd);
			}
		}
	}
	return res;
}

bool BMV2CmdsAnalyzer::hasTableAddCmds(cstring table) const{
	for(auto cmd:cmds){
		if(cmd->cmdType == NAME_TABLE_ADD){
			TableAdd* tableAdd = (TableAdd*)cmd;
			if(isSame(table, tableAdd->table)){
				return true;
			}
		}
	}
	return false;
}

TableSetDefault* BMV2CmdsAnalyzer::getTableSetDefaultCmd(cstring table) const{
	for(auto cmd:cmds){
		if(cmd->cmdType == NAME_TABLE_SET_DEFAULT){
			TableSetDefault* tableSet = (TableSetDefault*)cmd;
			if(isSame(table, tableSet->table)){
				return tableSet;
			}
		}
	}
	return nullptr;
}

std::vector<cstring> BMV2Cmd::split(cstring str){
	return split(std::string(str.c_str()));
}

std::vector<cstring> BMV2Cmd::split(std::string str){
	std::vector<cstring> res;
	std::string::size_type idx1 = 0, idx2 = str.find(" ");

	auto trimToken = [](const std::string& token) -> std::string {
		size_t start = 0;
		while(start < token.size() && (token[start] == ' ' || token[start] == '\t' ||
				token[start] == '\r' || token[start] == '\n')){
			start++;
		}
		size_t end = token.size();
		while(end > start && (token[end - 1] == ' ' || token[end - 1] == '\t' ||
				token[end - 1] == '\r' || token[end - 1] == '\n')){
			end--;
		}
		return token.substr(start, end - start);
	};

	// remove space
	while(str[idx1]==' '){
		idx1++;
	}
	idx2 = str.find(" ", idx1);

	while(idx2 != std::string::npos){
		std::string token = trimToken(str.substr(idx1, idx2-idx1));
		if(!token.empty()){
			res.push_back(token);
		}
		// std::cout << "  push_back:  " << str.substr(idx1, idx2-idx1) << std::endl;
		idx1 = idx2+1;
		while(idx1 != str.length() && str[idx1]==' '){
			idx1++;
		}
		if(idx1 == str.length()){
			idx2 = std::string::npos;
		}
		else{
			idx2 = str.find(" ", idx1);
		}
	}

	if(idx1 < str.length()){
		std::string token = trimToken(str.substr(idx1));
		if(!token.empty()){
			res.push_back(token);
		}
		// std::cout << "  push_back_rest:  " << str.substr(idx1) << std::endl;
	}

	return res;
}

cstring BMV2Cmd::splitFirst(std::string str){
	std::string::size_type idx1 = 0, idx2 = str.find(" ");
	while(str[idx1]==' '){
		idx1++;
	}
	idx2 = str.find(" ", idx1);
	return str.substr(idx1, idx2-idx1);
}

cstring BMV2Cmd::getName(std::string str){
	std::string::size_type idx = str.find(".");
	return str.substr(idx+1);
}

BMV2Cmd::BMV2Cmd(){}

BMV2Cmd::BMV2Cmd(cstring _cont){
	cont = _cont;
	cmdType = NAME_BMV2_CMD;
}

TableAdd::TableAdd(cstring _cont){
	cont = _cont;
	cmdType = NAME_TABLE_ADD;
	std::vector<cstring> vec = split(_cont);
	table = getName(vec[1].c_str());
	action = getName(vec[2].c_str());

	int idx = 3;
	while(idx < static_cast<int>(vec.size()) && vec[idx] != TABLE_MATCH_SYMBOL) idx++;

	if(idx >= static_cast<int>(vec.size())){
		std::cerr << "ERROR_INFO: " << cont << std::endl;
		throw "ERROR: Illegal table_add command!!!\nUsage: table_add <table name> <action name> <match fields> => <action parameters> [priority]";
	}

	// std::cout << "  fields:" << std::endl;
	for(int i = 3; i < idx; i++){
		fields.push_back(vec[i]);
		// std::cout << "    " << vec[i] << std::endl;
	}

	// std::cout << "  parameters:" << std::endl;
	int size = vec.size();
	for(int i = idx+1; i < size; i++){
		parameters.push_back(vec[i]);
		// std::cout << "    " << vec[i] << std::endl;
	}

	// std::cout << table << std::endl;
	// std::cout << action << std::endl;
}

TableDelete::TableDelete(cstring _cont){
	cont = _cont;
	cmdType = NAME_TABLE_DELETE;
	std::vector<cstring> vec = split(_cont);
}

TableSetDefault::TableSetDefault(cstring _cont){
	cont = _cont;
	cmdType = NAME_TABLE_SET_DEFAULT;
	std::vector<cstring> vec = split(_cont);
	if(vec.size() < 3){
		std::cerr << "ERROR_INFO: " << cont << std::endl;
		throw "ERROR: Illegal table_set_default command!!!\nUsage: table_set_default <table name> <action name> <action parameters>";
	}
	table = getName(vec[1].c_str());
	action = getName(vec[2].c_str());
	for(size_t i = 3; i < vec.size(); i++){
		parameters.push_back(vec[i]);
	}
}

RegisterWrite::RegisterWrite(cstring _cont){
	cont = _cont;
	cmdType = NAME_REGISTER_WRITE;
	std::vector<cstring> vec = split(_cont);
	if(vec.size() != 4){
        std::cerr << "ERROR_INFO: " << cont << std::endl;
		throw "ERROR: Illegal register_write command!!!\nUsage: register_write <name> <index> <value>";
	}
	reg = getName(vec[1].c_str());
	index = vec[2];
	value = vec[3];
}

static cstring formatLiteral(cstring raw, int width) {
	cstring num = str2num(raw);
	if (width > 0) {
		return num + "bv" + cstring::to_cstring(width);
	}
	return num;
}

cstring TableAdd::getCondition(const std::vector<cstring>& keys, const std::vector<int>& keyWidths) {
	if (keys.size() != fields.size()) {
		return "";
	}

	cstring condition = "";

	for (size_t i = 0; i < fields.size(); ++i) {
		cstring field_value = fields[i];
		std::string field_str = field_value.c_str();
		cstring key = keys[i];
		int width = -1;
		if (i < keyWidths.size()) {
			width = keyWidths[i];
		}

		if (field_value == "*" || field_value == "?") {
			continue;
		}

		if (condition != "") {
			condition += " && ";
		}

			if (field_str.find("/") != std::string::npos) { // lpm
				std::string::size_type idx = field_str.find("/");
				cstring ip = formatLiteral(field_value.substr(0, idx), width > 0 ? width : 32);
				int bits = std::stoi(field_value.substr(idx + 1).c_str());
				int maskWidth = (width > 0 ? width : 32);
			uint64_t mask = 0;
			if (bits > 0) {
				if (bits >= maskWidth && maskWidth < 64) {
					mask = (maskWidth == 64) ? ~0ULL : ((1ULL << maskWidth) - 1ULL);
				} else if (maskWidth < 64) {
					mask = ((1ULL << bits) - 1ULL) << (maskWidth - bits);
				} else {
					mask = ~0ULL;
				}
				}
				cstring maskLit = formatLiteral(cstring::to_cstring(mask), maskWidth);
				condition += "band.bv" + cstring::to_cstring(maskWidth) + "(" + key + ", " + maskLit + ") == " + ip;
			} else if (field_str.find("&&&") != std::string::npos) { // ternary
				std::string::size_type idx = field_str.find("&&&");
				int maskWidth = (width > 0 ? width : 32);
				cstring value = formatLiteral(field_value.substr(0, idx), maskWidth);
				cstring mask = formatLiteral(field_value.substr(idx + 3), maskWidth);
				cstring bandFun = "band.bv" + cstring::to_cstring(maskWidth);
				condition += bandFun + "(" + key + ", " + mask + ") == " + bandFun + "(" + value + ", " + mask + ")";
			} else if (field_str.find("->") != std::string::npos) { // range
				std::string::size_type idx = field_str.find("->");
				int rangeWidth = (width > 0 ? width : 32);
				cstring min = formatLiteral(field_value.substr(0, idx), rangeWidth);
				cstring max = formatLiteral(field_value.substr(idx + 2), rangeWidth);
				cstring bugeFun = "buge.bv" + cstring::to_cstring(rangeWidth);
				cstring buleFun = "bule.bv" + cstring::to_cstring(rangeWidth);
				condition += "(" + bugeFun + "(" + key + ", " + min + ")) && (" + buleFun + "(" + key + ", " + max + "))";
			} else { // exact
				cstring value = formatLiteral(field_value, width);
				condition += key + " == " + value;
			}
	}

	if (condition == "") {
		return "true";
	}
	return condition;
}
