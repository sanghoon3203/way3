//
//  EnhancedMerchantPin.swift
//  way3 - Pokemon GO Style Merchant Pins
//
//  Pokemon GO 스타일의 상인 마커 애니메이션
//

import SwiftUI
import CoreLocation

struct EnhancedMerchantPin: View {
    let merchant: EnhancedMerchant
    let playerLocation: CLLocationCoordinate2D?
    let district: DistrictManager.GameDistrict
    
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    private var canTrade: Bool {
        guard let distance = merchant.distanceFromPlayer else { return false }
        return distance <= 400
    }
    
    private var distanceText: String {
        guard let distance = merchant.distanceFromPlayer else { return "---" }
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1fkm", distance / 1000)
        }
    }
    
    var body: some View {
        ZStack {
            // 배경 펄스 효과 (Pokemon GO 스타일)
            if canTrade {
                Circle()
                    .fill(merchant.type.color.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .scaleEffect(pulseScale)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: pulseScale
                    )
            }
            
            // 메인 핀
            VStack(spacing: 0) {
                ZStack {
                    // 핀 배경
                    Circle()
                        .fill(canTrade ? merchant.type.color : Color.gray)
                        .frame(width: 44, height: 44)
                        .shadow(radius: 4)
                    
                    // 상인 아이콘
                    Image(systemName: merchant.type.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(isAnimating ? 1.1 : 1.0)
                .rotationEffect(.degrees(isAnimating ? 5 : -5))
                
                // 핀 꼬리
                Triangle()
                    .fill(canTrade ? merchant.type.color : Color.gray)
                    .frame(width: 12, height: 8)
                    .offset(y: -2)
            }
            
            // 상인 정보 카드 (근거리에서만 표시)
            if canTrade {
                VStack(spacing: 2) {
                    Text(merchant.name)
                        .font(.chosunCaption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(distanceText)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                    
                    // 협상 난이도 표시
                    HStack(spacing: 2) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < merchant.negotiationDifficulty ? "star.fill" : "star")
                                .font(.system(size: 8))
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.8))
                )
                .offset(y: -70)
                .opacity(canTrade ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: canTrade)
            }
            
            // 거래 불가 상태 표시
            if !canTrade && merchant.distanceFromPlayer != nil {
                VStack {
                    Image(systemName: "lock.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                        )
                }
                .offset(x: 15, y: -15)
            }
        }
        .onAppear {
            // 무작위 애니메이션 시작
            DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
                withAnimation(
                    Animation.easeInOut(duration: 3.0)
                        .repeatForever(autoreverses: true)
                ) {
                    isAnimating = true
                }
                
                withAnimation(
                    Animation.easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    pulseScale = 1.3
                }
            }
        }
    }
}

// MARK: - Triangle Shape for Pin Tail
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Nearby Player Pin
struct NearbyPlayerPin: View {
    let player: SocketManager.NearbyPlayer
    
    @State private var bounceOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                // 플레이어 배경
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 34, height: 34)
                    .shadow(radius: 3)
                
                // 플레이어 아이콘
                VStack(spacing: 1) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Lv.\(player.level)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: bounceOffset)
            
            // 플레이어 정보
            VStack(spacing: 2) {
                Text(player.name)
                    .font(.chosunCaption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(player.distanceText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 2)
            )
        }
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
                    .delay(Double.random(in: 0...1))
            ) {
                bounceOffset = -4
            }
        }
    }
}

// MARK: - District Information Card
struct DistrictInfoCard: View {
    let district: DistrictManager.GameDistrict
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(district.emoji)
                    .font(.system(size: 32))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(district.displayName)
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                    
                    Text(district.description)
                        .font(.chosunBody)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 지역 특성 표시
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                districtFeature("상인 밀도", value: getDistrictDensity(district))
                districtFeature("평균 가격", value: getDistrictPriceLevel(district))
                districtFeature("특산품", value: getDistrictSpecialty(district))
                districtFeature("접근성", value: getDistrictAccessibility(district))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(district.color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(district.color, lineWidth: 2)
                )
        )
    }
    
    private func districtFeature(_ title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.chosunCaption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.chosunBody)
                .fontWeight(.semibold)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func getDistrictDensity(_ district: DistrictManager.GameDistrict) -> String {
        switch district {
        case .gangnam: return "높음"
        case .jung: return "중간"
        case .mapo: return "높음"
        case .jongno: return "중간"
        case .yongsan: return "낮음"
        case .other: return "미지"
        }
    }
    
    private func getDistrictPriceLevel(_ district: DistrictManager.GameDistrict) -> String {
        switch district {
        case .gangnam: return "비쌈"
        case .jung: return "적정"
        case .mapo: return "보통"
        case .jongno: return "높음"
        case .yongsan: return "매우 높음"
        case .other: return "가변"
        }
    }
    
    private func getDistrictSpecialty(_ district: DistrictManager.GameDistrict) -> String {
        switch district {
        case .gangnam: return "전자제품"
        case .jung: return "전통공예"
        case .mapo: return "예술품"
        case .jongno: return "고서·골동"
        case .yongsan: return "수입품"
        case .other: return "다양"
        }
    }
    
    private func getDistrictAccessibility(_ district: DistrictManager.GameDistrict) -> String {
        switch district {
        case .gangnam: return "★★★★★"
        case .jung: return "★★★★☆"
        case .mapo: return "★★★☆☆"
        case .jongno: return "★★★★☆"
        case .yongsan: return "★★★★★"
        case .other: return "☆☆☆☆☆"
        }
    }
}

#Preview {
    VStack {
        EnhancedMerchantPin(
            merchant: EnhancedMerchant(
                id: "1",
                name: "김테크",
                title: "전자제품 전문가",
                type: .electronics,
                location: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
                district: .gangnam,
                priceModifier: 1.2,
                negotiationDifficulty: 4,
                reputationRequirement: 50,
                distanceFromPlayer: 250
            ),
            playerLocation: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
            district: .gangnam
        )
        .frame(width: 200, height: 200)
        
        Spacer()
        
        DistrictInfoCard(district: .gangnam)
            .padding()
    }
}