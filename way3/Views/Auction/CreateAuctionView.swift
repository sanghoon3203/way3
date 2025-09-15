//
//  CreateAuctionView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  경매 생성 인터페이스 - 아이템 선택부터 경매 등록까지
//

import SwiftUI

struct CreateAuctionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tradeManager = TradeManager.shared
    @ObservedObject var auctionManager: AuctionManager
    
    @State private var selectedItem: TradeItem?
    @State private var selectedAuctionType: AuctionType = .standard
    @State private var startingPrice: String = ""
    @State private var auctionDuration: Double = 3600 // 1시간 기본값
    @State private var showingCreateConfirm = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isCreating = false
    
    // 예약가 경매용
    @State private var reservePrice: String = ""
    
    // 네덜란드 경매용
    @State private var decrementAmount: String = ""
    @State private var decrementInterval: Double = 300 // 5분 기본값
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 헤더
                    VStack(spacing: 12) {
                        Text("경매 생성")
                            .font(.custom("ChosunCentennial", size: 28))
                            .fontWeight(.bold)
                        
                        Text("보유 아이템을 경매에 등록하여\n다른 상인들과 거래하세요")
                            .font(.custom("ChosunCentennial", size: 16))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // 아이템 선택 섹션
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cube.box.fill")
                                .foregroundColor(.blue)
                            Text("경매할 아이템 선택")
                                .font(.custom("ChosunCentennial", size: 18))
                                .fontWeight(.semibold)
                        }
                        
                        if let selectedItem = selectedItem {
                            SelectedItemCard(item: selectedItem) {
                                self.selectedItem = nil
                            }
                        } else {
                            Button("아이템 선택하기") {
                                // 인벤토리 모달 표시
                            }
                            .font(.custom("ChosunCentennial", size: 16))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(12)
                            .overlay {
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.blue, style: StrokeStyle(lineWidth: 1, dash: [5]))
                            }
                        }
                        
                        // 보유 아이템 목록
                        InventoryGrid(
                            items: tradeManager.inventory,
                            selectedItem: $selectedItem
                        )
                    }
                    .padding(.horizontal)
                    
                    // 경매 유형 선택
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "hammer.fill")
                                .foregroundColor(.orange)
                            Text("경매 유형")
                                .font(.custom("ChosunCentennial", size: 18))
                                .fontWeight(.semibold)
                        }
                        
                        AuctionTypeSelector(selectedType: $selectedAuctionType)
                    }
                    .padding(.horizontal)
                    
                    // 경매 설정
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "gear.circle.fill")
                                .foregroundColor(.green)
                            Text("경매 설정")
                                .font(.custom("ChosunCentennial", size: 18))
                                .fontWeight(.semibold)
                        }
                        
                        // 시작가
                        VStack(alignment: .leading, spacing: 8) {
                            Text("시작가")
                                .font(.custom("ChosunCentennial", size: 16))
                                .fontWeight(.medium)
                            
                            HStack {
                                TextField("시작가를 입력하세요", text: $startingPrice)
                                    .keyboardType(.numberPad)
                                    .font(.custom("ChosunCentennial", size: 16))
                                    .padding()
                                    .background(.gray.opacity(0.1))
                                    .cornerRadius(12)
                                
                                Text("원")
                                    .font(.custom("ChosunCentennial", size: 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // 예약가 (예약가 경매일 때만)
                        if selectedAuctionType == .reserve {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("예약가")
                                        .font(.custom("ChosunCentennial", size: 16))
                                        .fontWeight(.medium)
                                    
                                    Button {
                                        // 예약가 설명
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                                
                                HStack {
                                    TextField("최소 낙찰가를 입력하세요", text: $reservePrice)
                                        .keyboardType(.numberPad)
                                        .font(.custom("ChosunCentennial", size: 16))
                                        .padding()
                                        .background(.gray.opacity(0.1))
                                        .cornerRadius(12)
                                    
                                    Text("원")
                                        .font(.custom("ChosunCentennial", size: 16))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        // 네덜란드 경매 설정
                        if selectedAuctionType == .dutch {
                            VStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("가격 하락폭")
                                        .font(.custom("ChosunCentennial", size: 16))
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        TextField("하락폭을 입력하세요", text: $decrementAmount)
                                            .keyboardType(.numberPad)
                                            .font(.custom("ChosunCentennial", size: 16))
                                            .padding()
                                            .background(.gray.opacity(0.1))
                                            .cornerRadius(12)
                                        
                                        Text("원")
                                            .font(.custom("ChosunCentennial", size: 16))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("하락 간격")
                                        .font(.custom("ChosunCentennial", size: 16))
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Slider(value: $decrementInterval, in: 60...600, step: 60) {
                                            Text("하락 간격")
                                        }
                                        .accentColor(.orange)
                                        
                                        Text("\(Int(decrementInterval / 60))분")
                                            .font(.custom("ChosunCentennial", size: 14))
                                            .foregroundColor(.secondary)
                                            .frame(width: 40)
                                    }
                                }
                            }
                        }
                        
                        // 경매 시간
                        VStack(alignment: .leading, spacing: 8) {
                            Text("경매 기간")
                                .font(.custom("ChosunCentennial", size: 16))
                                .fontWeight(.medium)
                            
                            HStack {
                                Slider(value: $auctionDuration, in: 1800...86400, step: 1800) {
                                    Text("경매 기간")
                                }
                                .accentColor(.green)
                                
                                Text(formatDuration(auctionDuration))
                                    .font(.custom("ChosunCentennial", size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(width: 60)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // 경매 미리보기
                    if selectedItem != nil {
                        AuctionPreviewCard(
                            item: selectedItem!,
                            auctionType: selectedAuctionType,
                            startingPrice: Int(startingPrice) ?? 0,
                            duration: auctionDuration
                        )
                        .padding(.horizontal)
                    }
                    
                    // 생성 버튼
                    VStack(spacing: 12) {
                        Button("경매 생성하기") {
                            createAuction()
                        }
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(canCreateAuction ? .blue : .gray)
                        .cornerRadius(28)
                        .disabled(!canCreateAuction || isCreating)
                        .opacity(isCreating ? 0.7 : 1.0)
                        .overlay {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            }
                        }
                        
                        Button("취소") {
                            dismiss()
                        }
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
        .alert("경매 생성 오류", isPresented: $showingError) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var canCreateAuction: Bool {
        guard let selectedItem = selectedItem,
              let startingPriceInt = Int(startingPrice),
              startingPriceInt > 0 else {
            return false
        }
        
        if selectedAuctionType == .reserve {
            guard let reservePriceInt = Int(reservePrice),
                  reservePriceInt >= startingPriceInt else {
                return false
            }
        }
        
        if selectedAuctionType == .dutch {
            guard let decrementInt = Int(decrementAmount),
                  decrementInt > 0,
                  decrementInt < startingPriceInt else {
                return false
            }
        }
        
        return true
    }
    
    private func createAuction() {
        guard let selectedItem = selectedItem,
              let startingPriceInt = Int(startingPrice) else {
            return
        }
        
        isCreating = true
        
        // 경매 생성 로직
        auctionManager.createAuction(
            item: selectedItem,
            startingPrice: startingPriceInt,
            duration: auctionDuration
        )
        
        // 성공 처리 (실제로는 서버 응답 처리)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isCreating = false
            dismiss()
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
}

// MARK: - 선택된 아이템 카드
struct SelectedItemCard: View {
    let item: TradeItem
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 아이템 이미지 영역
            RoundedRectangle(cornerRadius: 12)
                .fill(item.grade.color.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay {
                    VStack {
                        Image(systemName: "cube.fill")
                            .font(.system(size: 24))
                            .foregroundColor(item.grade.color)
                        
                        Text(String(item.grade.rawValue))
                            .font(.custom("ChosunCentennial", size: 10))
                            .foregroundColor(item.grade.color)
                    }
                }
            
            // 아이템 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
                
                Text(item.category)
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.secondary)
                
                Text(item.grade.displayName)
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(item.grade.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(item.grade.color.opacity(0.2))
                    .cornerRadius(6)
            }
            
            Spacer()
            
            // 제거 버튼
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - 인벤토리 그리드
struct InventoryGrid: View {
    let items: [TradeItem]
    @Binding var selectedItem: TradeItem?
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Array(items.prefix(9).enumerated()), id: \.element.itemId) { index, item in
                InventoryItemCard(
                    item: item,
                    isSelected: selectedItem?.itemId == item.itemId
                ) {
                    selectedItem = item
                }
            }
        }
        .frame(maxHeight: 220)
    }
}

// Note: InventoryItemCard is defined in Components/InventoryItemCard.swift to avoid duplicates

// MARK: - 경매 유형 선택기
struct AuctionTypeSelector: View {
    @Binding var selectedType: AuctionType
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(AuctionType.allCases, id: \.rawValue) { type in
                AuctionTypeCard(
                    type: type,
                    isSelected: selectedType == type
                ) {
                    selectedType = type
                }
            }
        }
    }
}

// MARK: - 경매 유형 카드
struct AuctionTypeCard: View {
    let type: AuctionType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // 아이콘
                ZStack {
                    Circle()
                        .fill(type.color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: type.iconName)
                        .font(.system(size: 24))
                        .foregroundColor(type.color)
                }
                
                // 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.custom("ChosunCentennial", size: 16))
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                // 선택 표시
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(isSelected ? .blue.opacity(0.05) : .gray.opacity(0.02))
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .gray.opacity(0.3), lineWidth: 1)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 경매 미리보기 카드
struct AuctionPreviewCard: View {
    let item: TradeItem
    let auctionType: AuctionType
    let startingPrice: Int
    let duration: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "eye.fill")
                    .foregroundColor(.purple)
                Text("경매 미리보기")
                    .font(.custom("ChosunCentennial", size: 18))
                    .fontWeight(.semibold)
            }
            
            VStack(spacing: 16) {
                // 아이템 정보
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(item.grade.color.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .overlay {
                            Image(systemName: "cube.fill")
                                .foregroundColor(item.grade.color)
                        }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.semibold)
                        
                        HStack {
                            Text(auctionType.displayName)
                                .font(.custom("ChosunCentennial", size: 12))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(auctionType.color)
                                .cornerRadius(6)
                            
                            Text(item.grade.displayName)
                                .font(.custom("ChosunCentennial", size: 12))
                                .foregroundColor(item.grade.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(item.grade.color.opacity(0.2))
                                .cornerRadius(6)
                        }
                    }
                    
                    Spacer()
                }
                
                // 가격 정보
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("시작가")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("₩\(startingPrice)")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("경매 기간")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(duration))
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(.purple.opacity(0.05))
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.purple.opacity(0.3), lineWidth: 1)
            }
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            return "\(hours)시간"
        } else {
            return "\(minutes)분"
        }
    }
}

#Preview {
    CreateAuctionView(auctionManager: AuctionManager())
}