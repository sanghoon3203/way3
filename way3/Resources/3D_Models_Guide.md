# 📦 3D Player Models Guide

Way3 게임의 3D 플레이어 모델 관리 가이드입니다.

## 🎯 모델 파일 구조

```
way3/Resources/
├── 3D_Models/
│   ├── player_novice_idle.glb      # 초보자 대기 모델
│   ├── player_novice_walking.glb   # 초보자 이동 모델
│   ├── player_trader_idle.glb      # 트레이더 대기 모델
│   ├── player_trader_walking.glb   # 트레이더 이동 모델
│   ├── player_expert_idle.glb      # 전문가 대기 모델
│   ├── player_expert_walking.glb   # 전문가 이동 모델
│   ├── player_master_idle.glb      # 마스터 대기 모델
│   └── player_master_walking.glb   # 마스터 이동 모델
└── 3D_Models_Guide.md
```

## 🎨 모델 제작 가이드라인

### 기술 사양
- **파일 포맷**: glTF 2.0 (.glb) 권장
- **파일 크기**: 2MB 이하
- **폴리곤 수**: 5,000 triangles 이하
- **텍스처 해상도**: 512x512 픽셀 이하
- **애니메이션**: 선택사항 (있으면 자동 재생)

### 모델 방향
- **정면**: Z축 음의 방향 (0, 0, -1)
- **위쪽**: Y축 양의 방향 (0, 1, 0)
- **크기**: 약 1-2 미터 높이의 휴머노이드

### 레벨별 테마
1. **Novice (1-5레벨)**: 간단한 복장, 기본 도구
2. **Trader (6-10레벨)**: 상인복, 가방, 계산기
3. **Expert (11-20레벨)**: 고급 정장, 브리프케이스
4. **Master (21+레벨)**: 화려한 복장, 특별 액세서리

## 🛠️ 제작 도구

### 무료 도구
- **Blender**: https://www.blender.org/
- **SketchUp**: https://www.sketchup.com/
- **Wings 3D**: http://www.wings3d.com/

### 온라인 도구
- **Sketchfab**: https://sketchfab.com/
- **Ready Player Me**: https://readyplayer.me/
- **VRoid Studio**: https://vroid.com/

### 컨버터
- **glTF Validator**: https://github.khronos.org/glTF-Validator/
- **Blender glTF Exporter**: 내장 플러그인

## 📱 iOS 프로젝트 추가 방법

1. **Xcode에서 파일 추가**:
   ```
   Project Navigator → way3 → Add Files to "way3"
   → 3D 모델 파일 선택 → Add to target: way3
   ```

2. **Bundle 리소스 확인**:
   ```
   Target Settings → Build Phases → Copy Bundle Resources
   → 모델 파일들이 포함되어 있는지 확인
   ```

3. **테스트**:
   ```swift
   if let modelURL = Bundle.main.url(forResource: "player_novice_idle", withExtension: "glb") {
       print("모델 파일 찾음: \(modelURL)")
   }
   ```

## 🧪 테스트용 모델

현재 사용 중인 Khronos glTF Sample Models:
- **CesiumMan**: 기본 애니메이션 캐릭터
- **RiggedSimple**: 간단한 리깅 모델
- **BrainStem**: 복잡한 애니메이션 모델

이 모델들은 온라인에서 로드되므로, 실제 배포 시에는 로컬 모델로 교체하는 것이 좋습니다.

## 🎮 MapView 연동

MapView.swift에서 자동으로 다음과 같이 작동합니다:

1. **플레이어 레벨 확인** → 적절한 모델 선택
2. **이동 상태 감지** → idle/walking 모델 전환
3. **거래 상호작용** → 특별한 애니메이션 효과
4. **실시간 위치 추적** → 3D 모델이 따라 이동

## 🔧 문제 해결

### 모델이 표시되지 않는 경우
1. Bundle에 파일이 정확히 추가되었는지 확인
2. 파일명과 확장자가 일치하는지 확인
3. glTF 파일이 유효한지 검증
4. 온라인 모델 URL이 접근 가능한지 확인

### 성능 문제가 있는 경우
1. 폴리곤 수 줄이기 (< 5,000)
2. 텍스처 해상도 낮추기 (512x512)
3. 불필요한 애니메이션 제거
4. 파일 크기 최적화 (< 2MB)

---

## 📞 지원

모델 제작이나 연동에 문제가 있으면 개발팀에 문의하세요.
Mapbox 3D 모델 문서: https://docs.mapbox.com/ios/maps/examples/custom-3D-puck/