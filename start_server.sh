#!/bin/bash

# Way Game Server 시작 스크립트

echo "🚀 Way Game Server 시작 중..."

# 서버 디렉토리로 이동
cd theway_server

# Node.js 버전 확인
echo "📍 Node.js 버전 확인:"
node --version
npm --version

# 의존성 설치 확인
echo "📦 의존성 확인:"
if [ ! -d "node_modules" ]; then
    echo "의존성 설치 중..."
    npm install
fi

# 환경 변수 파일 확인
if [ ! -f ".env" ]; then
    echo "❌ .env 파일이 없습니다!"
    exit 1
fi

# 데이터베이스 디렉토리 확인
if [ ! -d "data" ]; then
    echo "📁 데이터 디렉토리 생성..."
    mkdir -p data
fi

# 로그 디렉토리 확인
if [ ! -d "logs" ]; then
    echo "📁 로그 디렉토리 생성..."
    mkdir -p logs
fi

echo "✅ 준비 완료!"
echo "🎯 서버 시작 중... (Ctrl+C로 종료)"
echo "📱 iOS 앱: http://localhost:3000"
echo "🎛️  관리자 패널: http://localhost:3000/admin"
echo "=============================================="

# 서버 시작
npm run dev