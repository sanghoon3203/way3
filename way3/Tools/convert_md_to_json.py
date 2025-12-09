import os
import re
import json
import argparse

def parse_markdown(file_path, output_dir, start_id_prefix):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by scenes (---)
    scenes = content.split('---')
    
    current_bg = None
    node_counter = 1
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for scene in scenes:
        lines = scene.strip().split('\n')
        for line in lines:
            line = line.strip()
            if not line:
                continue

            # Parse Metadata
            bg_match = re.match(r'\*\*.*Location.*:\s*(.*)\*\*', line, re.IGNORECASE)
            if bg_match:
                # Extract simplified bg name or keep as is
                # Logic: If text contains parenthesis, use content inside. Else use full text.
                raw_bg = bg_match.group(1).strip()
                paren_match = re.search(r'\((.*?)\)', raw_bg)
                if paren_match:
                    current_bg = paren_match.group(1)
                else:
                    # Fallback mapping or cleaner
                    current_bg = raw_bg
                continue
            
            # Skip Headers
            if line.startswith('#'):
                continue
                
            # Parse Dialogue
            # Format 1: Name: "Text"
            # Format 2: Name(Action): "Text"
            # Format 3: "Text" (Implied Narrator or Previous Speaker? Assuming Narrator for unlabeled)
            
            character_id = "Narrator"
            text = line
            
            dialogue_match = re.match(r'^([^:]+):\s*"(.*)"$', line)
            quote_only_match = re.match(r'^"(.*)"$', line)
            
            if dialogue_match:
                character_id = dialogue_match.group(1).strip()
                text = dialogue_match.group(2).strip()
                # Clean action indicators from name e.g. "Name (Action)" -> "Name"
                character_id = re.sub(r'\(.*\)', '', character_id).strip()
            elif quote_only_match:
                # If it's just a quote, it might be the protagonist or continuation. 
                # For safety, let's assume it's direct narration or monologue if not specified
                text = quote_only_match.group(1).strip()
                # Heuristic: if text starts with quotes but no name, it's often monologue or highlighted text
            
            # Construct Node ID
            node_id = f"{start_id_prefix}_{node_counter:03d}"
            next_node_id = f"{start_id_prefix}_{node_counter+1:03d}"
            
            data = {
                "node_id": node_id,
                "background_image": current_bg,
                "character_id": character_id,
                "character_sprite": None,
                "dialogue_text": text,
                "dialogue_sound_id": None,
                "sound_effect": None,
                "next_node_id": next_node_id
            }
            
            # Write JSON
            out_file = os.path.join(output_dir, f"{node_id}.json")
            with open(out_file, 'w', encoding='utf-8') as out:
                json.dump(data, out, ensure_ascii=False, indent=2)
            
            node_counter += 1

    # Fix last node's next_node_id to null
    last_node_id = f"{start_id_prefix}_{node_counter-1:03d}"
    last_file = os.path.join(output_dir, f"{last_node_id}.json")
    if os.path.exists(last_file):
        with open(last_file, 'r', encoding='utf-8') as f:
            last_data = json.load(f)
        last_data['next_node_id'] = None
        with open(last_file, 'w', encoding='utf-8') as f:
            json.dump(last_data, f, ensure_ascii=False, indent=2)

    print(f"Generated {node_counter-1} nodes in {output_dir}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("input", help="Input Markdown file")
    parser.add_argument("output", help="Output Directory")
    parser.add_argument("prefix", help="Node ID Prefix (e.g. seocho_1_1)")
    args = parser.parse_args()
    
    parse_markdown(args.input, args.output, args.prefix)
