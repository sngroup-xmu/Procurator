class LTLFormula:
    def __init__(self, op, *args):
        self.op = op
        self.args = args

    def __str__(self):
        if self.op in {'<>', '[]', '!'}:
            # Unary operators
            return f"{self.op}({self.args[0]})"
        elif self.op in {'U', '&&', '||', '->', '<->'}:
            # Binary operators
            return f"({self.args[0]} {self.op} {self.args[1]})"
        else:
            # Atomic propositions
            return self.op

class LTLTransformation:
    def __init__(self, fieldMappingFile):
        self.readFieldMappingFromFile(fieldMappingFile)

    def readFieldMappingFromFile(self, path):
        """
        读取成dict
        """
        self.fieldMapping = {}
        try:
            with open(path, "r") as f:
                for line in f:
                    key_value_pair = line.strip().split(':')
                    if len(key_value_pair) == 2:
                        key, value = key_value_pair
                        self.fieldMapping[key.strip()] = value.strip()
        except FileNotFoundError:
            print(f"文件 {path} 未找到。")
    
    def transform_operator(self, formula):
        """
        Transforms LTL formula to replace all instances of <> with ![]!.
        """
        if formula.op == '<>':
            # Transform <>φ to ![]!φ
            inner_transformed = self.transform_operator(formula.args[0])
            return LTLFormula('!', LTLFormula('[]', LTLFormula('!', inner_transformed)))
        elif formula.op == '[]':
            # Transform within the [] scope as well
            inner_transformed = self.transform_operator(formula.args[0])
            return LTLFormula('[]', inner_transformed)
        elif formula.op == '!':
            # Apply transformation inside negation
            inner_transformed = self.transform_operator(formula.args[0])
            return LTLFormula('!', inner_transformed)
        elif formula.op in {'U', '&&', '||', '->', '<->'}:
            # Apply transformation in both arguments of binary operators
            left_transformed = self.transform_operator(formula.args[0])
            right_transformed = self.transform_operator(formula.args[1])
            return LTLFormula(formula.op, left_transformed, right_transformed)
        else:
            # For atomic propositions or unknown operators, return as is
            return formula

    def handleVariableReference(self, switchID, variale_P4):
        """
        将P4变量引用处理成promela变量引用
        e.g., hdr.ipv4.dstAddr ->  s1_hdr.ipv4.dstAddr
        e.g., value_reg ->  s1_value_reg_0
        """
        arr = variale_P4.split(".")
        field = arr[-1]
        arr[-1] = self.fieldMapping.get(field, "")
        print(variale_P4, "->", switchID + "_" + ".".join(arr))
        return switchID + "_" + ".".join(arr)
    

# x = LTLTransformation("/home/shenhuan/P4-verification/code/log/ipv4/field_mapping.csv")
# x.handleVariableReference("s1", "hdr.priority")

# Example usage
# Formula: <>([](p) && (q -> r))
# p = LTLFormula('p')                       # atomic proposition p
# q = LTLFormula('q')                       # atomic proposition q
# r = LTLFormula('r')                       # atomic proposition r
# # Compound formula with unary and binary operators
# nested_formula = LTLFormula('<>', LTLFormula('&&', LTLFormula('[]', p), LTLFormula('->', q, r)))  # <>([](p) && (q -> r))

# # Transform the formula
# transformed_formula = transform_operator(nested_formula)
# print("Original Formula:", nested_formula)
# print("Transformed Formula:", transformed_formula)



