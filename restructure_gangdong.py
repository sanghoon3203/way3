# -*- coding: utf-8 -*-
import json
import os
import sys

print("Starting restructuring process...")

# Define input/output paths
base_path = "."
input_file = 'gangdong_source_data.json'
output_dir = os.path.join(base_path, r"way3\StoryData\Gangdong")

# Create sub-directories for organization?
# User implied "moved to Jinbaekho's subquest part for them to be moved to".
# Usually this implies file *location* or just *ID sequence*.
# Given "StoryData" structure is flat in the previous step, I will create flat files but with distinct prefixes.
# Or better, create folders if 'SubQuests' folder exists.
# Let's check if 'SubQuests' exists in StoryData.
# Wait, user said "18~43 move to Jinbaekho's subquest part".
# I will create 'way3/StoryData/Gangdong/Jinbaekho' and 'way3/StoryData/Gangdong/Jubulsu' to be safe,
# OR just prefix them `gangdong_sub_jinbaekho_001.json` in the main folder.
# I will stick to the main folder with CLEAR prefixes as that's safer for loading unless I update the loader.
# I will use prefixes:
# 1-17: gangdong_main_001 ~ 017
# 18-43: subquest_jinbaekho_001 ~ 026
# 44-63: subquest_jubulsu_001 ~ 020
# 64-88: gangdong_main_064 ~ 088 (or renumbered?)
# User said "65 onwards connect to Main Quest".
# This implies 65 is the ID to keep? Or just "Main Quest content".
# If I change 65's ID, I break the user's mental model if they are looking at numbers.
# I will KEEP the main quest numbering as requested "65 onwards Main Quest".
# So 64 should be Main Quest too (Introduction to Climax).
# I will set:
# 1-17: gangdong_main_001...017. NEXT -> subquest_jinbaekho_001
# 18-43: subquest_jinbaekho_001...026. NEXT -> subquest_jubulsu_001 (Linear flow as written)
# 44-63: subquest_jubulsu_001...020. NEXT -> gangdong_main_064
# 64-88: gangdong_main_064...088.

try:
    with open(input_file, 'r', encoding='utf-8') as f:
        data_nodes = json.load(f)
except Exception as e:
    print(f"Failed to load source file: {e}")
    sys.exit(1)

# Indices (1-based in my comments, 0-based in list)
# List index 0 is Main_001.
# 1-17 means list indices 0 to 16.
# 18-43 means list indices 17 to 42.
# 44-63 means list indices 43 to 62.
# 64-88 means list indices 63 to 87.

# Define ranges
range_main_intro = (0, 17) # 0 to 16
range_jin = (17, 43) # 17 to 42
range_ju = (43, 63) # 43 to 62
range_main_climax = (63, 88) # 63 to 87

# Helper to generate ID
def get_id(idx, section_type):
    if section_type == "main":
        return f"gangdong_main_{idx+1:03d}"
    elif section_type == "jin":
        # Local index for subquest
        return f"subquest_jinbaekho_{idx - 17 + 1:03d}"
    elif section_type == "ju":
        return f"subquest_jubulsu_{idx - 43 + 1:03d}"
    return "error"

# Helper to determine section
def get_section(idx):
    if 0 <= idx < 17: return "main"
    if 17 <= idx < 43: return "jin"
    if 43 <= idx < 63: return "ju"
    if 63 <= idx < 88: return "main"
    return "unknown"

# Generate
for i in range(len(data_nodes)):
    node = data_nodes[i]
    section = get_section(i)
    current_id = get_id(i, section)
    
    # Determine next ID
    if i < len(data_nodes) - 1:
        next_idx = i + 1
        next_section = get_section(next_idx)
        next_id = get_id(next_idx, next_section)
    else:
        next_id = None
        
    data = {
        "dialogue_text": node["t"],
        "sound_effect": None, # Could customize based on content
        "node_id": current_id,
        "next_node_id": next_id, # Linking logic handles the jumps automatically
        "character_id": node["c"],
        "background_image": None,
        "character_sprite": None,
        "dialogue_sound_id": None
    }
    
    # Write file
    try:
        file_path = os.path.join(output_dir, f"{current_id}.json")
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=4, ensure_ascii=False)
    except Exception as e:
        print(f"Error {current_id}: {e}")

print("Restructuring complete.")
