# speclang

Parser/semantic checker for the DSL spec language.

Entry points:
- `dslc.speclang.parse_tree(text)` -> Lark tree
- `dslc.speclang.parse_model(text)` -> `SpecModel`
- `dslc.speclang.SemanticAnalyzer().analyze(tree)` -> semantic checks
