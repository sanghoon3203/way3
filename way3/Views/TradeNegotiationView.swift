//
//  TradeNegotiationView.swift
//  way3 - Interactive Trade Negotiation System
//
//  Pokemon GO 스타일의 인터랙티브 거래 협상 시스템
//

import SwiftUI
import CoreLocation

struct TradeNegotiationView: View {
    let merchant: EnhancedMerchant
    let item: MerchantItem
    let onTradeComplete: (MerchantItem, Int) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var currentOffer: Int
    @State private var negotiationRound = 0
    @State private var maxRounds = 3
    @State private var merchantResponse: MerchantResponse?
    @State private var isNegotiating = false
    @State private var negotiationHistory: [NegotiationRound] = []
    @State private var showSuccess = false
    @State private var showFailure = false
    
    private let minAcceptablePrice: Int
    private let maxAcceptablePrice: Int
    
    init(merchant: EnhancedMerchant, item: MerchantItem, onTradeComplete: @escaping (MerchantItem, Int) -> Void) {
        self.merchant = merchant
        self.item = item
        self.onTradeComplete = onTradeComplete
        
        // 협상 범위 설정 (상인의 가격 조정률과 협상 난이도에 따라)
        let basePrice = item.currentPrice
        self.minAcceptablePrice = Int(Double(basePrice) * (1.0 - 0.15)) // 최대 15% 할인
        self.maxAcceptablePrice = Int(Double(basePrice) * 1.05) // 최대 5% 프리미엄
        
        self._currentOffer = State(initialValue: Int(Double(basePrice) * 0.85)) // 15% 할인으로 시작
        self.maxRounds = 5 - merchant.negotiationDifficulty // 어려울수록 적은 라운드
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 헤더
                negotiationHeader
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 아이템 카드
                        itemCard
                        
                        // 협상 히스토리
                        if !negotiationHistory.isEmpty {
                            negotiationHistoryView
                        }
                        
                        // 현재 상황
                        currentSituationView
                        
                        // 가격 입력 섹션
                        priceInputSection
                        
                        // 액션 버튼들
                        actionButtons
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .overlay(
            Group {
                if showSuccess {
                    SuccessOverlay(
                        title: "거래 성사!",
                        message: "\\(item.name)을(를) \\(formatMoney(currentOffer))에 구매했습니다",
                        onDismiss: {
                            showSuccess = false
                            onTradeComplete(item, currentOffer)
                            dismiss()
                        }
                    )
                }
                
                if showFailure {
                    FailureOverlay(
                        title: "협상 실패",
                        message: "\\(merchant.name)님이 거래를 거절했습니다",
                        onDismiss: {
                            showFailure = false
                            dismiss()
                        }
                    )
                }
            }
        )
        .onAppear {
            setupNegotiation()
        }
    }
    
    // MARK: - Negotiation Header
    private var negotiationHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button("취소") {
                    dismiss()
                }
                .foregroundColor(.white)
                
                Spacer()
                
                VStack {
                    Text("협상 \\(negotiationRound + 1)/\\(maxRounds)")
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    ProgressView(value: Double(negotiationRound), total: Double(maxRounds))
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(width: 100)
                }
                
                Spacer()
                
                Button("정보") {
                    // 협상 도움말
                }
                .foregroundColor(.white)
            }
            .padding()
            
            // 상인 정보
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(merchant.type.color)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: merchant.type.icon)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(merchant.name)
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text("협상 난이도:")
                        
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < merchant.negotiationDifficulty ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    .font(.chosunCaption)
                    .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [merchant.type.color, merchant.type.color.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Item Card
    private var itemCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 아이템 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(item.gradeColor.opacity(0.3))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: item.categoryIcon)
                        .font(.system(size: 24))
                        .foregroundColor(item.gradeColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.chosunHeadline)
                        .fontWeight(.bold)
                    
                    Text(item.description)
                        .font(.chosunBody)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("등급 \\(item.grade)")
                            .font(.chosunCaption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(item.gradeColor.opacity(0.2))
                            )
                            .foregroundColor(item.gradeColor)
                        
                        Spacer()
                        
                        Text("정가: \\(formatMoney(item.currentPrice))")
                            .font(.chosunBody)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    // MARK: - Negotiation History
    private var negotiationHistoryView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("협상 과정")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            ForEach(negotiationHistory.indices, id: \\.self) { index in
                let round = negotiationHistory[index]
                NegotiationRoundView(round: round, roundNumber: index + 1)
            }
        }
    }
    
    // MARK: - Current Situation
    private var currentSituationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("현재 상황")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            if let response = merchantResponse {
                MerchantResponseView(response: response, merchant: merchant)
            } else {
                Text("첫 제안을 해보세요!")
                    .font(.chosunBody)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                    )
            }
        }
    }
    
    // MARK: - Price Input Section
    private var priceInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("제안 가격")
                .font(.chosunHeadline)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // 가격 슬라이더
                VStack(spacing: 8) {
                    HStack {
                        Text("\\(formatMoney(minAcceptablePrice))")
                            .font(.chosunCaption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\\(formatMoney(currentOffer))")
                            .font(.chosunHeadline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\\(formatMoney(maxAcceptablePrice))")
                            .font(.chosunCaption)
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(currentOffer) },
                            set: { currentOffer = Int($0) }
                        ),
                        in: Double(minAcceptablePrice)...Double(maxAcceptablePrice),
                        step: 1000
                    )
                    .tint(merchant.type.color)
                }
                
                // 빠른 선택 버튼들
                HStack(spacing: 12) {
                    quickOfferButton("10% 할인", multiplier: 0.9)
                    quickOfferButton("5% 할인", multiplier: 0.95)
                    quickOfferButton("정가", multiplier: 1.0)
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // 제안하기 버튼
            Button(action: makeOffer) {
                HStack {
                    if isNegotiating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "hand.point.up.fill")
                    }
                    
                    Text(isNegotiating ? "협상 중..." : "제안하기")
                        .fontWeight(.semibold)
                }
                .font(.chosunBody)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(merchant.type.color)
                )
            }
            .disabled(isNegotiating || negotiationRound >= maxRounds)
            
            // 정가로 구매 버튼
            Button(action: buyAtFullPrice) {
                Text("정가로 구매 (\\(formatMoney(item.currentPrice)))")
                    .font(.chosunBody)
                    .foregroundColor(merchant.type.color)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(merchant.type.color, lineWidth: 2)
                    )
            }
            .disabled(isNegotiating)
        }
    }
    
    // MARK: - Helper Views
    private func quickOfferButton(_ title: String, multiplier: Double) -> some View {
        Button(action: {
            currentOffer = Int(Double(item.currentPrice) * multiplier)
        }) {
            Text(title)
                .font(.chosunCaption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.tertiarySystemBackground))
                )
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Methods
    private func setupNegotiation() {
        // 협상 초기 설정
        negotiationRound = 0
        negotiationHistory = []
    }
    
    private func makeOffer() {
        guard negotiationRound < maxRounds else { return }
        
        isNegotiating = true
        
        // 상인의 응답 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let response = generateMerchantResponse()
            
            let round = NegotiationRound(
                playerOffer: currentOffer,
                merchantResponse: response,
                timestamp: Date()
            )
            
            negotiationHistory.append(round)
            merchantResponse = response
            negotiationRound += 1
            
            if response.accepted {
                showSuccess = true
            } else if negotiationRound >= maxRounds {
                showFailure = true
            } else {
                // 상인의 카운터 오퍼가 있다면 적용
                if let counterOffer = response.counterOffer {
                    currentOffer = counterOffer
                }
            }
            
            isNegotiating = false
        }
    }
    
    private func generateMerchantResponse() -> MerchantResponse {
        let acceptanceThreshold = calculateAcceptanceThreshold()
        let offerRatio = Double(currentOffer) / Double(item.currentPrice)
        
        if offerRatio >= acceptanceThreshold {
            return MerchantResponse(
                accepted: true,
                message: generateAcceptanceMessage(),
                counterOffer: nil,
                mood: .happy
            )
        } else {
            let counterOffer = generateCounterOffer()
            return MerchantResponse(
                accepted: false,
                message: generateRejectionMessage(counterOffer: counterOffer),
                counterOffer: counterOffer,
                mood: offerRatio < 0.8 ? .annoyed : .neutral
            )
        }
    }
    
    private func calculateAcceptanceThreshold() -> Double {
        // 협상 난이도와 라운드에 따른 수락 기준
        let baseTreshold = 0.85 // 기본 85%
        let difficultyAdjustment = Double(merchant.negotiationDifficulty) * 0.02 // 난이도당 2% 추가
        let roundAdjustment = Double(negotiationRound) * 0.03 // 라운드당 3% 감소
        
        return max(0.75, baseTreshold + difficultyAdjustment - roundAdjustment)
    }
    
    private func generateCounterOffer() -> Int? {
        // 상인의 카운터 오퍼 생성
        if negotiationRound < maxRounds - 1 {
            let targetPrice = Double(item.currentPrice) * calculateAcceptanceThreshold()
            let currentGap = targetPrice - Double(currentOffer)
            let counterOffer = Double(currentOffer) + (currentGap * 0.6) // 60% 타협
            
            return Int(counterOffer / 1000) * 1000 // 천원 단위로 반올림
        }
        return nil
    }
    
    private func generateAcceptanceMessage() -> String {
        let messages = [
            "좋습니다! 거래하시죠.",
            "합리적인 가격이네요. 동의합니다.",
            "훌륭한 협상이었습니다!",
            "이 정도면 만족스럽습니다.",
            "오케이, 거래 성사입니다!"
        ]
        return messages.randomElement() ?? messages[0]
    }
    
    private func generateRejectionMessage(counterOffer: Int?) -> String {
        if let counterOffer = counterOffer {
            return "\\(formatMoney(counterOffer))은 어떠신가요?"
        } else {
            let messages = [
                "좀 더 생각해보시죠.",
                "아직 부족한 것 같습니다.",
                "조금 더 올려주세요.",
                "다시 한번 고려해보세요."
            ]
            return messages.randomElement() ?? messages[0]
        }
    }
    
    private func buyAtFullPrice() {
        showSuccess = true
        currentOffer = item.currentPrice
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\\(formatter.string(from: NSNumber(value: amount)) ?? "0")원"
    }
}

// MARK: - Supporting Views

struct NegotiationRoundView: View {
    let round: NegotiationRound
    let roundNumber: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("라운드 \\(roundNumber)")
                    .font(.chosunBody)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(round.timestamp, style: .time)
                    .font(.chosunCaption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("내 제안")
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                    
                    Text(formatMoney(round.playerOffer))
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.gameBlue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("상인 응답")
                        .font(.chosunCaption)
                        .foregroundColor(.secondary)
                    
                    Text(round.merchantResponse.accepted ? "수락" : "거절")
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                        .foregroundColor(round.merchantResponse.accepted ? .gameGreen : .red)
                }
            }
            
            Text(round.merchantResponse.message)
                .font(.chosunCaption)
                .foregroundColor(.primary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.tertiarySystemBackground))
                )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\\(formatter.string(from: NSNumber(value: amount)) ?? "0")원"
    }
}

struct MerchantResponseView: View {
    let response: MerchantResponse
    let merchant: EnhancedMerchant
    
    var body: some View {
        HStack(spacing: 12) {
            // 상인 아바타 (기분에 따라 표정 변화)
            ZStack {
                Circle()
                    .fill(merchant.type.color.opacity(0.3))
                    .frame(width: 50, height: 50)
                
                Text(response.mood.emoji)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(merchant.name)
                    .font(.chosunBody)
                    .fontWeight(.semibold)
                
                Text(response.message)
                    .font(.chosunBody)
                    .foregroundColor(.primary)
                
                if let counterOffer = response.counterOffer {
                    Text("카운터 오퍼: \\(formatMoney(counterOffer))")
                        .font(.chosunCaption)
                        .foregroundColor(.gameGreen)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(response.accepted ? Color.gameGreen.opacity(0.1) : Color(.tertiarySystemBackground))
        )
    }
    
    private func formatMoney(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return "\\(formatter.string(from: NSNumber(value: amount)) ?? "0")원"
    }
}

// MARK: - Success/Failure Overlays

struct SuccessOverlay: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gameGreen)
                
                Text(title)
                    .font(.chosunTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.chosunBody)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Button("확인") {
                    onDismiss()
                }
                .font(.chosunBody)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.gameGreen)
                )
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .padding(40)
        }
    }
}

struct FailureOverlay: View {
    let title: String
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.red)
                
                Text(title)
                    .font(.chosunTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(message)
                    .font(.chosunBody)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                
                Button("확인") {
                    onDismiss()
                }
                .font(.chosunBody)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(Color.red)
                )
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
            )
            .padding(40)
        }
    }
}

// MARK: - Data Models

struct NegotiationRound {
    let playerOffer: Int
    let merchantResponse: MerchantResponse
    let timestamp: Date
}

struct MerchantResponse {
    let accepted: Bool
    let message: String
    let counterOffer: Int?
    let mood: MerchantMood
    
    enum MerchantMood {
        case happy, neutral, annoyed
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .neutral: return "😐"
            case .annoyed: return "😤"
            }
        }
    }
}

#Preview {
    TradeNegotiationView(
        merchant: EnhancedMerchant(
            id: "1",
            name: "김테크",
            title: "전자제품 전문가",
            type: .electronics,
            location: CLLocationCoordinate2D(latitude: 37.4979, longitude: 127.0276),
            district: .gangnam,
            priceModifier: 1.2,
            negotiationDifficulty: 3,
            reputationRequirement: 50
        ),
        item: MerchantItem(
            id: "1",
            name: "스마트폰",
            category: "electronics",
            grade: 2,
            basePrice: 800000,
            currentPrice: 850000,
            quantity: 1,
            description: "최신 스마트폰"
        )
    ) { item, price in
        print("거래 완료: \\(item.name) - \\(price)")
    }
}