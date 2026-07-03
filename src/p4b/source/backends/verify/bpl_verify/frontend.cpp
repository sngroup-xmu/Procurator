// Frontend loading and normalization for the verify backend.
#include "backends/verify/bpl_verify/frontend.h"

#include <cctype>
#include <cerrno>
#include <fstream>
#include <iostream>
#include <map>
#include <regex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/constantFolding.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/createBuiltins.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/simplifyDefUse.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "ir/json_loader.h"
#include "ir/json_parser.h"
#include "ir/pass_manager.h"
#include "lib/error.h"
#include "midend/local_copyprop.h"

namespace P4Verify {
namespace {

void inferJsonInput(P4VerifyOptions& options) {
    if (!options.loadIRFromJson && P4VerifyCompat::hasPath(options.file)) {
        const std::string inputPath = P4VerifyCompat::pathToString(options.file);
        if (inputPath.size() >= 5 && inputPath.rfind(".json") == inputPath.size() - 5) {
            options.loadIRFromJson = true;
        }
    }
}

bool readTextFile(const std::string& path, std::string* out) {
    std::ifstream in(path);
    if (!in) {
        return false;
    }
    std::ostringstream buf;
    buf << in.rdbuf();
    *out = buf.str();
    return true;
}

bool fileExists(const std::string& path) {
    struct stat st {};
    return stat(path.c_str(), &st) == 0;
}

std::string dirnameOf(const std::string& path) {
    const auto slash = path.find_last_of("/\\");
    if (slash == std::string::npos) {
        return ".";
    }
    return path.substr(0, slash);
}

std::string basenameOf(const std::string& path) {
    const auto slash = path.find_last_of("/\\");
    if (slash == std::string::npos) {
        return path;
    }
    return path.substr(slash + 1);
}

std::string joinPath(const std::string& dir, const std::string& name) {
    if (dir.empty() || dir == ".") {
        return name;
    }
    return dir + "/" + name;
}

std::string normalizeSlashes(std::string path) {
    for (char& ch : path) {
        if (ch == '\\') {
            ch = '/';
        }
    }
    return path;
}

bool ensureDir(const std::string& path) {
    if (path.empty() || path == ".") {
        return true;
    }
    std::string cur;
    size_t pos = 0;
    if (!path.empty() && path[0] == '/') {
        cur = "/";
        pos = 1;
    }
    while (pos <= path.size()) {
        const size_t next = path.find('/', pos);
        const std::string part = path.substr(pos, next == std::string::npos ? std::string::npos : next - pos);
        if (!part.empty()) {
            if (!cur.empty() && cur.back() != '/') {
                cur += "/";
            }
            cur += part;
            if (mkdir(cur.c_str(), 0700) != 0 && errno != EEXIST) {
                return false;
            }
        }
        if (next == std::string::npos) {
            break;
        }
        pos = next + 1;
    }
    return true;
}

bool writeTextFile(const std::string& path, const std::string& content) {
    if (!ensureDir(dirnameOf(path))) {
        return false;
    }
    std::ofstream out(path);
    if (!out) {
        return false;
    }
    out << content;
    return true;
}

std::string makeSanitizerRoot() {
    std::string tmplStr = "/tmp/p4b_sanitized_XXXXXX";
    std::vector<char> tmpl(tmplStr.begin(), tmplStr.end());
    tmpl.push_back('\0');
    char* made = mkdtemp(tmpl.data());
    if (made == nullptr) {
        return "";
    }
    return std::string(made);
}

int braceDelta(const std::string& line) {
    int delta = 0;
    for (char ch : line) {
        if (ch == '{') {
            delta++;
        } else if (ch == '}') {
            delta--;
        }
    }
    return delta;
}

std::string trimRightAscii(std::string line) {
    while (!line.empty() && std::isspace(static_cast<unsigned char>(line.back()))) {
        line.pop_back();
    }
    return line;
}

bool lineStartsApplyBlock(const std::string& line, std::string* indent) {
    size_t i = 0;
    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (line.compare(i, 5, "apply") != 0) {
        return false;
    }
    const size_t afterApply = i + 5;
    if (afterApply < line.size() &&
        (std::isalnum(static_cast<unsigned char>(line[afterApply])) || line[afterApply] == '_')) {
        return false;
    }
    size_t j = afterApply;
    while (j < line.size() && (line[j] == ' ' || line[j] == '\t')) {
        j++;
    }
    if (j >= line.size() || line[j] != '{') {
        return false;
    }
    *indent = line.substr(0, i);
    return true;
}

bool parseApplyLocalInstantiationLine(const std::string& line,
                                      const std::string& hoistIndent,
                                      std::string* hoistedDecl,
                                      std::string* outTypeName = nullptr,
                                      std::string* outInstanceName = nullptr) {
    size_t i = 0;
    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (i >= line.size() || !std::isupper(static_cast<unsigned char>(line[i]))) {
        return false;
    }

    const size_t typeStart = i;
    int angleDepth = 0;
    while (i < line.size()) {
        const char ch = line[i];
        if (ch == '<') {
            angleDepth++;
        } else if (ch == '>' && angleDepth > 0) {
            angleDepth--;
        } else if ((ch == ' ' || ch == '\t') && angleDepth == 0) {
            break;
        } else if (ch == ';' || ch == '{' || ch == '}') {
            return false;
        }
        i++;
    }
    if (i == typeStart || angleDepth != 0) {
        return false;
    }
    const std::string typeName = line.substr(typeStart, i - typeStart);

    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (i >= line.size() || !(std::isalpha(static_cast<unsigned char>(line[i])) || line[i] == '_')) {
        return false;
    }
    const size_t nameStart = i;
    i++;
    while (i < line.size() &&
           (std::isalnum(static_cast<unsigned char>(line[i])) || line[i] == '_')) {
        i++;
    }
    const std::string instanceName = line.substr(nameStart, i - nameStart);

    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (i >= line.size() || line[i] != '(') {
        return false;
    }
    const size_t argsStart = i + 1;
    int parenDepth = 1;
    i++;
    while (i < line.size() && parenDepth > 0) {
        if (line[i] == '(') {
            parenDepth++;
        } else if (line[i] == ')') {
            parenDepth--;
        }
        i++;
    }
    if (parenDepth != 0) {
        return false;
    }
    const std::string args = line.substr(argsStart, i - argsStart - 1);
    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (i >= line.size() || line[i] != ';') {
        return false;
    }
    const std::string suffix = line.substr(i + 1);
    *hoistedDecl = hoistIndent + typeName + "(" + args + ") " + instanceName + ";" + suffix;
    if (outTypeName != nullptr) {
        *outTypeName = typeName;
    }
    if (outInstanceName != nullptr) {
        *outInstanceName = instanceName;
    }
    return true;
}

std::unordered_map<std::string, std::string> collectSingleParameterControlTypes(const std::string& content) {
    std::unordered_map<std::string, std::string> out;
    size_t pos = 0;
    while ((pos = content.find("control", pos)) != std::string::npos) {
        const bool beforeOk =
            pos == 0 || !(std::isalnum(static_cast<unsigned char>(content[pos - 1])) || content[pos - 1] == '_');
        size_t i = pos + 7;
        const bool afterOk =
            i >= content.size() ||
            !(std::isalnum(static_cast<unsigned char>(content[i])) || content[i] == '_');
        if (!beforeOk || !afterOk) {
            pos = i;
            continue;
        }
        while (i < content.size() && std::isspace(static_cast<unsigned char>(content[i]))) {
            i++;
        }
        if (i >= content.size() ||
            !(std::isupper(static_cast<unsigned char>(content[i])) || content[i] == '_')) {
            pos = i;
            continue;
        }
        const size_t nameStart = i;
        i++;
        while (i < content.size() &&
               (std::isalnum(static_cast<unsigned char>(content[i])) || content[i] == '_')) {
            i++;
        }
        const std::string controlName = content.substr(nameStart, i - nameStart);
        while (i < content.size() && std::isspace(static_cast<unsigned char>(content[i]))) {
            i++;
        }
        if (i >= content.size() || content[i] != '(') {
            pos = i;
            continue;
        }
        const size_t paramsStart = i + 1;
        int parenDepth = 1;
        i++;
        while (i < content.size() && parenDepth > 0) {
            if (content[i] == '(') {
                parenDepth++;
            } else if (content[i] == ')') {
                parenDepth--;
            }
            i++;
        }
        if (parenDepth != 0) {
            break;
        }
        const std::string params = content.substr(paramsStart, i - paramsStart - 1);
        if (params.find(',') == std::string::npos) {
            std::stringstream ss(params);
            std::vector<std::string> parts;
            std::string part;
            while (ss >> part) {
                parts.push_back(part);
            }
            if (parts.size() == 3 &&
                (parts[0] == "in" || parts[0] == "out" || parts[0] == "inout")) {
                out[controlName] = parts[1];
            }
        }
        pos = i;
    }
    return out;
}

bool rewriteApplyLocalInstantiations(const std::string& content, std::string* out) {
    std::stringstream in(content);
    std::ostringstream rewritten;
    std::vector<std::string> applyBuffer;
    std::vector<std::string> hoistedDecls;
    std::unordered_map<std::string, std::string> applyArgByInstance;
    const auto singleParamControls = collectSingleParameterControlTypes(content);
    std::string applyIndent;
    std::string line;
    bool inApply = false;
    int applyDepth = 0;
    bool changed = false;

    while (std::getline(in, line)) {
        if (!inApply) {
            if (lineStartsApplyBlock(line, &applyIndent)) {
                inApply = true;
                applyDepth = braceDelta(line);
                applyBuffer.clear();
                hoistedDecls.clear();
                applyBuffer.push_back(line);
                if (applyDepth == 0) {
                    rewritten << line << "\n";
                    inApply = false;
                }
                continue;
            }
            rewritten << line << "\n";
            continue;
        }

        std::string hoistedDecl;
        std::string typeName;
        std::string instanceName;
        if (parseApplyLocalInstantiationLine(line, applyIndent, &hoistedDecl, &typeName, &instanceName)) {
            auto it = singleParamControls.find(typeName);
            if (it != singleParamControls.end()) {
                std::string argName = "p4b_auto_" + instanceName + "_arg";
                hoistedDecls.push_back(applyIndent + it->second + " " + argName + ";");
                applyArgByInstance[instanceName] = argName;
            }
            hoistedDecls.push_back(hoistedDecl);
            changed = true;
        } else {
            for (const auto& kv : applyArgByInstance) {
                const std::regex emptyApply(
                    R"(\b)" + kv.first + R"(\s*\.\s*apply\s*\(\s*\))");
                line = std::regex_replace(line, emptyApply, kv.first + ".apply(" + kv.second + ")");
            }
            applyBuffer.push_back(line);
        }

        applyDepth += braceDelta(line);
        if (applyDepth <= 0) {
            for (const auto& decl : hoistedDecls) {
                rewritten << decl << "\n";
            }
            for (const auto& buffered : applyBuffer) {
                rewritten << buffered << "\n";
            }
            inApply = false;
        }
    }

    if (inApply) {
        for (const auto& buffered : applyBuffer) {
            rewritten << buffered << "\n";
        }
    }

    *out = changed ? rewritten.str() : content;
    return changed;
}

bool rewriteEnumAssignmentsFromBitTemps(const std::string& content, std::string* out) {
    static const std::regex enumDecl(R"(^\s*enum\s+bit\s*<\s*[0-9]+\s*>\s+([A-Za-z_][A-Za-z0-9_]*)\s*\{.*$)");
    static const std::regex bitVar(R"(^\s*bit\s*<\s*[0-9]+\s*>\s+([A-Za-z_][A-Za-z0-9_]*)\s*;\s*$)");
    static const std::regex assignment(
        R"(^(\s*)([A-Za-z_][A-Za-z0-9_.]*)\s*=\s*([A-Za-z_][A-Za-z0-9_]*)\s*;(.*)$)");

    std::unordered_map<std::string, std::string> fieldTypes;
    std::unordered_set<std::string> enumFieldNames;
    std::vector<std::string> enumTypes;
    std::stringstream declScan(content);
    std::string line;
    while (std::getline(declScan, line)) {
        const std::string matchLine = trimRightAscii(line);
        std::smatch m;
        if (std::regex_match(matchLine, m, enumDecl)) {
            enumTypes.push_back(m[1].str());
            continue;
        }

        std::string scrubbed = matchLine;
        const auto comment = scrubbed.find("//");
        if (comment != std::string::npos) {
            scrubbed = scrubbed.substr(0, comment);
        }
        std::stringstream fieldStream(scrubbed);
        std::string type;
        std::string fieldName;
        std::string extra;
        if (!(fieldStream >> type >> fieldName)) {
            continue;
        }
        if (fieldStream >> extra) {
            continue;
        }
        if (fieldName.empty() || fieldName.back() != ';') {
            continue;
        }
        fieldName.pop_back();
        for (const auto& enumType : enumTypes) {
            if (type != enumType) {
                continue;
            }
            fieldTypes[fieldName] = type;
            enumFieldNames.insert(fieldName);
            const auto dot = fieldName.find_last_of('.');
            if (dot != std::string::npos) {
                const std::string shortName = fieldName.substr(dot + 1);
                fieldTypes[shortName] = type;
                enumFieldNames.insert(shortName);
            }
            break;
        }
    }
    if (fieldTypes.empty()) {
        *out = content;
        return false;
    }

    std::unordered_map<std::string, std::string> bitTemps;
    std::stringstream in(content);
    std::ostringstream rewritten;
    bool changed = false;
    while (std::getline(in, line)) {
        const std::string matchLine = trimRightAscii(line);
        std::smatch m;
        if (std::regex_match(matchLine, m, bitVar)) {
            bitTemps[m[1].str()] = m[1].str();
            rewritten << line << "\n";
            continue;
        }
        if (std::regex_match(matchLine, m, assignment)) {
            const std::string lhs = m[2].str();
            const std::string rhs = m[3].str();
            auto fieldIt = fieldTypes.find(lhs);
            if (fieldIt == fieldTypes.end()) {
                const auto dot = lhs.find_last_of('.');
                if (dot != std::string::npos) {
                    fieldIt = fieldTypes.find(lhs.substr(dot + 1));
                }
            }
            if (fieldIt == fieldTypes.end()) {
                const auto dot = lhs.find_last_of('.');
                const std::string shortName = dot == std::string::npos ? lhs : lhs.substr(dot + 1);
                if (enumFieldNames.find(shortName) != enumFieldNames.end() && !enumTypes.empty()) {
                    fieldTypes[shortName] = enumTypes.front();
                    fieldIt = fieldTypes.find(shortName);
                }
            }
            if (fieldIt == fieldTypes.end() && lhs.find('.') != std::string::npos &&
                enumTypes.size() == 1 && bitTemps.find(rhs) != bitTemps.end()) {
                const auto dot = lhs.find_last_of('.');
                const std::string shortName = lhs.substr(dot + 1);
                fieldTypes[shortName] = enumTypes.front();
                fieldIt = fieldTypes.find(shortName);
            }
            if (fieldIt != fieldTypes.end() && bitTemps.find(rhs) != bitTemps.end()) {
                rewritten << m[1].str() << lhs << " = (" << fieldIt->second << ")" << rhs << ";"
                          << m[4].str() << "\n";
                changed = true;
                continue;
            }
        }
        rewritten << line << "\n";
    }
    *out = changed ? rewritten.str() : content;
    return changed;
}

bool needsApplyLocalInstantiationRewriteInClosure(const std::string& content) {
    std::string ignored;
    return rewriteApplyLocalInstantiations(content, &ignored);
}

bool rewriteCtorStyleLocalInstantiations(const std::string& content, std::string* out) {
    return rewriteApplyLocalInstantiations(content, out);
}

bool needsVerifyFrontendRewrite(const std::string& content) {
    if (content.find("@assert") != std::string::npos || content.find("@assume") != std::string::npos) {
        return true;
    }
    return needsApplyLocalInstantiationRewriteInClosure(content);
}

bool sanitizeP4TvContent(const std::string& content, std::string* sanitizedOut) {
    const bool hasAssert = content.find("@assert") != std::string::npos;
    const bool hasAssume = content.find("@assume") != std::string::npos;

    // p4tv-style annotations use a non-standard syntax:
    //   @assert[COND] {}
    //   @assume[COND] {}
    //
    // P4C does not parse the bracket form.  Convert it into extern calls that
    // are both parseable and preserved by frontend simplification.
    std::string sanitized = content;
    bool needsExterns = false;
    if (hasAssert) {
        sanitized = std::regex_replace(
            sanitized, std::regex(R"(@assert\s*\[([^\]]*)\])"), "@p4b_assert($1)");
    }
    if (hasAssume) {
        sanitized = std::regex_replace(
            sanitized, std::regex(R"(@assume\s*\[([^\]]*)\])"), "@p4b_assume($1)");
    }

    const std::string before = sanitized;
    sanitized = std::regex_replace(
        sanitized,
        std::regex(R"(@p4b_assert\s*\(\s*([^\)]*)\s*\)\s*\{\s*\})"),
        "p4b_assert($1);");
    sanitized = std::regex_replace(
        sanitized,
        std::regex(R"(@p4b_assume\s*\(\s*([^\)]*)\s*\)\s*\{\s*\})"),
        "p4b_assume($1);");
    if (sanitized != before) {
        needsExterns = true;
    }

    if (needsExterns &&
        sanitized.find("extern void p4b_assert") == std::string::npos &&
        sanitized.find("extern void p4b_assume") == std::string::npos) {
        const std::string decls =
            "extern void p4b_assert(in bool cond);\n"
            "extern void p4b_assume(in bool cond);\n\n";

        size_t insertPos = 0;
        size_t scanPos = 0;
        while (scanPos < sanitized.size()) {
            const size_t lineEnd = sanitized.find('\n', scanPos);
            const size_t end = (lineEnd == std::string::npos) ? sanitized.size() : lineEnd;
            size_t i = scanPos;
            while (i < end && (sanitized[i] == ' ' || sanitized[i] == '\t')) {
                i++;
            }
            if (end - i >= 8 && sanitized.compare(i, 8, "#include") == 0) {
                scanPos = (lineEnd == std::string::npos) ? sanitized.size() : (lineEnd + 1);
                insertPos = scanPos;
                continue;
            }
            break;
        }
        sanitized.insert(insertPos, decls);
    }

    std::string ctorRewritten;
    if (rewriteCtorStyleLocalInstantiations(sanitized, &ctorRewritten)) {
        sanitized = ctorRewritten;
    }
    std::string enumRewritten;
    if (rewriteEnumAssignmentsFromBitTemps(sanitized, &enumRewritten)) {
        sanitized = enumRewritten;
    }

    *sanitizedOut = sanitized;
    return sanitized != content;
}

bool parseQuotedIncludeLine(const std::string& line,
                            std::string* prefix,
                            std::string* includeName,
                            std::string* suffix) {
    size_t i = 0;
    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (i >= line.size() || line[i] != '#') {
        return false;
    }
    const size_t includePos = line.find("include", i + 1);
    if (includePos == std::string::npos) {
        return false;
    }
    const size_t firstQuote = line.find('"', includePos + 7);
    if (firstQuote == std::string::npos) {
        return false;
    }
    const size_t secondQuote = line.find('"', firstQuote + 1);
    if (secondQuote == std::string::npos) {
        return false;
    }
    *prefix = line.substr(0, firstQuote + 1);
    *includeName = line.substr(firstQuote + 1, secondQuote - firstQuote - 1);
    *suffix = line.substr(secondQuote);
    return true;
}

bool parseAngledIncludeLine(const std::string& line, std::string* includeName) {
    size_t i = 0;
    while (i < line.size() && (line[i] == ' ' || line[i] == '\t')) {
        i++;
    }
    if (i >= line.size() || line[i] != '#') {
        return false;
    }
    const size_t includePos = line.find("include", i + 1);
    if (includePos == std::string::npos) {
        return false;
    }
    const size_t first = line.find('<', includePos + 7);
    if (first == std::string::npos) {
        return false;
    }
    const size_t second = line.find('>', first + 1);
    if (second == std::string::npos) {
        return false;
    }
    *includeName = line.substr(first + 1, second - first - 1);
    return true;
}

bool sanitizeP4TvTree(const std::string& inputPath,
                      const std::string& outRoot,
                      std::map<std::string, std::string>* rewritten,
                      std::string* outPath,
                      bool* changedAny) {
    auto it = rewritten->find(inputPath);
    if (it != rewritten->end()) {
        *outPath = it->second;
        return true;
    }

    std::string content;
    if (!readTextFile(inputPath, &content)) {
        return false;
    }

    std::string sanitized;
    bool changed = sanitizeP4TvContent(content, &sanitized);
    const std::string inputDir = dirnameOf(inputPath);
    const std::string outDir = joinPath(outRoot, rewritten->empty() ? "." : basenameOf(inputDir));
    const std::string targetPath = joinPath(outDir, basenameOf(inputPath));
    (*rewritten)[inputPath] = targetPath;

    std::stringstream in(sanitized);
    std::ostringstream out;
    std::string line;
    while (std::getline(in, line)) {
        std::string prefix;
        std::string includeName;
        std::string suffix;
        if (parseQuotedIncludeLine(line, &prefix, &includeName, &suffix)) {
            const std::string includePath = joinPath(inputDir, includeName);
            std::string rewrittenInclude;
            if (sanitizeP4TvTree(includePath, outRoot, rewritten, &rewrittenInclude, changedAny)) {
                const std::string relName = basenameOf(dirnameOf(rewrittenInclude)) + "/" + basenameOf(rewrittenInclude);
                out << prefix << relName << suffix << "\n";
                changed = true;
                continue;
            }
        }
        out << line << "\n";
    }
    sanitized = out.str();

    if (!writeTextFile(targetPath, sanitized)) {
        return false;
    }
    if (changed) {
        *changedAny = true;
    }
    *outPath = targetPath;
    return true;
}

bool verifyFrontendRewriteInClosure(const std::string& inputPath, std::map<std::string, bool>* seen) {
    if (seen->find(inputPath) != seen->end()) {
        return false;
    }
    (*seen)[inputPath] = true;
    std::string content;
    if (!readTextFile(inputPath, &content)) {
        return false;
    }
    if (needsVerifyFrontendRewrite(content)) {
        return true;
    }
    const std::string inputDir = dirnameOf(inputPath);
    std::stringstream in(content);
    std::string line;
    while (std::getline(in, line)) {
        std::string prefix;
        std::string includeName;
        std::string suffix;
        if (!parseQuotedIncludeLine(line, &prefix, &includeName, &suffix)) {
            continue;
        }
        if (verifyFrontendRewriteInClosure(joinPath(inputDir, includeName), seen)) {
            return true;
        }
    }
    return false;
}

bool pathNeedsFrontendRewrite(const std::string& path) {
    return path.find_first_of(" \t\r\n") != std::string::npos;
}

bool sourceClosureIncludesTna(const std::string& inputPath, std::map<std::string, bool>* seen) {
    if (seen->find(inputPath) != seen->end()) {
        return false;
    }
    (*seen)[inputPath] = true;
    std::string content;
    if (!readTextFile(inputPath, &content)) {
        return false;
    }
    const std::string inputDir = dirnameOf(inputPath);
    std::stringstream in(content);
    std::string line;
    while (std::getline(in, line)) {
        std::string angled;
        if (parseAngledIncludeLine(line, &angled) && angled == "tna.p4") {
            return true;
        }
        std::string prefix;
        std::string includeName;
        std::string suffix;
        if (!parseQuotedIncludeLine(line, &prefix, &includeName, &suffix)) {
            continue;
        }
        if (sourceClosureIncludesTna(joinPath(inputDir, includeName), seen)) {
            return true;
        }
    }
    return false;
}

std::string findTofinoP4Include(const char* argv0) {
    std::vector<std::string> candidates;
    if (argv0 != nullptr) {
        const std::string exeDir = dirnameOf(normalizeSlashes(argv0));
        candidates.push_back(joinPath(exeDir, "../backends/tofino/bf-p4c/p4include"));
        candidates.push_back(joinPath(exeDir, "../../backends/tofino/bf-p4c/p4include"));
    }
    candidates.push_back("src/p4b/source/backends/tofino/bf-p4c/p4include");
    candidates.push_back("backends/tofino/bf-p4c/p4include");
    candidates.push_back("../backends/tofino/bf-p4c/p4include");
    for (const auto& candidate : candidates) {
        if (fileExists(joinPath(candidate, "tna.p4"))) {
            return candidate;
        }
    }
    return "";
}

void normalizeVerifyFrontendOptionsImpl(P4VerifyOptions& options, const char* argv0) {
    if (options.loadIRFromJson || !P4VerifyCompat::hasPath(options.file)) {
        return;
    }
    const std::string inputPath = P4VerifyCompat::pathToString(options.file);
    std::map<std::string, bool> seen;
    if (!sourceClosureIncludesTna(inputPath, &seen)) {
        return;
    }
    if (options.preprocessor_options.string().find("__TARGET_TOFINO__") == std::string::npos) {
        options.preprocessor_options += " -D__TARGET_TOFINO__=1";
    }
    const std::string tofinoInclude = findTofinoP4Include(argv0);
    if (!tofinoInclude.empty() &&
        options.preprocessor_options.string().find(tofinoInclude) == std::string::npos) {
        options.preprocessor_options += " -I" + tofinoInclude;
    }
}

void rewriteVerifyFrontendInput(P4VerifyOptions& options) {
    if (!P4VerifyCompat::hasPath(options.file)) {
        return;
    }
    const std::string inputPath = P4VerifyCompat::pathToString(options.file);
    const bool pathNeedsRewrite = pathNeedsFrontendRewrite(inputPath);
    std::map<std::string, bool> seen;
    if (!pathNeedsRewrite && !verifyFrontendRewriteInClosure(inputPath, &seen)) {
        return;
    }
    std::string root = makeSanitizerRoot();
    if (root.empty()) {
        return;
    }
    std::map<std::string, std::string> rewritten;
    std::string rewrittenTop;
    bool changedAny = false;
    if (!sanitizeP4TvTree(inputPath, root, &rewritten, &rewrittenTop, &changedAny)) {
        return;
    }
    if (changedAny || pathNeedsRewrite) {
        options.file = rewrittenTop;
    }
}

const IR::P4Program* loadJsonProgram(const P4VerifyOptions& options) {
    const bool debugJson = std::getenv("P4VERIFY_DEBUG_JSON_FRONTEND") != nullptr;
    if (debugJson) {
        std::cerr << "[p4verify-json] loading " << options.file << std::endl;
    }
    std::ifstream json(options.file);
    if (!json) {
        error(ErrorType::ERR_IO, "Can't open %s",
              P4VerifyCompat::pathToString(options.file).c_str());
        return nullptr;
    }
    const bool oldStrict = P4::JsonData::strict;
    const IR::Node* node = nullptr;
    try {
        // Keep legacy JSON IR dumps loadable. Several Procurator datasets were
        // produced by older p4c/BF-SDE builds whose JSON omits fields that the
        // latest strict loader requires. We still avoid source-level frontend
        // passes below, so this remains a conservative compatibility path.
        P4::JsonData::strict = false;
        P4::JSONLoader loader(json);
        loader >> node;
        P4::JsonData::strict = oldStrict;
        if (debugJson) {
            std::cerr << "[p4verify-json] loaded node "
                      << (node == nullptr ? "<null>" : node->node_type_name()) << std::endl;
        }
    } catch (const P4::JsonData::error& jsonError) {
        P4::JsonData::strict = oldStrict;
        error(ErrorType::ERR_INVALID, "%s: invalid JSON IR: %s",
              P4VerifyCompat::pathToString(options.file).c_str(), jsonError.what());
        return nullptr;
    }
    const IR::P4Program* program = node ? node->to<IR::P4Program>() : nullptr;
    if (program == nullptr) {
        error(ErrorType::ERR_INVALID, "%s is not a P4Program in json format",
              P4VerifyCompat::pathToString(options.file).c_str());
    } else if (debugJson) {
        std::cerr << "[p4verify-json] program objects "
                  << program->objects.size() << std::endl;
    }
    return program;
}

const IR::P4Program* parseSourceProgram(P4VerifyOptions& options) {
    const bool parsedAsP4_14 = options.isv1();
    rewriteVerifyFrontendInput(options);
    const IR::P4Program* program = P4::parseP4File(options);
    if (program == nullptr || ::errorCount() > 0) {
        return nullptr;
    }
    if (parsedAsP4_14) {
        // parseP4File has already converted P4_14 into P4_16 using the v1model
        // converter. Running the generic P4_16 frontend again can re-resolve
        // compiler-generated v1model extern calls (for example digest) with
        // source-order checks that are invalid for P4_14's any-order semantics.
        return program;
    }
    try {
        P4::P4COptionPragmaParser optionsPragmaParser(true);
        program->apply(P4::ApplyOptionsPragmas(optionsPragmaParser));

        P4::FrontEnd frontend;
        frontend.addDebugHook(options.getDebugHook());
        program = frontend.run(options, program);
    } catch (const std::exception& bug) {
        std::cerr << bug.what() << std::endl;
        return nullptr;
    }
    return program;
}

const IR::P4Program* normalizeJsonForSlicing(const IR::P4Program* program,
                                             const P4VerifyOptions& options) {
    if (!options.loadIRFromJson || !options.slicingEnabled || options.slicingVarNames.empty()) {
        return program;
    }

    P4::ReferenceMap normRefMap;
    P4::TypeMap normTypeMap;
    P4::PassManager normalizer;
    normalizer.addPasses({
        new P4::TypeChecking(&normRefMap, &normTypeMap),
        new P4::SimplifyDefUse(&normTypeMap),
        new P4::LocalCopyPropagation(&normTypeMap),
        new P4::ConstantFolding(&normTypeMap),
    });
    return program->apply(normalizer)->to<IR::P4Program>();
}

}  // namespace

void normalizeVerifyFrontendOptions(P4VerifyOptions& options, const char* argv0) {
    normalizeVerifyFrontendOptionsImpl(options, argv0);
}

bool loadFrontendProgram(P4VerifyOptions& options, LoadedProgram* loaded) {
    const bool debugJson = std::getenv("P4VERIFY_DEBUG_JSON_FRONTEND") != nullptr;
    CHECK_NULL(loaded);
    inferJsonInput(options);
    if (::errorCount() > 0) {
        return false;
    }

    const IR::P4Program* program = nullptr;
    if (options.loadIRFromJson) {
        program = loadJsonProgram(options);
    } else {
        program = parseSourceProgram(options);
    }
    if (program == nullptr || ::errorCount() > 0) {
        return false;
    }

    if (options.loadIRFromJson) {
        // p4c JSON is an internal IR dump format, not a stable source AST.
        // Older JSON dumps can still deserialize into IR nodes, but rerunning
        // source-level frontend normalization or TypeChecking on them can
        // crash or mutate semantics. Keep JSON mode conservative: translate
        // the loaded IR as-is and let the backend disable unsafe pruning.
        options.slicingEnabled = false;
        loaded->program = program;
        if (debugJson) {
            std::cerr << "[p4verify-json] returning raw JSON IR" << std::endl;
        }
        return true;
    }

    program = normalizeJsonForSlicing(program, options);
    if (program == nullptr || ::errorCount() > 0) {
        return false;
    }

    loaded->refMap.setIsV1(options.isv1());
    if (options.isv1()) {
        P4::PassManager v1TypeRecovery;
        v1TypeRecovery.addPasses({
            new P4::CreateBuiltins(),
            new P4::TypeInference(&loaded->typeMap, /* readOnly */ false,
                                  /* checkArrays */ true, /* errorOnNullDecls */ true),
            new P4::ResolveReferences(&loaded->refMap),
        });
        program = program->apply(v1TypeRecovery)->to<IR::P4Program>();
    } else {
        P4::TypeChecking typeChecking(&loaded->refMap, &loaded->typeMap);
        program = program->apply(typeChecking)->to<IR::P4Program>();
    }
    if (program == nullptr || ::errorCount() > 0) {
        return false;
    }

    loaded->program = program;
    return true;
}

}  // namespace P4Verify
