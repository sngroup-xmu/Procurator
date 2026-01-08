#include "chan_extractor.h"
#include <fstream>
#include <iostream>

ChanExtractor::ChanExtractor(const std::string& json_output_path, const std::unordered_map<cstring, int> mp)
    : json_output_path(json_output_path), defMap(mp) {}

void ChanExtractor::generateJsonFile() const {
    json j;
    // 添加 headers 信息
    for (const auto& pair : headers_map) {
        json header_json;
        auto header = pair.second;
        header_json["name"] = header.name;
        for (const auto& field : header.fields) {
            json field_json;
            field_json["name"] = field.name;
            field_json["type"] = field.type;
            header_json["fields"].push_back(field_json);
        }
        j["headers"].push_back(header_json);
    }

    // 添加 header_instances 信息
    for (const auto& pair : instances_map) {
        json instance_json;
        auto instances = pair.second;
        for (auto instance : instances) {
            instance_json["name"] = instance.name;
            instance_json["type"] = instance.type;
            j["header_instances"].push_back(instance_json);
        }
    }

    // 写入 JSON 文件
    std::ofstream ofs(json_output_path);
    if (!ofs.is_open()) {
        std::cerr << "Failed to open JSON output file: " << json_output_path << std::endl;
        return;
    }
    ofs << j.dump(4); // 美化输出，缩进4个空格
    ofs.close();

    // std::cout << "Header information extracted to " << json_output_path << std::endl;
}

void ChanExtractor::addHeaderInstance(const std::string& headerTypeName, const std::string& fieldName) {
    // std::cout << "addHeaderInstance: " << headerTypeName << ", " << fieldName << std::endl;
    if (headers_map.find(headerTypeName) == headers_map.end()) {
        headers_map[headerTypeName] = {};
        headers_map[headerTypeName].name = headerTypeName;
    }
    if (fieldName != "") {
        HeaderInstance instance = {fieldName, headerTypeName};
        if (instances_map.find(headerTypeName) == instances_map.end()) {
            instances_map[headerTypeName] = std::vector<HeaderInstance>();
        }
        instances_map[headerTypeName].push_back(instance); // may have multiple instance with same type
    }
}

bool ChanExtractor::isHeader(const std::string& typeName) {
    return headers_map.find(typeName) != headers_map.end(); // struct, not header
}

void ChanExtractor::addFieldForHeader(const std::string& headerTypeName, const std::string& fieldType, const std::string& fieldName) {
    if (!isHeader(headerTypeName)) {
        return;
    }
    // std::cout << "addFieldForHeader: " << headerTypeName << ". " << fieldType << ", " << fieldName << std::endl;

    HeaderInfo& info = headers_map[headerTypeName];
    HeaderField field_info = {fieldName, fieldType};
    info.fields.push_back(field_info);
}