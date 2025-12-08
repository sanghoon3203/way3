# Story Data Creation Guide

This document outlines the standard JSON structure for creating story data in the Way3 project.

## File Naming Convention
- Files should be named sequentially: `character_subX_YYY.json` or `chapter_district_YYY.json`.
- `X`: Substory number (e.g., 1, 2, 3).
- `YYY`: Sequence number (e.g., 001, 002, 010).

## JSON Structure

Each story node is a single JSON object with the following fields:

| Field | Type | Description | Handling Rules |
| :--- | :--- | :--- | :--- |
| `node_id` | String | Unique identifier for the current node. | Format: `subX_YYY` (e.g., `sub1_001`). Matches the file's sequence number. |
| `background_image` | String? | Filename of the background image. | Set ONLY when the background changes. Otherwise, set to `null` to persist the previous background. |
| `character_id` | String | Name of the speaker. | e.g., "서예나", "플레이어", "직원". Use "Narrator" or empty string for narration. |
| `character_sprite` | String? | Filename of the character sprite to display. | Set to `null` by default unless a visual change is required. |
| `dialogue_text` | String | The actual dialogue or narration text. | One line per JSON file. |
| `dialogue_sound_id` | String? | ID for voiceover or specific dialogue sound. | Set to `null`. |
| `sound_effect` | String? | ID for background sound effects. | Set to `null`. |
| `next_node_id` | String? | ID of the next node in the sequence. | Format: `subX_YYY` (next number). Set to `null` for the final node of a chapter. |

## Example

```json
{
  "node_id": "sub1_001",
  "background_image": "bg_rodeo_inside",
  "character_id": "Narrator",
  "character_sprite": null,
  "dialogue_text": "처음 들어온 로데오 아레나 내부는 황금빛으로 반짝였다.",
  "dialogue_sound_id": null,
  "sound_effect": null,
  "next_node_id": "sub1_002"
}
```

## Workflow
1. Write the full script in a Markdown file (e.g., `seoyena_sub1-3.md`).
2. Break down the script into individual lines.
3. Create a JSON file for each line, incrementing the `node_id` and `next_node_id`.
4. Manage `background_image` changes only when the scene transitions in the script.
