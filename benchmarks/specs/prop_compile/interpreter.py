import os
import shutil
import time
from pathlib import Path

from lark import Lark, Tree, Token
from compileStrategy import TestP4CompileStrategy, DirectPromelaCompileStrategy
from parser import grammar, dsl_code, PropTransformer
from utils.merge_hdr import compute_chan
from utils.path import modify_path, get_unique_run_directory

import argparse

class DSLInterpreter:
    def __init__(self, parsed_tree, compile_strategy):
        self.header_json = {}
        self.out_path = get_unique_run_directory(Path().cwd().parent.parent)
        self.tree = parsed_tree
        self.imports = {}
        self.entry_files = {}
        self.topology = []
        self.node_prop = {}
        self.global_prop = []
        # DSL-level config directives (not emitted into target code)
        # - external_input: per-node flag indicating whether Env/host can inject packets into this node
        self.node_external_input = {}  # node_name -> bool
        # - queue_capacity: global queue capacity knob (e.g., Bag(K) / FIFO(K) / mailbox)
        self.queue_capacity = None  # int | None
        self.slicing_vars = {}
        self._channel_name = "packet_channel"  # 固定的通道名称
        self._is_global = False
        self._current_node = None
        self._compile_strategy = compile_strategy

    def interpret(self):
        self._process_node(self.tree)
        self._compile_p4_files() # TODO: handle error during compilation

        self._generate_spin_model()
        self._execute_spin_model()

    def _process_node(self, node):
        node_type = node.data
        children = node.children

        if node_type == 'start':
            for section in children:
                self._process_node(section)

        elif node_type == 'import_section':
            for idx in range(len(children)):
                p4_alias = children[idx].children[0]
                if len( children[idx].children) == 3:
                    p4_entry_file = children[idx].children[2].children[0]
                    self.entry_files[str(p4_alias)] = str(p4_entry_file).strip('"')
                p4_path = children[idx].children[1].strip('"')  # 去除引号
                self.imports[str(p4_alias)] = str(p4_path)

        elif node_type == 'topology_section':
            for link in children:
                src_node = link.children[0]
                dest_node = link.children[1]
                port = "ALL"
                if len(link.children) >= 3:
                    port_node = link.children[2]
                    if isinstance(port_node, Tree) and port_node.children:
                        port = port_node.children[0]
                    else:
                        port = port_node
                self.topology.append((str(src_node), str(dest_node), str(port)))

        elif node_type == 'node_section':
            node_name = str(children[0])
            self.node_prop[node_name] = []  # 初始化该节点的属性列表
            self._current_node = node_name
            for stmt in children[1:]:
                self._process_node(stmt)
            self._current_node = None


        elif node_type == 'var_decl':
            var_type = children[0].data
            var_name = str(self._process_expression(children[1]))
            assign_op = children[2]
            if assign_op.data == "assign":
                assign_op = '='
            elif assign_op.data == "addeq":
                assign_op = '+='
            var_value = self._process_expression(children[3])

            # Handle DSL directives (do NOT emit as code)
            if not self._is_global and self._current_node and var_name == "external_input":
                if var_value not in {"true", "false"}:
                    raise ValueError(f"external_input must be true/false, got: {var_value}")
                self.node_external_input[self._current_node] = (var_value == "true")
                return
            if self._is_global and var_name == "queue_capacity":
                try:
                    self.queue_capacity = int(var_value)
                except ValueError as e:
                    raise ValueError(f"queue_capacity must be an integer, got: {var_value}") from e
                return

            var_decl_code = f"{str(var_type)} {var_name} {assign_op} {var_value};"
            if not self._is_global:
                self.node_prop[self._current_node].append(var_decl_code)
            else:
                self.global_prop.append(var_decl_code)

        elif node_type == 'assignment':
            var_name = str(self._process_expression(children[0]))
            assign_op = children[1]
            if assign_op.data == "assign":
                assign_op = '='
            elif assign_op.data == "addeq":
                assign_op = '+='
            var_value = self._process_expression(children[2])

            # Handle DSL directives (do NOT emit as code)
            if not self._is_global and self._current_node and var_name == "external_input":
                if var_value not in {"true", "false"}:
                    raise ValueError(f"external_input must be true/false, got: {var_value}")
                self.node_external_input[self._current_node] = (var_value == "true")
                return
            if self._is_global and var_name == "queue_capacity":
                try:
                    self.queue_capacity = int(var_value)
                except ValueError as e:
                    raise ValueError(f"queue_capacity must be an integer, got: {var_value}") from e
                return

            assign_code = f"{var_name} {assign_op} {var_value};"
            if not self._is_global:
                self.node_prop[self._current_node].append(assign_code)
            else:
                self.global_prop.append(assign_code)

        elif node_type == 'assert_statement':
            conditions = children
            for condition in conditions[0].children:
                assert_code = f"assert({self._process_expression(condition)});"
                if not self._is_global:
                    self.node_prop[self._current_node].append(assert_code)
                else:
                    self.global_prop.append(assert_code)

        elif node_type == 'ltl_statement':
            # 'ltl_statement' 可能有名称或无名称
            # 如果有名称，children[0] 是 'NAME'，否则是 'ltl_expr_list'
            if len(children) == 2 and isinstance(children[0], Token) and children[0].type == 'NAME':
                name = str(children[0])
                ltl_expr_list = children[1]
                print(f"Processing LTL statement with name '{name}' for node {self._current_node}")  # 调试信息
            elif len(children) == 2:
                name = None
                ltl_expr_list = children[1]
                # print(ltl_expr_list)
                print(f"Processing unnamed LTL statement for node {self._current_node}")  # 调试信息
            elif len(children) == 1:
                name = None
                ltl_expr_list = children[0]
                # print(ltl_expr_list)
                print(f"Processing unnamed LTL statement for node {self._current_node}")  # 调试信息

            for formula in ltl_expr_list.children:
                need_record = True
                ltl_code = self._process_expression(formula.children[0], need_record)
                if name:
                    ltl_code = f"ltl {name}: {ltl_code};"
                else:
                    ltl_code = f"ltl: {ltl_code};"
                if not self._is_global:
                    self.node_prop[self._current_node].append(ltl_code)
                    # print(f"Added LTL to node {self._current_node}: {ltl_code}")  # 调试信息
                else:
                    self.global_prop.append(ltl_code)
                    # print(f"Added global LTL: {ltl_code}")  # 调试信息

        elif node_type == 'global_section':
            self._is_global = True
            for stmt in children:
                self._process_node(stmt)
            self._is_global = False

        elif node_type == 'reachability_stmt':
            if len(children[0].children) == 2:
                self.global_prop.append(f"reachability({str(children[0].children[0])}, {str(children[0].children[1])})")
            else:
                print(f"error parsing reachability statement for node {children}")

        elif node_type == 'runtime_reachability_stmt':
            if len(children[0].children) == 2:
                self.global_prop.append(f"runtime_reachability({str(children[0].children[0])}, {str(children[0].children[1])})")
            else:
                print(f"error parsing reachability statement for node {children}")

        elif node_type == 'symmetry_stmt':
            # No-op for Promela backend; symmetry is handled in the Boogie backend.
            return

        else:
            print(f"未知的节点类型: {node_type}")

    def _process_expression(self, expr_node, need_record = False):
        """
        处理表达式节点，递归地解析表达式，生成对应的代码字符串。
        """
        if isinstance(expr_node, Tree):
            expr_type = str(expr_node.data)
            children = expr_node.children

            if expr_type == 'var':
                return self._process_expression(children[0], need_record)
            elif expr_type == 'dotted_var':
                var_name = ""
                for item in children:
                    if isinstance(item, Token):
                        if item.type == 'NAME':
                            var_name += (str(item) + ".")
                        elif item.type == 'NUMBER':
                            var_name = var_name.rstrip(".")
                            var_name += ("[" + str(item) + "].")
                var_name = var_name.rstrip(".")
                if need_record and var_name.split(".")[0] in self.slicing_vars and self._is_global:
                    if var_name.lstrip(var_name.split(".")[0]).lstrip(".") not in self.slicing_vars[var_name.split(".")[0]]:
                        self.slicing_vars[var_name.split(".")[0]].append(var_name.lstrip(var_name.split(".")[0]).lstrip("."))
                elif need_record and var_name.split(".")[0] not in self.slicing_vars and self._is_global:
                    lst = [var_name.lstrip(var_name.split(".")[0]).lstrip(".")]
                    self.slicing_vars[var_name.split(".")[0]] = lst

                return var_name
            elif expr_type == 'number':
                return str(children[0])
            elif expr_type == 'true':
                return "true"
            elif expr_type == 'false':
                return "false"
            elif expr_type == 'bool':
                # 'bool' 处理布尔字面量或变量
                child = children[0]
                if isinstance(child, Tree):
                    # 可能是变量或嵌套表达式
                    return self._process_expression(child, need_record)
                elif isinstance(child, Token):
                    if child.type == 'NAME':
                        return str(child)
                    elif child.type == 'NUMBER':
                        return str(child)
                elif isinstance(child, str):
                    return "true" if child == "true" else "false"
                else:
                    return "false"
            elif expr_type in {'add', 'sub', 'mul', 'div', 'less', 'less_eq', 'greater', 'greater_eq', 'eq', 'neq'}:
                operator_map = {
                    'add': '+',
                    'sub': '-',
                    'mul': '*',
                    'div': '/',
                    'less': '<',
                    'less_eq': '<=',
                    'greater': '>',
                    'greater_eq': '>=',
                    'eq': '==',
                    'neq': '!=',
                }
                operator = operator_map.get(expr_type, '?')
                left = self._process_expression(children[0], need_record)
                right = self._process_expression(children[1], need_record)
                return f"({left} {operator} {right})"
            elif expr_type in {'or_op', 'and_op'}:
                operator_map = {
                    'or_op': '||',
                    'and_op': '&&',
                }
                operator = operator_map.get(expr_type, '?')
                if len(children) == 2:
                    left = self._process_expression(children[0], need_record)
                    right = self._process_expression(children[1], need_record)
                    return f"({left} {operator} {right})"
                elif operator == '||':
                    right = self._process_expression(children[0], need_record)
                    return f"(false {operator} {right})"
                elif operator == '&&':
                    right = self._process_expression(children[0], need_record)
                    return f"(true {operator} {right})"

            elif expr_type == 'not_op':
                operand = self._process_expression(children[0], need_record)
                return f"!({operand})"
            elif expr_type in {'always_op', 'eventually_op'}:
                operator_map = {
                    'always_op': '[]',
                    'eventually_op': '<>',
                }
                operator = operator_map.get(expr_type, '?')
                operand = self._process_expression(children[1], need_record)
                return f"{operator}({operand})"
            else:
                print(f"未知的表达式类型: {expr_type}")
                return ""
        elif isinstance(expr_node, Token):
            if expr_node.type == 'NAME':
                return str(expr_node)
            elif expr_node.type == 'NUMBER':
                return str(expr_node)
            elif expr_node.type == 'ALL':
                return 'ALL'
            else:
                print(f"无法处理的 Token 类型: {expr_node.type}")
                return ""
        elif isinstance(expr_node, str):
            return expr_node
        else:
            print(f"无法处理的表达式节点: {expr_node}")
            return ""

    def _compile_p4_files(self, buffer_size=160000):
        # 构建 egress_port 映射
        self.egress_port_map = {}  # {node: {egress_port: dest_node}}
        for src, dest, port in self.topology:
            src = src.strip('\'"')
            dest = dest.strip('\'"')
            if src not in self.egress_port_map:
                self.egress_port_map[src] = {}
            egress_port = port  # 使用指定的端口号
            self.egress_port_map[src][egress_port] = dest

        current_hdr_path = ""
        self.process_files = {}
        idx = 0
        for alias, path in self.imports.items():
            idx += 1
            # find each file path
            file_path = path
            print(file_path)
            suffix = file_path.split('.')[-1]

            print(f"Processing {file_path}")
            context = self.node_prop[alias]
            try:
                egress_port = self.egress_port_map[alias]
            except KeyError:
                egress_port = { -1: alias}
            # egress_port['ALL'] = f'h{idx}'
            modified_pml_file_path = str(modify_path(file_path, self.out_path, alias))
            current_hdr_path = Path(modified_pml_file_path).parent.parent / "hdr_info"

            if not current_hdr_path.exists():
                current_hdr_path.mkdir()

            modified_pml_hdr_path = None

            if suffix == 'p4' or suffix == 'json':
                modified_pml_file_path = modified_pml_file_path.replace(suffix, "pml")
                p4_strategy = TestP4CompileStrategy({"context": context, "egress_port": egress_port, "entry_files": self.entry_files, "slicing_vars": self.slicing_vars})
                p4_strategy.compile(alias, file_path, "", "", modified_pml_file_path)
                modified_pml_hdr_path = os.path.join(str(Path(modified_pml_file_path).parent), "headers.json")
                hdr_f_name = f"{alias}_headers.json"
                try:
                    shutil.copy(str(modified_pml_hdr_path), str(current_hdr_path / hdr_f_name))
                except FileNotFoundError as e:
                    print(e)

            elif suffix == 'pml':
                print(modified_pml_file_path)
                pml_strategy = DirectPromelaCompileStrategy({"context":context, "egress_port":egress_port})
                pml_strategy.compile(alias, file_path, "", "", modified_pml_file_path)

            if modified_pml_hdr_path is not None:
                self.header_json[alias] = str(modified_pml_hdr_path)
            self.process_files[alias] = modified_pml_file_path
        compute_chan(current_hdr_path)

    def _generate_spin_model(self):
        # 初始化一个字符串变量，用于存储生成的模型内容


        model_content = '// Auto-generated Spin model\n\n'

        # 定义 MAX_BUF_SIZE (optional DSL config: queue_capacity)
        max_buf_size = self.queue_capacity if self.queue_capacity is not None else 5
        model_content += f'#define MAX_BUF_SIZE {max_buf_size}\n\n'

        # 定义全局的 headers 类型
        hdr_path = str(self.out_path / 'hdr_info' / 'global_channel.pml')

        # 定义信道（为每个节点和主机创建信道）
        node_aliases = [alias.strip('\'"') for alias in self.imports.keys()]
        host_aliases = []  # 主机别名列表

        # 包含必要的头文件
        for alias in node_aliases:
            modified_pml_file_path = self.process_files.get(alias.split("\\")[-1].split(".")[0], "")
            modified_pml_hdr_file_path = str(Path(modified_pml_file_path).parent / (alias + "_type.pml"))
            model_content += f'#include "{modified_pml_hdr_file_path}"\n'

        model_content += f'#include "{hdr_path}"\n\n'  # 假设您已经有 global_type.pml 文件

        # 定义节点信道
        for alias in node_aliases:
            model_content += f'chan {alias} = [MAX_BUF_SIZE] of {{ headers }};\n'
        model_content += '\n'

        # 定义主机信道
        for i, alias in enumerate(node_aliases):
            host_alias = f'h{i + 1}'
            host_aliases.append(host_alias)
            model_content += f'chan {host_alias} = [MAX_BUF_SIZE] of {{ headers }};  // {host_alias} <-> {alias} \n'
        model_content += '\n'

        # 包含节点的 PML 文件
        model_content += '// Include node processes\n'
        for alias in node_aliases:
            modified_pml_file_path = self.process_files.get(alias.split("\\")[-1].split(".")[0], "")
            if not modified_pml_file_path:
                print(f"Warning: No modified PML file found for alias {alias}")
                continue
            include_path = modified_pml_file_path
            model_content += f'#include "{include_path}"\n'

        model_content += '\n'

        # 初始化 source_node 和 target_node
        source_node = None
        target_node = None

        # 添加全局属性（来自 self.global_prop），排除 reachability 属性
        model_content += '// Global properties\n'
        for prop in self.global_prop:
            if prop.startswith('reachability('):
                # 获取源节点和目标节点
                nodes = prop[len('reachability('):-1].split(',')
                nodes = [node.strip() for node in nodes]
                if len(nodes) >= 2:
                    source_node = nodes[0]
                    target_node = nodes[1]
                else:
                    print(f"Error: reachability requires at least two nodes, got: {prop}")
                    return
                # 定义全局变量，用于标记目标节点是否接收到来自源节点的包
                model_content += f'bool {target_node}_received_from_{source_node} = false;\n'
            elif prop.startswith('runtime_reachability('):
                # 类似处理 runtime_reachability
                nodes = prop[len('runtime_reachability('):-1].split(',')
                nodes = [node.strip() for node in nodes]
                if len(nodes) >= 2:
                    source_node = nodes[0]
                    target_node = nodes[1]
                    # 定义全局变量，用于标记目标节点是否接收到来自源节点的包
                    model_content += f'bool {target_node}_received_from_{source_node} = false;\n'
                else:
                    print(f"Error: runtime_reachability requires at least two nodes, got: {prop}")
                    return
            else:
                model_content += f'{prop}\n'
        model_content += '\n'

        # 定义主机进程
        for i, host_alias in enumerate(host_aliases):
            connected_node = node_aliases[i]
            source_addr = 167772417 + i * 257  # 示例源地址，可根据需要调整
            model_content += f'headers {host_alias}_hdr_send;\n'
            model_content += f'headers {host_alias}_hdr_recv;\n'
            model_content += f'int {host_alias}_srcAddr = {source_addr};\n'
            model_content += f'proctype host_{host_alias}() {{\n'
            model_content += '  do\n'
            model_content += '  :: atomic {\n'
            # 发送逻辑
            model_content += f'      {host_alias}_hdr_send.ipv4.srcAddr = {host_alias}_srcAddr;\n'
            model_content += f'      {host_alias}_hdr_send.ethernet.etherType = 2048;\n' # ipv4
            model_content += '      // TODO: Set other packet fields and send packet\n'
            model_content += f'      {connected_node} ! {host_alias}_hdr_send;\n'
            model_content += '  }\n'
            # 接收逻辑
            model_content += f'  :: {host_alias} ? {host_alias}_hdr_recv -> atomic {{\n'
            model_content += '      // Handle received packet\n'
            model_content += '      printf("Host received a packet\\n");\n'
            # 如果定义了 target_node，且 connected_node 是 target_node，检查包的源地址
            if host_alias == target_node:
                source_host_srcAddr = f'{source_node}_srcAddr'
            # 生成 Promela的 if 语句
            #     model_content += '      if\n'
            #     model_content += f'      :: {host_alias}_hdr_recv.ipv4.srcAddr == {source_host_srcAddr} -> {target_node}_received_from_{source_node} = true;\n'
            #     model_content += '      fi\n'
                model_content += '      if\n'
                model_content += f'      :: {host_alias}_hdr_recv.ipv4.srcAddr == {source_host_srcAddr} -> {target_node}_received_from_{source_node} = true;\n'
                model_content += '      :: else -> skip;\n'
                model_content += '      fi\n'


            model_content += '    }\n'
            model_content += '  od\n'
            model_content += '}\n\n'

        # 定义 LTL 公式
        if target_node is not None and source_node is not None:
            model_content += '// LTL property for reachability\n'
            model_content += f'ltl unreached_{source_node}_to_{target_node} {{ [] ({target_node}_received_from_{source_node} == false) }}\n'
            model_content += f'// The property asserts that {target_node} never receives packets from {source_node}.\n'
            model_content += f'// If Spin finds a counterexample, it means {target_node} can receive packets from {source_node}, i.e., reachability exists.\n\n'

        # 初始化进程
        model_content += 'init {\n'
        model_content += '  atomic {\n'
        # 运行主机进程
        for host_alias in host_aliases:
            model_content += f'    run host_{host_alias}();\n'
        model_content += '\n'
        # 运行节点的主程序，假设为 alias_mainProcedure()
        for alias in node_aliases:
            model_content += f'    run {alias}_mainProcedure();\n'
        model_content += '  }\n'
        model_content += '}\n'

        # 最后将生成的模型内容写入文件
        with open(str(self.out_path / 'main_model.pml'), 'w', encoding='utf-8') as f:
            f.write(model_content)

        # 如果需要，可以在此处打印或调试 model_content
        # print(model_content)  # 取消注释以在控制台输出模型内容

    def _execute_spin_model(self):
        print("Executing Spin model...")
        # Uncomment the following lines to execute Spin commands
        # subprocess.run("spin -a main_model.pml", shell=True, check=True)
        # subprocess.run("gcc -o pan pan.c", shell=True, check=True)
        # subprocess.run("./pan", shell=True, check=True)


if __name__ == '__main__':
    argumentParser = argparse.ArgumentParser()
    argumentParser.add_argument('--spec', type=str, help='Path of the specification file.')
    args = argumentParser.parse_args()
    filename = args.spec
    with open(filename, 'r', encoding='utf-8') as file:
        dsl_code = file.read()
    
    parser = Lark(grammar, start='start', parser='lalr')
    tree = parser.parse(dsl_code)
    # print(tree)
    # PropTransformer.transform(tree)
    interpreter = DSLInterpreter(tree, "test")
    interpreter.interpret()
