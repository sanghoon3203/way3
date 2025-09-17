//
//  AuctionHallView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  경매장 - 준비 중 화면
//

import SwiftUI

struct AuctionHallView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()

                // 경매 아이콘
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 120, height: 120)

                    Image(systemName: "hammer.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                }

                VStack(spacing: 16) {
                    Text("경매장")
                        .font(.custom("ChosunCentennial", size: 32))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("준비 중입니다")
                        .font(.custom("ChosunCentennial", size: 20))
                        .foregroundColor(.secondary)

                    Text("곧 다양한 아이템들을 경매로\n만나보실 수 있습니다!")
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                // 알림 설정 버튼
                Button(action: {
                    // 알림 설정 로직 (추후 구현)
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                        Text("오픈 알림 받기")
                    }
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.orange)
                    )
                }
                .padding(.horizontal, 40)

                Spacer()

                // 하단 미리보기 정보
                VStack(spacing: 12) {
                    Text("🔥 예정 기능")
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)

                    HStack(spacing: 20) {
                        FeaturePreview(icon: "timer", title: "실시간 경매")
                        FeaturePreview(icon: "person.3.fill", title: "플레이어 대전")
                        FeaturePreview(icon: "star.fill", title: "희귀템 경매")
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
            .navigationTitle("경매장")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - 기능 미리보기 컴포넌트
struct FeaturePreview: View {
    let icon: String
    let title: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.orange)

            Text(title)
                .font(.custom("ChosunCentennial", size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    AuctionHallView()
}