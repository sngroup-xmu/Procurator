from pathlib import Path

def get_unique_run_directory(grandparent_dir):
    """
    在 grandparent_dir 下创建一个唯一的 run_X 文件夹。
    如果 run_0 存在，则尝试 run_1，依此类推。
    """
    i = 0
    while True:
        run_dir = grandparent_dir / f"run_{i}"
        if not run_dir.exists():
            run_dir.mkdir(parents=True)
            return run_dir
        i += 1

def modify_path(file_path_str, run_path, alia = None):
    """
    修改文件路径，使其适应跨平台，并将修改后的文件放置在当前目录的上上级目录中的 run_X 文件夹内。
    """
    # 将字符串路径转换为 Path 对象
    file_path = Path(file_path_str)
    if alia is None:
        alia = str(file_path).split("/")[-1].split(".")[0]

    # 获取当前工作目录的上上级目录
    grandparent_dir = run_path

    if not (grandparent_dir / alia).exists():
        (grandparent_dir / alia).mkdir(parents=True)
    # if not (grandparent_dir / f"{alia}_type").exists():
    #     (grandparent_dir / f"{alia}_type").mkdir(parents=True)

    run_dir = (grandparent_dir / alia)

    # 构建新的修改后的文件路径
    modified_pml_file_path = run_dir / (alia + f"{str(file_path.suffix)}")

    return modified_pml_file_path