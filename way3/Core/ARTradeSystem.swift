//
//  ARTradeSystem.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  AR 거래 시스템 - ARKit을 활용한 실시간 3D 거래
//

import Foundation
import SwiftUI
import ARKit
import RealityKit
import Combine

// MARK: - AR 거래 매니저
class ARTradeSystem: NSObject, ObservableObject {
    @Published var isARSupported = false
    @Published var isARSessionActive = false
    @Published var nearbyARMerchants: [ARMerchant] = []
    @Published var selectedARItem: ARTradeItem?
    @Published var arSessionError: String?
    
    private var arView: ARView?
    private var anchorEntities: [String: AnchorEntity] = [:]
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        checkARSupport()
        setupLocationManager()
    }
    
    // MARK: - AR 지원 체크
    private func checkARSupport() {
        if ARWorldTrackingConfiguration.isSupported {
            isARSupported = true
        } else {
            arSessionError = "이 기기는 AR을 지원하지 않습니다."
        }
    }
    
    // MARK: - AR 세션 시작
    func startARSession(with arView: ARView) {
        self.arView = arView
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.environmentTexturing = .automatic
        
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }
        
        arView.session.run(configuration)
        arView.session.delegate = self
        
        isARSessionActive = true
        
        // 근처 상인들을 AR 공간에 배치
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateARMerchants()
        }
    }
    
    // MARK: - AR 세션 종료
    func stopARSession() {
        arView?.session.pause()
        isARSessionActive = false
        clearAllARContent()
    }
    
    // MARK: - AR 상인 업데이트
    private func updateARMerchants() {
        guard let arView = arView,
              let currentLocation = locationManager.location else { return }
        
        // 실제로는 서버에서 근처 상인 데이터를 가져와야 함
        let mockMerchants = generateMockARMerchants()
        
        DispatchQueue.main.async {
            self.nearbyARMerchants = mockMerchants
            self.placeARMerchants(mockMerchants)
        }
    }
    
    // MARK: - AR 상인 배치
    private func placeARMerchants(_ merchants: [ARMerchant]) {
        guard let arView = arView else { return }
        
        for merchant in merchants {
            // 이미 배치된 상인은 스킵
            if anchorEntities[merchant.id] != nil { continue }
            
            let anchorEntity = AnchorEntity(world: merchant.worldPosition)
            
            // 상인 3D 모델 생성
            let merchantModel = createMerchantModel(for: merchant)
            anchorEntity.addChild(merchantModel)
            
            // 상호작용 가능한 영역 추가
            let interactionSphere = ModelEntity(
                mesh: .generateSphere(radius: 0.5),
                materials: [SimpleMaterial(color: .blue.withAlphaComponent(0.3), isMetallic: false)]
            )
            interactionSphere.position = [0, 1, 0]
            anchorEntity.addChild(interactionSphere)
            
            // 상인 정보 UI 패널
            let infoPanel = createInfoPanel(for: merchant)
            infoPanel.position = [0, 2, 0]
            anchorEntity.addChild(infoPanel)
            
            arView.scene.addAnchor(anchorEntity)
            anchorEntities[merchant.id] = anchorEntity
        }
    }
    
    // MARK: - 3D 상인 모델 생성
    private func createMerchantModel(for merchant: ARMerchant) -> ModelEntity {
        let bodyMesh = MeshResource.generateBox(width: 0.4, height: 1.8, depth: 0.3)
        let bodyMaterial = SimpleMaterial(color: merchant.color, roughness: 0.5, isMetallic: false)
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        
        // 머리 추가
        let headMesh = MeshResource.generateSphere(radius: 0.2)
        let headMaterial = SimpleMaterial(color: .systemPink, roughness: 0.3, isMetallic: false)
        let head = ModelEntity(mesh: headMesh, materials: [headMaterial])
        head.position = [0, 1.1, 0]
        body.addChild(head)
        
        // 애니메이션 추가
        let rotationAnimation = try! AnimationResource.generate(
            with: FromToByAnimation(
                from: Transform.identity,
                to: Transform(rotation: simd_quatf(angle: .pi * 2, axis: [0, 1, 0])),
                duration: 4.0
            )
        )
        body.playAnimation(rotationAnimation.repeat())
        
        return body
    }
    
    // MARK: - 정보 패널 생성
    private func createInfoPanel(for merchant: ARMerchant) -> ModelEntity {
        let panelMesh = MeshResource.generatePlane(width: 1.0, depth: 0.6)
        let panelMaterial = SimpleMaterial(color: .white.withAlphaComponent(0.9), isMetallic: false)
        let panel = ModelEntity(mesh: panelMesh, materials: [panelMaterial])
        
        // 텍스트는 실제로는 TextKit을 사용하여 렌더링해야 함
        // 여기서는 간단한 색상으로 대체
        let textIndicator = ModelEntity(
            mesh: .generateBox(width: 0.8, height: 0.1, depth: 0.01),
            materials: [SimpleMaterial(color: .black, isMetallic: false)]
        )
        textIndicator.position = [0, 0.1, 0.01]
        panel.addChild(textIndicator)
        
        return panel
    }
    
    // MARK: - AR 아이템 생성
    func createARTradeItem(_ item: TradeItem, at position: SIMD3<Float>) {
        guard let arView = arView else { return }
        
        let anchorEntity = AnchorEntity(world: position)
        
        // 아이템 3D 모델
        let itemModel = createItemModel(for: item)
        anchorEntity.addChild(itemModel)
        
        // 홀로그램 효과
        let hologramEffect = createHologramEffect()
        hologramEffect.position = position
        anchorEntity.addChild(hologramEffect)
        
        arView.scene.addAnchor(anchorEntity)
    }
    
    // MARK: - 아이템 3D 모델 생성
    private func createItemModel(for item: TradeItem) -> ModelEntity {
        let itemMesh: MeshResource
        let itemColor: UIColor
        
        // 카테고리에 따른 3D 모양 결정
        switch item.category {
        case "보석":
            itemMesh = .generateBox(width: 0.1, height: 0.1, depth: 0.1)
            itemColor = .systemYellow
        case "직물":
            itemMesh = .generatePlane(width: 0.2, depth: 0.2)
            itemColor = .systemPurple
        case "금속공예":
            itemMesh = .generateCylinder(height: 0.3, radius: 0.05)
            itemColor = .systemGray
        default:
            itemMesh = .generateSphere(radius: 0.1)
            itemColor = .systemBlue
        }
        
        let material = SimpleMaterial(
            color: itemColor,
            roughness: 0.2,
            isMetallic: item.category == "금속공예"
        )
        
        let model = ModelEntity(mesh: itemMesh, materials: [material])
        
        // 회전 애니메이션
        let rotation = try! AnimationResource.generate(
            with: FromToByAnimation(
                from: Transform.identity,
                to: Transform(rotation: simd_quatf(angle: .pi * 2, axis: [0, 1, 0])),
                duration: 3.0
            )
        )
        model.playAnimation(rotation.repeat())
        
        return model
    }
    
    // MARK: - 홀로그램 효과
    private func createHologramEffect() -> ModelEntity {
        let effectMesh = MeshResource.generateSphere(radius: 0.2)
        let effectMaterial = SimpleMaterial(
            color: .cyan.withAlphaComponent(0.3),
            roughness: 0.0,
            isMetallic: true
        )
        
        let effect = ModelEntity(mesh: effectMesh, materials: [effectMaterial])
        
        // 펄스 애니메이션
        let scaleAnimation = try! AnimationResource.generate(
            with: FromToByAnimation(
                from: Transform.identity,
                to: Transform(scale: SIMD3<Float>(repeating: 1.2)),
                duration: 2.0
            )
        )
        effect.playAnimation(scaleAnimation.repeat())
        
        return effect
    }
    
    // MARK: - 제스처 처리
    func handleARTap(at location: CGPoint) {
        guard let arView = arView else { return }
        
        let results = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .any)
        
        if let firstResult = results.first {
            let position = firstResult.worldTransform.columns.3
            let worldPosition = SIMD3<Float>(position.x, position.y, position.z)
            
            // 가장 가까운 상인 찾기
            let nearestMerchant = findNearestMerchant(to: worldPosition)
            
            if let merchant = nearestMerchant,
               distance(worldPosition, merchant.worldPosition) < 2.0 {
                // 거래 시작
                startARTrade(with: merchant)
            }
        }
    }
    
    // MARK: - AR 거래 시작
    private func startARTrade(with merchant: ARMerchant) {
        // 거래 UI를 AR 공간에 표시
        showARTradeInterface(for: merchant)
    }
    
    private func showARTradeInterface(for merchant: ARMerchant) {
        guard let arView = arView,
              let anchorEntity = anchorEntities[merchant.id] else { return }
        
        // 거래 인터페이스 패널 생성
        let tradePanel = createTradePanel(for: merchant)
        tradePanel.position = [0, 1.5, 0]
        anchorEntity.addChild(tradePanel)
    }
    
    private func createTradePanel(for merchant: ARMerchant) -> ModelEntity {
        let panelMesh = MeshResource.generatePlane(width: 2.0, depth: 1.5)
        let panelMaterial = SimpleMaterial(
            color: .white.withAlphaComponent(0.9),
            isMetallic: false
        )
        
        let panel = ModelEntity(mesh: panelMesh, materials: [panelMaterial])
        
        // 아이템들을 3D 그리드로 배치
        for (index, item) in merchant.inventory.enumerated() {
            let itemModel = createItemModel(for: item.tradeItem)
            let row = index / 3
            let col = index % 3
            itemModel.position = [
                Float(col - 1) * 0.4,
                Float(1 - row) * 0.3,
                0.1
            ]
            panel.addChild(itemModel)
        }
        
        return panel
    }
    
    // MARK: - 유틸리티 메서드
    private func findNearestMerchant(to position: SIMD3<Float>) -> ARMerchant? {
        return nearbyARMerchants.min { merchant1, merchant2 in
            distance(position, merchant1.worldPosition) < distance(position, merchant2.worldPosition)
        }
    }
    
    private func distance(_ pos1: SIMD3<Float>, _ pos2: SIMD3<Float>) -> Float {
        return length(pos1 - pos2)
    }
    
    private func clearAllARContent() {
        arView?.scene.anchors.removeAll()
        anchorEntities.removeAll()
    }
    
    // MARK: - Mock 데이터
    private func generateMockARMerchants() -> [ARMerchant] {
        return [
            ARMerchant(
                id: "ar_merchant_1",
                name: "AR 보석상",
                worldPosition: SIMD3<Float>(2, 0, -3),
                color: .systemYellow,
                inventory: [
                    ARTradeItem(
                        tradeItem: TradeItem(
                            itemId: "ar_item_1",
                            name: "루비 목걸이",
                            category: "보석",
                            grade: .legendary,
                            requiredLicense: .advanced,
                            basePrice: 500000
                        ),
                        arModel: "ruby_necklace"
                    )
                ]
            ),
            ARMerchant(
                id: "ar_merchant_2",
                name: "AR 공예품상",
                worldPosition: SIMD3<Float>(-2, 0, -2),
                color: .systemGreen,
                inventory: [
                    ARTradeItem(
                        tradeItem: TradeItem(
                            itemId: "ar_item_2",
                            name: "전통 도자기",
                            category: "공예품",
                            grade: .rare,
                            requiredLicense: .intermediate,
                            basePrice: 250000
                        ),
                        arModel: "ceramic_vase"
                    )
                ]
            )
        ]
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
}

// MARK: - ARSessionDelegate
extension ARTradeSystem: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.arSessionError = "AR 세션 오류: \(error.localizedDescription)"
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.arSessionError = "AR 세션이 중단되었습니다."
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension ARTradeSystem: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // 위치 업데이트 처리
    }
}

// MARK: - AR 상인 모델
struct ARMerchant: Identifiable {
    let id: String
    let name: String
    let worldPosition: SIMD3<Float>
    let color: UIColor
    let inventory: [ARTradeItem]
}

// MARK: - AR 거래 아이템
struct ARTradeItem: Identifiable {
    let id = UUID()
    let tradeItem: TradeItem
    let arModel: String // 3D 모델 파일명
    
    init(tradeItem: TradeItem, arModel: String) {
        self.tradeItem = tradeItem
        self.arModel = arModel
    }
}