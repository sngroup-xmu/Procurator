// Frontend loading and normalization for the verify backend.
#include "backends/verify/bpl_verify/frontend.h"

#include <fstream>
#include <iostream>
#include <map>
#include <regex>
#include <sstream>
#include <string>
#include <cerrno>
#include <sys/stat.h>
#include <unistd.h>
#include <vector>

#include "frontends/common/applyOptionsPragmas.h"
#include "frontends/common/constantFolding.h"
#include "frontends/common/parseInput.h"
#include "frontends/p4/frontend.h"
#include "frontends/p4/simplifyDefUse.h"
#include "frontends/p4/typeChecking/typeChecker.h"
#include "ir/json_loader.h"
#include "ir/pass_manager.h"
#include "lib/error.h"
#include "midend/local_copyprop.h"

namespace P4Verify {
namespace {

void inferJsonInput(P4VerifyOptions& options) {
    if (!options.loadIRFromJson && options.file != nullptr) {
        const std::string inputPath = options.file.c_str();
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

bool sanitizeP4TvContent(const std::string& content, std::string* sanitizedOut) {
    const bool hasAssert = content.find("@assert") != std::string::npos;
    const bool hasAssume = content.find("@assume") != std::string::npos;
    if (!hasAssert && !hasAssume) {
        *sanitizedOut = content;
        return false;
    }

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

bool p4TvAnnotationInClosure(const std::string& inputPath, std::map<std::string, bool>* seen) {
    if (seen->find(inputPath) != seen->end()) {
        return false;
    }
    (*seen)[inputPath] = true;
    std::string content;
    if (!readTextFile(inputPath, &content)) {
        return false;
    }
    if (content.find("@assert") != std::string::npos || content.find("@assume") != std::string::npos) {
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
        if (p4TvAnnotationInClosure(joinPath(inputDir, includeName), seen)) {
            return true;
        }
    }
    return false;
}

void rewriteP4TvAnnotations(P4VerifyOptions& options) {
    if (options.file == nullptr) {
        return;
    }
    const std::string inputPath = options.file.c_str();
    std::map<std::string, bool> seen;
    if (!p4TvAnnotationInClosure(inputPath, &seen)) {
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
    if (changedAny) {
        options.file = cstring(rewrittenTop);
    }
}

const IR::P4Program* loadJsonProgram(const P4VerifyOptions& options) {
    std::ifstream json(options.file);
    if (!json) {
        error(ErrorType::ERR_IO, "Can't open %s", options.file);
        return nullptr;
    }
    JSONLoader loader(json);
    const IR::Node* node = nullptr;
    loader >> node;
    const IR::P4Program* program = node ? node->to<IR::P4Program>() : nullptr;
    if (program == nullptr) {
        error(ErrorType::ERR_INVALID, "%s is not a P4Program in json format", options.file);
    }
    return program;
}

const IR::P4Program* parseSourceProgram(P4VerifyOptions& options) {
    rewriteP4TvAnnotations(options);
    const IR::P4Program* program = P4::parseP4File(options);
    if (program == nullptr || ::errorCount() > 0) {
        return nullptr;
    }
    try {
        P4::P4COptionPragmaParser optionsPragmaParser;
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
    PassManager normalizer;
    normalizer.addPasses({
        new P4::TypeChecking(&normRefMap, &normTypeMap),
        new P4::SimplifyDefUse(&normRefMap, &normTypeMap),
        new P4::LocalCopyPropagation(&normRefMap, &normTypeMap),
        new P4::ConstantFolding(&normRefMap, &normTypeMap),
    });
    return program->apply(normalizer)->to<IR::P4Program>();
}

}  // namespace

bool loadFrontendProgram(P4VerifyOptions& options, LoadedProgram* loaded) {
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

    program = normalizeJsonForSlicing(program, options);
    if (program == nullptr || ::errorCount() > 0) {
        return false;
    }

    P4::TypeChecking typeChecking(&loaded->refMap, &loaded->typeMap);
    program = program->apply(typeChecking)->to<IR::P4Program>();
    if (program == nullptr || ::errorCount() > 0) {
        return false;
    }

    loaded->program = program;
    return true;
}

}  // namespace P4Verify
