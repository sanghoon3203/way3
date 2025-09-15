//
//  ARTradingView.swift
//  way3 - AR Trading Interface
//
//  Pokemon GO 스타일 AR 거래 인터페이스
//

import SwiftUI
import ARKit
import RealityKit

struct ARTradingView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var socketManager: SocketManager
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var arManager = ARTradeManager()
    @State private var selectedARMerchant: ARMerchant?
    @State private var showMerchantDetail = false
    @State private var detectedItems: [ARTradeItem] = []
    @State private var collectingItem: ARTradeItem?
    @State private var showCollectionAnimation = false
    
    var body: some View {
        ZStack {
            // AR 카메라 뷰
            ARViewContainer(arManager: arManager)
                .ignoresSafeArea()
            
            // AR UI 오버레이
            arOverlayUI
            
            // 수집 애니메이션
            if showCollectionAnimation {
                itemCollectionAnimation
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            arManager.startARSession()
            arManager.setPlayerLocation(locationManager.currentLocation)
        }
        .onDisappear {
            arManager.stopARSession()
        }
        .sheet(isPresented: $showMerchantDetail) {
            if let merchant = selectedARMerchant {
                ARMerchantDetailView(arMerchant: merchant)
                    .environmentObject(networkManager)
                    .environmentObject(socketManager)
            }
        }
    }
    
    // MARK: - AR 오버레이 UI
    private var arOverlayUI: some View {
        VStack {
            // 상단 UI
            HStack {
                // 닫기 버튼
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.chosunHeadline)
                        .foregroundColor(.white)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                
                Spacer()
                
                // AR 상태 정보
                VStack(alignment: .trailing, spacing: 4) {
                    Text("AR 모드")
                        .font(.chosunBody)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("주변을 탐색하세요")
                        .font(.chosunCaption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))
                )
            }
            .padding()
            
            Spacer()
            
            // 하단 UI
            VStack(spacing: 16) {
                // 탐지된 아이템 목록
                if !detectedItems.isEmpty {
                    arItemGrid
                }
                
                // 액션 버튼들
                HStack(spacing: 20) {
                    // 스캔 모드 토글
                    actionButton(
                        icon: "viewfinder.circle",
                        title: "스캔",
                        color: .gameBlue
                    ) {
                        arManager.toggleScanMode()
                    }
                    
                    // 인벤토리 빠른 접근
                    actionButton(
                        icon: "bag.circle",
                        title: "가방",
                        color: .gamePurple
                    ) {
                        // 인벤토리 열기
                    }
                    
                    // 맵으로 돌아가기
                    actionButton(
                        icon: "map.circle",
                        title: "지도",
                        color: .gameGreen
                    ) {
                        dismiss()
                    }
                }
                .padding(.horizontal, 40)
            }
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - AR 아이템 그리드
    private var arItemGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(detectedItems) { item in
                    Button(action: {
                        collectItem(item)
                    }) {
                        VStack(spacing: 6) {
                            ZStack {
                                Circle()
                                    .fill(item.rarity.color.opacity(0.3))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: item.icon)
                                    .font(.title2)
                                    .foregroundColor(item.rarity.color)
                            }
                            
                            Text(item.name)
                                .font(.chosunCaption)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                            
                            Text(item.distanceText)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.7))
                        )
                    }
                    .disabled(item.distance > 50) // 50m 이내에서만 수집 가능
                    .opacity(item.distance > 50 ? 0.5 : 1.0)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 액션 버튼
    private func actionButton(icon: String, title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.chosunCaption)
                    .foregroundColor(.white)
            }
            .frame(width: 60, height: 60)
            .background(
                Circle()
                    .fill(color.opacity(0.8))
                    .shadow(radius: 4)
            )
        }
    }
    
    // MARK: - 수집 애니메이션
    private var itemCollectionAnimation: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if let item = collectingItem {
                    // 아이템 이미지
                    ZStack {
                        Circle()
                            .fill(item.rarity.color.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .scaleEffect(showCollectionAnimation ? 1.2 : 1.0)
                        
                        Image(systemName: item.icon)
                            .font(.system(size: 60))
                            .foregroundColor(item.rarity.color)
                            .scaleEffect(showCollectionAnimation ? 1.1 : 1.0)
                    }
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatCount(3, autoreverses: true),
                        value: showCollectionAnimation
                    )
                    
                    // 축하 메시지
                    VStack(spacing: 8) {
                        Text("아이템 획득!")
                            .font(.chosunHeadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(item.name)
                            .font(.chosunBody)
                            .foregroundColor(item.rarity.color)
                            .fontWeight(.semibold)
                        
                        Text(item.rarity.displayName)
                            .font(.chosunCaption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    private func collectItem(_ item: ARTradeItem) {
        guard item.distance <= 50 else { return }
        
        collectingItem = item
        showCollectionAnimation = true
        
        // 수집 애니메이션 시작
        withAnimation(.easeInOut(duration: 0.3)) {
            showCollectionAnimation = true
        }
        
        // 서버에 수집 요청
        networkManager.collectARItem(itemId: item.id) { success in
            DispatchQueue.main.async {
                if success {
                    // 수집 성공 시 아이템 제거
                    detectedItems.removeAll { $0.id == item.id }
                    arManager.removeItem(item)
                }
                
                // 애니메이션 종료
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showCollectionAnimation = false
                        collectingItem = nil
                    }
                }
            }
        }
    }
}

// MARK: - AR 뷰 컨테이너
// ARViewContainer 정의는 Views/AR/ARTradeView.swift에 있습니다

// MARK: - AR 상인 디테일 뷰
struct ARMerchantDetailView: View {
    let arMerchant: ARMerchant
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var socketManager: SocketManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showTradeInterface = false
    @State private var selectedItems: [TradeItem] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // AR 상인 정보 헤더
                arMerchantHeader
                
                // 거래 아이템 목록
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(arMerchant.availableItems) { item in
                            ARTradeItemCard(item: item) {
                                selectedItems.append(item)
                                showTradeInterface = true
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AR 상인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showTradeInterface) {
            ARTradeNegotiationView(
                merchant: arMerchant,
                selectedItems: selectedItems
            )
            .environmentObject(networkManager)
            .environmentObject(socketManager)
        }
    }
    
    private var arMerchantHeader: some View {
        VStack(spacing: 16) {
            // 상인 아바타
            ZStack {
                Circle()
                    .fill(arMerchant.type.color.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: arMerchant.type.icon)
                    .font(.system(size: 40))
                    .foregroundColor(arMerchant.type.color)
            }
            
            // 상인 정보
            VStack(spacing: 8) {
                Text(arMerchant.name)
                    .font(.chosunHeadline)
                    .fontWeight(.bold)
                
                Text(arMerchant.title)
                    .font(.chosunBody)
                    .foregroundColor(.secondary)
                
                // AR 특별 혜택 표시
                HStack {
                    Image(systemName: "arkit")
                        .foregroundColor(.gameBlue)
                    
                    Text("AR 할인 5%")
                        .font(.chosunCaption)
                        .foregroundColor(.gameBlue)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.gameBlue.opacity(0.1))
                )
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - AR 거래 아이템 카드
// ARTradeItemCard 정의는 Views/AR/ARTradeView.swift에 있습니다

// MARK: - AR 거래 협상 뷰
struct ARTradeNegotiationView: View {
    let merchant: ARMerchant
    let selectedItems: [TradeItem]
    @EnvironmentObject var networkManager: NetworkManager
    @EnvironmentObject var socketManager: SocketManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var negotiationPhase: NegotiationPhase = .greeting
    @State private var merchantMood: MerchantMood = .neutral
    @State private var playerOffer: Int = 0
    @State private var merchantResponse: String = ""
    
    enum NegotiationPhase {
        case greeting, discussion, offer, response, conclusion
    }
    
    enum MerchantMood {
        case happy, neutral, annoyed, angry
        
        var emoji: String {
            switch self {
            case .happy: return "😊"
            case .neutral: return "😐"
            case .annoyed: return "😒"
            case .angry: return "😠"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // AR 협상 헤더
                arNegotiationHeader
                
                // 협상 진행 단계
                negotiationProgress
                
                // 선택된 아이템들
                selectedItemsList
                
                Spacer()
                
                // 협상 액션 버튼
                negotiationActions
            }
            .padding()
            .navigationTitle("AR 거래 협상")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var arNegotiationHeader: some View {
        HStack {
            // 상인 얼굴 (기분 표시)
            VStack {
                Text(merchantMood.emoji)
                    .font(.system(size: 50))
                
                Text(merchant.name)
                    .font(.chosunBody)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            // AR 보너스 정보
            VStack(alignment: .trailing) {
                HStack {
                    Image(systemName: "arkit")
                        .foregroundColor(.gameBlue)
                    Text("AR 모드")
                        .font(.chosunCaption)
                        .foregroundColor(.gameBlue)
                }
                
                Text("협상력 +10%")
                    .font(.chosunCaption)
                    .foregroundColor(.gameGreen)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGroupedBackground))
        )
    }
    
    private var negotiationProgress: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("협상 진행 상황")
                .font(.chosunCaption)
                .foregroundColor(.secondary)
            
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: .gameBlue))
            
            Text(negotiationPhase.description)
                .font(.chosunBody)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private var selectedItemsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("선택한 아이템")
                .font(.chosunHeadline)
                .fontWeight(.semibold)
            
            ForEach(selectedItems) { item in
                HStack {
                    Text(item.name)
                        .font(.chosunBody)
                    
                    Spacer()
                    
                    Text("\(Int(Double(item.price) * 0.95))원")
                        .font(.chosunBody)
                        .fontWeight(.semibold)
                        .foregroundColor(.gameGreen)
                }
                .padding(.vertical, 4)
            }
            
            Divider()
            
            HStack {
                Text("총합 (AR 할인 적용)")
                    .font(.chosunBody)
                    .fontWeight(.bold)
                
                Spacer()
                
                Text("\(totalPrice)원")
                    .font(.chosunHeadline)
                    .fontWeight(.bold)
                    .foregroundColor(.gameGreen)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }
    
    private var negotiationActions: some View {
        VStack(spacing: 12) {
            // 가격 제안 슬라이더
            VStack(alignment: .leading, spacing: 8) {
                Text("제안 가격: \(playerOffer)원")
                    .font(.chosunBody)
                    .fontWeight(.semibold)
                
                Slider(
                    value: Binding(
                        get: { Double(playerOffer) },
                        set: { playerOffer = Int($0) }
                    ),
                    in: Double(totalPrice * 0.7)...Double(totalPrice * 1.1),
                    step: 1000
                )
                .tint(.gameBlue)
            }
            
            // 액션 버튼들
            HStack(spacing: 16) {
                Button("가격 제안") {
                    makeOffer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gameBlue)
                .foregroundColor(.white)
                .cornerRadius(12)
                
                Button("거래 완료") {
                    completeTrade()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gameGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
                .disabled(negotiationPhase != .conclusion)
            }
        }
    }
    
    private var progressValue: Double {
        switch negotiationPhase {
        case .greeting: return 0.2
        case .discussion: return 0.4
        case .offer: return 0.6
        case .response: return 0.8
        case .conclusion: return 1.0
        }
    }
    
    private var totalPrice: Int {
        selectedItems.reduce(0) { sum, item in
            sum + Int(Double(item.price) * 0.95) // AR 할인 5%
        }
    }
    
    private func makeOffer() {
        // 협상 로직 구현
        negotiationPhase = .offer
        
        // 상인 반응 시뮬레이션
        let difference = Double(playerOffer) / Double(totalPrice)
        
        if difference >= 0.95 {
            merchantMood = .happy
            merchantResponse = "좋은 제안이네요! 거래하죠."
            negotiationPhase = .conclusion
        } else if difference >= 0.85 {
            merchantMood = .neutral
            merchantResponse = "음... 조금 더 올려주실 수 있나요?"
        } else {
            merchantMood = .annoyed
            merchantResponse = "너무 낮은 가격이에요. 다시 생각해보세요."
        }
    }
    
    private func completeTrade() {
        // 거래 완료 처리
        networkManager.completeARTrade(
            merchantId: merchant.id,
            items: selectedItems,
            finalPrice: playerOffer
        ) { success in
            DispatchQueue.main.async {
                if success {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Extension for NegotiationPhase
extension ARTradeNegotiationView.NegotiationPhase {
    var description: String {
        switch self {
        case .greeting: return "인사 및 소개"
        case .discussion: return "아이템 검토 중"
        case .offer: return "가격 협상 중"
        case .response: return "상인 응답 대기"
        case .conclusion: return "거래 합의 완료"
        }
    }
}

#Preview {
    ARTradingView()
        .environmentObject(NetworkManager.shared)
        .environmentObject(LocationManager())
        .environmentObject(SocketManager.shared)
}