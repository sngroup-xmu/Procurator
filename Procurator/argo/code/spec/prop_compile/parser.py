from lark import Lark, Transformer

grammar = r"""
    start: import_section topology_section node_section* global_section

    import_section: (import_stmt)*

    import_stmt: "import" NAME "from" STRING (entries_clause)? ";"

    entries_clause: "entries" STRING

    topology_section: "topology" "{" link* "}"
    node_section: "node" NAME "{" statement* "}"

    global_section: "global" "{" (statement | reachability_stmt | runtime_reachability_stmt | symmetry_stmt)* "}"

    // 定义 reachability_stmt
    reachability_stmt: "reachability" "(" node_list ")" ";"

    // 定义 runtime_reachability_stmt
    runtime_reachability_stmt: "runtime_reachability" "(" node_list ")" ";"

    // 定义 node_list，可以传入多个节点名
    node_list: NAME ("," NAME)*

    symmetry_stmt: "symmetry" "(" node_list ")" ";"

    link: "link" NAME "->" NAME port? ";"

    port: NUMBER | ALL

    ?statement: var_decl ";"           
              | assignment ";"        
              | expression ";"       
              | assume_statement ";"
              | assert_statement ";"  
              | ltl_statement ";" 

    // 使用 dotted_var 代替 NAME
    var_decl: type dotted_var assign_op expression 

    assignment: dotted_var assign_op expression 

    assert_statement: "assert" "{" bool_expr_list "}"
    
    assume_statement: "assume" "{" bool_expr_list "}"
    
    ltl_statement: "ltl" [NAME] "{" ltl_expr_list "}" 

    ltl_expr_list: (ltl_expr ";")+

    bool_expr_list: (bool_expr ";")*

    ?assign_op: "="                    -> assign
              | "+="                   -> addeq

    ?bool_expr: logic_term

    // 布尔表达式规则
    ?expression: logic_term
               | logic_term "or" logic_term   -> or_op
               | logic_term "||" logic_term   -> or_op
               | logic_term "\\/" logic_term  -> or_op

    ?logic_term: arith_expr
               | arith_expr "and" arith_expr  -> and_op
               | arith_expr "/\\" arith_expr  -> and_op
               | arith_expr "&&" arith_expr   -> and_op
               | arith_expr ">" arith_expr    -> greater
               | arith_expr ">=" arith_expr   -> greater_eq
               | arith_expr "<" arith_expr    -> less
               | arith_expr "<=" arith_expr   -> less_eq
               | arith_expr "==" arith_expr   -> eq
               | arith_expr "!=" arith_expr   -> neq

    ?arith_expr: term
               | arith_expr "+" term          -> add
               | arith_expr "-" term          -> sub

    ?term: factor
         | term "*" factor                   -> mul
         | term "/" factor                   -> div

    ?factor: NUMBER                          -> number
           | "true"                          -> true
           | "false"                         -> false
           | dotted_var                      -> var
           | "(" expression ")"

    // 新增规则：带点的变量名
    dotted_var: NAME ("." NAME)* ("[" NUMBER "]")*

    ?type: "int"                             -> int
         | "bool"                            -> bool

    // LTL Expression Definitions
    ltl_expr: ltl_or

    ?ltl_or: ltl_and (OP_OR ltl_and)* -> or_op

    ?ltl_and: ltl_unary (OP_AND ltl_unary)* -> and_op

    ?ltl_unary: OP_NOT ltl_unary              -> not_op
               | OP_ALWAYS ltl_unary          -> always_op
               | OP_EVENTUALLY ltl_unary      -> eventually_op
               | "(" ltl_expr ")" 
               | ltl_operand

    ?ltl_operand: "true" -> true
                | "false" -> false
                | dotted_var 
                | "{" expression "}"

    OP_OR: "||" | "\\/" | "or"
    OP_AND: "&&" | "/\\" | "and"
    OP_U: "U" | "until"
    OP_W: "W" | "weakuntil"
    OP_V: "V" | "release"
    OP_NOT: "!" | "not"
    OP_ALWAYS: "[]" | "always"
    OP_EVENTUALLY: "<>" | "eventually" 

    ALL: "ALL"

    COMMENT: /\/\/[^\n]*/
    %ignore COMMENT

    %import common.CNAME -> NAME
    %import common.NUMBER
    %import common.ESCAPED_STRING -> STRING
    %import common.WS
    %ignore WS
"""

parser = Lark(grammar, start='start', parser='lalr')

class PropTransformer(Transformer):
    def start(self, args):
        return ('start', args)

    def import_section(self, args):
        imports = []
        for import_stmt in args:
            imports.append(import_stmt)
        return ('import_section', imports)

    def import_stmt(self, args):
        return ('import', args[0], args[1])

    def topology_section(self, args):
        return ('topology_section', args)

    def link(self, args):
        if len(args) == 2:
            # 没有指定端口号
            return ('link', args[0], args[1], None)
        elif len(args) == 3:
            # 指定了端口号
            return ('link', args[0], args[1], args[2])
        else:
            raise ValueError("Invalid number of arguments for link statement")

    def port(self, args):
        return args[0]  # 返回端口号或 "ALL"

    def node_section(self, args):
        return ('node_section', [i for i in args])

    def global_section(self, args):
        return ('global_section', args)

    def var_declaration(self, args):
        # 确保有四个参数
        if len(args) != 4:
            raise ValueError(f"var_declaration expects 4 arguments, got {len(args)}: {args}")
        return ('variable_declaration', args[0], args[1], args[2], args[3])

    def assign_statement(self, args):
        return ('assign_statement', args[0], args[1], args[2])

    def expression_statement(self, args):
        return ('expression_statement', args[0])

    def assert_statement(self, args):
        return ('assert_statement', args[0])

    def ltl_statement(self, args):
        # args can be [NAME, ltl_expr1, ltl_expr2, ...] or [ltl_expr1, ...]
        if len(args) == 0:
            raise ValueError("ltl_statement must have at least one expression")
        if isinstance(args[0], str):
            # First argument is NAME
            name = args[0]
            formulas = args[1:]
            return ('ltl_statement', name, formulas)
        else:
            # No NAME
            formulas = args
            return ('ltl_statement', None, formulas)

    def ltl_expr_list(self, args):
        return args  # 返回所有 ltl_expr

    def bool_expr_list(self, args):
        return [expr for expr in args]

    def ltl_expr(self, args):
        return args[0]

    # LTL Operators
    def or_op(self, args):
        if len(args) == 1:
            return args[0]
        left = args[0]
        for right in args[1:]:
            left = ('or_op', left, right)
        return left

    def and_op(self, args):
        if len(args) == 1:
            return args[0]
        left = args[0]
        for right in args[1:]:
            left = ('and_op', left, right)
        return left

    def not_op(self, args):
        return ('not_op', args[0])

    def always_op(self, args):
        return ('always_op', args[0])

    def eventually_op(self, args):
        return ('eventually_op', args[0])

    # LTL Operand
    def ltl_operand(self, args):
        if len(args) != 1:
            raise ValueError(f"ltl_operand expects 1 argument, got {len(args)}: {args}")
        return args[0]

    # 基本表达式
    def add(self, args):
        return ('add', args[0], args[1])

    def sub(self, args):
        return ('sub', args[0], args[1])

    def mul(self, args):
        return ('mul', args[0], args[1])

    def div(self, args):
        return ('div', args[0], args[1])

    def greater(self, args):
        return ('greater', args[0], args[1])

    def greater_eq(self, args):
        return ('greater_eq', args[0], args[1])

    def less(self, args):
        return ('less', args[0], args[1])

    def less_eq(self, args):
        return ('less_eq', args[0], args[1])

    def eq(self, args):
        return ('eq', args[0], args[1])

    def neq(self, args):
        return ('neq', args[0], args[1])

    def number(self, args):
        return ('number', int(args[0]))

    def true(self, args):
        return ('bool', True)

    def false(self, args):
        return ('bool', False)

    def var(self, args):
        return ('var', args[0])

    def type(self, args):
        return str(args[0])

    def IDENTIFIER(self, token):
        return str(token)

    def INT(self, token):
        return int(token)

    def STRING(self, token):
        return str(token[1:-1])  # 去除引号

    # 移除 'operand' 方法以避免冲突
    def operand(self, args):
        raise ValueError("Unexpected rule 'operand' called")



# 更新后的测试输入
dsl_code = '''
import s1 from "/mnt/d/work/P4-verification/code/dataset/Netchain/netchain_16.p4" entries "/mnt/d/work/P4-verification/code/dataset/Netchain/commands_1.txt";
import s2 from "/mnt/d/work/P4-verification/code/dataset/Netchain/netchain_16.p4" entries "/mnt/d/work/P4-verification/code/dataset/Netchain/commands_2.txt";
import s3 from "/mnt/d/work/P4-verification/code/dataset/Netchain/netchain_16.p4" entries "/mnt/d/work/P4-verification/code/dataset/Netchain/commands_3.txt";

topology {
  link s1 -> s2 ALL;
  link s2 -> s3 ALL;
}

node s1 {
    
}

node s2{}

node s3{}

global {
    ltl a {
        [] {((s1.sequence_reg[0] >= s2.sequence_reg[0]) && (s2.sequence_reg[0] >= s3.sequence_reg[0]))};
    };
}
'''

dsl_code2 = '''
import Switch1 from "/path/to/switch1.p4" entries "/path/to/switch1_entries.txt";
import Switch2 from "/path/to/switch2.p4";
import Switch3 from "/path/to/switch3.p4";

topology {
  link Switch1 -> Switch2 2;
  link Switch2 -> Switch3 ALL;
}

node Switch1 {
    assume {
        
    }
    s1_hdr.ipv4.dstAddr[0] = 167772674;
    int PacketCounter = 0;
    PacketCounter += 1;
    assert {
        BufferUsage < 100;
        PacketCounter <= 1000;
    };
}

node Switch2 {
    int count_processed_packets = 1000;
    int PacketsProcessed = 0;
    PacketsProcessed += count_processed_packets;
    assert {
        PacketsProcessed > 1000;
    };
}

node Switch3 {

}

global {
    ltl {
        true;
    };
    reachability(Switch1, Switch3);
    runtime_reachability(Switch1, Switch3);
}
'''


dsl_code3 = '''
import s1 from "/mnt/d/work/P4-verification/code/dataset/netchain_16.p4" entries "/mnt/d/work/P4-verification/code/dataset/commands_1.txt";
import s2 from "/mnt/d/work/P4-verification/code/dataset/netchain_16.p4" entries "/mnt/d/work/P4-verification/code/dataset/commands_2.txt";
import s3 from "/mnt/d/work/P4-verification/code/dataset/netchain_16.p4" entries "/mnt/d/work/P4-verification/code/dataset/commands_3.txt";

topology {
  link s1 -> s2 ALL;
  link s2 -> s3 ALL;
}

node s1 {
    assume {
        s1_hdr.ipv4.dstAddr > 65536 &&  s1_hdr.ipv4.dstAddr < 16777216;
    }
    int var = 1000;
    assert {
        egress_spec == 1;
    };
}

node s2{}

node s3{}

global {
    ltl {
        [] {(s1.sequence_reg[0] >= s2.sequence_reg[0]) && (s2.sequence_reg[0] >= s3.sequence_reg[0])};
    };
}
'''

# def test_link_with_port():
#     dsl = 'link s1 -> s2 8080;'
#     tree = parser.parse(dsl)
#     transformed = PropTransformer().transform(tree)
#     expected = ('start', [
#         ('import_section', []),
#         ('topology_section', [
#             ('link', 's1', 's2', 8080)
#         ]),
#         ('node_section', []),
#         ('global_section', [])
#     ])
#     assert transformed == expected
#
# def test_link_with_all():
#     dsl = 'link s2 -> s3 ALL;'
#     tree = parser.parse(dsl)
#     transformed = PropTransformer().transform(tree)
#     expected = ('start', [
#         ('import_section', []),
#         ('topology_section', [
#             ('link', 's2', 's3', 'ALL')
#         ]),
#         ('node_section', []),
#         ('global_section', [])
#     ])
#     assert transformed == expected
#
# def test_ltl_statement():
#     dsl = '''
#     global {
#         ltl p { [] { p }; }
#     }
#     '''
#     tree = parser.parse(dsl)
#     transformed = PropTransformer().transform(tree)
#     expected = ('start', [
#         ('import_section', []),
#         ('topology_section', []),
#         ('node_section', []),
#         ('global_section', [
#             ('ltl_statement', 'p', [
#                 ('always_op', ('var', 'p'))
#             ])
#         ])
#     ])
#     assert transformed == expected



if __name__ == '__main__':
    try:
        tree1 = parser.parse(dsl_code)
        tree2 = parser.parse(dsl_code2)
        tree3 = parser.parse(dsl_code3)

        print("Tree 1:")
        print(tree1.pretty())
        transformed_tree1 = PropTransformer().transform(tree1)
        print("Transformed Tree 1:")
        print(transformed_tree1)
        print("\nTree 2:")
        print(tree2.pretty())
        transformed_tree2 = PropTransformer().transform(tree2)
        print("Transformed Tree 2:")
        print(transformed_tree2)

        print(tree3.pretty())
        print("Transformed Tree 3:")

        transformed_tree3 = PropTransformer().transform(tree3)
        print(transformed_tree3)

    except Exception as e:
        print(f"Error: {e}")

    # test_link_with_port()
    # test_link_with_all()
    # test_ltl_statement()
