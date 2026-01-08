#pragma once

#include <map>
#include <sstream>
#include <string>
#include <utility>
#include <vector>

namespace nlohmann {

class json {
public:
    enum class Type { kNull, kBool, kNumber, kString, kObject, kArray };

    json() : type_(Type::kNull), bool_val_(false), num_val_(0) {}
    json(const char* s) : type_(Type::kString), str_val_(s ? s : "") {}
    json(const std::string& s) : type_(Type::kString), str_val_(s) {}
    json(int v) : type_(Type::kNumber), num_val_(static_cast<long long>(v)) {}
    json(long long v) : type_(Type::kNumber), num_val_(v) {}
    json(bool v) : type_(Type::kBool), bool_val_(v) {}

    static json array() {
        json j;
        j.type_ = Type::kArray;
        return j;
    }

    json& operator=(const std::string& s) {
        type_ = Type::kString;
        str_val_ = s;
        return *this;
    }
    json& operator=(const char* s) {
        type_ = Type::kString;
        str_val_ = s ? s : "";
        return *this;
    }
    json& operator=(int v) {
        type_ = Type::kNumber;
        num_val_ = static_cast<long long>(v);
        return *this;
    }
    json& operator=(long long v) {
        type_ = Type::kNumber;
        num_val_ = v;
        return *this;
    }
    json& operator=(bool v) {
        type_ = Type::kBool;
        bool_val_ = v;
        return *this;
    }
    json& operator=(const json& other) {
        if (this == &other) {
            return *this;
        }
        type_ = other.type_;
        bool_val_ = other.bool_val_;
        num_val_ = other.num_val_;
        str_val_ = other.str_val_;
        obj_val_ = other.obj_val_;
        arr_val_ = other.arr_val_;
        return *this;
    }

    json& operator[](const std::string& key) {
        if (type_ == Type::kNull) {
            type_ = Type::kObject;
        }
        if (type_ != Type::kObject) {
            // Overwrite to object to keep behavior permissive.
            type_ = Type::kObject;
            obj_val_.clear();
        }
        return obj_val_[key];
    }

    void push_back(const json& value) {
        ensureArray();
        arr_val_.push_back(value);
    }
    void push_back(const std::string& value) {
        ensureArray();
        arr_val_.push_back(json(value));
    }
    void push_back(const char* value) {
        ensureArray();
        arr_val_.push_back(json(value));
    }
    void push_back(int value) {
        ensureArray();
        arr_val_.push_back(json(value));
    }
    void push_back(long long value) {
        ensureArray();
        arr_val_.push_back(json(value));
    }
    void push_back(bool value) {
        ensureArray();
        arr_val_.push_back(json(value));
    }

    std::string dump(int indent = -1) const {
        std::ostringstream oss;
        dumpImpl(oss, indent, 0);
        return oss.str();
    }

private:
    void ensureArray() {
        if (type_ == Type::kNull) {
            type_ = Type::kArray;
        }
        if (type_ != Type::kArray) {
            type_ = Type::kArray;
            arr_val_.clear();
        }
    }

    static std::string escape(const std::string& in) {
        std::string out;
        out.reserve(in.size());
        for (char c : in) {
            switch (c) {
            case '\\': out += "\\\\"; break;
            case '"': out += "\\\""; break;
            case '\n': out += "\\n"; break;
            case '\r': out += "\\r"; break;
            case '\t': out += "\\t"; break;
            default: out += c; break;
            }
        }
        return out;
    }

    void indent(std::ostringstream& oss, int indent, int depth) const {
        if (indent <= 0) {
            return;
        }
        for (int i = 0; i < depth * indent; ++i) {
            oss << ' ';
        }
    }

    void dumpImpl(std::ostringstream& oss, int indent_width, int depth) const {
        switch (type_) {
        case Type::kNull:
            oss << "null";
            break;
        case Type::kBool:
            oss << (bool_val_ ? "true" : "false");
            break;
        case Type::kNumber:
            oss << num_val_;
            break;
        case Type::kString:
            oss << '"' << escape(str_val_) << '"';
            break;
        case Type::kArray: {
            oss << '[';
            if (!arr_val_.empty()) {
                bool pretty = indent_width > 0;
                if (pretty) {
                    oss << '\n';
                }
                for (size_t i = 0; i < arr_val_.size(); ++i) {
                    if (pretty) {
                        indent(oss, indent_width, depth + 1);
                    }
                    arr_val_[i].dumpImpl(oss, indent_width, depth + 1);
                    if (i + 1 < arr_val_.size()) {
                        oss << ',';
                    }
                    if (pretty) {
                        oss << '\n';
                    }
                }
                if (pretty) {
                    indent(oss, indent_width, depth);
                }
            }
            oss << ']';
            break;
        }
        case Type::kObject: {
            oss << '{';
            if (!obj_val_.empty()) {
                bool pretty = indent_width > 0;
                if (pretty) {
                    oss << '\n';
                }
                size_t idx = 0;
                for (const auto& kv : obj_val_) {
                    if (pretty) {
                        indent(oss, indent_width, depth + 1);
                    }
                    oss << '"' << escape(kv.first) << "\":";
                    if (pretty) {
                        oss << ' ';
                    }
                    kv.second.dumpImpl(oss, indent_width, depth + 1);
                    if (++idx < obj_val_.size()) {
                        oss << ',';
                    }
                    if (pretty) {
                        oss << '\n';
                    }
                }
                if (pretty) {
                    indent(oss, indent_width, depth);
                }
            }
            oss << '}';
            break;
        }
        }
    }

    Type type_;
    bool bool_val_;
    long long num_val_;
    std::string str_val_;
    std::map<std::string, json> obj_val_;
    std::vector<json> arr_val_;
};

}  // namespace nlohmann
