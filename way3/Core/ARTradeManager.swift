//
//  ARTradeManager.swift
//  way3 - AR Trading Manager
//
//  AR 거래 시스템 관리자
//

import Foundation
import ARKit
import RealityKit
import CoreLocation
import Combine

class ARTradeManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isARSessionActive = false
    @Published var trackingState: ARCamera.TrackingState = .notAvailable
    @Published var detectedMerchants: [ARMerchant] = []
    @Published var detectedItems: [ARTradeItem] = []
    @Published var scanMode: ARScanMode = .merchants
    
    // MARK: - Private Properties
    private var arView: ARView?
    private var arSession: ARSession?
    private var playerLocation: CLLocationCoordinate2D?
    private var locationUpdateTimer: Timer?
    
    // MARK: - AR 스캔 모드
    enum ARScanMode {
        case merchants  // 상인 탐지
        case items      // 아이템 탐지
        case both       // 모든 것 탐지
        
        var displayName: String {
            switch self {
            case .merchants: return "상인 탐지"
            case .items: return "아이템 탐지"
            case .both: return "전체 탐지"
            }
        }
    }
    
    override init() {
        super.init()
        setupARSession()
    }
    
    // MARK: - AR 세션 관리
    func setupARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            print("AR World Tracking not supported")
            return
        }
        
        arSession = ARSession()
        arSession?.delegate = self
    }
    
    func startARSession() {
        guard let arSession = arSession else { return }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        
        // 위치 기반 추적 활성화 (iOS 14+)
        if #available(iOS 14.0, *) {
            configuration.sceneReconstruction = .mesh
        }
        
        arSession.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        isARSessionActive = true
        
        // 위치 업데이트 타이머 시작
        startLocationUpdates()
    }
    
    func stopARSession() {
        arSession?.pause()
        isARSessionActive = false
        stopLocationUpdates()
    }
    
    func setARView(_ arView: ARView) {
        self.arView = arView
        arView.session = arSession ?? ARSession()
        
        // AR 환경 설정
        arView.automaticallyConfigureSession = false
        arView.environment.sceneUnderstanding.options.insert(.physics)
        arView.environment.sceneUnderstanding.options.insert(.collision)
    }
    
    // MARK: - 위치 관리
    func setPlayerLocation(_ location: CLLocationCoordinate2D?) {
        self.playerLocation = location
        if isARSessionActive {
            updateNearbyContent()
        }
    }
    
    private func startLocationUpdates() {
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.updateNearbyContent()
        }
    }
    
    private func stopLocationUpdates() {
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
    }
    
    // MARK: - 스캔 모드 관리
    func toggleScanMode() {
        switch scanMode {
        case .merchants:
            scanMode = .items
        case .items:
            scanMode = .both
        case .both:
            scanMode = .merchants
        }
        
        updateNearbyContent()
    }
    
    func setScanMode(_ mode: ARScanMode) {
        scanMode = mode
        updateNearbyContent()
    }
    
    // MARK: - 콘텐츠 업데이트
    private func updateNearbyContent() {
        guard let playerLocation = playerLocation else { return }
        
        Task {
            await loadNearbyARContent(for: playerLocation)
        }
    }
    
    @MainActor
    private func loadNearbyARContent(for location: CLLocationCoordinate2D) async {
        // 스캔 모드에 따라 다른 콘텐츠 로드
        switch scanMode {
        case .merchants:
            await loadNearbyMerchants(for: location)
        case .items:
            await loadNearbyItems(for: location)
        case .both:
            async let merchants = loadNearbyMerchants(for: location)
            async let items = loadNearbyItems(for: location)
            await (merchants, items)
        }
    }
    
    private func loadNearbyMerchants(for location: CLLocationCoordinate2D) async {
        // 실제 구현에서는 서버에서 근처 AR 상인 정보를 가져옴
        let mockMerchants = generateMockARMerchants(near: location)
        
        DispatchQueue.main.async {
            self.detectedMerchants = mockMerchants
            self.placeARMerchants(mockMerchants)
        }
    }
    
    private func loadNearbyItems(for location: CLLocationCoordinate2D) async {
        // 실제 구현에서는 서버에서 근처 AR 아이템 정보를 가져옴
        let mockItems = generateMockARItems(near: location)
        
        DispatchQueue.main.async {
            self.detectedItems = mockItems
            self.placeARItems(mockItems)
        }
    }
    
    // MARK: - AR 객체 배치
    private func placeARMerchants(_ merchants: [ARMerchant]) {
        guard let arView = arView else { return }
        
        // 기존 상인 앵커 제거
        arView.scene.anchors.removeAll { anchor in
            anchor.name?.hasPrefix("merchant_") == true
        }
        
        for merchant in merchants {
            let anchorEntity = createMerchantAnchor(for: merchant)
            arView.scene.addAnchor(anchorEntity)
        }
    }
    
    private func placeARItems(_ items: [ARTradeItem]) {
        guard let arView = arView else { return }
        
        // 기존 아이템 앵커 제거
        arView.scene.anchors.removeAll { anchor in
            anchor.name?.hasPrefix("item_") == true
        }
        
        for item in items {
            let anchorEntity = createItemAnchor(for: item)
            arView.scene.addAnchor(anchorEntity)
        }
    }
    
    // MARK: - AR 앵커 생성
    private func createMerchantAnchor(for merchant: ARMerchant) -> AnchorEntity {
        // 실제 GPS 좌표를 AR 공간 좌표로 변환
        let position = worldPosition(for: merchant.location)
        let anchor = AnchorEntity(world: position)
        anchor.name = "merchant_\(merchant.id)"
        
        // 상인 3D 모델 또는 빌보드 생성
        let merchantEntity = createMerchantEntity(for: merchant)
        anchor.addChild(merchantEntity)
        
        return anchor
    }
    
    private func createItemAnchor(for item: ARTradeItem) -> AnchorEntity {
        let position = worldPosition(for: item.location)
        let anchor = AnchorEntity(world: position)
        anchor.name = "item_\(item.id)"
        
        // 아이템 3D 모델 생성
        let itemEntity = createItemEntity(for: item)
        anchor.addChild(itemEntity)
        
        return anchor
    }
    
    // MARK: - 3D 엔티티 생성
    private func createMerchantEntity(for merchant: ARMerchant) -> ModelEntity {
        // 상인 표현을 위한 3D 모델 생성
        let mesh = MeshResource.generateBox(size: 0.3)
        let material = SimpleMaterial(color: merchant.type.uiColor, isMetallic: false)
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // 호버 애니메이션 추가
        let hoverAnimation = AnimationResource.makeOrbit(
            duration: 3.0,
            axis: [0, 1, 0],
            times: .infinity,
            bindTarget: .transform
        )
        
        modelEntity.playAnimation(hoverAnimation.repeat())
        
        // 상호작용 가능하도록 설정
        modelEntity.generateCollisionShapes(recursive: true)
        
        return modelEntity
    }
    
    private func createItemEntity(for item: ARTradeItem) -> ModelEntity {
        // 아이템 희귀도에 따른 다른 크기와 효과
        let size: Float = item.rarity.arSize
        let mesh = MeshResource.generateSphere(radius: size)
        
        // 희귀도별 재질 설정
        var material = SimpleMaterial(color: item.rarity.uiColor, isMetallic: true)
        material.roughness = 0.1
        material.metallic = 1.0
        
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // 희귀도별 다른 애니메이션
        let animation = item.rarity.arAnimation
        modelEntity.playAnimation(animation.repeat())
        
        // 파티클 효과 추가 (높은 희귀도 아이템)
        if item.rarity == .legendary || item.rarity == .epic {
            addParticleEffect(to: modelEntity, rarity: item.rarity)
        }
        
        modelEntity.generateCollisionShapes(recursive: true)
        
        return modelEntity
    }
    
    // MARK: - 효과 추가
    private func addParticleEffect(to entity: ModelEntity, rarity: ItemGrade) {
        // 파티클 시스템 생성 (RealityKit 파티클)
        // 실제 구현에서는 더 정교한 파티클 효과 추가
        let particleEmitter = try? ParticleEmitterComponent(
            simulating: .sparkles,
            renderingMode: .realtime
        )
        
        if let emitter = particleEmitter {
            entity.components.set(emitter)
        }
    }
    
    // MARK: - 좌표 변환
    private func worldPosition(for coordinate: CLLocationCoordinate2D) -> SIMD3<Float> {
        guard let playerLocation = playerLocation else {
            return SIMD3<Float>(0, 0, -2) // 기본 위치
        }
        
        // GPS 좌표 차이를 미터 단위로 변환
        let deltaLat = coordinate.latitude - playerLocation.latitude
        let deltaLng = coordinate.longitude - playerLocation.longitude
        
        // 위도/경도를 미터로 변환 (서울 기준 근사치)
        let metersPerDegreeLat: Double = 111000
        let metersPerDegreeLng: Double = 89000 // 서울 위도에서의 근사치
        
        let xOffset = Float(deltaLng * metersPerDegreeLng)
        let zOffset = Float(-deltaLat * metersPerDegreeLat) // Z축 반전
        
        return SIMD3<Float>(xOffset, 0, zOffset)
    }
    
    // MARK: - Mock 데이터 생성
    private func generateMockARMerchants(near location: CLLocationCoordinate2D) -> [ARMerchant] {
        // 반경 500m 내의 랜덤 위치에 상인 배치
        var merchants: [ARMerchant] = []
        
        for i in 0..<5 {
            let randomOffset = 0.002 // 약 200m
            let randomLat = location.latitude + Double.random(in: -randomOffset...randomOffset)
            let randomLng = location.longitude + Double.random(in: -randomOffset...randomOffset)
            
            let merchant = ARMerchant(
                id: "ar_merchant_\(i)",
                name: "AR상인\(i+1)",
                title: "특별한 상인",
                type: ARMerchant.MerchantType.allCases.randomElement() ?? .electronics,
                location: CLLocationCoordinate2D(latitude: randomLat, longitude: randomLng),
                availableItems: generateMockTradeItems(),
                isARExclusive: true
            )
            
            merchants.append(merchant)
        }
        
        return merchants
    }
    
    private func generateMockARItems(near location: CLLocationCoordinate2D) -> [ARTradeItem] {
        var items: [ARTradeItem] = []
        
        for i in 0..<10 {
            let randomOffset = 0.001 // 약 100m
            let randomLat = location.latitude + Double.random(in: -randomOffset...randomOffset)
            let randomLng = location.longitude + Double.random(in: -randomOffset...randomOffset)
            
            let item = ARTradeItem(
                id: "ar_item_\(i)",
                name: "AR아이템\(i+1)",
                description: "AR로만 수집 가능한 특별한 아이템",
                rarity: ItemGrade.allCases.randomElement() ?? .common,
                location: CLLocationCoordinate2D(latitude: randomLat, longitude: randomLng),
                icon: "star.fill",
                distance: CLLocation(latitude: location.latitude, longitude: location.longitude)
                    .distance(from: CLLocation(latitude: randomLat, longitude: randomLng))
            )
            
            items.append(item)
        }
        
        return items
    }
    
    private func generateMockTradeItems() -> [TradeItem] {
        // 임시 거래 아이템 생성
        return [
            TradeItem(
                id: "1",
                name: "AR 특별 아이템",
                description: "AR에서만 구매 가능한 특별한 아이템",
                price: 50000,
                category: .electronics,
                iconName: "star.fill"
            )
        ]
    }
    
    // MARK: - 아이템 제거
    func removeItem(_ item: ARTradeItem) {
        guard let arView = arView else { return }
        
        // AR 뷰에서 아이템 앵커 제거
        if let anchor = arView.scene.anchors.first(where: { $0.name == "item_\(item.id)" }) {
            arView.scene.removeAnchor(anchor)
        }
        
        // 감지된 아이템 목록에서 제거
        detectedItems.removeAll { $0.id == item.id }
    }
}

// MARK: - ARSessionDelegate
extension ARTradeManager: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        DispatchQueue.main.async {
            self.trackingState = frame.camera.trackingState
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR Session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isARSessionActive = false
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        DispatchQueue.main.async {
            self.isARSessionActive = false
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        DispatchQueue.main.async {
            self.startARSession()
        }
    }
}

// MARK: - AR 모델 정의
// Note: ARMerchant and ARTradeItem structs are defined in ARTradeSystem.swift to avoid duplicate declarations

