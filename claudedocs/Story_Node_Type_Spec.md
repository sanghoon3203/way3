# VNNode 타입 확장 설계 메모

## 개요

스토리 노드를 단일 `dialogue_text` 기반으로 처리하던 기존 구조를 확장해, 다음과 같은 타입을 지원하도록 설계했습니다.

| 타입 | 설명 | 대표 필드 |
|------|------|-----------|
| `dialogue` | 기존과 동일한 선형 대사 노드 | `text`, `speaker_id`, `background_image`, `character_sprite`, `next_node_id` |
| `decision` | 플레이어 선택지가 포함된 분기 노드 | `prompt`, `choices[].id`, `choices[].text`, `choices[].next_node_id` |
| `conditional` | 진행 상태를 검사해 자동 분기하는 노드 | `condition.type`, `condition.value`, `on_success`, `on_failure` |
| `quest_gate` | 특정 퀘스트 생성/검증 후 흐름을 제어하는 노드 | `quest_id`, `auto_start`, `next_node_id` |

모든 노드는 `node_id`와 `type`을 공통으로 가지며, `type`이 명시되지 않은 경우 레거시 `dialogue`로 간주합니다.

## JSON 예시

```jsonc
{
  "node_id": "gangnam_choice_01",
  "type": "decision",
  "dialogue": {
    "text": "서예나는 당신에게 두 가지 제안을 건넵니다.",
    "speaker_id": "merchant_seoyena",
    "background_image": "gangnam_rooftop"
  },
  "decision": {
    "prompt": "어떤 방법으로 조사할까요?",
    "choices": [
      { "id": "choice_a", "text": "경매장을 역추적한다", "next_node_id": "gangnam_trace_start" },
      { "id": "choice_b", "text": "서예나의 네트워크를 활용한다", "next_node_id": "gangnam_network_start" }
    ]
  }
}
```

## StoryView 처리 흐름

1. `VNLoader`가 `type`에 따라 `VNNode`를 파싱하고, 레거시 필드는 자동으로 새 구조에 병합합니다.
2. `StoryView`는 `node.type`을 기준으로 UI를 분기합니다.
   - `dialogue`: 기존 타이핑 UI + `BottomProceedBar`.
   - `decision`: 타이핑된 프롬프트 + `DecisionChoiceList` 버튼.
   - `conditional`: `StoryUnlockCondition`을 즉시 평가하여 성공/실패 분기.
   - `quest_gate`: `MainQuestRepository`와 `QuestManager`를 이용해 퀘스트를 생성한 뒤 다음 노드로 이동.
3. 분기 선택/조건 판단 시 `advance(to:)`를 통해 다음 노드를 비동기적으로 로드합니다.

## 호환성 전략

- `dialogue_text`, `background_image`, `character_id`, `next_node_id` 등 기존 키가 존재할 경우 자동으로 `dialogue` 구조에 병합합니다.
- `type` 키가 비어 있으면 `dialogue`로 간주하여 기존 JSON을 수정 없이 사용할 수 있습니다.
- 선택지/조건/퀘스트 데이터가 준비되지 않은 노드는 `PendingNodeOverlay`로 플레이어에게 안내 후 자동 처리됩니다.

## TODO

- `quest_gate`에서 서브 퀘스트와 메인 퀘스트를 구분할 수 있는 추가 메타(`scope`, `quest_type`) 도입.
- `decision` 노드에 선택지별 보상/조건을 정의할 수 있는 확장 (`choice.condition`, `choice.rewards`).
- StoryEditor용 JSON 템플릿 및 검증 스크립트 작성.
