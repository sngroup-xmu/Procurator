from __future__ import annotations

import re
from typing import List


_BVB_BUILTIN_DECL_RE = re.compile(
    r'^\s*function\s*\{:\s*bvbuiltin\s+"[^"]+"\}\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*\([^;]*\);\s*$',
    re.MULTILINE,
)

_BVB_BUILTIN_ATTR_RE = re.compile(r'\{:\s*[A-Za-z0-9_]*bvbuiltin\s+"(?P<name>[A-Za-z0-9_]+)"\}')

_BOOGIE_KEYWORDS = {
    "assert",
    "assume",
    "axiom",
    "bool",
    "break",
    "call",
    "const",
    "else",
    "ensures",
    "exists",
    "false",
    "forall",
    "free",
    "function",
    "goto",
    "havoc",
    "if",
    "implementation",
    "int",
    "lambda",
    "modifies",
    "old",
    "par",
    "procedure",
    "returns",
    "return",
    "requires",
    "true",
    "type",
    "unique",
    "var",
    "while",
    "bvbuiltin",
    "inline",
}


class BoogiePrefixer:
    """
    Prefix all declared Boogie symbols in a single .bpl unit with `prefix_...`.
    Pragmatic regex-based prefixer tailored for P4->Boogie outputs.
    """

    _IDENT_CHARS = r"A-Za-z0-9_\.\$"
    _IDENT_RE = re.compile(r"\b[A-Za-z_][A-Za-z0-9_\.\$]*\b")
    _BV_TYPE_RE = re.compile(r"^bv\d+$")
    _BV_BUILTIN_RE = re.compile(r"^bv[A-Za-z0-9_]*\.bv\d+(?:\$builtin)?$")
    _TYPE_RE = re.compile(r"^\s*type\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*(?:=|;)", re.MULTILINE)
    _VAR_RE = re.compile(r"^\s*var\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", re.MULTILINE)
    _CONST_RE = re.compile(r"^\s*const(?:\s+unique)?\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*:", re.MULTILINE)
    _PROC_RE = re.compile(
        r"^\s*procedure(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*(?:\(|;)",
        re.MULTILINE,
    )
    _FUNC_RE = re.compile(
        r"^\s*function(?:\s*\{:[^}]+\}\s*)*\s+(?P<name>[A-Za-z0-9_\.\$]+)\s*\(",
        re.MULTILINE,
    )

    def __init__(self, prefix: str):
        if not prefix or not re.fullmatch(r"[A-Za-z0-9_]+", prefix):
            raise ValueError(f"Invalid prefix '{prefix}'; expected [A-Za-z0-9_]+")
        self._prefix = prefix

    def prefix_content(self, bpl: str) -> str:
        names = self._collect_names(bpl)
        if not names:
            return bpl
        sorted_names = sorted(names, key=len, reverse=True)
        out = bpl
        for name in sorted_names:
            out = self._replace_ident(out, name, f"{self._prefix}_{name}")
        return _normalize_bvbuiltin_attrs(out, self._prefix)

    def _collect_names(self, bpl: str) -> List[str]:
        names: List[str] = []
        for rx in (self._TYPE_RE, self._VAR_RE, self._CONST_RE, self._PROC_RE):
            names.extend(m.group("name") for m in rx.finditer(bpl))
        for m in self._FUNC_RE.finditer(bpl):
            decl = m.group(0)
            if "{:bvbuiltin" in decl:
                continue
            names.append(m.group("name"))
        names.extend(self._collect_referenced_names(bpl))
        seen = set()
        deduped: List[str] = []
        for n in names:
            if n not in seen:
                seen.add(n)
                deduped.append(n)
        return deduped

    def _collect_referenced_names(self, bpl: str) -> List[str]:
        bvbuiltins = {m.group("name") for m in _BVB_BUILTIN_DECL_RE.finditer(bpl)}
        names: List[str] = []
        for m in self._IDENT_RE.finditer(bpl):
            name = m.group(0)
            if name in _BOOGIE_KEYWORDS:
                continue
            if name in bvbuiltins:
                continue
            if self._BV_TYPE_RE.match(name):
                continue
            if self._BV_BUILTIN_RE.match(name):
                continue
            names.append(name)
        return names

    def _replace_ident(self, text: str, old: str, new: str) -> str:
        boundary = f"(?<![{self._IDENT_CHARS}]){re.escape(old)}(?![{self._IDENT_CHARS}])"
        return re.sub(boundary, new, text)


def _normalize_bvbuiltin_attrs(bpl: str, prefix: str) -> str:
    """
    Undo accidental prefixing of {:bvbuiltin "..."} attributes.
    """

    def repl(match: re.Match[str]) -> str:
        name = match.group("name")
        if name.startswith(prefix + "_"):
            name = name[len(prefix) + 1 :]
        return f'{{:bvbuiltin "{name}"}}'

    return _BVB_BUILTIN_ATTR_RE.sub(repl, bpl)


def dedup_bvbuiltin_decls(bpl: str, seen: set[str]) -> str:
    """
    Remove duplicate {:bvbuiltin} function declarations across merged nodes.
    """
    out: List[str] = []
    for line in bpl.splitlines(True):
        m = _BVB_BUILTIN_DECL_RE.match(line)
        if m:
            name = m.group("name")
            if name in seen:
                continue
            seen.add(name)
        out.append(line)
    return "".join(out)


_ULTIMATE_BVB_BUILTIN_ATTR_RE = re.compile(r"\{:\s*bvbuiltin\b")


def ultimate_rewrite_bvbuiltin_attrs(bpl: str) -> str:
    """
    Ultimate does not interpret Boogie-style `{:bvbuiltin "..."}`
    attributes, which makes bitvector ops uninterpreted and yields spurious
    counterexamples. Rewrite them to Ultimate's `{:builtin "..."}`
    attributes.
    """
    return _ULTIMATE_BVB_BUILTIN_ATTR_RE.sub("{:builtin", bpl)

