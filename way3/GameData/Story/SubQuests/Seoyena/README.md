# 서예나 서브 퀘스트 데이터

서예나의 3단계 서브 퀘스트 시스템 - 대화, 위치, 거래

## 📁 파일 구조

```
SubQuests/Seoyena/
├── README.md                                    # 이 파일
├── subquest_seoyena_01_dialogue.json           # 서브 퀘스트 1: 대화형
├── subquest_seoyena_02_location.json           # 서브 퀘스트 2: 위치형
├── subquest_seoyena_03_trading.json            # 서브 퀘스트 3: 거래형
└── story_nodes_seoyena_substories.json         # 스토리 노드 데이터
```

## 🎯 퀘스트 개요

### 서브 퀘스트 1: 서예나의 심문 (dialogue)
- **퀘스트 ID**: `subquest_seoyena_01_dialogue`
- **타입**: 대화 완료형
- **노드**: /021 ~ /035 (15개)
- **목표**: 서예나의 3가지 질문에 답하기
- **보상**: 친밀도 +10, 경험치 +200, 로데오 아레나 임시 출입증

### 서브 퀘스트 2: 강남의 숨은 명소 (location)
- **퀘스트 ID**: `subquest_seoyena_02_location`
- **타입**: GPS 위치 인증형
- **노드**: /036 ~ /053 (18개)
- **목표**: 3곳의 명소 방문 및 증표 획득
  1. 현대 모터 스튜디오 서울 → 미래의 증표
  2. 봉은사 → 고요의 증표
  3. 코엑스 별마당 도서관 → 지혜의 증표
- **보상**: 친밀도 +10, 경험치 +300, 3가지 증표

### 서브 퀘스트 3: 강남의 맛 (trading)
- **퀘스트 ID**: `subquest_seoyena_03_trading`
- **타입**: 영수증 OCR 인증형
- **노드**: /054 ~ /068 (15개)
- **목표**: 2곳에서 구매 및 영수증 제출
  1. 히트커피로스터스 신사 → 시그니처 원두 (25,000원)
  2. 양재천 카페거리 → 디저트 (자유 선택, 8,000원 예상)
- **보상**: 친밀도 +10, 경험치 +500, 골드 +2,000, VIP 카드, 개인 연락처

## 🔄 퀘스트 흐름

```
메인 스토리 /020 완료
  ↓
[서브 1] 대화 (dialogue)
  ↓ 친밀도 0 → 10
[서브 2] 위치 (location)
  ↓ 친밀도 10 → 20
[서브 3] 거래 (trading)
  ↓ 친밀도 20 → 30
메인 스토리 Act 3 해금
```

## 📊 데이터 구조

### 1. 퀘스트 메타데이터 (subquest_*.json)

```json
{
  "quest_id": "고유 퀘스트 ID",
  "quest_type": "dialogue | delivery | trading",
  "title": "퀘스트 제목",
  "description": "퀘스트 설명",
  "unlock_conditions": [],
  "objectives": [],
  "rewards": {},
  "post_completion": {}
}
```

### 2. 스토리 노드 (story_nodes_*.json)

```json
{
  "node_id": "고유 노드 ID (예: seoyena_sub1_021)",
  "quest_id": "연결된 퀘스트 ID",
  "title": "노드 제목",
  "order": 21,
  "content": {
    "text": ["대화 텍스트 배열"],
    "speaker": "화자",
    "background": "배경 ID",
    "bgm": "BGM ID",
    "character_sprites": []
  },
  "choices": [],
  "next_node": "다음 노드 ID",
  "auto_advance": true/false
}
```

## 🎮 게임 시스템 연동

### 1. 친밀도 시스템
```typescript
interface FriendshipReward {
  merchant_id: string;
  amount: number;
  final_level: number;
}
```

### 2. GPS 위치 인증
```typescript
interface GPSLocation {
  name: string;
  coordinates: {
    latitude: number;
    longitude: number;
  };
  radius: number; // 인증 반경 (미터)
}
```

### 3. OCR 영수증 인증
```typescript
interface OCRVerification {
  required_fields: string[];
  date_validation: string;
  min_confidence: number;
  retry_attempts: number;
}
```

## 🗺️ 실제 위치 정보

### 서브 퀘스트 2 - GPS 위치
1. **현대 모터 스튜디오 서울**
   - 주소: 서울특별시 강남구 테헤란로 152 GBC 빌딩
   - 좌표: 37.5015, 127.0395
   - 반경: 50m

2. **봉은사**
   - 주소: 서울특별시 강남구 봉은사로 531
   - 좌표: 37.5147, 127.0591
   - 반경: 100m

3. **코엑스 별마당 도서관**
   - 주소: 서울특별시 강남구 영동대로 513 코엑스몰 1층
   - 좌표: 37.5126, 127.0591
   - 반경: 50m

### 서브 퀘스트 3 - 구매 위치
1. **히트커피로스터스 신사점**
   - 주소: 서울특별시 강남구 논현로153길 24
   - 좌표: 37.5193, 127.0236
   - 반경: 50m
   - 필수 구매: 시그니처 원두 (20,000원 이상)

2. **양재천 카페거리**
   - 주소: 서울특별시 서초구 매헌로 16 일대
   - 좌표: 37.4722, 127.0347
   - 반경: 500m
   - 필수 구매: 디저트 (5,000원 이상, 카페 자유 선택)

## 🔧 구현 가이드

### 1. 퀘스트 활성화
```typescript
// 메인 스토리 /020 완료 시
unlockSubQuest("subquest_seoyena_01_dialogue");

// 각 서브 퀘스트 완료 시 다음 해금
onQuestComplete("subquest_seoyena_01_dialogue", () => {
  unlockSubQuest("subquest_seoyena_02_location");
});
```

### 2. GPS 인증 처리
```typescript
async function verifyGPSLocation(
  questId: string,
  objectiveId: string,
  userLocation: Coordinates
): Promise<boolean> {
  const objective = getObjective(questId, objectiveId);
  const distance = calculateDistance(
    userLocation,
    objective.location.coordinates
  );
  return distance <= objective.location.radius;
}
```

### 3. OCR 영수증 처리
```typescript
async function verifyReceipt(
  questId: string,
  objectiveId: string,
  receiptImage: Image
): Promise<OCRResult> {
  const ocrData = await performOCR(receiptImage);
  const validation = validateReceiptData(
    ocrData,
    getRequiredPurchase(questId, objectiveId)
  );
  return validation;
}
```

## 📝 스토리 노드 확장

현재 스토리 노드 JSON은 주요 노드만 포함하고 있습니다. 전체 48개 노드를 완성하려면:

### 서브 스토리 1: 추가 필요 노드
- /026 ~ /034 (9개): 가치의 정의, 세 번째 질문, 선택, 평가, 다짐, 시험 통과

### 서브 스토리 2: 추가 필요 노드
- /038 ~ /052 (15개): 각 장소의 상세 탐방 과정

### 서브 스토리 3: 추가 필요 노드
- /056 ~ /067 (12개): 커피 구매 과정, 양재천 탐방, 최종 평가

## 🎨 에셋 요구사항

### 배경 (Background)
- `rodeo_arena_lobby`: 로데오 아레나 로비
- `seoyena_office`: 서예나 사무실
- `player_room`: 플레이어 거처
- `gbc_building_exterior`: GBC 빌딩 외관
- `bongeunsa_temple`: 봉은사
- `starfield_library`: 별마당 도서관
- `sinsa_alley`: 신사동 골목
- `yangjaecheon_cafe`: 양재천 카페거리

### 캐릭터 스프라이트 (Seoyena)
- `neutral`: 중립 표정
- `professional`: 프로페셔널
- `serious`: 진지
- `intrigued`: 관심
- `thoughtful`: 사색
- `gentle_smile`: 부드러운 미소
- `encouraging`: 격려
- `warm_smile`: 따뜻한 미소

### BGM
- `gangnam_elegant`: 강남 우아함
- `tension_low`: 낮은 긴장감
- `morning_calm`: 아침의 평온함
- `discovery`: 발견의 음악
- `cafe_ambience`: 카페 분위기

## 📱 UI/UX 통합

### MerchantDetailView 연동
```typescript
// DIALOGUE 탭 클릭 시
onDialogueTabClick(() => {
  if (hasActiveSubQuest("merchant_Seoyena")) {
    loadStoryNode(getCurrentSubQuestNode());
  } else {
    showCompletedSubQuests("merchant_Seoyena");
  }
});
```

### 퀘스트 진행 UI
```typescript
interface QuestProgressUI {
  questTitle: string;
  objectives: ObjectiveStatus[];
  timeRemaining?: number;
  currentStep: string;
}
```

## 🧪 테스트 시나리오

### 1. 대화 퀘스트 테스트
- [ ] 메인 스토리 /020 완료 후 서브 1 활성화 확인
- [ ] 대화 노드 순차 진행 확인
- [ ] 퀘스트 완료 시 보상 지급 확인
- [ ] 친밀도 10 달성 확인

### 2. 위치 퀘스트 테스트
- [ ] GPS 위치 인증 정확도 테스트 (각 반경별)
- [ ] 3곳 모두 방문 완료 확인
- [ ] 증표 아이템 획득 확인
- [ ] 친밀도 20 달성 확인

### 3. 거래 퀘스트 테스트
- [ ] OCR 영수증 인식 정확도 테스트
- [ ] 상호명/아이템명/가격 검증 확인
- [ ] 날짜 유효성 검사 확인
- [ ] VIP 카드 및 연락처 획득 확인
- [ ] 친밀도 30 달성 확인
- [ ] 메인 스토리 Act 3 해금 확인

## 📄 라이센스 및 크레딧

- **작성자**: Claude + User
- **생성일**: 2025-10-16
- **버전**: 1.0
- **프로젝트**: WAY3 - 위치기반 트레이딩 RPG

## 🔗 관련 문서

- [메인 스토리 구조](../../story_main_chapters.json)
- [서예나 캐릭터 프로필](../../../../Story/CharacterStory/강남권_캐릭터들_v2.md)
- [서예나 3단계 구조 설명](../../../../Story/MainStory_New/서예나_3단계_구조_설명.md)
