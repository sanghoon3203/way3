//
//  TradeManager.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  거래 관리자 - 상인과의 거래 처리
//

import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - 거래 관련 모델
enum TradeType: String, Codable {
    case buy = "buy"
    case sell = "sell"
    case exchange = "exchange"
}

// TradeItem is defined in Models/TradeItem.swift

struct TradeRequest: Codable {
    let merchantId: String
    let items: [TradeItemRequest]
}

struct TradeItemRequest: Codable {
    let itemId: String
    let quantity: Int
    let action: TradeType
}

struct TradeResult: Codable {
    let success: Bool
    let message: String
    let totalAmount: Int
    let experienceGained: Int
    let purchasedItemIds: [String]
    let soldItemIds: [String]
}

// MARK: - 거래 매니저
class TradeManager: ObservableObject {
    static let shared = TradeManager()
    
    @Published var selectedItems: [TradeItem] = []
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var lastTradeResult: TradeResult?
    
    private let baseURL = "http://localhost:3000/api/trade"
    
    var totalAmount: Int {
        selectedItems.reduce(into: 0) { result, item in
            result += (item.currentPrice * item.quantity)
        }
    }
    
    var selectedItemCount: Int {
        selectedItems.count
    }
    
    // MARK: - 아이템 선택/해제
    func toggleItem(_ item: TradeItem, type: TradeType) {
        if let index = selectedItems.firstIndex(where: { $0.id == item.id }) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
    }
    
    func clearSelection() {
        selectedItems.removeAll()
    }
    
    func updateItemQuantity(_ itemId: String, quantity: Int) {
        if let index = selectedItems.firstIndex(where: { $0.id == itemId }) {
            var updatedItem = selectedItems[index]
            updatedItem = TradeItem(
                itemId: updatedItem.itemId,
                name: updatedItem.name,
                category: updatedItem.category,
                grade: updatedItem.grade,
                requiredLicense: updatedItem.requiredLicense,
                basePrice: updatedItem.basePrice,
                currentPrice: updatedItem.currentPrice,
                weight: updatedItem.weight,
                description: updatedItem.description
            )
            updatedItem.quantity = quantity
            selectedItems[index] = updatedItem
        }
    }
    
    // MARK: - 거래 실행
    func executeTrade(with merchant: Merchant) async {
        await MainActor.run {
            isLoading = true
            errorMessage = ""
        }
        
        do {
            let tradeRequest = TradeRequest(
                merchantId: merchant.id,
                items: selectedItems.map { item in
                    TradeItemRequest(
                        itemId: item.id,
                        quantity: item.quantity,
                        action: .buy // 현재는 구매만 구현
                    )
                }
            )
            
            let result = try await performTradeRequest(tradeRequest)
            
            await MainActor.run {
                if result.success {
                    lastTradeResult = result
                    clearSelection()
                    
                    // 성공 알림 (진동, 소리 등)
                    triggerSuccessHaptic()
                } else {
                    errorMessage = result.message
                }
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "거래 실패: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    // MARK: - 거래 시뮬레이션 (서버 연결 전 테스트용)
    func simulateTrade(with merchant: Merchant) async {
        await MainActor.run {
            isLoading = true
        }
        
        // 1-2초 지연으로 실제 거래를 시뮬레이션
        try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
        
        await MainActor.run {
            let success = Double.random(in: 0...1) > 0.1 // 90% 성공률
            
            if success {
                lastTradeResult = TradeResult(
                    success: true,
                    message: "거래가 성공적으로 완료되었습니다!",
                    totalAmount: totalAmount,
                    experienceGained: selectedItems.count * 10,
                    purchasedItemIds: selectedItems.map { $0.itemId },
                    soldItemIds: []
                )
                clearSelection()
                triggerSuccessHaptic()
            } else {
                errorMessage = "거래 실패: 상인의 재고가 부족합니다."
            }
            
            isLoading = false
        }
    }
    
    // MARK: - 네트워크 요청
    private func performTradeRequest(_ request: TradeRequest) async throws -> TradeResult {
        guard let url = URL(string: baseURL + "/execute") else {
            throw URLError(.badURL)
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.allHTTPHeaderFields = AuthManager.shared.getAuthHeaders()
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if httpResponse.statusCode == 401 {
            // 토큰 만료시 갱신 시도
            if await AuthManager.shared.refreshAuthToken() {
                urlRequest.allHTTPHeaderFields = AuthManager.shared.getAuthHeaders()
                let (retryData, _) = try await URLSession.shared.data(for: urlRequest)
                return try JSONDecoder().decode(TradeResult.self, from: retryData)
            } else {
                throw URLError(.userAuthenticationRequired)
            }
        }
        
        return try JSONDecoder().decode(TradeResult.self, from: data)
    }
    
    // MARK: - 햅틱 피드백
    private func triggerSuccessHaptic() {
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
        
        // 성공 소리 재생 (선택사항)
        // AudioServicesPlaySystemSound(1016)
    }
    
    // MARK: - 거래 유효성 검사
    func validateTrade(with merchant: Merchant) -> (isValid: Bool, message: String) {
        guard !selectedItems.isEmpty else {
            return (false, "거래할 아이템을 선택해주세요.")
        }
        
        let totalCost = totalAmount
        let playerMoney = 15420 // 임시 값, 실제로는 플레이어 데이터에서 가져와야 함
        
        if totalCost > playerMoney {
            return (false, "보유 금액이 부족합니다.")
        }
        
        // 거리 체크
        if merchant.distance > 100 {
            return (false, "상인과의 거리가 너무 멉니다.")
        }
        
        return (true, "거래 가능")
    }
    
    // MARK: - 거래 통계
    func calculatePotentialProfit() -> Int {
        // 구매 후 다른 상인에게 판매했을 때의 예상 수익
        return selectedItems.reduce(into: 0) { total, item in
            let estimatedSellPrice = Int(Double(item.currentPrice) * 1.2) // 20% 마진 가정
            total += (estimatedSellPrice - item.currentPrice) * item.quantity
        }
    }
}

// MARK: - 거래 확인 뷰
struct TradeConfirmationView: View {
    let merchant: Merchant
    @ObservedObject var tradeManager: TradeManager
    @Binding var isPresented: Bool
    @State private var showResult = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 상인 정보
                HStack(spacing: 15) {
                    ZStack {
                        Circle()
                            .fill(merchant.pinColor)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: merchant.iconName)
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(merchant.name)
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                        Text("거래 확인")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                // 선택된 아이템 목록
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(tradeManager.selectedItems) { item in
                            TradeItemRow(item: item)
                        }
                    }
                }
                
                Divider()
                
                // 거래 요약
                VStack(spacing: 12) {
                    HStack {
                        Text("총 아이템 수")
                            .font(.custom("ChosunCentennial", size: 16))
                        Spacer()
                        Text("\(tradeManager.selectedItems.count)개")
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("총 거래 금액")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                        Spacer()
                        Text("₩\(tradeManager.totalAmount)")
                            .font(.custom("ChosunCentennial", size: 20))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    HStack {
                        Text("예상 수익")
                            .font(.custom("ChosunCentennial", size: 16))
                        Spacer()
                        Text("₩\(tradeManager.calculatePotentialProfit())")
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                
                Spacer()
                
                // 거래 버튼
                Button(action: {
                    Task {
                        await tradeManager.simulateTrade(with: merchant)
                        if tradeManager.lastTradeResult?.success == true {
                            showResult = true
                        }
                    }
                }) {
                    HStack {
                        if tradeManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "creditcard.fill")
                        }
                        
                        Text(tradeManager.isLoading ? "거래 중..." : "거래 확정")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 55)
                    .background(
                        RoundedRectangle(cornerRadius: 27.5)
                            .fill(Color.blue)
                    )
                }
                .disabled(tradeManager.isLoading)
                
                // 에러 메시지
                if !tradeManager.errorMessage.isEmpty {
                    Text(tradeManager.errorMessage)
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("거래 확인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        isPresented = false
                    }
                    .font(.custom("ChosunCentennial", size: 16))
                }
            }
        }
        .alert("거래 성공!", isPresented: $showResult) {
            Button("확인") {
                isPresented = false
            }
        } message: {
            if let result = tradeManager.lastTradeResult {
                Text("\(result.message)\n경험치 +\(result.experienceGained)")
            }
        }
    }
}

// MARK: - 거래 아이템 행
struct TradeItemRow: View {
    let item: TradeItem
    
    var body: some View {
        HStack(spacing: 15) {
            // 아이템 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(item.grade.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: item.iconName)
                    .foregroundColor(item.grade.color)
                    .font(.title3)
            }
            
            // 아이템 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.medium)
                
                Text(item.grade.displayName)
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(item.grade.color)
            }
            
            Spacer()
            
            // 가격과 수량
            VStack(alignment: .trailing, spacing: 4) {
                Text("₩\(item.currentPrice)")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                
                Text("\(item.quantity)개")
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }
}