# -*- coding: utf-8 -*-
import json
import os
import sys

# Define proper paths
# Using relative path assuming script is in way3 root
base_path = "."
input_dir = os.path.join(base_path, r"way3\StoryData\Gangnam")
output_dir = os.path.join(base_path, r"way3\StoryData")

print(f"Reading from: {input_dir}")
print(f"Writing to: {output_dir}")

all_dialogues = []
seoyena_dialogues = []

# Iterate 1 to 51
for i in range(1, 52):
    filename = f"chapter_gangnam_{i:03d}.json"
    file_path = os.path.join(input_dir, filename)
    
    if not os.path.exists(file_path):
        print(f"Warning: {filename} not found.")
        continue

    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        node_id = data.get("node_id", f"node_{i}")
        char_id = data.get("character_id", "Unknown")
        text = data.get("dialogue_text", "")
        
        # Format for Markdown
        # [NodeID] Character: Text
        md_line = f"**{char_id}** ({node_id}): {text}\n\n"
        all_dialogues.append(md_line)
        
        if char_id == "Seoyena":
            seoyena_dialogues.append(md_line)
            
    except Exception as e:
        print(f"Error reading {filename}: {e}")

# Write Gangnam.md
gangnam_md_path = os.path.join(output_dir, "Gangnam.md")
try:
    with open(gangnam_md_path, 'w', encoding='utf-8') as f:
        f.write("# Gangnam Story\n\n")
        f.writelines(all_dialogues)
    print(f"Generated {gangnam_md_path}")
except Exception as e:
    print(f"Error writing Gangnam.md: {e}")

# Write SeoYena.md
seoyena_md_path = os.path.join(output_dir, "SeoYena.md")
try:
    with open(seoyena_md_path, 'w', encoding='utf-8') as f:
        f.write("# Seo Yena Dialogue\n\n")
        f.writelines(seoyena_dialogues)
    print(f"Generated {seoyena_md_path}")
except Exception as e:
    print(f"Error writing SeoYena.md: {e}")
