"""
Lark grammar for Procurator's property DSL.

Keep grammar isolated so both backends share an identical front-end.
"""

GRAMMAR = r"""
    start: import_section topology_section (node_section | host_section)* global_section

    import_section: (import_stmt)*

    import_stmt: "import" NAME "from" STRING (entries_clause)? ";"

    entries_clause: "entries" STRING

    topology_section: "topology" "{" link* "}"
    node_section: "node" NAME "{" statement* "}"
    host_section: "host" NAME "{" host_stmt* "}"

    global_section: "global" "{" (statement | reachability_stmt | runtime_reachability_stmt | symmetry_stmt)* "}"

    // reachability_stmt
    reachability_stmt: "reachability" "(" node_list ")" ";"
    runtime_reachability_stmt: "runtime_reachability" "(" node_list ")" ";"
    node_list: NAME ("," NAME)*
    symmetry_stmt: "symmetry" "(" node_list ")" ";"

    link: "link" NAME "->" NAME port? ";"
    port: INT | ALL

    ?statement: var_decl ";"
              | assignment ";"
              | expression ";"
              | assume_statement ";"
              | assert_statement ";"
              | ltl_statement ";"
              | if_statement
              | env_block

    host_stmt: connect_stmt
             | statement

    connect_stmt: "connect" NAME ";"

    if_statement: "if" "(" bool_expr ")" "{" statement* "}" else_block?
    else_block: "else" "{" statement* "}"
    env_block: "env" "{" statement* "}"

    var_decl: type dotted_var assign_op expression
    assignment: dotted_var assign_op expression

    assert_statement: "assert" "{" bool_expr_list "}"
    assume_statement: "assume" "{" bool_expr_list "}"

    ltl_statement: "ltl" [NAME] "{" ltl_expr_list "}"
    ltl_expr_list: (ltl_expr ";")+

    bool_expr_list: (bool_expr ";")*

    ?assign_op: "="                    -> assign
              | "+="                   -> addeq

    ?bool_expr: logic_or

    // boolean / arithmetic expressions
    ?expression: logic_or

    ?logic_or: logic_and
             | logic_and (OP_OR logic_and)+   -> or_op

    ?logic_and: logic_not
              | logic_not (OP_AND logic_not)+ -> and_op

    ?logic_not: OP_NOT logic_not              -> not_op
              | rel_expr

    ?rel_expr: arith_expr
             | arith_expr ">" arith_expr      -> greater
             | arith_expr ">=" arith_expr     -> greater_eq
             | arith_expr "<" arith_expr      -> less
             | arith_expr "<=" arith_expr     -> less_eq
             | arith_expr "==" arith_expr     -> eq
             | arith_expr "!=" arith_expr     -> neq

    ?arith_expr: term
               | arith_expr "+" term          -> add
               | arith_expr "-" term          -> sub

    ?term: factor
         | term "*" factor                   -> mul
         | term "/" factor                   -> div

    ?factor: primary
           | primary BITSLICE                -> bit_slice

    ?primary: INT                            -> number
            | "true"                         -> true
            | "false"                        -> false
            | dotted_var                     -> var
            | "(" expression ")"

    // Allow numeric path segments like hdr.overlay.0.swip (Boogie emits stacks as .0/.1/...)
    // IMPORTANT: Keep dot-numeric segments (INTSEG) distinct from bracket indices (INT),
    // so the compiler can reconstruct Boogie names without ambiguity.
    dotted_var: NAME ("." (NAME|INTSEG))* ("[" INT "]")*

    ?type: "int"                             -> int
         | "bool"                            -> bool

    // LTL expression definitions
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
    OP_NOT: "!" | "not"
    OP_ALWAYS: "[]" | "always"
    OP_EVENTUALLY: "<>" | "eventually"

    ALL: "ALL"
    INTSEG: /[0-9]+/
    BITSLICE.2: /\[[0-9]+:[0-9]+\]/

    COMMENT: /\/\/[^\n]*/
    %ignore COMMENT

    %import common.CNAME -> NAME
    %import common.INT
    %import common.ESCAPED_STRING -> STRING
    %import common.WS
    %ignore WS
"""
