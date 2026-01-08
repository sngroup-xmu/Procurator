#include "field_mapping.h"
#include <fstream>
#include <iostream>


FieldMapping::FieldMapping(const std::string& output_path) : output_path(output_path) {}


void FieldMapping::addVariableMapping(const IR::ID& id, const cstring& nameInPromela) {
    if (id.originalName == nullptr)
        return;
    variableMapping[id.originalName] = nameInPromela;
}


void FieldMapping::writeToFile() {
    std::ofstream ofs(output_path);
    if (!ofs.is_open()) {
        std::cerr << "Failed to open file: " << output_path << std::endl;
        return;
    }
    for (auto iter : variableMapping) {
        ofs << iter.first << ":" << iter.second << "\n";
    }
    ofs.close();
}