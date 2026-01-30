from __future__ import annotations

import json
import os
import re
from collections import OrderedDict, defaultdict
from pathlib import Path
from typing import Any


def _load_header_json(file_path: str) -> dict[str, Any]:
    with open(file_path, "r", encoding="utf-8") as f:
        return json.load(f)


def _parse_array_type(type_str: str) -> tuple[str, str | None]:
    # Parse types like "overlay_t[10]" or "overlay_t [10]".
    match = re.match(r"(\\w+)\\s*\\[(\\d+)\\]", type_str)
    if match:
        return match.group(1), match.group(2)
    return type_str, None


def _merge_headers_and_instances(
    header_list: list[dict[str, Any]],
    instance_list: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    merged_headers: "OrderedDict[str, dict[str, Any]]" = OrderedDict()
    instance_dict: "OrderedDict[str, dict[str, Any]]" = OrderedDict()

    for header in header_list:
        header_name = header["name"]
        header.setdefault("fields", [])

        if header_name not in merged_headers:
            merged_headers[header_name] = header
            continue

        # Merge fields, handle duplicates conservatively.
        existing_fields = {field["name"]: field for field in merged_headers[header_name]["fields"]}
        for field in header["fields"]:
            field_name = field["name"]
            if field_name not in existing_fields:
                merged_headers[header_name]["fields"].append(field)
                continue

            if existing_fields[field_name].get("type") != field.get("type"):
                # Prefer the newer type (best-effort).
                existing_fields[field_name]["type"] = field.get("type")

    # Merge header_instances, handle duplicates and type conflicts.
    for instance in instance_list:
        instance_name = instance["name"]
        instance_type = instance["type"]

        if instance_name not in instance_dict:
            instance_dict[instance_name] = instance
            continue

        if instance_dict[instance_name].get("type") != instance_type:
            instance_dict[instance_name]["type"] = instance_type

    return list(merged_headers.values()), list(instance_dict.values())


def _compute_type_dependencies(headers: list[dict[str, Any]]) -> dict[str, set[str]]:
    dependencies: dict[str, set[str]] = defaultdict(set)
    type_names = {header["name"] for header in headers}

    for header in headers:
        header_name = header["name"]
        for field in header.get("fields", []):
            field_type = str(field.get("type", "")).strip()
            base_type, _ = _parse_array_type(field_type)
            base_type = base_type.strip()
            if base_type in type_names:
                dependencies[header_name].add(base_type)

    return dependencies


def _topological_sort(dependencies: dict[str, set[str]]) -> list[str]:
    visited: set[str] = set()
    temp_marks: set[str] = set()
    result: list[str] = []

    def visit(node: str) -> None:
        if node in temp_marks:
            raise RuntimeError(f"cyclic dependency detected involving {node}")
        if node in visited:
            return
        temp_marks.add(node)
        for m in dependencies.get(node, set()):
            visit(m)
        temp_marks.remove(node)
        visited.add(node)
        result.append(node)

    for node in dependencies:
        if node not in visited:
            visit(node)
    return result


def _compute_global_channel(merged_headers: list[dict[str, Any]], merged_instances: list[dict[str, Any]]) -> str:
    dependencies = _compute_type_dependencies(merged_headers)

    # Ensure every header appears in the dependency map.
    for header in merged_headers:
        dependencies.setdefault(header["name"], set())

    sorted_header_names = _topological_sort(dependencies)
    header_dict = {header["name"]: header for header in merged_headers}

    out = []

    # Define header types as Promela typedefs in dependency order.
    for header_name in sorted_header_names:
        header = header_dict[header_name]
        out.append(f"typedef {header_name} {{")
        for field in header.get("fields", []):
            promela_type = field.get("type")
            field_name = field.get("name")
            out.append(f"    {promela_type} {field_name};")
        out.append("};\n")

    # Define the global headers structure including all header instances.
    out.append("typedef headers {")
    for instance in merged_instances:
        instance_type = instance["type"]
        instance_name = instance["name"]
        if "[" in instance_type and "]" in instance_type:
            base_type, array_size = _parse_array_type(instance_type)
            out.append(f"    {base_type} {instance_name}[{array_size}];")
        else:
            out.append(f"    {instance_type} {instance_name};")
    out.append("};\n")

    # Define a global channel using the headers type.
    out.append("chan global_channel = [1] of { headers };")
    return "\n".join(out) + "\n"


def compute_chan(hdr_dir: str | Path) -> None:
    """
    Merge multiple `*_headers.json` (from the p4c-translator) and emit:
      - global_headers.json
      - global_channel.pml
    into the given directory.
    """
    hdr_dir = Path(hdr_dir)

    header_files = [str(hdr_dir / f) for f in os.listdir(hdr_dir) if f.endswith(".json")]
    all_headers: list[dict[str, Any]] = []
    all_instances: list[dict[str, Any]] = []

    for header_file in header_files:
        header_data = _load_header_json(header_file)
        all_headers.extend(header_data.get("headers", []))
        all_instances.extend(header_data.get("header_instances", []))

    merged_headers, merged_instances = _merge_headers_and_instances(all_headers, all_instances)

    (hdr_dir / "global_headers.json").write_text(
        json.dumps({"headers": merged_headers, "header_instances": merged_instances}, indent=4),
        encoding="utf-8",
    )

    global_channel_def = _compute_global_channel(merged_headers, merged_instances)
    (hdr_dir / "global_channel.pml").write_text(global_channel_def, encoding="utf-8")


__all__ = ["compute_chan"]

