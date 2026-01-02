# -*- coding: utf-8 -*-
import json
import os
import glob

# Paths
base_dir = os.path.dirname(os.path.abspath(__file__))
substory_dir = os.path.join(base_dir, r"way3\StoryData\Substories\Seoyena")
output_file = os.path.join(substory_dir, "Seoyena_All_Dialogues.md")

print(f"Reading JSONs from: {substory_dir}")

# Get all json files
json_files = glob.glob(os.path.join(substory_dir, "*.json"))
json_files.sort() # Ensure sorted order

dialogues = []

for file_path in json_files:
    filename = os.path.basename(file_path)
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        node_id = data.get("node_id", filename)
        char_id = data.get("character_id", "Unknown")
        text = data.get("dialogue_text", "")
        
        # Format:
        # ### [Node ID] CharacterID
        # Dialogue Text
        
        entry = f"**{filename} / {char_id}**\n\n{text}\n\n---\n\n"
        dialogues.append(entry)
        
    except Exception as e:
        print(f"Error reading {filename}: {e}")

# Write to file
try:
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write("# Seoyena Substory Dialogues\n\n")
        f.writelines(dialogues)
    print(f"Successfully generated: {output_file}")
    print(f"Total entries: {len(dialogues)}")
except Exception as e:
    print(f"Error writing output file: {e}")
