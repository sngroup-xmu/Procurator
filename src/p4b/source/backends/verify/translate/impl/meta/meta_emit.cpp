#include "translate.h"

#include <map>
#include <sstream>
#include <string>
#include <vector>

static std::string jsonEscape(const std::string &s) {
    std::string out;
    out.reserve(s.size() + 16);
    for (char c : s) {
        switch (c) {
        case '\\': out += "\\\\"; break;
        case '"': out += "\\\""; break;
        case '\b': out += "\\b"; break;
        case '\f': out += "\\f"; break;
        case '\n': out += "\\n"; break;
        case '\r': out += "\\r"; break;
        case '\t': out += "\\t"; break;
        default:
            if (static_cast<unsigned char>(c) < 0x20) {
                // Control char: escape as \u00XX
                const char hex[] = "0123456789abcdef";
                out += "\\u00";
                out += hex[(c >> 4) & 0xF];
                out += hex[c & 0xF];
            } else {
                out += c;
            }
        }
    }
    return out;
}

static void writeJsonStringArray(std::ostream &out,
                                 const std::string &key,
                                 const std::vector<cstring> &items,
                                 const std::string &indent) {
    out << indent << "\"" << key << "\": [";
    if (!items.empty()) {
        out << "\n";
        for (size_t i = 0; i < items.size(); ++i) {
            if (i > 0) {
                out << ",\n";
            }
            out << indent << "  \"" << jsonEscape(items[i].c_str()) << "\"";
        }
        out << "\n" << indent;
    }
    out << "]";
}

static void writeJsonWraparoundRegisters(std::ostream &out,
                                        const std::vector<P4VerifyOptions::WraparoundRegisterInfo> &regs,
                                        const std::string &indent) {
    out << indent << "\"registers\": [";
    if (!regs.empty()) {
        out << "\n";
        for (size_t i = 0; i < regs.size(); ++i) {
            if (i > 0) {
                out << ",\n";
            }
            const auto &r = regs[i];
            const std::string internal = r.internal_name ? r.internal_name.c_str() : "";
            const std::string name = r.boogie_name ? r.boogie_name.c_str() : "";
            out << indent << "  {"
                << "\"internal\": \"" << jsonEscape(internal) << "\", "
                << "\"name\": \"" << jsonEscape(name) << "\", "
                << "\"value_width\": " << r.value_width << ", "
                << "\"index_width\": " << r.index_width
                << "}";
        }
        out << "\n" << indent;
    }
    out << "]";
}

static void writeJsonWraparoundUpdates(std::ostream &out,
                                      const std::vector<P4VerifyOptions::WraparoundUpdate> &updates,
                                      const std::string &indent) {
	    out << indent << "\"updates\": [";
	    if (!updates.empty()) {
	        out << "\n";
	        for (size_t i = 0; i < updates.size(); ++i) {
            if (i > 0) {
                out << ",\n";
            }
	            const auto &u = updates[i];
	            const std::string regInternal = u.reg_internal ? u.reg_internal.c_str() : "";
	            const std::string reg = u.reg_boogie ? u.reg_boogie.c_str() : "";
	            const std::string idxExpr = u.idx_expr ? u.idx_expr.c_str() : "";
	            const std::string valVar = u.value_var ? u.value_var.c_str() : "";
	            const std::string op = u.op ? u.op.c_str() : "";
	            const std::string delta = u.delta_const ? u.delta_const.c_str() : "";
	            const std::string ctx = u.context ? u.context.c_str() : "";

            out << indent << "  {";
            out << "\"reg_internal\": \"" << jsonEscape(regInternal) << "\", ";
            out << "\"reg\": \"" << jsonEscape(reg) << "\", ";
            out << "\"idx_vars\": [";
            for (size_t j = 0; j < u.idx_vars.size(); ++j) {
                if (j > 0) {
                    out << ", ";
                }
                out << "\"" << jsonEscape(u.idx_vars[j].c_str()) << "\"";
            }
            out << "], ";
	            if (u.idx_const >= 0) {
	                out << "\"idx_const\": " << u.idx_const << ", ";
	            } else {
	                out << "\"idx_const\": null, ";
	            }
	            if (u.idx_expr && !idxExpr.empty()) {
	                out << "\"idx_expr\": \"" << jsonEscape(idxExpr) << "\", ";
	            } else {
	                out << "\"idx_expr\": null, ";
	            }
	            out << "\"value_var\": \"" << jsonEscape(valVar) << "\", ";
	            out << "\"op\": \"" << jsonEscape(op) << "\", ";
	            out << "\"delta_is_const\": " << (u.delta_is_const ? "true" : "false") << ", ";
	            out << "\"delta_const\": \"" << jsonEscape(delta) << "\", ";
            out << "\"delta_is_odd\": " << (u.delta_is_odd ? "true" : "false") << ", ";
            out << "\"value_width\": " << u.value_width << ", ";
            out << "\"index_width\": " << u.index_width << ", ";
            out << "\"context\": \"" << jsonEscape(ctx) << "\"";
            out << "}";
        }
        out << "\n" << indent;
    }
	    out << "]";
}

static void writeJsonDefinitions(std::ostream &out,
                                 const std::string &key,
                                 const std::vector<P4VerifyOptions::IndexDefinition> &defs,
                                 const std::string &indent) {
    out << indent << "\"" << key << "\": [";
    if (!defs.empty()) {
        out << "\n";
        for (size_t i = 0; i < defs.size(); ++i) {
            if (i > 0) {
                out << ",\n";
            }
            const auto &d = defs[i];
            const std::string target = d.target_var ? d.target_var.c_str() : "";
            const std::string expr = d.expr ? d.expr.c_str() : "";
            const std::string ctx = d.context ? d.context.c_str() : "";
            out << indent << "  {";
            out << "\"target_var\": \"" << jsonEscape(target) << "\", ";
            out << "\"expr\": \"" << jsonEscape(expr) << "\", ";
            out << "\"deps\": [";
            for (size_t j = 0; j < d.deps.size(); ++j) {
                if (j > 0) {
                    out << ", ";
                }
                out << "\"" << jsonEscape(d.deps[j].c_str()) << "\"";
            }
            out << "], ";
            out << "\"context\": \"" << jsonEscape(ctx) << "\", ";
            out << "\"ambiguous\": " << (d.ambiguous ? "true" : "false");
            out << "}";
        }
        out << "\n" << indent;
    }
    out << "]";
}

static void writeJsonRegisterInits(std::ostream &out,
                                   const std::map<cstring, std::map<cstring, cstring>> &inits,
                                   const std::string &indent) {
    out << indent << "\"register_inits\": {";
    if (!inits.empty()) {
        out << "\n";
        bool firstReg = true;
        for (const auto &rk : inits) {
            if (!firstReg) {
                out << ",\n";
            }
            firstReg = false;
            out << indent << "  \"" << jsonEscape(rk.first.c_str()) << "\": {";
            if (!rk.second.empty()) {
                out << "\n";
                bool firstIdx = true;
                for (const auto &iv : rk.second) {
                    if (!firstIdx) {
                        out << ",\n";
                    }
                    firstIdx = false;
                    out << indent << "    \"" << jsonEscape(iv.first.c_str()) << "\": \""
                        << jsonEscape(iv.second.c_str()) << "\"";
                }
                out << "\n" << indent << "  ";
            }
            out << "}";
        }
        out << "\n" << indent;
    }
    out << "}";
}

static void writeJsonIntMap(std::ostream &out,
                            const std::string &key,
                            const std::map<cstring, int> &items,
                            const std::string &indent) {
    out << indent << "\"" << key << "\": {";
    if (!items.empty()) {
        out << "\n";
        bool first = true;
        for (const auto &kv : items) {
            if (!first) {
                out << ",\n";
            }
            first = false;
            out << indent << "  \"" << jsonEscape(kv.first.c_str()) << "\": " << kv.second;
        }
        out << "\n" << indent;
    }
    out << "}";
}

void Translator::writeMetaToFile(std::ostream &metaOut) const {
    // Minimal contract v1:
    // - globalVariables: list of Boogie globals
    // - varTypes: (best-effort) var decl types as emitted in Boogie
    // - sizes: bitwidths for scalar vars when tracked (0 means bool)
    // - entry procedures: mainProcedure / havocProcedure
    metaOut << "{\n";
    metaOut << "  \"format\": \"p4bmeta-v1\",\n";
    metaOut << "  \"entry\": {\n";
    metaOut << "    \"main_procedure\": \"mainProcedure\",\n";
    metaOut << "    \"havoc_procedure\": \"havocProcedure\"\n";
    metaOut << "  },\n";

    // globals
    metaOut << "  \"globals\": [\n";
    bool first = true;
    for (const auto &g : globalVariables) {
        if (!first) metaOut << ",\n";
        first = false;
        metaOut << "    \"" << jsonEscape(g.c_str()) << "\"";
    }
    metaOut << "\n  ],\n";

    // varTypes
    metaOut << "  \"var_types\": {\n";
    first = true;
    for (const auto &kv : varTypes) {
        if (!first) metaOut << ",\n";
        first = false;
        metaOut << "    \"" << jsonEscape(kv.first.c_str()) << "\": \"" << jsonEscape(kv.second.c_str()) << "\"";
    }
    metaOut << "\n  },\n";

    // sizes
    metaOut << "  \"sizes\": {\n";
    first = true;
    for (const auto &kv : sizes) {
        if (!first) metaOut << ",\n";
        first = false;
        metaOut << "    \"" << jsonEscape(kv.first.c_str()) << "\": " << kv.second;
    }
    metaOut << "\n  },\n";

    // rw
    metaOut << "  \"rw\": {\n";
    writeJsonStringArray(metaOut, "stateful", options.rwStatefulObjects, "    ");
    metaOut << ",\n";
    writeJsonStringArray(metaOut, "reads", options.rwReads, "    ");
    metaOut << ",\n";
    writeJsonStringArray(metaOut, "writes", options.rwWrites, "    ");
    metaOut << "\n  },\n";

    // wraparound/monotonic analysis (post-slicing)
    metaOut << "  \"wraparound\": {\n";
    writeJsonWraparoundRegisters(metaOut, options.wraparound_registers, "    ");
    metaOut << ",\n";
    writeJsonWraparoundUpdates(metaOut, options.wraparound_updates, "    ");
    metaOut << ",\n";
    writeJsonDefinitions(metaOut, "index_definitions", options.index_definitions, "    ");
    metaOut << ",\n";
    writeJsonDefinitions(metaOut, "deterministic_definitions", options.deterministic_definitions, "    ");
    metaOut << "\n  },\n";

    // Control-plane register initialization (BMV2 `register_write`)
    std::map<cstring, std::map<cstring, cstring>> regInits;
    if (bMV2CmdsAnalyzer != nullptr) {
        struct RegInitState {
            bool hasDefault = false;
            cstring defaultVal;
            std::map<cstring, cstring> cells;
        };
        std::map<cstring, RegInitState> acc;

        auto isRegisterArrayGlobal = [&](const cstring &name) -> bool {
            auto it = varTypes.find(name);
            if (it == varTypes.end()) {
                return false;
            }
            const std::string t = it->second.c_str();
            return !t.empty() && t[0] == '[';
        };

        auto resolveBoogieRegister = [&](const RegisterWrite *rw) -> cstring {
            if (rw == nullptr) {
                return "";
            }
            const cstring regOnly = remapName(rw->reg);
            const bool hasCtrl = (rw->control != nullptr && rw->control != "");
            const cstring ctrl = hasCtrl ? remapName(rw->control) : "";

            auto tryExact = [&](const cstring &cand) -> cstring {
                if (cand != "" && globalVariables.find(cand) != globalVariables.end() &&
                    isRegisterArrayGlobal(cand)) {
                    return cand;
                }
                // Some backends may use '_' instead of '.' in names.
                std::string s = cand.c_str();
                if (s.find('.') != std::string::npos) {
                    for (auto &ch : s) {
                        if (ch == '.') ch = '_';
                    }
                    cstring alt = s.c_str();
                    if (globalVariables.find(alt) != globalVariables.end() &&
                        isRegisterArrayGlobal(alt)) {
                        return alt;
                    }
                }
                return "";
            };

            // Prefer explicit (qualified) matches when available.
            if (hasCtrl) {
                cstring cand = ctrl + "_" + regOnly;
                cstring m = tryExact(cand);
                if (m != "") {
                    return m;
                }
                cand = ctrl + "." + regOnly;
                m = tryExact(cand);
                if (m != "") {
                    return m;
                }
            }
            {
                cstring m = tryExact(regOnly);
                if (m != "") {
                    return m;
                }
            }

            // Fallback: suffix match (e.g., `netcacheEgress_latest_reg` for `latest_reg`).
            std::vector<cstring> matchesCtrl;
            std::vector<cstring> matchesAny;
            const std::string suffix = "_" + std::string(regOnly.c_str());
            const std::string prefix = hasCtrl ? (std::string(ctrl.c_str()) + "_") : "";

            for (const auto &g : globalVariables) {
                if (!isRegisterArrayGlobal(g)) {
                    continue;
                }
                const std::string gs = g.c_str();
                const bool ends = (gs == regOnly.c_str()) ||
                                  (gs.size() > suffix.size() &&
                                   gs.rfind(suffix) == gs.size() - suffix.size());
                if (!ends) {
                    continue;
                }
                matchesAny.push_back(g);
                if (hasCtrl && !prefix.empty() && gs.rfind(prefix, 0) == 0) {
                    matchesCtrl.push_back(g);
                }
            }

            if (matchesCtrl.size() == 1) {
                return matchesCtrl[0];
            }
            if (matchesAny.size() == 1) {
                return matchesAny[0];
            }
            return "";
        };

        for (const auto *rw : bMV2CmdsAnalyzer->getRegisterWriteCmds()) {
            const cstring boogieReg = resolveBoogieRegister(rw);
            if (boogieReg == "") {
                continue;
            }
            cstring idx = str2num(rw->index);
            cstring val = str2num(rw->value);

            std::string idxs = idx.c_str();
            const bool isAll = (!idxs.empty() && idxs[0] == '-');

            auto &st = acc[boogieReg];
            if (isAll) {
                st.hasDefault = true;
                st.defaultVal = val;
                st.cells.clear();
            } else {
                st.cells[idx] = val;
            }
        }

        for (const auto &kv : acc) {
            std::map<cstring, cstring> m;
            if (kv.second.hasDefault) {
                m["*"] = kv.second.defaultVal;
            }
            for (const auto &iv : kv.second.cells) {
                m[iv.first] = iv.second;
            }
            if (!m.empty()) {
                regInits[kv.first] = m;
            }
        }
    }
    writeJsonRegisterInits(metaOut, regInits, "  ");
    metaOut << ",\n";

    writeJsonIntMap(metaOut, "register_sizes", registerDomainSizes, "  ");
    metaOut << ",\n";

    metaOut << "  \"max_bitvector_size\": " << maxBitvectorSize << "\n";
    metaOut << "}\n";
}
