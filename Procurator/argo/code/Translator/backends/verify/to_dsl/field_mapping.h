#ifndef FieldMapping_H
#define FieldMapping_H

#include "ir/id.h"


// 用于生成P4 struct、header等的字段名称与最终promela里的名称映射
// 因为有时候会被重命名，比如 value_reg 变为 value_reg_0
class FieldMapping {
public:
    explicit FieldMapping() {};
    explicit FieldMapping(const std::string& output_path);

    void addVariableMapping(const IR::ID& id, const cstring& nameInPromela);
    void writeToFile();

private:
    // 输出文件的路径
    std::string output_path;

	std::unordered_map<cstring,cstring> variableMapping; // key:variableInP4, value:variableInPromela
};


#endif