import json
from pathlib import Path

from spec.script.control_flow_transformer import ControlFlowTransformer


def main():
    # 指定JSON路径
    json_path = Path("../../run_1/s1/cfg.json")

    # 检查文件是否存在
    if not json_path.exists():
        print(f"Error: File not found at {json_path}")
        return

    # 读取JSON文件
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            json_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"Error: Failed to parse JSON file. {e}")
        return

    # 初始化 ControlFlowTransformer 实例
    try:
        transformer = ControlFlowTransformer(json_data, str(json_path.cwd() / "info.json"))
    except Exception as e:
        print(f"Error: Failed to initialize PromelaGenerator. {e}")
        return

    # 调用功能，例如 merge_consecutive_statements
    try:
        transformer.merge_consecutive_statements()
    except Exception as e:
        print(f"Error: Failed during statement merging. {e}")
        return

    # 如果需要生成 Promela 代码或其他处理，可以继续扩展此部分
    print("PromelaGenerator initialized and processed successfully.")

if __name__ == "__main__":
    main()