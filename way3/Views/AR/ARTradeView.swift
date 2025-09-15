//
//  ARTradeView.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  AR 거래 메인 화면
//

import SwiftUI
import ARKit
import RealityKit

struct ARTradeView: View {
    @StateObject private var arTradeSystem = ARTradeSystem()
    @State private var showingPermissionAlert = false
    @State private var showingUnsupportedAlert = false
    @State private var selectedMerchant: ARMerchant?
    @State private var showingTradeDetail = false
    
    var body: some View {
        ZStack {
            if arTradeSystem.isARSupported {
                ARViewContainer(arTradeSystem: arTradeSystem)
                    .edgesIgnoringSafeArea(.all)
                
                // AR UI 오버레이
                VStack {
                    // 상단 컨트롤
                    ARTopControls(arTradeSystem: arTradeSystem)
                    
                    Spacer()
                    
                    // 하단 정보 패널
                    ARBottomPanel(
                        arTradeSystem: arTradeSystem,
                        selectedMerchant: $selectedMerchant,
                        showingTradeDetail: $showingTradeDetail
                    )
                }
                
                // AR 크로스헤어
                ARCrosshair()
                
                // 거래 상세 모달
                if showingTradeDetail, let merchant = selectedMerchant {
                    ARTradeDetailModal(
                        merchant: merchant,
                        isPresented: $showingTradeDetail
                    )
                }
                
            } else {
                ARUnsupportedView()
            }
        }
        .onAppear {
            checkPermissionsAndStartAR()
        }
        .alert("AR 권한 필요", isPresented: $showingPermissionAlert) {
            Button("설정으로 이동") {
                openSettings()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("AR 거래 기능을 사용하려면 카메라 권한이 필요합니다.")
        }
        .alert("AR 미지원", isPresented: $showingUnsupportedAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("이 기기는 AR 기능을 지원하지 않습니다.")
        }
    }
    
    private func checkPermissionsAndStartAR() {
        if !arTradeSystem.isARSupported {
            showingUnsupportedAlert = true
            return
        }
        
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthStatus {
        case .authorized:
            // AR 세션 시작은 ARViewContainer에서 처리
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        self.showingPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        @unknown default:
            showingPermissionAlert = true
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - ARView Container
struct ARViewContainer: UIViewRepresentable {
    let arTradeSystem: ARTradeSystem
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.session.delegate = arTradeSystem
        
        // 제스처 인식기 추가
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        // AR 세션 시작
        arTradeSystem.startARSession(with: arView)
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        // AR 뷰 업데이트 처리
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(arTradeSystem: arTradeSystem)
    }
    
    class Coordinator {
        let arTradeSystem: ARTradeSystem
        
        init(arTradeSystem: ARTradeSystem) {
            self.arTradeSystem = arTradeSystem
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            arTradeSystem.handleARTap(at: location)
        }
    }
}

// MARK: - AR 상단 컨트롤
struct ARTopControls: View {
    @ObservedObject var arTradeSystem: ARTradeSystem
    
    var body: some View {
        HStack {
            // 세션 상태 표시
            HStack(spacing: 8) {
                Circle()
                    .fill(arTradeSystem.isARSessionActive ? .green : .red)
                    .frame(width: 8, height: 8)
                
                Text(arTradeSystem.isARSessionActive ? "AR 활성" : "AR 비활성")
                    .font(.custom("ChosunCentennial", size: 12))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.black.opacity(0.7))
            .cornerRadius(20)
            
            Spacer()
            
            // 근처 상인 수
            HStack(spacing: 4) {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.white)
                Text("\(arTradeSystem.nearbyARMerchants.count)")
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.blue.opacity(0.8))
            .cornerRadius(20)
        }
        .padding()
    }
}

// MARK: - AR 하단 패널
struct ARBottomPanel: View {
    @ObservedObject var arTradeSystem: ARTradeSystem
    @Binding var selectedMerchant: ARMerchant?
    @Binding var showingTradeDetail: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            // 오류 메시지
            if let error = arTradeSystem.arSessionError {
                Text(error)
                    .font(.custom("ChosunCentennial", size: 14))
                    .foregroundColor(.red)
                    .padding()
                    .background(.white.opacity(0.9))
                    .cornerRadius(12)
            }
            
            // 근처 상인 목록
            if !arTradeSystem.nearbyARMerchants.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(arTradeSystem.nearbyARMerchants) { merchant in
                            ARMerchantCard(merchant: merchant) {
                                selectedMerchant = merchant
                                showingTradeDetail = true
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 120)
            }
            
            // 안내 메시지
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.white)
                    Text("화면을 탭하여 상인과 거래하세요")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 12) {
                    Image(systemName: "camera.viewfinder")
                        .foregroundColor(.white)
                    Text("카메라를 움직여 주변을 탐색하세요")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
            .background(.black.opacity(0.6))
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - AR 상인 카드
struct ARMerchantCard: View {
    let merchant: ARMerchant
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 상인 아이콘
                ZStack {
                    Circle()
                        .fill(Color(merchant.color))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                
                // 상인 정보
                VStack(spacing: 2) {
                    Text(merchant.name)
                        .font(.custom("ChosunCentennial", size: 12))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text("\(merchant.inventory.count)개 아이템")
                        .font(.custom("ChosunCentennial", size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 80)
            .padding(.vertical, 8)
            .background(.black.opacity(0.7))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AR 크로스헤어
struct ARCrosshair: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(.white.opacity(0.5), lineWidth: 2)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 4, height: 4)
                }
                
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - AR 거래 상세 모달
struct ARTradeDetailModal: View {
    let merchant: ARMerchant
    @Binding var isPresented: Bool
    @State private var selectedItem: ARTradeItem?
    @State private var tradeQuantity = 1
    
    var body: some View {
        ZStack {
            // 배경 블러
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // 모달 컨텐츠
            VStack(spacing: 20) {
                // 헤더
                HStack {
                    VStack(alignment: .leading) {
                        Text(merchant.name)
                            .font(.custom("ChosunCentennial", size: 20))
                            .fontWeight(.bold)
                        
                        Text("AR 거래상")
                            .font(.custom("ChosunCentennial", size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("닫기") {
                        isPresented = false
                    }
                    .font(.custom("ChosunCentennial", size: 16))
                }
                
                Divider()
                
                // 아이템 목록
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(merchant.inventory) { arItem in
                            ARTradeItemCard(
                                arItem: arItem,
                                isSelected: selectedItem?.id == arItem.id
                            ) {
                                selectedItem = arItem
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                // 거래 버튼
                if let selectedItem = selectedItem {
                    VStack(spacing: 12) {
                        HStack {
                            Text("수량:")
                            Stepper(value: $tradeQuantity, in: 1...10) {
                                Text("\(tradeQuantity)")
                                    .font(.custom("ChosunCentennial", size: 16))
                            }
                        }
                        
                        Button("AR로 거래하기") {
                            performARTrade(item: selectedItem)
                        }
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(.blue)
                        .cornerRadius(25)
                    }
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(20)
            .padding()
        }
    }
    
    private func performARTrade(item: ARTradeItem) {
        // AR 거래 로직 구현
        // 실제로는 3D 애니메이션과 함께 거래 처리
        withAnimation {
            isPresented = false
        }
        
        // 성공 햅틱 피드백
        let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        impactGenerator.impactOccurred()
    }
}

// MARK: - AR 거래 아이템 카드
struct ARTradeItemCard: View {
    let arItem: ARTradeItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // 3D 모델 미리보기 (실제로는 Model3D 사용)
                RoundedRectangle(cornerRadius: 8)
                    .fill(arItem.tradeItem.grade.color.opacity(0.3))
                    .frame(height: 80)
                    .overlay {
                        VStack {
                            Image(systemName: "cube.fill")
                                .font(.system(size: 30))
                                .foregroundColor(arItem.tradeItem.grade.color)
                            
                            Text("3D")
                                .font(.custom("ChosunCentennial", size: 10))
                                .foregroundColor(arItem.tradeItem.grade.color)
                        }
                    }
                
                VStack(spacing: 4) {
                    Text(arItem.tradeItem.name)
                        .font(.custom("ChosunCentennial", size: 14))
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Text("₩\(arItem.tradeItem.currentPrice)")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.blue)
                    
                    Text(arItem.tradeItem.grade.displayName)
                        .font(.custom("ChosunCentennial", size: 10))
                        .foregroundColor(arItem.tradeItem.grade.color)
                }
            }
            .padding()
            .background(isSelected ? .blue.opacity(0.2) : .gray.opacity(0.1))
            .cornerRadius(12)
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? .blue : .clear, lineWidth: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - AR 미지원 뷰
struct ARUnsupportedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 80))
                .foregroundColor(.gray)
            
            Text("AR 기능 미지원")
                .font(.custom("ChosunCentennial", size: 24))
                .fontWeight(.bold)
            
            Text("이 기기는 AR 거래 기능을 지원하지 않습니다.\n일반 거래 모드를 사용해주세요.")
                .font(.custom("ChosunCentennial", size: 16))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ARTradeView()
}