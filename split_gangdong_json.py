# -*- coding: utf-8 -*-
import json
import os
import sys

print("Starting splitting process...")

try:
    with open('gangdong_source_data.json', 'r', encoding='utf-8') as f:
        data_nodes = json.load(f)
    print(f"Loaded {len(data_nodes)} nodes from source file.")
except Exception as e:
    print(f"Failed to load source file: {e}")
    sys.exit(1)

# Define output path
output_dir = r"way3\StoryData\Gangdong"
os.makedirs(output_dir, exist_ok=True)

start_idx = 1
for i, node in enumerate(data_nodes):
    node_idx = start_idx + i
    current_id = f"gangdong_main_{node_idx:03d}"
    
    if i < len(data_nodes) - 1:
        next_id = f"gangdong_main_{node_idx+1:03d}"
    else:
        next_id = None
        
    data = {
        "dialogue_text": node["t"],
        "sound_effect": None,
        "node_id": current_id,
        "next_node_id": next_id,
        "character_id": node["c"],
        "background_image": None,
        "character_sprite": None,
        "dialogue_sound_id": None
    }
    
    filename = f"{current_id}.json"
    file_path = os.path.join(output_dir, filename)
    
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
    except Exception as e:
        print(f"Error creating {filename}: {e}")

print(f"Successfully generated {len(data_nodes)} JSON files.")
