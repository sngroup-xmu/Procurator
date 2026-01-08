//
// Created by smy on 24-10-12.
//
#ifndef CHAN_EXTRACTOR_H
#define CHAN_EXTRACTOR_H

#include <string>
#include <vector>
#include <nlohmann/json.hpp>
#include "ir/ir.h" // 根据您的项目结构调整头文件路径

using json = nlohmann::json;

// 定义一个结构体来存储 header 字段信息
struct HeaderField {
    std::string name;
    std::string type;
};

// 定义一个结构体来存储 header 信息
struct HeaderInfo {
    std::string name;
    std::vector<HeaderField> fields;
};

struct HeaderInstance {
    std::string name;
    std::string type;
};

class ChanExtractor {
public:
    explicit ChanExtractor() {};
    // 构造函数，接受输出 JSON 文件的路径
    explicit ChanExtractor(const std::string& json_output_path, const std::unordered_map<cstring, int>);

    // // 提取 headers 信息并生成 JSON 文件
    // void extract(const IR::P4Program* program);

    // 
    void addHeaderInstance(const std::string& headerTypeName, const std::string& fieldName);
    bool isHeader(const std::string& typeName);
    void addFieldForHeader(const std::string& headerTypeName, const std::string& fieldType, const std::string& fieldName);

    // 生成 JSON 并写入文件
    void generateJsonFile() const;
private:
    // 存储提取的 headers 信息
    std::unordered_map<std::string, HeaderInfo> headers_map; // <header_type_name:HeaderInfo>
    std::unordered_map<std::string, std::vector<HeaderInstance>> instances_map; // <header_type_name:HeaderInstance>

    // 输出 JSON 文件的路径
    std::string json_output_path;
    std::unordered_map<cstring, int> defMap;
    // // 遍历并处理 Type_Header 节点
    // void processTypeHeader(const IR::Type_Header* typeHeader);

    // void processTypeStruct(const IR::Type_Struct *typeStruct);

};

#endif // CHAN_EXTRACTOR_H
