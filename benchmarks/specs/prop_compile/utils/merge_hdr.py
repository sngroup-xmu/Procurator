import json
import os
from collections import OrderedDict, defaultdict
import re
from pathlib import Path

def load_header_json(file_path):
    with open(file_path, 'r') as f:
        data = json.load(f)
    return data

def merge_headers_and_instances(header_list, instance_list):
    merged_headers = OrderedDict()
    instance_dict = OrderedDict()

    for header in header_list:
        header_name = header['name']

        if 'fields' not in header:
            header['fields'] = []
        if header_name not in merged_headers:
            merged_headers[header_name] = header
        else:
            # Merge fields, handle possible duplicates
            existing_fields = {field['name']: field for field in merged_headers[header_name]['fields']}
            for field in header['fields']:
                field_name = field['name']
                if field_name not in existing_fields:
                    merged_headers[header_name]['fields'].append(field)
                else:
                    # If field names are the same but types are different, handle conflict
                    if existing_fields[field_name]['type'] != field['type']:
                        print(f"Type conflict in header '{header_name}', field '{field_name}':")
                        print(f"  Existing type: {existing_fields[field_name]['type']}")
                        print(f"  New type: {field['type']}")
                        # Choose the new type or handle accordingly
                        existing_fields[field_name]['type'] = field['type']

    # Merge header_instances, handle possible duplicates and type conflicts
    for instance in instance_list:
        instance_name = instance['name']
        instance_type = instance['type']
        if instance_name not in instance_dict:
            instance_dict[instance_name] = instance
        else:
            if instance_dict[instance_name]['type'] != instance_type:
                print(f"Type conflict in header instance '{instance_name}':")
                print(f"  Existing type: {instance_dict[instance_name]['type']}")
                print(f"  New type: {instance_type}")
                # Choose the new type or handle accordingly
                instance_dict[instance_name]['type'] = instance_type

    merged_instances = list(instance_dict.values())
    return list(merged_headers.values()), merged_instances

def compute_type_dependencies(headers):
    dependencies = defaultdict(set)
    type_names = set(header['name'] for header in headers)

    for header in headers:
        header_name = header['name']
        for field in header['fields']:
            field_type = field['type'].strip()
            # Handle array types and remove any whitespace
            base_type, array_size = parse_array_type(field_type)
            # Remove any whitespace from base_type
            base_type = base_type.strip()
            if base_type in type_names:
                dependencies[header_name].add(base_type)
    return dependencies

def topological_sort(dependencies):
    visited = set()
    temp_marks = set()
    result = []

    def visit(node):
        if node in temp_marks:
            raise Exception(f"Cyclic dependency detected involving {node}")
        if node not in visited:
            temp_marks.add(node)
            for m in dependencies.get(node, []):
                visit(m)
            temp_marks.remove(node)
            visited.add(node)
            result.append(node)  # 不再反转列表，直接添加到结果列表末尾

    for node in dependencies:
        if node not in visited:
            visit(node)

    return result  # 不再反转结果列表

def parse_array_type(type_str):
    # Parse types like "overlay_t[10]" or "overlay_t [10]"
    match = re.match(r'(\w+)\s*\[(\d+)\]', type_str)
    if match:
        base_type = match.group(1)
        array_size = match.group(2)
        return base_type, array_size
    else:
        return type_str, None

def compute_global_channel(merged_headers, merged_instances):
    # Compute dependencies
    dependencies = compute_type_dependencies(merged_headers)
    # Add headers without dependencies
    all_header_names = set(header['name'] for header in merged_headers)
    for header_name in all_header_names:
        if header_name not in dependencies:
            dependencies[header_name] = set()

    # Perform topological sort
    try:
        sorted_header_names = topological_sort(dependencies)
    except Exception as e:
        print(f"Error: {e}")
        return ""

    # Build a mapping from header name to header definition
    header_dict = {header['name']: header for header in merged_headers}

    # Define all header types as Promela typedefs in the correct order
    channel_definition = ""
    for header_name in sorted_header_names:
        header = header_dict[header_name]
        typedef_str = f"typedef {header_name} {{\n"
        for field in header['fields']:
            promela_type = field['type']
            field_name = field['name']
            typedef_str += f"    {promela_type} {field_name};\n"
        typedef_str += f"}};\n\n"
        channel_definition += typedef_str

    # Define the global headers structure, including all header instances
    packet_struct = "typedef headers {\n"
    for instance in merged_instances:
        instance_type = instance['type']
        instance_name = instance['name']
        # Handle array types, if any
        if '[' in instance_type and ']' in instance_type:
            base_type, array_size = parse_array_type(instance_type)
            packet_struct += f"    {base_type} {instance_name}[{array_size}];\n"
        else:
            packet_struct += f"    {instance_type} {instance_name};\n"
    packet_struct += "};\n\n"
    channel_definition += packet_struct

    # Define the global channel using the headers type
    channel_definition += f"chan global_channel = [1] of {{ headers }};\n"
    return channel_definition

def compute_chan(hdr_dir):
    # Directory where header.json files are located
    headers_dir = hdr_dir

    # Get all header.json files
    header_files = [os.path.join(headers_dir, f) for f in os.listdir(headers_dir) if f.endswith('.json')]

    all_headers = []
    all_instances = []
    for header_file in header_files:
        header_data = load_header_json(header_file)
        if 'headers' in header_data:
            all_headers.extend(header_data['headers'])
        if 'header_instances' in header_data:
            all_instances.extend(header_data['header_instances'])

    # Merge headers and header_instances
    merged_headers, merged_instances = merge_headers_and_instances(all_headers, all_instances)

    # Save merged headers.json
    save_path = Path(hdr_dir)
    save_json_path = save_path / 'global_headers.json'
    with open(str(save_json_path), 'w') as f:
        json.dump({'headers': merged_headers, 'header_instances': merged_instances}, f, indent=4)
    print("Merged headers saved to global_headers.json")

    # Compute global channel
    global_channel_def = compute_global_channel(merged_headers, merged_instances)
    print("Global channel definition:")
    print(global_channel_def)

    save_pml_path = save_path / 'global_channel.pml'
    # Save global channel definition to file
    with open(save_pml_path, 'w') as f:
        f.write(global_channel_def)
    print("Global channel definition saved to global_channel.pml")

if __name__ == '__main__':
    path_now = Path.cwd().parent.parent.parent / "run_1" / "hdr_info"
    compute_chan(path_now)
