//
//  NearbyPlayersView.swift
//  way3 - Nearby Players Interface
//
//  주변 플레이어 목록 및 상호작용 인터페이스
//

import SwiftUI

struct NearbyPlayersView: View {
    @EnvironmentObject var socketManager: SocketManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPlayer: SocketManager.NearbyPlayer?
    @State private var showTradeOffer = false
    @State private var searchRadius: Double = 1000
    
    var body: some View {
        NavigationView {
            VStack {
                // 검색 범위 조절
                searchRadiusControl
                
                if socketManager.nearbyPlayers.isEmpty {
                    // 빈 상태
                    emptyState
                } else {
                    // 플레이어 목록
                    playersList
                }
            }
            .navigationTitle("근처 플레이어")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshPlayers) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .sheet(isPresented: $showTradeOffer) {
            if let player = selectedPlayer {
                TradeOfferView(targetPlayer: player)
                    .environmentObject(socketManager)
            }
        }
    }
    
    // MARK: - Search Radius Control
    private var searchRadiusControl: some View {
        VStack(spacing: 8) {
            HStack {
                Text("검색 범위")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(searchRadius < 1000 ? Int(searchRadius) : Int(searchRadius / 1000))\(searchRadius < 1000 ? "m" : "km")")
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)
            }
            
            Slider(value: $searchRadius, in: 100...5000, step: 100) {
                Text("검색 범위")
            }
            .tint(.blue)
            .onChange(of: searchRadius) { _ in
                // 범위 변경 시 재검색
                refreshPlayers()
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("근처에 플레이어가 없습니다")
                .font(.custom("ChosunCentennial", size: 20))
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            Text("검색 범위를 넓히거나\n인기 있는 지역으로 이동해보세요")
                .font(.custom("ChosunCentennial", size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("새로고침") {
                refreshPlayers()
            }
            .buttonStyle(.bordered)
            .tint(.blue)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Players List
    private var playersList: some View {
        List {
            Section(header: Text("\(socketManager.nearbyPlayers.count)명의 플레이어 발견")
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.secondary)
            ) {
                ForEach(socketManager.nearbyPlayers.sorted { $0.distance < $1.distance }) { player in
                    PlayerRowView(player: player) {
                        selectedPlayer = player
                        showTradeOffer = true
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
    
    // MARK: - Methods
    private func refreshPlayers() {
        // LocationManager에서 현재 위치를 가져와서 검색
        // 실제 구현에서는 locationManager를 통해 현재 위치 확인 필요
        socketManager.searchNearbyPlayers(
            lat: 37.5665,  // 현재 위치로 대체 필요
            lng: 126.9780, // 현재 위치로 대체 필요
            radius: searchRadius
        )
    }
}

// MARK: - Player Row View
struct PlayerRowView: View {
    let player: SocketManager.NearbyPlayer
    let onTradeOffer: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 플레이어 아바타
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)

                VStack(spacing: 2) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)

                    Text("\(player.level)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            
            // 플레이어 정보
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.custom("ChosunCentennial", size: 16))
                    .fontWeight(.semibold)

                HStack {
                    Text("레벨 \(player.level)")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(player.distanceText)
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }
            }
            
            Spacer()
            
            // 거래 제안 버튼
            Button(action: onTradeOffer) {
                Image(systemName: "handshake.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.green))
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trade Offer View
struct TradeOfferView: View {
    let targetPlayer: SocketManager.NearbyPlayer
    @EnvironmentObject var socketManager: SocketManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedOfferedItems: [String] = []
    @State private var selectedRequestedItems: [String] = []
    @State private var tradeMessage = ""
    
    // 임시 아이템 목록 (실제로는 플레이어 인벤토리에서 가져옴)
    private let availableItems = [
        "스마트폰", "노트북", "이어폰", "태블릿", "게임 콘솔",
        "정장", "운동화", "가방", "시계", "모자",
        "김치", "고급 한우", "인삼", "녹차", "막걸리"
    ]
    
    var body: some View {
        NavigationView {
            VStack {
                // 대상 플레이어 정보
                targetPlayerInfo
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 제공할 아이템 선택
                        offerSection
                        
                        // 요청할 아이템 입력
                        requestSection
                        
                        // 메시지 입력
                        messageSection
                    }
                    .padding()
                }
                
                // 전송 버튼
                sendOfferButton
            }
            .navigationTitle("거래 제안")
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
    
    // MARK: - Target Player Info
    private var targetPlayerInfo: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 60)

                VStack(spacing: 2) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)

                    Text("\(targetPlayer.level)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(targetPlayer.name)
                    .font(.custom("ChosunCentennial", size: 20))
                    .fontWeight(.bold)

                Text("레벨 \(targetPlayer.level) • \(targetPlayer.distanceText)")
                    .font(.custom("ChosunCentennial", size: 16))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Offer Section
    private var offerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("제공할 아이템")
                .font(.custom("ChosunCentennial", size: 18))
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(availableItems, id: \.self) { item in
                    Button(action: {
                        toggleOfferedItem(item)
                    }) {
                        Text(item)
                            .font(.custom("ChosunCentennial", size: 14))
                            .padding(8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedOfferedItems.contains(item) ?
                                          Color.green.opacity(0.2) :
                                          Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedOfferedItems.contains(item) ?
                                                   Color.green : Color.gray.opacity(0.3),
                                                   lineWidth: 1)
                                    )
                            )
                            .foregroundColor(selectedOfferedItems.contains(item) ?
                                           Color.green : Color.primary)
                    }
                }
            }
            
            if !selectedOfferedItems.isEmpty {
                Text("선택된 아이템: \(selectedOfferedItems.joined(separator: ", "))")
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.green)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Request Section
    private var requestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("요청할 아이템")
                .font(.custom("ChosunCentennial", size: 18))
                .fontWeight(.semibold)
            
            // 요청 아이템 입력 필드들
            VStack(spacing: 8) {
                ForEach(0..<max(1, selectedRequestedItems.count + 1), id: \.self) { index in
                    HStack {
                        TextField("아이템 이름을 입력하세요", text: Binding(
                            get: { 
                                index < selectedRequestedItems.count ? selectedRequestedItems[index] : ""
                            },
                            set: { newValue in
                                updateRequestedItem(at: index, with: newValue)
                            }
                        ))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.custom("ChosunCentennial", size: 16))
                        
                        if index < selectedRequestedItems.count && !selectedRequestedItems[index].isEmpty {
                            Button(action: {
                                selectedRequestedItems.remove(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Message Section
    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("메시지 (선택사항)")
                .font(.custom("ChosunCentennial", size: 18))
                .fontWeight(.semibold)

            TextField("거래 제안에 대한 메시지를 입력하세요", text: $tradeMessage, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.custom("ChosunCentennial", size: 16))
                .lineLimit(3...6)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    // MARK: - Send Offer Button
    private var sendOfferButton: some View {
        Button(action: sendTradeOffer) {
            Text("거래 제안 보내기")
                .font(.custom("ChosunCentennial", size: 16))
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canSendOffer ? Color.green : Color.gray)
                )
        }
        .disabled(!canSendOffer)
        .padding()
    }
    
    private var canSendOffer: Bool {
        !selectedOfferedItems.isEmpty && !selectedRequestedItems.filter { !$0.isEmpty }.isEmpty
    }
    
    // MARK: - Methods
    private func toggleOfferedItem(_ item: String) {
        if selectedOfferedItems.contains(item) {
            selectedOfferedItems.removeAll { $0 == item }
        } else {
            selectedOfferedItems.append(item)
        }
    }
    
    private func updateRequestedItem(at index: Int, with value: String) {
        if index >= selectedRequestedItems.count {
            if !value.isEmpty {
                selectedRequestedItems.append(value)
            }
        } else {
            if value.isEmpty {
                selectedRequestedItems.remove(at: index)
            } else {
                selectedRequestedItems[index] = value
            }
        }
    }
    
    private func sendTradeOffer() {
        let filteredRequestedItems = selectedRequestedItems.filter { !$0.isEmpty }
        
        socketManager.sendTradeOffer(
            to: targetPlayer.id,
            playerName: targetPlayer.name,
            offeredItems: selectedOfferedItems,
            requestedItems: filteredRequestedItems,
            message: tradeMessage.isEmpty ? nil : tradeMessage
        )
        
        dismiss()
    }
}

#Preview {
    NearbyPlayersView()
        .environmentObject(SocketManager.shared)
}