"""
WAY3 Story Data Build Script
개별 JSON 노드 파일들을 하나의 통합 JSON 파일로 병합합니다.

사용법: python build_story_data.py
"""

import os
import json
from pathlib import Path

# 경로 설정
BASE_DIR = Path(__file__).parent
STORY_DATA_PATH = BASE_DIR / "way3" / "StoryData"
OUTPUT_PATH = BASE_DIR / "way3-web" / "src" / "data" / "story"

# 챕터 정의
CHAPTERS = [
    {"folder": "Prologue", "id": "prologue", "title": "프롤로그"},
    {"folder": "Gangnam", "id": "gangnam", "title": "강남"},
    {"folder": "Seocho", "id": "seocho", "title": "서초"},
    {"folder": "Songpa", "id": "songpa", "title": "송파"},
    {"folder": "Gangdong", "id": "gangdong", "title": "강동"},
]


def normalize_next_node_id(next_node_id):
    """next_node_id 정규화 (.json 확장자 제거)"""
    if not next_node_id or next_node_id == "":
        return None
    return next_node_id.replace(".json", "")


def normalize_node(node):
    """노드 데이터 정규화"""
    return {
        "node_id": node.get("node_id", ""),
        "background_image": node.get("background_image") or None,
        "character_id": node.get("character_id", ""),
        "character_sprite": node.get("character_sprite") or None,
        "dialogue_text": node.get("dialogue_text", ""),
        "dialogue_sound_id": node.get("dialogue_sound_id") or None,
        "sound_effect": node.get("sound_effect") or None,
        "next_node_id": normalize_next_node_id(node.get("next_node_id")),
    }


def read_json_files_from_folder(folder_path):
    """폴더 내의 모든 JSON 파일을 읽어서 배열로 반환"""
    if not folder_path.exists():
        print(f"⚠️  폴더가 존재하지 않습니다: {folder_path}")
        return []

    files = sorted(
        [f for f in folder_path.glob("*.json") if "gate" not in f.name],
        key=lambda f: int("".join(filter(str.isdigit, f.stem)) or 0),
    )

    nodes = []
    for file in files:
        try:
            with open(file, "r", encoding="utf-8") as f:
                node = json.load(f)
                nodes.append(normalize_node(node))
        except Exception as e:
            print(f"❌ 파일 읽기 오류: {file.name} - {e}")

    return nodes


def build_chapter(chapter):
    """챕터 데이터 빌드"""
    print(f"\n📖 {chapter['title']} ({chapter['id']}) 빌드 중...")

    folder_path = STORY_DATA_PATH / chapter["folder"]
    nodes = read_json_files_from_folder(folder_path)

    if not nodes:
        print("   ⏭️  노드가 없습니다. 건너뜁니다.")
        return None

    result = {
        "id": chapter["id"],
        "title": chapter["title"],
        "nodeCount": len(nodes),
        "startNodeId": nodes[0]["node_id"] if nodes else None,
        "nodes": nodes,
    }

    print(f"   ✅ {len(nodes)}개 노드 로드 완료")
    print(f"   📍 시작 노드: {result['startNodeId']}")

    return result


def ensure_output_dir():
    """출력 폴더 생성"""
    OUTPUT_PATH.mkdir(parents=True, exist_ok=True)
    print(f"📁 출력 폴더: {OUTPUT_PATH}")


def build():
    """메인 빌드 함수"""
    print("🚀 WAY3 Story Data Build 시작...\n")
    print(f"📂 소스: {STORY_DATA_PATH}")
    print(f"📂 출력: {OUTPUT_PATH}")

    ensure_output_dir()

    all_chapters = []

    for chapter in CHAPTERS:
        result = build_chapter(chapter)

        if result:
            # 개별 챕터 파일 저장
            output_file = OUTPUT_PATH / f"{chapter['id']}.json"
            with open(output_file, "w", encoding="utf-8") as f:
                json.dump(result, f, ensure_ascii=False, indent=2)
            print(f"   💾 저장: {output_file}")

            all_chapters.append({
                "id": chapter["id"],
                "title": chapter["title"],
                "nodeCount": result["nodeCount"],
                "startNodeId": result["startNodeId"],
            })

    # 인덱스 파일 생성
    from datetime import datetime

    index_file = OUTPUT_PATH / "index.json"
    with open(index_file, "w", encoding="utf-8") as f:
        json.dump(
            {
                "version": "1.0.0",
                "buildTime": datetime.now().isoformat(),
                "chapters": all_chapters,
            },
            f,
            ensure_ascii=False,
            indent=2,
        )

    total_nodes = sum(c["nodeCount"] for c in all_chapters)
    print("\n" + "=" * 40)
    print("✅ 빌드 완료!")
    print(f"📊 총 {len(all_chapters)}개 챕터, {total_nodes}개 노드")
    print("=" * 40 + "\n")


if __name__ == "__main__":
    build()
