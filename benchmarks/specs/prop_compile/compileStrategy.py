import os
import re
import shutil
import time
import subprocess
from pathlib import Path


class P4CompileStrategy:
    def compile(self, alias, p4_file, commands_file, channel_name, output_path):
        raise NotImplementedError("This method should be overridden by subclasses")


class TestP4CompileStrategy(P4CompileStrategy):
    def __init__(self, compileContext):
        self.compileContext = compileContext

    def compile(self, alias, p4_file, commands_file, channel_name, output_path):
        """
        在环境中实际的 p4c 编译 P4 文件，生成 PML 文件。
        """

        pml_output = f"{alias}.pml"
        print(f"Compiling {p4_file} with commands {commands_file} to {output_path} in production environment")

        egress = self.compileContext["egress_port"]
        port_str = ""
        for k, v in egress.items():
            port_str += f"{k}:{v},"
        port_str = port_str.strip(",")

        print(port_str)
        path = Path(output_path).cwd()
        empty_path = path / "empty_file.file"

        try:
            with open(empty_path, mode='w+', encoding='utf-8') as pml_file:
                pml_file.write("")
        except OSError as e:
            print(f"Error opening file {empty_path}: {e}")
            return
        pml_file.close()

        # 实际的 p4c 编译命令
        # command = f"../../Translator/build/p4c-translator {p4_file} --switchID {alias} --bmv2cmds {commands_file} --port_dst {port_str} -o {output_path}"
        # print(command)
        # command = f"../../Translator/build/p4c-translator {p4_file} --switchID {alias} --port_dst {port_str} -o {pml_output}"
        fromJSON = "--fromJSON" if p4_file.endswith(".json") else ""

        slicing_vars_data = self.compileContext["slicing_vars"].get(alias)

        slicing_vars_str = ""
        if slicing_vars_data is not None:
            for item in slicing_vars_data:
                slicing_vars_str += f"{item},"
            slicing_vars_str = slicing_vars_str.rstrip(",")

        slicing_vars = f"--slicing-vars {slicing_vars_str}" if slicing_vars_data is not None else ""

        if commands_file == "":
            try:
                commands_file = self.compileContext['entry_files'][alias]
                command = f"../../Translator/build/p4c-translator {fromJSON} {p4_file} --switchID {alias} --bmv2cmds {commands_file} {slicing_vars} --port_dst {port_str} -o {output_path}"
            except KeyError as e:
                print(e)
                command = f"../../Translator/build/p4c-translator {fromJSON} {p4_file} {slicingVars} --switchID {alias}  --bmv2cmds {empty_path} {slicing_vars} --port_dst {port_str} -o {output_path}"
        try:
            subprocess.run(command, shell=True, check=True)
        except subprocess.CalledProcessError as e:
            print(f"Error during compilation of P4 file {p4_file}: {e}")
            return

        print(command)

        # time.sleep(2)
        # 打开 PML 文件
        try:
            with open(output_path, mode='r', encoding='utf-8') as pml_file:
                pml_code = pml_file.read()
        except OSError as e:
            print(f"Error opening file {output_path}: {e}")
            return

        # 获取节点的属性（变量声明、赋值和断言）
        node_props = self.compileContext["context"]

        variable_declarations = []
        assignments = []
        assertions = []
        ltl_statements = []

        for line in node_props:
            line = line.strip()
            if line.startswith('int') or line.startswith('bool'):
                variable_declarations.append(line)
            elif line.startswith('assert'):
                assertions.append(line)
            elif line.startswith('ltl'):
                ltl_statements.append(line)
            else:
                assignments.append(line)

        vars_code = '\n    '.join(variable_declarations)
        assigns_code = '\n    '.join(assignments)
        asserts_code = '\n    '.join(assertions)
        ltls_code = '\n    '.join(ltl_statements)

        # 准备要插入的代码
        insert_code = ''
        if vars_code:
            insert_code += '\n    // Variable Declarations\n  ' + vars_code + '\n'
        if assigns_code:
            insert_code += '\n    // Assignments\n    ' + assigns_code + '\n'
        if asserts_code:
            insert_code += '\n    // Assertions\n    ' + asserts_code + '\n'
        if ltls_code:
            insert_code += '\n    // LTL Statements\n    ' + ltls_code + '\n'

        # 查找 'od' 的位置
        od_idx = pml_code.rfind('od')
        if od_idx != -1:
            # 分割 PML 文件为两部分：在 'od' 之前和之后
            before_od = pml_code[:od_idx]
            after_od = pml_code[od_idx:]
            modified_pml_code = before_od + insert_code + after_od
        else:
            print(f"Warning: Could not find 'od' in {pml_output}, attempting to insert before the closing '}}' of the process.")
            # 查找 'proctype' 的位置
            proctype_idx = pml_code.find('proctype')
            if proctype_idx == -1:
                print(f"Error: Could not find 'proctype' in {pml_output}")
                return

            # 查找 '{' 的位置
            brace_open_idx = pml_code.find('{', proctype_idx)
            if brace_open_idx == -1:
                print(f"Error: Could not find '{{' after 'proctype' in {pml_output}")
                return

            # 查找匹配的 '}' 的位置
            def find_matching_brace(code, start_idx):
                stack = []
                for idx in range(start_idx, len(code)):
                    if code[idx] == '{':
                        stack.append('{')
                    elif code[idx] == '}':
                        if not stack:
                            return idx
                        stack.pop()
                        if not stack:
                            return idx
                return -1

            brace_close_idx = find_matching_brace(pml_code, brace_open_idx)
            if brace_close_idx == -1:
                print(f"Error: Could not find matching '}}' for the process in {pml_output}")
                return

            # 在闭括号之前插入代码
            before_brace_close = pml_code[:brace_close_idx]
            after_brace_close = pml_code[brace_close_idx:]
            modified_pml_code = before_brace_close + insert_code + after_brace_close

        # 写入修改后的 PML 文件
        try:
            with open(output_path, mode='w', encoding='utf-8') as modified_pml_file:
                modified_pml_file.write(modified_pml_code)
                print(f"Modified PML file written to {output_path}")
                return output_path
        except OSError as e:
            print(f"Error writing to model file {output_path}: {e}")


class DirectPromelaCompileStrategy(P4CompileStrategy):
    def __init__(self, compileContext):
        self.compileContext = compileContext

    def compile(self, alias, pml_file, commands_file, channel_name, output_path):
        """
        处理直接导入 Promela 代码的编译策略。
        在这里，需要插入的代码需要进行转换处理（写入LTL语句时同理），处理步骤如下：

        1、首先识别是否变量是在dsl中被定义的。
        2、不是在dsl中被定义的变量需要进行转换，也就是直接使用的变量。使用LTLTransformation类进行处理。
        3、将转换后的变量对应的语句重新进行写入。

        参数:
        - alias: str, 进程别名（例如 's1'）
        - pml_file: str, 原始 PML 文件路径
        - commands_file: str, 控制面的表项文件路径（在 DirectPromelaCompileStrategy 中可能不需要）
        - channel_name: str, 用于通信的信道名称
        - output_path: str, 修改后的 PML 文件输出路径（包含文件名）
        """
        # 获取输出目录
        output_dir = os.path.dirname(output_path)
        # 确保输出目录存在
        os.makedirs(output_dir, exist_ok=True)

        # 读取原始 PML 文件内容
        try:
            with open(pml_file.strip("'"), mode='r', encoding='utf-8') as file_obj:
                pml_code = file_obj.read()
        except OSError as e:
            print(f"Error opening PML file {pml_file}: {e}")
            return

        # 处理包含的文件，将它们复制到输出目录，并修改 include 路径
        def process_includes(pml_code, current_file_path, processed_files):
            include_pattern = re.compile(r'#include\s+"(.+?)"')
            includes = include_pattern.findall(pml_code)

            for include_file in includes:
                include_file_path = os.path.join(os.path.dirname(current_file_path), include_file)
                include_file_path = os.path.normpath(include_file_path)
                if not os.path.isfile(include_file_path):
                    print(f"Warning: Included file {include_file} not found at {include_file_path}")
                    continue

                # 避免重复处理相同的文件
                if include_file_path in processed_files:
                    continue
                processed_files.add(include_file_path)

                # 复制包含的文件到输出目录
                dest_include_file_path = os.path.join(output_dir, os.path.basename(include_file))
                try:
                    shutil.copy2(include_file_path, dest_include_file_path)
                except OSError as e:
                    print(f"Error copying included file {include_file_path} to {dest_include_file_path}: {e}")
                    continue

                # 读取包含文件的内容
                try:
                    with open(include_file_path, mode='r', encoding='utf-8') as inc_file_obj:
                        include_pml_code = inc_file_obj.read()
                except OSError as e:
                    print(f"Error opening included PML file {include_file_path}: {e}")
                    continue

                # 递归处理包含文件中的 includes
                include_pml_code = process_includes(include_pml_code, include_file_path, processed_files)

                # 将修改后的包含文件内容写入输出目录中的文件
                try:
                    with open(dest_include_file_path, mode='w', encoding='utf-8') as dest_inc_file_obj:
                        dest_inc_file_obj.write(include_pml_code)
                except OSError as e:
                    print(f"Error writing modified include file {dest_include_file_path}: {e}")
                    continue

                # 修改 include 路径为相对输出目录的文件名
                pml_code = pml_code.replace(f'#include "{include_file}"', f'#include "{os.path.basename(include_file)}"')

            return pml_code

        # 处理包含的文件，初始化已处理文件集
        processed_files = set()
        processed_files.add(os.path.abspath(pml_file))
        pml_code = process_includes(pml_code, pml_file, processed_files)

        # 找到最后一个 'od' 的位置
        od_idx = pml_code.rfind('od')
        if od_idx == -1:
            print(f"Error: Could not find 'od' in {pml_file}")
            return

        # 分割 PML 文件为两部分：在 'od' 之前和之后
        before_od = pml_code[:od_idx]
        after_od = pml_code[od_idx:]
        key = alias.split("\\")[-1].split(".")[0]

        # 获取节点的属性（变量声明、赋值和断言）
        node_props = self.compileContext.get("context", [])
        egress_ports = self.compileContext.get("egress_port", {})
        variable_declarations = []
        assignments = []
        assertions = []
        ltl_statements = []

        for line in node_props:
            line = line.strip()
            if line.startswith('int') or line.startswith('bool'):
                variable_declarations.append(line)
            elif line.startswith('assert'):
                assertions.append(line)
            elif line.startswith('ltl'):
                ltl_statements.append(line)
            else:
                assignments.append(line)

        vars_code = '\n  '.join(variable_declarations)
        assigns_code = '\n    '.join(assignments)
        asserts_code = '\n    '.join(assertions)
        ltls_code = '\n    '.join(ltl_statements)

        # 生成消息传递代码
        egress_cases = ''
        if 'ALL' in egress_ports:
            dest_nodes = egress_ports['ALL']
            if not isinstance(dest_nodes, list):
                dest_nodes = [dest_nodes]
            egress_code = ''
            for dest_node in dest_nodes:
                egress_code += f'    {dest_node}_in!packet;\n'
            message_passing_code = (
                '\n    // Message passing logic\n' +
                egress_code
            )
        else:
            egress_cases_list = []
            for egress_port, dest_node in egress_ports.items():
                egress_cases_list.append(f'    :: egress_port == {egress_port} -> {dest_node}_in!packet;')
            egress_cases_str = '\n'.join(egress_cases_list)
            egress_cases_str += f'\n    :: else -> printf("Unknown egress_port %d in {alias}\\n", egress_port);'
            message_passing_code = (
                '\n    // Message passing logic\n' +
                '    if\n' +
                f'{egress_cases_str}\n' +
                '    fi;\n'
            )

        # 准备要插入的代码
        insert_code = ''
        if vars_code:
            insert_code += '\n  // Variable Declarations\n  ' + vars_code + '\n'
        if assigns_code:
            insert_code += '\n    // Assignments\n    ' + assigns_code + '\n'
        insert_code += message_passing_code
        if asserts_code:
            insert_code += '\n    // Assertions\n    ' + asserts_code + '\n'
        if ltls_code:
            insert_code += '\n    // LTL Statements\n    ' + ltls_code + '\n'

        # 将插入的代码添加到 'od' 之前
        modified_pml_code = before_od + insert_code + after_od

        # 将修改后的 PML 文件写入到 output_path
        try:
            with open(output_path, mode='w', encoding='utf-8') as modified_pml_file:
                modified_pml_file.write(modified_pml_code)
                return output_path
        except OSError as e:
            print(f"Error writing to model file {output_path}: {e}")
            return



def get_compile_strategy_for_file(file_path, context):
    """
    根据文件名和环境选择适当的编译策略。

    参数:
    - file_path: str, 文件路径
    - environment: str, 当前环境，例如 'test', 'production'

    返回:
    - P4CompileStrategy 的实例
    """
    if file_path.endswith('.p4'):
        return TestP4CompileStrategy(context)
    elif file_path.endswith('.pml'):
        return DirectPromelaCompileStrategy(context)
    else:
        raise ValueError(f"Unsupported file type for file: {file_path}")