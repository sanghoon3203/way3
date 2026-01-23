# 🗺️ 서울을 무대로 한 위치 기반 트레이딩 RPG, Connect:Seoul

![Connect Seoul Banner](https://img.shields.io/badge/Connect:Seoul-Web-00D4FF?style=for-the-badge&logo=react&logoColor=white)
![Next.js](https://img.shields.io/badge/Next.js-16-black?style=for-the-badge&logo=next.js&logoColor=white)
![Status](https://img.shields.io/badge/Status-개발중-yellow?style=for-the-badge)

</div>

## 👨‍🏫 Connect:Seoul Description

**Connect:Seoul**은 서울시 전역을 무대로 한 위치 기반 트레이딩 RPG 게임입니다. 플레이어는 실제 GPS 기반으로 서울 25개 구역에 분산된 상인들과 만나 거래하고, Visual Novel 스타일의 스토리를 경험하며 캐릭터를 성장시킵니다.

사이버펑크 세계관 속 서울에서, 플레이어는 다양한 상인들과의 관계를 쌓아가며 거래 스킬을 발전시키고, 숨겨진 이야기를 발견해 나갑니다. 실제 위치와 연동된 게임플레이로 서울 곳곳을 탐험하며 몰입감 있는 경험을 제공합니다.

### ✨ 핵심 특징
- 🗺️ **실제 위치 연동**: GPS 기반 상인 발견 및 거래 시스템
- 📖 **Visual Novel 스토리**: 상인과의 대화, 선택지, 분기 시스템
- 💰 **거래 시뮬레이션**: 아이템 매입/매도를 통한 수익 창출
- 🎮 **미니게임**: 다양한 인터랙티브 게임 요소
- 📱 **반응형 웹**: 모바일 최적화된 웹 인터페이스

## ⏲ Development Timeline

> 2024.12 ~ 현재 (개발 진행 중)

## 👨‍👩‍👦‍👦 Developer

<table>
  <thead>
    <tr>
      <th>팀장 김상훈</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center"><img src="https://avatars.githubusercontent.com/u/80574796?v=4" width="100px;" alt="김상훈"/></td>
    </tr>
    <tr>
      <td align="center"><a href="https://github.com/sanghoon3203">@sanghoon3203</a></td>
    </tr>
    <tr>
      <td align="center">Full-Stack Developer</td>
    </tr>
  </tbody>
</table>

## 🚀 Main Feature

### 📌 GPS 기반 상인 발견
- 실제 위치를 기반으로 서울 25개 구역에 분산된 상인들을 발견할 수 있습니다.
- GPS 시뮬레이터를 통해 웹에서도 가상 위치로 테스트할 수 있습니다.

### 📌 Visual Novel 스토리 엔진
- 상인별 고유한 스토리라인과 대화 시스템을 제공합니다.
- 선택지에 따라 다양한 분기와 결말을 경험할 수 있습니다.

### 📌 실시간 거래 시스템
- 아이템 매입/매도를 통해 수익을 창출하고 캐릭터를 성장시킵니다.
- 거래 스킬과 협상 능력에 따라 가격이 변동됩니다.

### 📌 퀘스트 & 미니게임
- 다양한 퀘스트를 완료하여 보상을 획득합니다.
- 미니게임을 통해 추가적인 재화와 아이템을 얻을 수 있습니다.

### 📌 인벤토리 관리
- 보유 아이템을 관리하고 창고 시스템을 활용할 수 있습니다.

## 🔧 Stack

### Environment
![VSCode](https://img.shields.io/badge/VS_Code-007ACC?style=for-the-badge&logo=visual-studio-code&logoColor=white)
![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=Git&logoColor=white)
![Github](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=GitHub&logoColor=white)

### Development
![Next.js](https://img.shields.io/badge/Next.js-000000?style=for-the-badge&logo=next.js&logoColor=white)
![React](https://img.shields.io/badge/React-19-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?style=for-the-badge&logo=typescript&logoColor=white)
![Prisma](https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white)
![TailwindCSS](https://img.shields.io/badge/TailwindCSS-4-06B6D4?style=for-the-badge&logo=tailwindcss&logoColor=white)

### Database & Map
![SQLite](https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)
![Mapbox](https://img.shields.io/badge/Mapbox-000000?style=for-the-badge&logo=mapbox&logoColor=white)

### State Management & Animation
![Zustand](https://img.shields.io/badge/Zustand-5-f5a623?style=for-the-badge)
![Framer Motion](https://img.shields.io/badge/Framer_Motion-0055FF?style=for-the-badge&logo=framer&logoColor=white)

### Communication
![Discord](https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white)

## 📂 Project Structure

```
connect-seoul-web/
├── src/
│   ├── app/                    # Next.js App Router
│   │   ├── api/                # REST API Routes
│   │   ├── login/              # 로그인 페이지
│   │   ├── register/           # 회원가입 페이지
│   │   └── recover/            # 비밀번호 복구
│   ├── components/             # 재사용 컴포넌트
│   │   ├── chat/               # 채팅 UI 컴포넌트
│   │   ├── inventory/          # 인벤토리 시스템
│   │   ├── map/                # 지도 & GPS 시뮬레이터
│   │   ├── minigame/           # 미니게임 컴포넌트
│   │   ├── quests/             # 퀘스트 시스템
│   │   ├── story/              # VN 엔진 & 스토리
│   │   └── ui/                 # 공통 UI 컴포넌트
│   ├── data/                   # 스토리 & 게임 데이터 (JSON)
│   └── lib/                    # 유틸리티 & 헬퍼 함수
├── prisma/                     # Prisma 스키마 & 마이그레이션
├── public/                     # 정적 파일 (이미지, 폰트)
└── package.json
```

## 🏃 Getting Started

### Prerequisites
- Node.js 18+
- npm 9+

### Installation

```bash
# 저장소 클론
git clone https://github.com/sanghoon3203/connect-seoul-web.git
cd connect-seoul-web

# 의존성 설치
npm install

# 환경 변수 설정
cp .env.example .env.local
# .env.local 파일에서 필요한 값 수정

# 데이터베이스 초기화
npx prisma generate
npx prisma db push

# 개발 서버 실행
npm run dev
```

### 환경 변수 설정

```bash
# .env.local
DATABASE_URL="file:./dev.db"
JWT_SECRET="your-jwt-secret-key"
NEXT_PUBLIC_MAPBOX_TOKEN="your-mapbox-access-token"
```

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

**⭐ Star this repo if you found it helpful!**

Made with ❤️ in Seoul

</div>
