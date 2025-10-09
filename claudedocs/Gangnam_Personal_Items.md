# 강남권 Personal Items & Key Item 정의

**챕터**: Chapter 1 - 황금탑의 균형
**권역**: 강남권
**Personal Item 개수**: 5개
**Key Item**: 1개

---

## Personal Items 개요

Personal Item은 각 상인으로부터 받는 특별한 장비 아이템입니다.
- **획득 방식**: 메인 스토리 진행 중 각 상인과의 만남에서 자동 획득
- **용도**: 스토리 진행 필수 (피날레에서 5개 모두 필요), 장착 시 버프 효과
- **특징**: 거래 불가, 판매 불가, 고유 아이템
- **장착 슬롯**: Equipment 슬롯 (동시 장착 가능)

---

## 1. 로데오 아레나 전용 가면 (Rodeo Arena Mask)

### 기본 정보
- **Item ID**: `personal_item_seoyena_mask`
- **한글명**: 로데오 아레나 전용 가면
- **영문명**: Rodeo Arena Exclusive Mask
- **등급**: Rare (★★★)
- **카테고리**: Equipment (Accessory)
- **제공 상인**: 서예나 (Seoyena)

### 아이템 설명
```
압구정 로데오 아레나에서만 사용되는 특별한 가면.
익명 경매 참가 시 신원을 보호하며,
착용자의 탐욕을 가려주는 신비한 힘이 있다.

서예나가 수호자에게 직접 건넨 유일한 가면.

"탐욕을 가리고, 진정한 가치를 보세요."
- 서예나
```

### 효과 (버프)
- **협상력**: +15%
- **탐욕 저항**: +20%
- **신원 보호**: 익명성 보장

### 획득 조건
- 메인 퀘스트 `main_quest_gangnam_01` 완료
- 서예나와의 대화 완료

### 데이터베이스 스펙
```json
{
  "id": "personal_item_seoyena_mask",
  "name": "로데오 아레나 전용 가면",
  "name_en": "Rodeo Arena Exclusive Mask",
  "description": "압구정 로데오 아레나에서만 사용되는 특별한 가면. 익명 경매 참가 시 신원을 보호하며, 착용자의 탐욕을 가려주는 신비한 힘이 있다.",
  "rarity": "rare",
  "category": "equipment",
  "equipment_type": "accessory",
  "price": 0,
  "is_tradable": false,
  "is_sellable": false,
  "effects": {
    "negotiation_power": 15,
    "greed_resistance": 20,
    "anonymity": true
  },
  "merchant_id": "merchant_seoyena",
  "chapter_id": "chapter_1_gangnam",
  "quest_id": "main_quest_gangnam_01"
}
```

---

## 2. 라부지에 회복 포션 (Labuget Recovery Potion)

### 기본 정보
- **Item ID**: `personal_item_alicegang_potion`
- **한글명**: 라부지에 회복 포션
- **영문명**: Labuget Recovery Potion
- **등급**: Rare (★★★)
- **카테고리**: Equipment (Consumable/Reusable)
- **제공 상인**: 앨리스 강 (Alicegang)

### 아이템 설명
```
프티프랑스 마법학교 전통 레시피로 제조된 고급 회복 포션.
앨리스 강이 직접 조제한 마지막 고급 물약.

한 번 사용해도 마법의 힘으로 재생되어,
영구적으로 사용할 수 있다.

"제 마음을 담아 만든 물약이에요."
- 앨리스 강
```

### 효과 (버프)
- **HP 회복**: +60% (사용 시)
- **독 해제**: 모든 독 상태이상 제거
- **마법 저항**: +10% (장착 시 상시)
- **재생 가능**: 무한 사용 (쿨타임: 24시간)

### 획득 조건
- 메인 퀘스트 `main_quest_gangnam_02` 완료
- 앨리스 강과의 대화 완료

### 데이터베이스 스펙
```json
{
  "id": "personal_item_alicegang_potion",
  "name": "라부지에 회복 포션",
  "name_en": "Labuget Recovery Potion",
  "description": "프티프랑스 마법학교 전통 레시피로 제조된 고급 회복 포션. 앨리스 강이 직접 조제한 마지막 고급 물약. 한 번 사용해도 마법의 힘으로 재생되어, 영구적으로 사용할 수 있다.",
  "rarity": "rare",
  "category": "equipment",
  "equipment_type": "consumable_reusable",
  "price": 0,
  "is_tradable": false,
  "is_sellable": false,
  "effects": {
    "hp_recovery": 60,
    "poison_cure": true,
    "magic_resistance": 10,
    "reusable": true,
    "cooldown_hours": 24
  },
  "merchant_id": "merchant_alicegang",
  "chapter_id": "chapter_1_gangnam",
  "quest_id": "main_quest_gangnam_02"
}
```

---

## 3. 원더랜드 지팡이 (Wonderland Wand)

### 기본 정보
- **Item ID**: `personal_item_anipark_wand`
- **한글명**: 원더랜드 지팡이
- **영문명**: Wonderland Wand
- **등급**: Rare (★★★)
- **카테고리**: Equipment (Weapon)
- **제공 상인**: 애니박 (Anipark)

### 아이템 설명
```
레이크사이드 원더랜드의 공주가 사용하는 특별한 지팡이.
드림크리스탈의 힘이 담겨 있어,
착용자의 카리스마와 행복감을 증폭시킨다.

원래는 마법 연출용이었으나,
수호자가 사용하면 진짜 마법이 발동된다.

"당신이라면 진짜 마법을 쓸 수 있어요."
- 애니박
```

### 효과 (버프)
- **카리스마**: +20%
- **꿈 저항**: +15% (허위 정보 및 환상 저항)
- **행복감**: +10% (정신력 회복 속도 증가)
- **드림 부스트**: 드림크리스탈 관련 아이템 효과 +25%

### 획득 조건
- 메인 퀘스트 `main_quest_gangnam_03` 완료
- 애니박과의 대화 완료

### 데이터베이스 스펙
```json
{
  "id": "personal_item_anipark_wand",
  "name": "원더랜드 지팡이",
  "name_en": "Wonderland Wand",
  "description": "레이크사이드 원더랜드의 공주가 사용하는 특별한 지팡이. 드림크리스탈의 힘이 담겨 있어, 착용자의 카리스마와 행복감을 증폭시킨다.",
  "rarity": "rare",
  "category": "equipment",
  "equipment_type": "weapon",
  "price": 0,
  "is_tradable": false,
  "is_sellable": false,
  "effects": {
    "charisma": 20,
    "dream_resistance": 15,
    "happiness": 10,
    "dream_crystal_boost": 25
  },
  "merchant_id": "merchant_anipark",
  "chapter_id": "chapter_1_gangnam",
  "quest_id": "main_quest_gangnam_03"
}
```

---

## 4. 테라하우스 특제 원두 (Terra House Special Beans)

### 기본 정보
- **Item ID**: `personal_item_jinbaekho_coffee`
- **한글명**: 테라하우스 특제 원두
- **영문명**: Terra House Special Coffee Beans
- **등급**: Rare (★★★)
- **카테고리**: Equipment (Consumable/Reusable)
- **제공 상인**: 진백호 (Jinbaekho)

### 아이템 설명
```
천호동 테라 커피하우스의 진백호가 직접 블렌딩한 특제 원두.
한강의 맑은 기운과 장인의 정성이 담겨 있다.

한 번 추출해도 마법의 힘으로 원두가 재생되어,
영구적으로 사용할 수 있다.

"커피는 탐욕이 아니라 정성이에요."
- 진백호
```

### 효과 (버프)
- **집중력**: +25%
- **피로 회복**: +20%
- **정보력**: +15% (정보 수집 능력 향상)
- **재생 가능**: 무한 사용 (쿨타임: 12시간)
- **진정 효과**: 정신 상태이상 저항 +10%

### 획득 조건
- 메인 퀘스트 `main_quest_gangnam_04` 완료
- 진백호와의 대화 완료

### 데이터베이스 스펙
```json
{
  "id": "personal_item_jinbaekho_coffee",
  "name": "테라하우스 특제 원두",
  "name_en": "Terra House Special Coffee Beans",
  "description": "천호동 테라 커피하우스의 진백호가 직접 블렌딩한 특제 원두. 한강의 맑은 기운과 장인의 정성이 담겨 있다. 한 번 추출해도 마법의 힘으로 원두가 재생되어, 영구적으로 사용할 수 있다.",
  "rarity": "rare",
  "category": "equipment",
  "equipment_type": "consumable_reusable",
  "price": 0,
  "is_tradable": false,
  "is_sellable": false,
  "effects": {
    "concentration": 25,
    "fatigue_recovery": 20,
    "information_power": 15,
    "mental_resistance": 10,
    "reusable": true,
    "cooldown_hours": 12
  },
  "merchant_id": "merchant_jinbaekho",
  "chapter_id": "chapter_1_gangnam",
  "quest_id": "main_quest_gangnam_04"
}
```

---

## 5. 일륜도 (Ilryundo Sword)

### 기본 정보
- **Item ID**: `personal_item_jubulsu_sword`
- **한글명**: 일륜도
- **영문명**: Ilryundo Sword
- **등급**: Rare (★★★)
- **카테고리**: Equipment (Weapon)
- **제공 상인**: 주블수 (Jubulsu)

### 아이템 설명
```
크래프트타운 상인회 회장 주블수가 직접 제작한 실용검.
화려하지 않지만, 견고하고 믿을 수 있는 명검.

장인의 정신과 전통이 담겨 있어,
착용자의 공격력과 방어력을 동시에 높여준다.

"명검은 탐욕이 아니라 정성으로 만들어집니다."
- 주블수
```

### 효과 (버프)
- **공격력**: +30%
- **방어력**: +20%
- **장인 정신**: +25% (제작 관련 능력 향상)
- **내구도**: 무한 (절대 파괴되지 않음)
- **균형 강화**: 공격/방어 밸런스 최적화

### 획득 조건
- 메인 퀘스트 `main_quest_gangnam_05` 완료
- 주블수와의 대화 완료

### 데이터베이스 스펙
```json
{
  "id": "personal_item_jubulsu_sword",
  "name": "일륜도",
  "name_en": "Ilryundo Sword",
  "description": "크래프트타운 상인회 회장 주블수가 직접 제작한 실용검. 화려하지 않지만, 견고하고 믿을 수 있는 명검. 장인의 정신과 전통이 담겨 있어, 착용자의 공격력과 방어력을 동시에 높여준다.",
  "rarity": "rare",
  "category": "equipment",
  "equipment_type": "weapon",
  "price": 0,
  "is_tradable": false,
  "is_sellable": false,
  "effects": {
    "attack_power": 30,
    "defense_power": 20,
    "craftsmanship": 25,
    "durability": "infinite",
    "balance_bonus": true
  },
  "merchant_id": "merchant_jubulsu",
  "chapter_id": "chapter_1_gangnam",
  "quest_id": "main_quest_gangnam_05"
}
```

---

## Key Item: 강남의 증표

### 기본 정보
- **Item ID**: `key_item_gangnam`
- **한글명**: 강남의 증표
- **영문명**: Emblem of Gangnam
- **등급**: Legendary (★★★★★)
- **카테고리**: Key Item (Quest Item)
- **획득 방법**: 5개 Personal Item 모두 소지 시 자동 생성

### 아이템 설명
```
강남권의 균형이 회복되었음을 증명하는 황금빛 증표.

다섯 명의 상인이 전한 진심이 하나로 모여,
탐욕과 번영의 균형을 상징하는 빛으로 결정화되었다.

이 증표를 가진 자는 강남권의 수호자로 인정받는다.

"균형을 되찾은 자에게 주어지는 영광입니다."
- 서예나, 앨리스, 애니박, 진백호, 주블수
```

### 효과
- **권역 완료 증명**: 강남권 챕터 완료 표시
- **최종 챕터 언락**: 5개 권역 증표 수집 시 최종 챕터 언락
- **강남권 특혜**: 강남권 모든 상인과의 거래 시 10% 할인
- **명성**: +50
- **칭호 획득**: "강남의 수호자"

### 획득 조건
- 5개 Personal Item 모두 소지:
  1. `personal_item_seoyena_mask`
  2. `personal_item_alicegang_potion`
  3. `personal_item_anipark_wand`
  4. `personal_item_jinbaekho_coffee`
  5. `personal_item_jubulsu_sword`
- 메인 퀘스트 `main_quest_gangnam_final` 완료

### 데이터베이스 스펙
```json
{
  "id": "key_item_gangnam",
  "name": "강남의 증표",
  "name_en": "Emblem of Gangnam",
  "description": "강남권의 균형이 회복되었음을 증명하는 황금빛 증표. 다섯 명의 상인이 전한 진심이 하나로 모여, 탐욕과 번영의 균형을 상징하는 빛으로 결정화되었다.",
  "rarity": "legendary",
  "category": "key_item",
  "price": 0,
  "is_tradable": false,
  "is_sellable": false,
  "effects": {
    "chapter_completion": "chapter_1_gangnam",
    "final_chapter_unlock_requirement": true,
    "gangnam_discount": 10,
    "reputation": 50,
    "title": "강남의 수호자"
  },
  "required_items": [
    "personal_item_seoyena_mask",
    "personal_item_alicegang_potion",
    "personal_item_anipark_wand",
    "personal_item_jinbaekho_coffee",
    "personal_item_jubulsu_sword"
  ],
  "chapter_id": "chapter_1_gangnam",
  "quest_id": "main_quest_gangnam_final"
}
```

---

## Personal Item 체크 로직 (VNNode 조건문)

### 피날레 Scene에서의 체크 로직

```swift
// ProgressManager에서 Personal Item 체크
func hasAllGangnamPersonalItems() -> Bool {
    let requiredItems = [
        "personal_item_seoyena_mask",
        "personal_item_alicegang_potion",
        "personal_item_anipark_wand",
        "personal_item_jinbaekho_coffee",
        "personal_item_jubulsu_sword"
    ]

    // 플레이어 인벤토리에서 모든 아이템 소지 확인
    return requiredItems.allSatisfy { itemId in
        InventoryManager.shared.hasItem(itemId)
    }
}

// Key Item 자동 생성
func generateKeyItem() {
    if hasAllGangnamPersonalItems() {
        InventoryManager.shared.addItem("key_item_gangnam")
        ProgressManager.shared.acquireKeyItem("key_item_gangnam")
    }
}
```

### VNNode JSON 조건문 예시

```json
{
  "id": "gangnam_finale_check",
  "type": "conditional",
  "condition": {
    "type": "items_check",
    "required_items": [
      "personal_item_seoyena_mask",
      "personal_item_alicegang_potion",
      "personal_item_anipark_wand",
      "personal_item_jinbaekho_coffee",
      "personal_item_jubulsu_sword"
    ],
    "operator": "all"
  },
  "on_success": "gangnam_finale_key_item_generation",
  "on_failure": "gangnam_finale_incomplete_warning"
}
```

---

## 아이템 효과 종합 정리

### 전체 버프 효과 (5개 모두 장착 시)

| 효과 종류 | 수치 | 제공 아이템 |
|-----------|------|-------------|
| 협상력 | +15% | 로데오 가면 |
| 탐욕 저항 | +20% | 로데오 가면 |
| HP 회복 | +60% | 라부지에 포션 |
| 마법 저항 | +10% | 라부지에 포션 |
| 카리스마 | +20% | 원더랜드 지팡이 |
| 꿈 저항 | +15% | 원더랜드 지팡이 |
| 행복감 | +10% | 원더랜드 지팡이 |
| 집중력 | +25% | 테라하우스 원두 |
| 피로 회복 | +20% | 테라하우스 원두 |
| 정보력 | +15% | 테라하우스 원두 |
| 공격력 | +30% | 일륜도 |
| 방어력 | +20% | 일륜도 |
| 장인 정신 | +25% | 일륜도 |

### 특수 효과
- **재생 가능 아이템**: 라부지에 포션 (24시간), 테라하우스 원두 (12시간)
- **무한 내구도**: 일륜도
- **익명성 보장**: 로데오 가면
- **독 해제**: 라부지에 포션
- **드림크리스탈 부스트**: 원더랜드 지팡이 (+25%)

---

## 서버 데이터베이스 등록

### SQL 스크립트 (item_templates 테이블)

```sql
-- Personal Items 등록

INSERT INTO item_templates (
  id, name, name_en, description, rarity, category,
  equipment_type, price, is_tradable, is_sellable, effects, merchant_id
) VALUES
(
  'personal_item_seoyena_mask',
  '로데오 아레나 전용 가면',
  'Rodeo Arena Exclusive Mask',
  '압구정 로데오 아레나에서만 사용되는 특별한 가면. 익명 경매 참가 시 신원을 보호하며, 착용자의 탐욕을 가려주는 신비한 힘이 있다.',
  'rare',
  'equipment',
  'accessory',
  0,
  0,
  0,
  '{"negotiation_power":15,"greed_resistance":20,"anonymity":true}',
  'merchant_seoyena'
),
(
  'personal_item_alicegang_potion',
  '라부지에 회복 포션',
  'Labuget Recovery Potion',
  '프티프랑스 마법학교 전통 레시피로 제조된 고급 회복 포션. 앨리스 강이 직접 조제한 마지막 고급 물약.',
  'rare',
  'equipment',
  'consumable_reusable',
  0,
  0,
  0,
  '{"hp_recovery":60,"poison_cure":true,"magic_resistance":10,"reusable":true,"cooldown_hours":24}',
  'merchant_alicegang'
),
(
  'personal_item_anipark_wand',
  '원더랜드 지팡이',
  'Wonderland Wand',
  '레이크사이드 원더랜드의 공주가 사용하는 특별한 지팡이. 드림크리스탈의 힘이 담겨 있어, 착용자의 카리스마와 행복감을 증폭시킨다.',
  'rare',
  'equipment',
  'weapon',
  0,
  0,
  0,
  '{"charisma":20,"dream_resistance":15,"happiness":10,"dream_crystal_boost":25}',
  'merchant_anipark'
),
(
  'personal_item_jinbaekho_coffee',
  '테라하우스 특제 원두',
  'Terra House Special Coffee Beans',
  '천호동 테라 커피하우스의 진백호가 직접 블렌딩한 특제 원두. 한강의 맑은 기운과 장인의 정성이 담겨 있다.',
  'rare',
  'equipment',
  'consumable_reusable',
  0,
  0,
  0,
  '{"concentration":25,"fatigue_recovery":20,"information_power":15,"mental_resistance":10,"reusable":true,"cooldown_hours":12}',
  'merchant_jinbaekho'
),
(
  'personal_item_jubulsu_sword',
  '일륜도',
  'Ilryundo Sword',
  '크래프트타운 상인회 회장 주블수가 직접 제작한 실용검. 화려하지 않지만, 견고하고 믿을 수 있는 명검.',
  'rare',
  'equipment',
  'weapon',
  0,
  0,
  0,
  '{"attack_power":30,"defense_power":20,"craftsmanship":25,"durability":"infinite","balance_bonus":true}',
  'merchant_jubulsu'
);

-- Key Item 등록

INSERT INTO item_templates (
  id, name, name_en, description, rarity, category,
  price, is_tradable, is_sellable, effects
) VALUES
(
  'key_item_gangnam',
  '강남의 증표',
  'Emblem of Gangnam',
  '강남권의 균형이 회복되었음을 증명하는 황금빛 증표. 다섯 명의 상인이 전한 진심이 하나로 모여, 탐욕과 번영의 균형을 상징하는 빛으로 결정화되었다.',
  'legendary',
  'key_item',
  0,
  0,
  0,
  '{"chapter_completion":"chapter_1_gangnam","gangnam_discount":10,"reputation":50,"title":"강남의 수호자"}'
);
```

---

**작성일**: 2025-10-10
**버전**: 1.0.0
**Personal Item 수**: 5개
**Key Item 수**: 1개
**총 아이템 효과**: 13종 버프
