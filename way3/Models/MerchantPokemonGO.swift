//
//  MerchantPokemonGO.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  Pokemon GO 스타일 상인 모델
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Pokemon GO 스타일 상인 모델 (이름을 MapMerchant로 변경)
struct MapMerchant: Identifiable, Codable {
    let id: String
    let name: String
    let latitude: Double
    let longitude: Double
    let category: MerchantCategory
    let description: String
    
    // 거리 (동적으로 계산됨)
    var distance: CLLocationDistance = 0
    
    // 상인 상태
    var isDiscovered: Bool = false
    var lastInteractionDate: Date?
    
    init(id: String, name: String, latitude: Double, longitude: Double, category: MerchantCategory, description: String) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.category = category
        self.description = description
    }
    
    // MARK: - UI 관련 속성들
    var pinColor: Color {
        switch category {
        case .food: return .red
        case .craft: return .green
        case .luxury: return .purple
        case .general: return .blue
        }
    }
    
    var iconName: String {
        switch category {
        case .food: return "carrot.fill"
        case .craft: return "hammer.fill"
        case .luxury: return "gem"
        case .general: return "bag.fill"
        }
    }
}

// MARK: - 상인 카테고리
enum MerchantCategory: String, CaseIterable, Codable {
    case food = "food"
    case craft = "craft"
    case luxury = "luxury"
    case general = "general"
    
    var displayName: String {
        switch self {
        case .food: return "식료품"
        case .craft: return "공예품"
        case .luxury: return "명품"
        case .general: return "일반품"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .red
        case .craft: return .green
        case .luxury: return .purple
        case .general: return .blue
        }
    }
}