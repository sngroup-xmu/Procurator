from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Dict, List, Optional, Tuple


_RE_BV_LIT = re.compile(r"^(?P<val>\d+)bv(?P<w>\d+)$")


@dataclass(frozen=True)
class BvValue:
    value: int
    width: int

    def masked(self) -> "BvValue":
        return BvValue(self.value & ((1 << self.width) - 1), self.width)


def bv_width(typ: Optional[str]) -> Optional[int]:
    if typ is None:
        return None
    m = re.match(r"^bv(?P<w>\d+)$", typ.strip())
    if not m:
        return None
    return int(m.group("w"))


def eval_bv_expr(expr: str, *, const_eq: Dict[str, int], var_types: Dict[str, str]) -> Optional[BvValue]:
    parser = _BvParser(expr, const_eq=const_eq, var_types=var_types)
    value = parser.parse_expr()
    if value is None:
        return None
    parser.skip_ws()
    if not parser.at_end():
        return None
    return value.masked()


class _BvParser:
    def __init__(self, text: str, *, const_eq: Dict[str, int], var_types: Dict[str, str]) -> None:
        self.text = text
        self.pos = 0
        self.const_eq = const_eq
        self.var_types = var_types

    def at_end(self) -> bool:
        return self.pos >= len(self.text)

    def skip_ws(self) -> None:
        while self.pos < len(self.text) and self.text[self.pos].isspace():
            self.pos += 1

    def consume(self, token: str) -> bool:
        self.skip_ws()
        if self.text.startswith(token, self.pos):
            self.pos += len(token)
            return True
        return False

    def consume_word(self, word: str) -> bool:
        self.skip_ws()
        end = self.pos + len(word)
        if self.text[self.pos:end] != word:
            return False
        before_ok = self.pos == 0 or not _is_ident_char(self.text[self.pos - 1])
        after_ok = end >= len(self.text) or not _is_ident_char(self.text[end])
        if before_ok and after_ok:
            self.pos = end
            return True
        return False

    def parse_expr(self) -> Optional[BvValue]:
        self.skip_ws()
        if self.consume("("):
            before = self.pos
            inner = self.parse_expr()
            self.skip_ws()
            if inner is not None and self.consume(")"):
                value = inner
            else:
                self.pos = before
                value = self.parse_conditional_inside_open_paren()
                if value is None:
                    return None
                self.skip_ws()
                if not self.consume(")"):
                    return None
            self.skip_ws()
            value = self.apply_postfixes(value)
            if value is None:
                return None
            while self.consume("++"):
                rhs = self.parse_expr()
                if rhs is None:
                    return None
                value = _concat(value, rhs)
                self.skip_ws()
            return value

        value = self.parse_conditional()
        if value is None:
            value = self.parse_call_or_atom()
        if value is None:
            return None
        self.skip_ws()
        value = self.apply_postfixes(value)
        if value is None:
            return None
        while self.consume("++"):
            rhs = self.parse_expr()
            if rhs is None:
                return None
            value = _concat(value, rhs)
            self.skip_ws()
        return value

    def apply_postfixes(self, value: BvValue) -> Optional[BvValue]:
        while True:
            self.skip_ws()
            if not self.consume("["):
                return value
            hi = self.parse_decimal()
            if hi is None or not self.consume(":"):
                return None
            lo = self.parse_decimal()
            if lo is None or not self.consume("]"):
                return None
            if lo < 0 or hi <= lo or hi > value.width:
                return None
            value = BvValue((value.value >> lo) & ((1 << (hi - lo)) - 1), hi - lo)

    def parse_conditional_inside_open_paren(self) -> Optional[BvValue]:
        if not self.consume_word("if"):
            return None
        return self.parse_conditional_tail()

    def parse_conditional(self) -> Optional[BvValue]:
        if not self.consume_word("if"):
            return None
        return self.parse_conditional_tail()

    def parse_conditional_tail(self) -> Optional[BvValue]:
        cond = self.parse_bool_expr()
        if cond is None or not self.consume_word("then"):
            return None
        then_v = self.parse_expr()
        if then_v is None or not self.consume_word("else"):
            return None
        else_v = self.parse_expr()
        if else_v is None or then_v.width != else_v.width:
            return None
        return then_v if cond else else_v

    def parse_bool_expr(self) -> Optional[bool]:
        self.skip_ws()
        if self.consume("("):
            value = self.parse_bool_expr()
            self.skip_ws()
            return value if value is not None and self.consume(")") else None
        lhs = self.parse_expr()
        if lhs is None:
            return None
        if self.consume("=="):
            rhs = self.parse_expr()
            return None if rhs is None or lhs.width != rhs.width else lhs.value == rhs.value
        if self.consume("!="):
            rhs = self.parse_expr()
            return None if rhs is None or lhs.width != rhs.width else lhs.value != rhs.value
        return None

    def parse_call_or_atom(self) -> Optional[BvValue]:
        name = self.parse_ident()
        if name is None:
            return self.parse_bv_lit()
        self.skip_ws()
        if self.consume("("):
            args = self.parse_args()
            if args is None:
                return None
            return _eval_call(name, args)
        if name in self.const_eq:
            width = bv_width(self.var_types.get(name))
            if width is None:
                return None
            return BvValue(self.const_eq[name], width).masked()
        return None

    def parse_bv_lit(self) -> Optional[BvValue]:
        self.skip_ws()
        m = re.match(r"(?P<val>\d+)bv(?P<w>\d+)", self.text[self.pos :])
        if not m:
            return None
        end = self.pos + m.end()
        if end < len(self.text) and _is_ident_char(self.text[end]):
            return None
        self.pos += m.end()
        return BvValue(int(m.group("val")), int(m.group("w"))).masked()

    def parse_ident(self) -> Optional[str]:
        self.skip_ws()
        start = self.pos
        if start >= len(self.text) or not (self.text[start].isalpha() or self.text[start] == "_"):
            return None
        self.pos += 1
        while self.pos < len(self.text) and _is_ident_char(self.text[self.pos]):
            self.pos += 1
        return self.text[start : self.pos]

    def parse_decimal(self) -> Optional[int]:
        self.skip_ws()
        start = self.pos
        while self.pos < len(self.text) and self.text[self.pos].isdigit():
            self.pos += 1
        if self.pos == start:
            return None
        return int(self.text[start : self.pos])

    def parse_args(self) -> Optional[List[BvValue]]:
        args: List[BvValue] = []
        self.skip_ws()
        if self.consume(")"):
            return args
        while True:
            arg = self.parse_expr()
            if arg is None:
                return None
            args.append(arg)
            self.skip_ws()
            if self.consume(")"):
                return args
            if not self.consume(","):
                return None


def _is_ident_char(ch: str) -> bool:
    return ch.isalnum() or ch in "_.$"


def _concat(lhs: BvValue, rhs: BvValue) -> BvValue:
    return BvValue((lhs.value << rhs.width) | rhs.value, lhs.width + rhs.width).masked()


def _eval_call(name: str, args: List[BvValue]) -> Optional[BvValue]:
    base, width = _bv_call(name)
    if base is None or width is None:
        if name.endswith("__p4b_crc16_bmv2_byte") and len(args) == 2:
            return _crc16_bmv2_byte(args[0], args[1])
        if name.endswith("__p4b_crc32_bmv2_byte") and len(args) == 2:
            return _crc32_bmv2_byte(args[0], args[1])
        return None
    if base in {"add", "sub", "mul", "bxor", "band", "bor"} and len(args) == 2:
        if args[0].width != width or args[1].width != width:
            return None
        a, b = args[0].value, args[1].value
        ops = {
            "add": a + b,
            "sub": a - b,
            "mul": a * b,
            "bxor": a ^ b,
            "band": a & b,
            "bor": a | b,
        }
        return BvValue(ops[base], width).masked()
    if base == "urem" and len(args) == 2:
        if args[0].width != width or args[1].width != width or args[1].value == 0:
            return None
        return BvValue(args[0].value % args[1].value, width)
    if base in {"shr", "shl"} and len(args) == 2:
        if args[0].width != width or args[1].width != width:
            return None
        if base == "shr":
            return BvValue(args[0].value >> args[1].value, width).masked()
        return BvValue(args[0].value << args[1].value, width).masked()
    return None


def _bv_call(name: str) -> Tuple[Optional[str], Optional[int]]:
    m = re.match(r"^(?P<op>[A-Za-z]+)\.bv(?P<w>\d+)$", name)
    if not m:
        return None, None
    return m.group("op"), int(m.group("w"))


def _crc16_bmv2_byte(crc: BvValue, byte: BvValue) -> Optional[BvValue]:
    if crc.width != 16 or byte.width != 8:
        return None
    cur = crc.value ^ byte.value
    for _ in range(8):
        cur = ((cur >> 1) ^ 0xA001) if (cur & 1) else (cur >> 1)
        cur &= 0xFFFF
    return BvValue(cur, 16)


def _crc32_bmv2_byte(crc: BvValue, byte: BvValue) -> Optional[BvValue]:
    if crc.width != 32 or byte.width != 8:
        return None
    cur = crc.value ^ byte.value
    for _ in range(8):
        cur = ((cur >> 1) ^ 0xEDB88320) if (cur & 1) else (cur >> 1)
        cur &= 0xFFFFFFFF
    return BvValue(cur, 32)
