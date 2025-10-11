//
//  MerchantDetailView.swift
//  way3 - Way Trading Game
//
//  JRPG 스타일 상인 대화 시스템 및 거래 화면
//  ProfileInputView와 동일한 대화창 구조 사용
//

import SwiftUI
import UIKit
import Foundation

// MARK: - Local Episode Index (Merchant Sub Stories)

struct EpisodeMeta: Codable, Identifiable {
    var id: String { episode_id }
    let episode_id: String
    let title: String
    let entry_node: String
    let unlock_requirements: [UnlockReq]?
}

enum UnlockReqType: String, Codable { case quest_completed, main_progress_at_least }

struct UnlockReq: Codable {
    let type: UnlockReqType
    let quest_id: String?
    let value: Int?
}

enum EpisodeIndexLoader {
    static func load(merchantId: String) -> [EpisodeMeta] {
        // Resources/Story/Merchant/<merchantId>/episodes.json
        guard let path = Bundle.main.path(
            forResource: "episodes",
            ofType: "json",
            inDirectory: "Resources/Story/Merchant/\(merchantId)"
        ) else { return [] }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            return try JSONDecoder().decode([EpisodeMeta].self, from: data)
        } catch {
            print("EpisodeIndex load error:", error)
            return []
        }
    }
}

// MARK: - Tabs

enum MerchantDetailTab: Int {
    case dialogue
    case trade
    case story
}

// MARK: - Main View

struct MerchantDetailView: View {
    let merchant: Merchant
    @Binding var isPresented: Bool
    @EnvironmentObject var gameManager: GameManager

    @StateObject var viewModel = MerchantDetailViewModel()
    @StateObject var cartManager = CartManager()

    @State private var showEpisodePicker = false
    @State private var startNodeForStory: String? = nil  // StoryView 시작 노드ID
    @State private var selectedTab: MerchantDetailTab = .dialogue
    @State var showQuantityPopup = false
    @State var selectedItem: TradeItem?
    @State var showPurchaseConfirmation = false
    @State var isCartPresented = false
    @State private var showFullScreenTV = false  // 전체화면 TV 애니메이션
    @State private var currentDialogue: String = ""  // JSON에서 로드한 현재 대사

    // Extensions에서 사용할 수 있도록 computed properties 추가 - 🚀 ViewModel 연동
    var merchantInventoryGridView: some View {
        MerchantInventoryView(
            merchant: merchant,
            cartManager: cartManager,
            viewModel: viewModel,
            tradeType: .buy,
            onItemTap: selectItem
        )
    }

    var playerInventoryGridView: some View {
        PlayerInventoryView(
            merchant: merchant,
            cartManager: cartManager,
            viewModel: viewModel,
            tradeType: .sell,
            onItemTap: selectItem
        )
    }

    var cartDetailView: some View { CartDetailView }
    var quantitySelectionPopup: some View { QuantitySelectionPopup }
    var purchaseConfirmationPopup: some View { PurchaseConfirmationPopup }

    var body: some View {
        ZStack {
            Color.cyberpunkDarkBg.ignoresSafeArea()

            if viewModel.isLoading {
                LoadingView(
                    message: "상인 정보를 불러오는 중...",
                    style: .merchant
                )
            } else if let error = viewModel.error {
                ErrorView(error: error) {
                    viewModel.retryLoading()
                }
            } else {
                // 거래 탭: 전체화면 거래 뷰
                if selectedTab == .trade && !showFullScreenTV {
                    FullScreenTradeView(
                        merchant: merchant,
                        viewModel: viewModel,
                        cartManager: cartManager,
                        selectedTradeType: Binding(
                            get: { viewModel.selectedTradeType },
                            set: { viewModel.selectedTradeType = $0 }
                        ),
                        onSelectItem: { item in
                            selectedItem = item
                            showQuantityPopup = true
                        },
                        onPresentCart: { isCartPresented = true },
                        onBack: {
                            triggerFullScreenTVSwitch(to: .dialogue)
                        }
                    )
                } else {
                    // 대화/스토리 탭: 기존 레이아웃
                    VStack(spacing: 0) {
                        // 🎮 Hero Section - 항상 상단 고정
                        MerchantHeroView(
                            merchant: merchant,
                            dialogueText: currentDialogue
                        )

                        // 📱 콘텐츠 영역 - 탭별로 변경
                        Group {
                            switch selectedTab {
                            case .dialogue:
                                MerchantActionMenu(
                                    hasStory: merchant.hasActiveStory,
                                    onDialogue: {
                                        // 🔸 TV 애니메이션과 함께 에피소드 선택 띄우기
                                        triggerFullScreenTVSwitch(to: .dialogue)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                            showEpisodePicker = true
                                        }
                                    },
                                    onStory: merchant.hasActiveStory ? { selectTab(.story) } : nil,
                                    onTrade: { triggerFullScreenTVSwitch(to: .trade) },
                                    onExit: { isPresented = false }
                                )
                                .padding(.top, 24)
                                .padding(.horizontal, 20)

                            case .story:
                                ScrollView(.vertical, showsIndicators: false) {
                                    MerchantStorySection(merchant: merchant)
                                        .padding(.top, 32)
                                }
                                .padding(.horizontal, 20)

                            case .trade:
                                // 이 경우는 TV 애니메이션 중
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }

            // 📺 전체화면 TV 애니메이션
            if showFullScreenTV { FullScreenTVEffect() }

            if showQuantityPopup { QuantitySelectionPopup }
            if showPurchaseConfirmation { PurchaseConfirmationPopup }
            if isCartPresented { CartDetailView }

            // 🎬 에피소드 선택 오버레이
            if showEpisodePicker {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                    .onTapGesture { showEpisodePicker = false }

                EpisodePickerView(
                    merchant: merchant,
                    onClose: { showEpisodePicker = false },
                    onSelectEpisode: { ep in
                        startNodeForStory = ep.entry_node
                        showEpisodePicker = false
                    }
                )
                .transition(.opacity)
            }
        }
        // 🔽 ZStack "바깥"에 풀스크린 커버 체이닝 (안전)
        .fullScreenCover(item: Binding(
            get: { startNodeForStory.map { StoryStartWrapper(id: $0) } },
            set: { _ in startNodeForStory = nil }
        )) { wrapper in
            StoryView(startNodeID: wrapper.id, returnToMapOnCompletion: true)
                .background(Color.black.ignoresSafeArea())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true) // 필요 시 .toolbar(.hidden, for: .navigationBar) 로 교체
        .onAppear {
            Task {
                await viewModel.loadMerchant(id: merchant.id)
                loadRandomDialogue()
                selectTab(.dialogue)
            }
        }
    }
}

// StoryStartWrapper: fullScreenCover 식별용
private struct StoryStartWrapper: Identifiable { let id: String }

// MARK: - Hero

struct MerchantHeroView: View {
    let merchant: Merchant
    let dialogueText: String

    // 캐릭터 상태 관리
    @State private var characterState: CharacterState = .idle

    var body: some View {
        ZStack(alignment: .bottom) {
            // 📸 Layer 1: 배경 이미지 (캐릭터 위치 기준)
            BackgroundImageView(merchantId: merchant.id)
                .frame(height: 320)
                .frame(maxWidth: .infinity)
                .clipped()

            // 🌌 사이버펑크 스캔라인 효과
            VStack(spacing: 2) {
                ForEach(0..<160, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.cyberpunkCyan.opacity(0.02))
                        .frame(height: 1)
                }
            }
            .frame(height: 320)
            .allowsHitTesting(false)

            // 👤 Layer 2: 캐릭터 (하단 고정)
            VStack(spacing: 0) {
                Spacer()
                CharacterAnimationView(merchantId: merchant.id, state: characterState)
                    .frame(width: 224, height: 320)
            }

            // 💬 Layer 3: 대사창 (하단 고정)
            VisualNovelDialogueBox(
                merchantName: merchant.name,
                dialogue: dialogueText.isEmpty ? "..." : dialogueText,
                showContinue: false,
                onContinue: {}
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(height: 380)
        .background(
            LinearGradient(
                colors: [Color.black, Color.cyberpunkDarkBg.darker(by: 0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cyberpunkCyan.opacity(0.3),
                            Color.clear,
                            Color.cyberpunkCyan.opacity(0.3)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 1
                ),
            alignment: .bottom
        )
        .onChange(of: dialogueText) { _, newValue in
            updateCharacterState(for: newValue)
        }
    }

    private func updateCharacterState(for dialogue: String) {
        if dialogue.isEmpty {
            characterState = .idle
            return
        }
        characterState = CharacterState.recommendedState(for: dialogue)
    }
}

// 🎨 스캔라인 오버레이 - 사이버펑크 홀로그램 효과 (미사용 시 그대로 보관)
struct ScanlineOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 4) {
                ForEach(0..<Int(geometry.size.height / 8), id: \.self) { _ in
                    Rectangle()
                        .fill(Color.cyberpunkCyan.opacity(0.03))
                        .frame(height: 2)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Action Menu

struct MerchantActionMenu: View {
    let hasStory: Bool
    let onDialogue: () -> Void
    let onStory: (() -> Void)?
    let onTrade: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            UnifiedActionButton(
                title: "대화하기",
                accentColor: .cyberpunkCyan,
                action: onDialogue
            )

            if let onStory = onStory, hasStory {
                UnifiedActionButton(
                    title: "스토리 진행하기",
                    accentColor: .cyberpunkCyan,
                    action: onStory
                )
            }

            UnifiedActionButton(
                title: "거래하기",
                accentColor: .cyberpunkGreen,
                action: onTrade
            )

            UnifiedActionButton(
                title: "나가기",
                accentColor: .cyberpunkError,
                action: onExit
            )
        }
    }
}

// MARK: - Unified Button

struct UnifiedActionButton: View {
    let title: String
    let accentColor: Color
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title.uppercased())
                    .font(.cyberpunkButton())
                    .foregroundColor(buttonStyle.textColor)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 50)
            .cyberpunkButton(style: buttonStyle, isPressed: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: CGFloat.infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }, perform: {})
    }

    private var buttonStyle: CyberpunkButtonStyle {
        if accentColor == .cyberpunkGreen {
            return .primary
        } else if accentColor == .cyberpunkError {
            return .secondary
        } else {
            return .primary
        }
    }
}

// MARK: - Trade Section (embedded mode)

struct MerchantTradeSection: View {
    let merchant: Merchant
    @ObservedObject var viewModel: MerchantDetailViewModel
    @ObservedObject var cartManager: CartManager
    @Binding var selectedTradeType: TradeType
    let onSelectItem: (TradeItem) -> Void
    let onPresentCart: () -> Void
    let onBack: () -> Void

    @State private var showTVSwitch = false

    var body: some View {
        VStack(spacing: 0) {
            // ✅ 상단 탭 + 장바구니
            HStack(spacing: 12) {
                // BUY 탭
                TradeTabButton(
                    title: "BUY",
                    isSelected: selectedTradeType == .buy
                ) {
                    triggerTVSwitch(to: .buy)
                }

                // SELL 탭
                TradeTabButton(
                    title: "SELL",
                    isSelected: selectedTradeType == .sell
                ) {
                    triggerTVSwitch(to: .sell)
                }

                Spacer()

                // 장바구니 퀵 버튼
                CartQuickButton(cartManager: cartManager, onTap: onPresentCart)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.cyberpunkPanelBg)

            // ✅ 인벤토리 그리드 (TV 애니메이션)
            Group {
                if selectedTradeType == .buy {
                    MerchantInventoryView(
                        merchant: merchant,
                        cartManager: cartManager,
                        viewModel: viewModel,
                        tradeType: .buy,
                        onItemTap: onSelectItem
                    )
                } else {
                    PlayerInventoryView(
                        merchant: merchant,
                        cartManager: cartManager,
                        viewModel: viewModel,
                        tradeType: .sell,
                        onItemTap: onSelectItem
                    )
                }
            }
            .modifier(TVChannelSwitchTransition(isActive: showTVSwitch))

            // ✅ 하단 실시간 요약 + 거래 버튼
            if !cartManager.items.isEmpty {
                TradeActionFooter(cartManager: cartManager, onExecuteTrade: onPresentCart)
            }
        }
        .background(Color.cyberpunkDarkBg)
    }

    private func triggerTVSwitch(to type: TradeType) {
        showTVSwitch = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            selectedTradeType = type
            showTVSwitch = false
        }
    }
}

// MARK: - TV Effect

struct CRTStaticEffect: View {
    @State private var opacity: Double = 0

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.white, .gray, .black, .white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 0.1).repeatCount(3)) {
                    opacity = 0.8
                }
            }
    }
}

struct TVChannelSwitchTransition: ViewModifier {
    let isActive: Bool
    @State private var phase: TVSwitchPhase = .idle

    enum TVSwitchPhase {
        case idle, whiteNoise, dissolve, fadeIn
    }

    func body(content: Content) -> some View {
        ZStack {
            content
                .opacity(phase == .fadeIn || phase == .idle ? 1 : 0)
                .scaleEffect(phase == .fadeIn || phase == .idle ? 1 : 0.95)

            if phase == .whiteNoise {
                CRTStaticEffect()
            }

            if phase == .dissolve {
                Rectangle()
                    .fill(Color.cyberpunkCyan.opacity(0.3))
                    .blur(radius: 20)
            }
        }
        .onChange(of: isActive) { _, newValue in
            if newValue { performTVSwitch() }
        }
    }

    private func performTVSwitch() {
        phase = .whiteNoise
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                phase = .dissolve
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.15)) {
                    phase = .fadeIn
                }
            }
        }
    }
}

// MARK: - Trade UI Bits

struct TradeTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? .black : .cyberpunkTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    isSelected
                        ? Color.cyberpunkYellow
                        : Color.cyberpunkCardBg
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

struct CartQuickButton: View {
    @ObservedObject var cartManager: CartManager
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 18))

                if cartManager.items.count > 0 {
                    Text("\(cartManager.items.count)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.cyberpunkYellow))
                }
            }
            .foregroundColor(.cyberpunkCyan)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyberpunkCyan, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct TradeActionFooter: View {
    @ObservedObject var cartManager: CartManager
    let onExecuteTrade: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // 실시간 요약
            HStack {
                Text("📊 선택: \(cartManager.items.count)건")
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                let totalBuy = cartManager.totalBuyCost
                let totalSell = cartManager.totalSellRevenue
                let displayAmount = totalBuy > 0 ? totalBuy : totalSell

                Text("총액: ₩\(displayAmount)")
                    .font(.cyberpunkHeading(size: 18))
                    .foregroundColor(totalBuy > 0 ? .cyberpunkYellow : .cyberpunkGreen)
            }

            // 거래 실행 버튼
            Button(action: onExecuteTrade) {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("거래 실행하기")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 26)
                        .fill(Color.cyberpunkYellow)
                        .shadow(color: .cyberpunkYellow.opacity(0.5), radius: 8)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .overlay(
            Rectangle()
                .fill(Color.cyberpunkYellow)
                .frame(height: 3),
            alignment: .top
        )
    }
}

// MARK: - (Optional) Ace Attorney style bits (kept for reuse)

private struct AceAttorneyStyleHeader: View {
    @Binding var selectedTradeType: TradeType
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            AceAttorneyBackButton(onBack: onBack).frame(width: 50)
            CyberpunkTradeToggle(selectedTradeType: $selectedTradeType)
            OnlineIndicator().frame(width: 45)
        }
        .frame(height: 50)
    }
}

private struct AceAttorneyBackButton: View {
    let onBack: () -> Void

    var body: some View {
        Button(action: onBack) {
            VStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .heavy))
                    .foregroundColor(.cyberpunkCyan)

                Text("BACK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.cyberpunkCyan)
            }
            .frame(width: 50, height: 44)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.cyberpunkCardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    colors: [.cyberpunkCyan, .cyberpunkCyan.opacity(0.5)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .cyberpunkCyan.opacity(0.3), radius: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct CyberpunkTradeToggle: View {
    @Binding var selectedTradeType: TradeType

    var body: some View {
        HStack(spacing: 0) {
            ToggleButton(
                title: "BUY_MODE",
                subtitle: "구매",
                isSelected: selectedTradeType == .buy
            ) {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedTradeType = .buy
                }
            }

            Rectangle()
                .fill(Color.cyberpunkBorder.opacity(0.3))
                .frame(width: 1)

            ToggleButton(
                title: "SELL_MODE",
                subtitle: "판매",
                isSelected: selectedTradeType == .sell
            ) {
                withAnimation(.easeOut(duration: 0.2)) {
                    selectedTradeType = .sell
                }
            }
        }
        .frame(height: 44)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.cyberpunkBorder.opacity(0.6), lineWidth: 1)
        )
    }

    private struct ToggleButton: View {
        let title: String
        let subtitle: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .cyberpunkYellow : .cyberpunkTextSecondary)

                    Text(subtitle)
                        .font(.cyberpunkBody())
                        .foregroundColor(isSelected ? .white : .cyberpunkTextSecondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    isSelected
                        ? LinearGradient(
                            colors: [Color.cyberpunkYellow.opacity(0.15), Color.cyberpunkYellow.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        : LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    VStack {
                        if isSelected {
                            Rectangle()
                                .fill(Color.cyberpunkYellow)
                                .frame(height: 3)
                                .shadow(color: .cyberpunkYellow.opacity(0.6), radius: 4)
                                .transition(.opacity)
                        }
                        Spacer()
                    }
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct OnlineIndicator: View {
    var body: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(Color.cyberpunkGreen)
                .frame(width: 8, height: 8)
                .shadow(color: .cyberpunkGreen.opacity(0.8), radius: 4)

            Text("ONLINE")
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(.cyberpunkGreen)
        }
    }
}

// MARK: - Info & Stats (kept as-is)

struct MerchantInfoView: View {
    let merchant: Merchant

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                CyberpunkInfoSection(title: "OPERATING HOURS") {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.cyberpunkCyan)
                            .shadow(color: .cyberpunkCyan.opacity(0.4), radius: 3)
                        Text("09:00 - 18:00")
                            .font(.cyberpunkBody())
                            .foregroundColor(.cyberpunkTextPrimary)
                    }
                }

                CyberpunkInfoSection(title: "SPECIALTIES") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        CyberpunkSpecialtyTag(text: "유기농 식품")
                        CyberpunkSpecialtyTag(text: "전통 발효식품")
                        CyberpunkSpecialtyTag(text: "지역 특산품")
                        CyberpunkSpecialtyTag(text: "건강식품")
                    }
                }

                CyberpunkInfoSection(title: "MERCHANT PROFILE") {
                    Text("30년간 이 자리에서 신선한 식료품을 판매해온 김씨 상점입니다. 지역 농가와 직접 계약하여 신선하고 품질 좋은 식품만을 엄선하여 제공합니다.")
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineSpacing(6)
                }

                CyberpunkInfoSection(title: "TRADE STATISTICS") {
                    VStack(spacing: 12) {
                        CyberpunkStatRow(label: "총 거래 횟수", value: "1,234회")
                        CyberpunkStatRow(label: "평균 거래 만족도", value: "4.5/5.0")
                        CyberpunkStatRow(label: "주요 고객층", value: "일반 가정")
                        CyberpunkStatRow(label: "추천 상품", value: "한우, 인삼")
                    }
                }
            }
            .padding()
        }
        .background(Color.cyberpunkDarkBg)
    }
}

struct CyberpunkInfoSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Rectangle()
                    .fill(Color.cyberpunkCyan)
                    .frame(width: 3)
                    .shadow(color: .cyberpunkCyan.opacity(0.5), radius: 3)

                Text(title)
                    .font(.cyberpunkHeading(size: 14))
                    .foregroundColor(.cyberpunkYellow)
                    .textCase(.uppercase)
            }
            .frame(height: 24)

            content
                .padding(.leading, 15)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cyberpunkCardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyberpunkBorder.opacity(0.6), lineWidth: 1)
                )
        )
    }
}

struct CyberpunkSpecialtyTag: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(.cyberpunkCaption())
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.cyberpunkYellow.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.cyberpunkYellow.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(color: .cyberpunkYellow.opacity(0.2), radius: 2)
            )
            .foregroundColor(.cyberpunkYellow)
    }
}

struct CyberpunkStatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Text("▸")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.cyberpunkCyan)

            Text(label)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)

            Spacer()

            Text(value)
                .font(.cyberpunkBody())
                .fontWeight(.semibold)
                .foregroundColor(.cyberpunkYellow)
        }
    }
}

// MARK: - Inventories

struct MerchantInventoryView: View {
    let merchant: Merchant
    @ObservedObject var cartManager: CartManager
    @ObservedObject var viewModel: MerchantDetailViewModel
    let tradeType: TradeType
    let onItemTap: (TradeItem) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: CyberpunkLayout.gridSpacing),
                    GridItem(.flexible(), spacing: CyberpunkLayout.gridSpacing)
                ],
                spacing: CyberpunkLayout.gridSpacing
            ) {
                ForEach(viewModel.inventory) { item in
                    TradeItemCard(
                        item: item,
                        tradeType: tradeType,
                        isSelected: cartManager.items.contains { cartItem in
                            cartItem.item.id == item.id && cartItem.type == tradeType
                        },
                        onTap: { onItemTap(item) }
                    )
                }
            }
            .padding(CyberpunkLayout.screenPadding)
        }
        .background(Color.cyberpunkDarkBg)
    }
}

struct PlayerInventoryView: View {
    let merchant: Merchant
    @ObservedObject var cartManager: CartManager
    @ObservedObject var viewModel: MerchantDetailViewModel
    let tradeType: TradeType
    let onItemTap: (TradeItem) -> Void

    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: CyberpunkLayout.gridSpacing),
                    GridItem(.flexible(), spacing: CyberpunkLayout.gridSpacing)
                ],
                spacing: CyberpunkLayout.gridSpacing
            ) {
                ForEach(viewModel.playerInventory) { item in
                    TradeItemCard(
                        item: item,
                        tradeType: tradeType,
                        isSelected: cartManager.items.contains { cartItem in
                            cartItem.item.id == item.id && cartItem.type == tradeType
                        },
                        onTap: { onItemTap(item) }
                    )
                }
            }
            .padding(CyberpunkLayout.screenPadding)
        }
        .background(Color.cyberpunkDarkBg)
    }
}

// MARK: - Trade Item Card

struct TradeItemCard: View {
    let item: TradeItem
    let tradeType: TradeType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                ZStack {
                    Rectangle()
                        .fill(item.grade.color.opacity(0.1))
                        .frame(height: 80)
                        .overlay(
                            Rectangle()
                                .stroke(item.grade.color.opacity(0.4), lineWidth: 1)
                        )

                    Image(systemName: item.iconName)
                        .font(.system(size: 28))
                        .foregroundColor(item.grade.color)

                    Rectangle()
                        .stroke(Color.cyberpunkCyan.opacity(0.3), lineWidth: 0.5)
                        .frame(height: 80)
                        .opacity(isSelected ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.3), value: isSelected)
                }

                VStack(spacing: 2) {
                    Text(item.name.uppercased())
                        .font(.cyberpunkCaption())
                        .fontWeight(.semibold)
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(1)

                    HStack {
                        Text("PRICE")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)
                        Spacer()
                        Text("₩\(item.currentPrice)")
                            .font(.cyberpunkCaption())
                            .foregroundColor(.cyberpunkYellow)
                            .fontWeight(.semibold)
                    }

                    HStack {
                        Text("STOCK")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)
                        Spacer()
                        Text("\(item.quantity)")
                            .font(.cyberpunkCaption())
                            .foregroundColor(item.quantity > 0 ? .cyberpunkGreen : .cyberpunkError)
                            .fontWeight(.medium)
                    }
                }
            }
            .padding(12)
            .background(Color.cyberpunkCardBg)
            .overlay(
                Rectangle()
                    .stroke(
                        isSelected ? Color.cyberpunkActiveBorder : Color.cyberpunkBorder,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .shadow(
                color: isSelected ? Color.cyberpunkGlowBorder : Color.black.opacity(0.3),
                radius: isSelected ? 8 : 4
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - FullScreen TV Effect

struct FullScreenTVEffect: View {
    @State private var phase: Int = 0

    var body: some View {
        ZStack {
            if phase == 0 {
                // Phase 1: Static noise (0.1초)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.white, .gray, .black, .white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.8)
            } else if phase == 1 {
                // Phase 2: Cyan flash (0.2초)
                Rectangle()
                    .fill(Color.cyberpunkCyan.opacity(0.3))
                    .blur(radius: 20)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            // Phase 1 → Phase 2 transition
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.2)) {
                    phase = 1
                }
            }
        }
    }
}

// MARK: - Fullscreen Trade View

struct FullScreenTradeView: View {
    let merchant: Merchant
    @ObservedObject var viewModel: MerchantDetailViewModel
    @ObservedObject var cartManager: CartManager
    @Binding var selectedTradeType: TradeType
    let onSelectItem: (TradeItem) -> Void
    let onPresentCart: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // 150px 상인 정보 헤더
                MerchantInfoHeader(merchant: merchant, onBack: onBack)

                // BUY/SELL 버튼
                HStack(spacing: 16) {
                    TradeTypeButton(
                        title: "BUY",
                        isSelected: selectedTradeType == .buy,
                        accentColor: .cyberpunkCyan
                    ) { selectedTradeType = .buy }

                    TradeTypeButton(
                        title: "SELL",
                        isSelected: selectedTradeType == .sell,
                        accentColor: .cyberpunkYellow
                    ) { selectedTradeType = .sell }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .background(Color.cyberpunkDarkBg)

                // 거래 아이템 그리드
                if selectedTradeType == .buy {
                    MerchantInventoryView(
                        merchant: merchant,
                        cartManager: cartManager,
                        viewModel: viewModel,
                        tradeType: .buy,
                        onItemTap: onSelectItem
                    )
                } else {
                    PlayerInventoryView(
                        merchant: merchant,
                        cartManager: cartManager,
                        viewModel: viewModel,
                        tradeType: .sell,
                        onItemTap: onSelectItem
                    )
                }

                // 거래 푸터
                TradeActionFooter(cartManager: cartManager, onExecuteTrade: onPresentCart)
            }
            .background(Color.cyberpunkDarkBg)
            .ignoresSafeArea()

            // 오류 발생 시 오버레이
            if let error = viewModel.error {
                TradeErrorOverlay(
                    error: error,
                    onDismiss: { viewModel.clearError() },
                    onBack: onBack
                )
            }
        }
    }
}

struct MerchantInfoHeader: View {
    let merchant: Merchant
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // 뒤로가기 버튼
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyberpunkCyan)
                    .frame(width: 40, height: 40)
                    .background(
                        Rectangle()
                            .stroke(Color.cyberpunkCyan, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)

            // 프로필 사진 (100x100 증명사진 스타일)
            MerchantImageView(
                merchantName: merchant.name,
                imageFileName: merchant.imageFileName,
                width: 100,
                height: 100
            )
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.cyberpunkCyan, lineWidth: 2)
            )

            // 상인 정보
            VStack(alignment: .leading, spacing: 8) {
                Text(merchant.name)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.cyberpunkCyan)

                    Text(merchant.district.displayName)
                        .font(.system(size: 14, design: .monospaced))
                        .foregroundColor(.cyberpunkTextSecondary)
                }
            }

            Spacer()
        }
        .padding(16)
        .frame(height: 150)
        .background(Color.cyberpunkDarkBg)
        .overlay(
            Rectangle()
                .fill(Color.cyberpunkCyan)
                .frame(height: 2),
            alignment: .bottom
        )
    }
}

// MARK: - Trade Type Button

struct TradeTypeButton: View {
    let title: String
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(isSelected ? accentColor : .cyberpunkTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    Rectangle()
                        .stroke(isSelected ? accentColor : Color.cyberpunkBorder, lineWidth: isSelected ? 3 : 1)
                )
                .overlay(
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: isSelected ? 4 : 0),
                    alignment: .leading
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Story Archive / Playback

struct MerchantStorySection: View {
    let merchant: Merchant
    @StateObject private var viewModel = StoryViewModel()

    var body: some View {
        Group {
            if let currentNode = viewModel.currentNode {
                // 📖 스토리 재생 모드
                StoryPlaybackView(node: currentNode, viewModel: viewModel)
            } else {
                // 📚 챕터 선택 모드 (Court Record)
                StoryArchiveView(merchant: merchant, viewModel: viewModel)
            }
        }
        .onDisappear { viewModel.reset() }
    }
}

private struct StoryArchiveView: View {
    let merchant: Merchant
    @ObservedObject var viewModel: StoryViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("COURT RECORD")
                        .font(.system(size: 13, weight: .black, design: .monospaced))
                        .foregroundColor(.cyberpunkYellow)

                    Text("스토리 아카이브")
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextSecondary)
                }

                Spacer()

                Image(systemName: "book.closed.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.cyberpunkYellow.opacity(0.8))
            }
            .padding(20)
            .background(Color.cyberpunkPanelBg)
            .overlay(
                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(height: 3)
                    .shadow(color: .cyberpunkYellow.opacity(0.6), radius: 4),
                alignment: .top
            )

            // 본문
            if viewModel.isLoading {
                Spacer()
                ProgressView("챕터 목록을 불러오는 중...")
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyberpunkYellow))
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextSecondary)
                Spacer()
            } else if let error = viewModel.error {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.cyberpunkError)

                    Text("챕터를 불러올 수 없습니다")
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextPrimary)

                    Text(error)
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextSecondary)
                        .multilineTextAlignment(.center)

                    Button("다시 시도") {
                        Task { await viewModel.fetchChapters(for: merchant.id) }
                    }
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkYellow)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.cyberpunkCardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.cyberpunkYellow, lineWidth: 2)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(20)
                Spacer()
            } else if let chapters = viewModel.chapters, !chapters.isEmpty {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(chapters) { chapter in
                            CourtRecordChapterCard(chapter: chapter) {
                                Task { await viewModel.selectChapter(chapter) }
                            }
                        }
                    }
                    .padding(16)
                }
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.cyberpunkTextSecondary.opacity(0.5))

                    Text("진행 가능한 스토리가 없습니다")
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextSecondary)
                }
                Spacer()
            }
        }
        .background(Color.cyberpunkCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyberpunkBorder.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .task {
            await viewModel.fetchChapters(for: merchant.id)
        }
    }
}

private struct CourtRecordChapterCard: View {
    let chapter: StoryChapter
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("Ch.\(chapter.chapter)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundColor(.cyberpunkYellow)

                    if chapter.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.cyberpunkGreen)
                    }
                }
                .frame(width: 50)

                VStack(alignment: .leading, spacing: 6) {
                    Text(chapter.title)
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Text(chapter.storyType.uppercased())
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyberpunkCyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.cyberpunkCyan.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))

                        if chapter.completed {
                            Text("COMPLETED")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyberpunkGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.cyberpunkGreen.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }

                Spacer()

                Image(systemName: "play.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.cyberpunkYellow)
            }
            .padding(16)
            .background(Color.cyberpunkPanelBg)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        LinearGradient(
                            colors: [.cyberpunkYellow.opacity(0.4), .cyberpunkYellow.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .cyberpunkYellow.opacity(0.2), radius: 4)
        }
        .buttonStyle(.plain)
    }
}

private struct StoryPlaybackView: View {
    let node: StoryNode
    @ObservedObject var viewModel: StoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(node.content.speaker)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyberpunkCyan)
                .textCase(.uppercase)

            Text(node.content.text)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
                .lineSpacing(6)

            if let choices = node.choices, !choices.isEmpty {
                VStack(spacing: 12) {
                    ForEach(choices, id: \.id) { choice in
                        Button(action: {
                            Task { await viewModel.selectChoice(choice) }
                        }) {
                            HStack {
                                Text("▸")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.cyberpunkYellow)

                                Text(choice.text)
                                    .font(.cyberpunkBody())
                                    .foregroundColor(.cyberpunkTextPrimary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .foregroundColor(.cyberpunkYellow)
                            }
                            .padding()
                            .background(Color.cyberpunkPanelBg)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.cyberpunkYellow.opacity(0.4), lineWidth: 1)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            } else {
                Button(action: {
                    viewModel.currentNode = nil
                }) {
                    HStack {
                        Spacer()
                        Text("CONTINUE")
                            .font(.system(size: 14, weight: .black, design: .monospaced))
                            .foregroundColor(.cyberpunkTextPrimary)
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.cyberpunkYellow)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(Color.cyberpunkCardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.cyberpunkYellow, lineWidth: 2)
                            .shadow(color: .cyberpunkYellow.opacity(0.5), radius: 6)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(Color.cyberpunkCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyberpunkBorder.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// MARK: - View Extensions

extension MerchantDetailView {
    func selectTab(_ tab: MerchantDetailTab) {
        selectedTab = tab
        switch tab {
        case .dialogue:
            loadRandomDialogue()
        case .trade:
            viewModel.selectedTradeType = .buy
        case .story:
            break
        }
    }

    func selectItem(_ item: TradeItem) {
        selectedItem = item
        showQuantityPopup = true
    }

    /// 전체화면 TV 채널 전환 애니메이션 트리거
    func triggerFullScreenTVSwitch(to tab: MerchantDetailTab) {
        showFullScreenTV = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                showFullScreenTV = false
                selectedTab = tab
                switch tab {
                case .dialogue:
                    loadRandomDialogue()
                case .trade:
                    viewModel.selectedTradeType = .buy
                case .story:
                    break
                }
            }
        }
    }

    /// JSON에서 랜덤 대사 로드
    func loadRandomDialogue() {
        guard let jsonPath = Bundle.main.path(
            forResource: merchant.id,
            ofType: "json",
            inDirectory: "Resources/Merchant/\(merchant.id)"
        ),
        let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
        let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
        let npcs = json["npcs"] as? [String: Any],
        let npcData = npcs[merchant.id] as? [String: Any],
        let dialogues = npcData["dialogue"] as? [String],
        !dialogues.isEmpty else {
            currentDialogue = "..."
            return
        }

        currentDialogue = dialogues.randomElement() ?? "..."
    }
}

// MARK: - Episode Picker (대화하기 → 에피소드 선택)

struct EpisodePickerView: View {
    let merchant: Merchant
    let onClose: () -> Void
    let onSelectEpisode: (EpisodeMeta) -> Void

    @State private var episodes: [EpisodeMeta] = []

    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            HStack {
                Text("EPISODES")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(.cyberpunkYellow)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyberpunkTextSecondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color.cyberpunkPanelBg)
            .overlay(
                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(height: 2),
                alignment: .top
            )

            // 리스트
            if episodes.isEmpty {
                VStack(spacing: 12) {
                    Spacer(minLength: 24)
                    Image(systemName: "quote.bubble")
                        .font(.system(size: 28))
                        .foregroundColor(.cyberpunkTextSecondary.opacity(0.6))
                    Text("진행 가능한 에피소드가 없습니다")
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextSecondary)
                    Spacer(minLength: 24)
                }
                .frame(maxWidth: .infinity)
                .padding(16)
                .background(Color.cyberpunkCardBg)
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(episodes) { ep in
                            Button {
                                onSelectEpisode(ep)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(ep.title)
                                            .font(.cyberpunkBody())
                                            .foregroundColor(.cyberpunkTextPrimary)
                                        Text(ep.episode_id)
                                            .font(.cyberpunkCaption())
                                            .foregroundColor(.cyberpunkTextSecondary)
                                    }
                                    Spacer()
                                    Image(systemName: "play.circle.fill")
                                        .foregroundColor(.cyberpunkYellow)
                                        .font(.system(size: 24))
                                }
                                .padding(14)
                                .background(Color.cyberpunkPanelBg)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cyberpunkYellow.opacity(0.4), lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(16)
                }
                .background(Color.cyberpunkCardBg)
            }
        }
        .background(Color.cyberpunkCardBg)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.cyberpunkBorder.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
        .onAppear {
            // 🔐 잠금 로직 훅 (나중에 gameManager 상태에 맞게 교체)
            let all = EpisodeIndexLoader.load(merchantId: merchant.id)
            episodes = all.filter { _ in true }
        }
    }
}

// MARK: - Trade Error Overlay

struct TradeErrorOverlay: View {
    let error: MerchantDataError
    let onDismiss: () -> Void
    let onBack: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.red)
                }

                VStack(spacing: 12) {
                    Text("거래 오류")
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(error.localizedDescription)
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.cyberpunkTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }

                VStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("재시도")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Rectangle().fill(Color.cyberpunkCyan))
                            .overlay(Rectangle().stroke(Color.cyberpunkCyan.opacity(0.6), lineWidth: 2))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        onDismiss()
                        onBack()
                    }) {
                        Text("대화로 돌아가기")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyberpunkCyan)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Rectangle().stroke(Color.cyberpunkCyan, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
            }
            .padding(30)
            .frame(maxWidth: 400)
            .background(
                Rectangle()
                    .fill(Color.cyberpunkDarkBg)
                    .overlay(Rectangle().stroke(Color.red.opacity(0.6), lineWidth: 2))
            )
            .padding(.horizontal, 40)
        }
    }
}
