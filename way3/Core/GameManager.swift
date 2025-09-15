// 📁 Core/GameManager.swift - 게임 상태 중앙 관리
import Foundation
import SwiftUI
import CoreLocation
import Combine

class GameManager: ObservableObject {
    // MARK: - Singleton
    static let shared = GameManager()
    
    // MARK: - Published Properties
    @Published var player: Player = Player()
    @Published var gameState: GameState = .menu
    @Published var currentDistrict: SeoulDistrict = .gangnam
    @Published var isGameStarted: Bool = false
    @Published var isPaused: Bool = false
    
    // MARK: - Game Systems
    private let dataManager = DataManager()
    private let networkManager = NetworkManager.shared
    private let tradeManager = TradeManager.shared
    
    // MARK: - Location Reference (no need to duplicate LocationManager)
    private var locationManager: LocationManager?
    
    // MARK: - Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        initializeGame()
    }
    
    // MARK: - Setup Methods
    func setLocationManager(_ locationManager: LocationManager) {
        self.locationManager = locationManager
        setupLocationBindings()
    }
    
    private func setupLocationBindings() {
        // Location updates affect current district
        locationManager?.$currentLocation
            .compactMap { $0 }
            .sink { [weak self] coordinate in
                self?.updateCurrentDistrict(coordinate: coordinate)
            }
            .store(in: &cancellables)
    }
    
    private func initializeGame() {
        // Initialize player with default values if needed
        if player.name.isEmpty {
            player.name = "무명의 상인"
        }
        
        // Set initial game state
        gameState = .playing
        isGameStarted = true
    }
    
    // MARK: - Game State Management
    func startGame() {
        isGameStarted = true
        gameState = .playing
        isPaused = false
    }
    
    func pauseGame() {
        isPaused = true
        gameState = .paused
    }
    
    func resumeGame() {
        isPaused = false
        gameState = .playing
    }
    
    func resetGame() {
        player = Player()
        gameState = .menu
        isGameStarted = false
        isPaused = false
    }
    
    // MARK: - Location Management
    private func updateCurrentDistrict(coordinate: CLLocationCoordinate2D) {
        // Determine Seoul district based on coordinates
        let newDistrict = SeoulDistrict.fromCoordinate(
            lat: coordinate.latitude,
            lng: coordinate.longitude
        )
        
        if newDistrict != currentDistrict {
            currentDistrict = newDistrict
            // Trigger district change events
            handleDistrictChange(to: newDistrict)
        }
    }
    
    private func handleDistrictChange(to district: SeoulDistrict) {
        // Update player location reference if available
        if let coordinate = locationManager?.currentLocation {
            player.currentLocation = coordinate
        }
        
        // Notify other systems of district change
        NotificationCenter.default.post(
            name: .districtChanged,
            object: district
        )
    }
    
    // MARK: - Player Management
    func updatePlayerMoney(amount: Int) {
        player.money += amount
        objectWillChange.send()
    }
    
    func updatePlayerExperience(amount: Int) {
        let oldLevel = player.level
        player.experience += amount
        
        // Check for level up
        let newLevel = calculateLevel(experience: player.experience)
        if newLevel > oldLevel {
            handleLevelUp(from: oldLevel, to: newLevel)
        }
    }
    
    private func calculateLevel(experience: Int) -> Int {
        // Simple level calculation: every 1000 XP = 1 level
        return max(1, experience / 1000 + 1)
    }
    
    private func handleLevelUp(from oldLevel: Int, to newLevel: Int) {
        player.level = newLevel
        player.statPoints += (newLevel - oldLevel) * 3
        player.skillPoints += (newLevel - oldLevel) * 2
        
        // Show level up notification
        NotificationCenter.default.post(
            name: .playerLevelUp,
            object: ["oldLevel": oldLevel, "newLevel": newLevel]
        )
    }
    
    // MARK: - Game Events
    func triggerRandomEvent() {
        // Random game events logic here
        // For now, just a placeholder
    }
    
    func processGameTick() {
        // Regular game updates (called periodically)
        // Update time-based systems
        updateTimeBasedSystems()
    }
    
    private func updateTimeBasedSystems() {
        // Update market prices
        // Update merchant inventories
        // Update player fatigue, etc.
    }
}

// MARK: - Game State Enum
enum GameState {
    case menu
    case playing
    case paused
    case trading
    case inventory
    case map
    case settings
}

// MARK: - Notifications
extension Notification.Name {
    static let districtChanged = Notification.Name("districtChanged")
    static let playerLevelUp = Notification.Name("playerLevelUp")
}