//
//  PlayerInventory.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 2024-12-26.
//  플레이어 인벤토리 시스템 - 아이템, 착용품, 창고 관리
//

import Foundation
import SwiftUI

// MARK: - Player Inventory Class
class PlayerInventory: ObservableObject, Codable {
    // MARK: - 인벤토리 시스템
    @Published var inventory: [TradeItem] = []
    @Published var maxInventorySize: Int = 5
    @Published var storageItems: [TradeItem] = []
    @Published var maxStorageSize: Int = 50

    // MARK: - 착용품 시스템
    @Published var equippedItems: [EquipmentSlot: EquipmentItem] = [:]
    @Published var equipmentStorage: [EquipmentItem] = []

    // MARK: - 소유 자산
    @Published var ownedProperties: [Property] = []
    @Published var vehicles: [Vehicle] = []
    @Published var pets: [Pet] = []

    // MARK: - 보험 및 서비스
    @Published var insurancePolicies: [InsurancePolicy] = []
    @Published var activeContracts: [TradeContract] = []

    // MARK: - 초기화
    init() {}

    // MARK: - Codable 구현
    enum CodingKeys: String, CodingKey {
        case inventory, maxInventorySize, storageItems, maxStorageSize
        case equippedItems, equipmentStorage
        case ownedProperties, vehicles, pets
        case insurancePolicies, activeContracts
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        inventory = try container.decode([TradeItem].self, forKey: .inventory)
        maxInventorySize = try container.decode(Int.self, forKey: .maxInventorySize)
        storageItems = try container.decode([TradeItem].self, forKey: .storageItems)
        maxStorageSize = try container.decode(Int.self, forKey: .maxStorageSize)
        equippedItems = try container.decode([EquipmentSlot: EquipmentItem].self, forKey: .equippedItems)
        equipmentStorage = try container.decode([EquipmentItem].self, forKey: .equipmentStorage)
        ownedProperties = try container.decode([Property].self, forKey: .ownedProperties)
        vehicles = try container.decode([Vehicle].self, forKey: .vehicles)
        pets = try container.decode([Pet].self, forKey: .pets)
        insurancePolicies = try container.decode([InsurancePolicy].self, forKey: .insurancePolicies)
        activeContracts = try container.decode([TradeContract].self, forKey: .activeContracts)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(inventory, forKey: .inventory)
        try container.encode(maxInventorySize, forKey: .maxInventorySize)
        try container.encode(storageItems, forKey: .storageItems)
        try container.encode(maxStorageSize, forKey: .maxStorageSize)
        try container.encode(equippedItems, forKey: .equippedItems)
        try container.encode(equipmentStorage, forKey: .equipmentStorage)
        try container.encode(ownedProperties, forKey: .ownedProperties)
        try container.encode(vehicles, forKey: .vehicles)
        try container.encode(pets, forKey: .pets)
        try container.encode(insurancePolicies, forKey: .insurancePolicies)
        try container.encode(activeContracts, forKey: .activeContracts)
    }
}

// MARK: - 인벤토리 관리 메서드
extension PlayerInventory {
    // 아이템 추가
    func addItem(_ item: TradeItem) -> Bool {
        guard inventory.count < maxInventorySize else { return false }
        inventory.append(item)
        return true
    }

    // 아이템 제거
    func removeItem(_ item: TradeItem) -> Bool {
        guard let index = inventory.firstIndex(where: { $0.id == item.id }) else { return false }
        inventory.remove(at: index)
        return true
    }

    // 아이템 찾기
    func findItem(by id: String) -> TradeItem? {
        return inventory.first { $0.id == id }
    }

    // 특정 타입 아이템 개수
    func itemCount(of type: String) -> Int {
        return inventory.filter { $0.name == type }.count
    }

    // 인벤토리 여유 공간
    var availableSlots: Int {
        return maxInventorySize - inventory.count
    }

    // 인벤토리가 가득 찬지 확인
    var isFull: Bool {
        return inventory.count >= maxInventorySize
    }

    // 인벤토리 총 가치
    var totalInventoryValue: Int {
        return inventory.reduce(0) { $0 + $1.basePrice }
    }
}

// MARK: - 창고 관리 메서드
extension PlayerInventory {
    // 창고에 아이템 저장
    func storeItem(_ item: TradeItem) -> Bool {
        guard storageItems.count < maxStorageSize else { return false }
        guard removeItem(item) else { return false }
        storageItems.append(item)
        return true
    }

    // 창고에서 아이템 꺼내기
    func retrieveFromStorage(_ item: TradeItem) -> Bool {
        guard let index = storageItems.firstIndex(where: { $0.id == item.id }) else { return false }
        guard inventory.count < maxInventorySize else { return false }

        let storedItem = storageItems.remove(at: index)
        inventory.append(storedItem)
        return true
    }

    // 창고 여유 공간
    var availableStorageSlots: Int {
        return maxStorageSize - storageItems.count
    }

    // 창고 총 가치
    var totalStorageValue: Int {
        return storageItems.reduce(0) { $0 + $1.basePrice }
    }
}

// MARK: - 착용품 관리 메서드
extension PlayerInventory {
    // 아이템 착용
    func equipItem(_ item: EquipmentItem) -> Bool {
        // 이미 해당 슬롯에 착용품이 있으면 창고로 이동
        if let currentItem = equippedItems[item.slot] {
            equipmentStorage.append(currentItem)
        }

        equippedItems[item.slot] = item
        return true
    }

    // 착용품 해제
    func unequipItem(from slot: EquipmentSlot) -> Bool {
        guard let item = equippedItems[slot] else { return false }

        equippedItems.removeValue(forKey: slot)
        equipmentStorage.append(item)
        return true
    }

    // 특정 슬롯의 착용품 가져오기
    func getEquippedItem(for slot: EquipmentSlot) -> EquipmentItem? {
        return equippedItems[slot]
    }

    // 착용 중인 아이템 총 스탯 보너스
    var totalEquipmentStats: [String: Int] {
        var totalStats: [String: Int] = [:]

        for (_, item) in equippedItems {
            for (stat, value) in item.stats {
                totalStats[stat, default: 0] += value
            }
        }

        return totalStats
    }
}

// MARK: - 자산 관리 메서드
extension PlayerInventory {
    // 부동산 구매
    func buyProperty(_ property: Property) {
        ownedProperties.append(property)
    }

    // 부동산 판매
    func sellProperty(_ property: Property) -> Bool {
        guard let index = ownedProperties.firstIndex(where: { $0.id == property.id }) else { return false }
        ownedProperties.remove(at: index)
        return true
    }

    // 차량 구매
    func buyVehicle(_ vehicle: Vehicle) {
        vehicles.append(vehicle)
    }

    // 펫 입양
    func adoptPet(_ pet: Pet) {
        pets.append(pet)
    }

    // 총 자산 가치
    var totalAssetValue: Int {
        let propertyValue = ownedProperties.reduce(0) { $0 + $1.value }
        let inventoryValue = totalInventoryValue
        let storageValue = totalStorageValue

        return propertyValue + inventoryValue + storageValue
    }
}

// MARK: - 보험 관리 메서드
extension PlayerInventory {
    // 보험 가입
    func purchaseInsurance(_ policy: InsurancePolicy) {
        insurancePolicies.append(policy)
    }

    // 보험 해지
    func cancelInsurance(_ policy: InsurancePolicy) -> Bool {
        guard let index = insurancePolicies.firstIndex(where: { $0.id == policy.id }) else { return false }
        insurancePolicies.remove(at: index)
        return true
    }

    // 활성 보험 확인
    func hasActiveInsurance(for type: InsuranceType) -> Bool {
        return insurancePolicies.contains { $0.type == type && $0.isActive }
    }
}

// MARK: - 계약 관리 메서드
extension PlayerInventory {
    // 계약 체결
    func signContract(_ contract: TradeContract) {
        activeContracts.append(contract)
    }

    // 계약 완료
    func completeContract(_ contract: TradeContract) -> Bool {
        guard let index = activeContracts.firstIndex(where: { $0.id == contract.id }) else { return false }
        activeContracts.remove(at: index)
        return true
    }

    // 만료된 계약 정리
    func cleanupExpiredContracts() {
        let now = Date()
        activeContracts.removeAll { $0.expiryDate < now }
    }
}

// MARK: - 지원 구조체들
struct EquipmentItem: Identifiable, Codable {
    let id = UUID()
    let name: String
    let slot: EquipmentSlot
    let stats: [String: Int]
    let rarity: ItemRarity
    let description: String

    enum CodingKeys: String, CodingKey {
        case name, slot, stats, rarity, description
    }
}

enum EquipmentSlot: String, CaseIterable, Codable {
    case head, chest, legs, feet, weapon, accessory

    var displayName: String {
        switch self {
        case .head: return "머리"
        case .chest: return "가슴"
        case .legs: return "다리"
        case .feet: return "신발"
        case .weapon: return "무기"
        case .accessory: return "장신구"
        }
    }
}

struct Property: Identifiable, Codable {
    let id = UUID()
    let name: String
    let location: String
    let value: Int
    let type: PropertyType

    enum CodingKeys: String, CodingKey {
        case name, location, value, type
    }
}

enum PropertyType: String, Codable {
    case house, shop, warehouse, land

    var displayName: String {
        switch self {
        case .house: return "주택"
        case .shop: return "상점"
        case .warehouse: return "창고"
        case .land: return "토지"
        }
    }
}

struct Vehicle: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: String
    let capacity: Int
    let speed: Int

    enum CodingKeys: String, CodingKey {
        case name, type, capacity, speed
    }
}

struct Pet: Identifiable, Codable {
    let id = UUID()
    let name: String
    let species: String
    let level: Int
    let skills: [String]

    enum CodingKeys: String, CodingKey {
        case name, species, level, skills
    }
}

struct InsurancePolicy: Identifiable, Codable {
    let id = UUID()
    let type: InsuranceType
    let coverage: Int
    let premium: Int
    let duration: TimeInterval
    let purchaseDate: Date

    var isActive: Bool {
        return Date().timeIntervalSince(purchaseDate) < duration
    }

    enum CodingKeys: String, CodingKey {
        case type, coverage, premium, duration, purchaseDate
    }
}

enum InsuranceType: String, CaseIterable, Codable {
    case theft, damage, price, travel

    var displayName: String {
        switch self {
        case .theft: return "도난 보험"
        case .damage: return "손상 보험"
        case .price: return "가격 보험"
        case .travel: return "여행 보험"
        }
    }
}

struct TradeContract: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let reward: Int
    let requirements: [String]
    let expiryDate: Date
    let difficulty: ContractDifficulty

    enum CodingKeys: String, CodingKey {
        case title, description, reward, requirements, expiryDate, difficulty
    }
}

enum ContractDifficulty: String, Codable {
    case easy, medium, hard, expert

    var displayName: String {
        switch self {
        case .easy: return "쉬움"
        case .medium: return "보통"
        case .hard: return "어려움"
        case .expert: return "전문가"
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .expert: return .red
        }
    }
}

enum ItemRarity: String, Codable, CaseIterable {
    case common, uncommon, rare, epic, legendary, mythical

    var displayName: String {
        switch self {
        case .common: return "일반"
        case .uncommon: return "고급"
        case .rare: return "희귀"
        case .epic: return "영웅"
        case .legendary: return "전설"
        case .mythical: return "신화"
        }
    }

    var color: Color {
        switch self {
        case .common: return .gray
        case .uncommon: return .green
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        case .mythical: return .red
        }
    }
}