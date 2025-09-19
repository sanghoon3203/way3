//
//  GameEnums.swift
//  way3 - Way Trading Game
//
//  Created by Claude on 12/25/25.
//  게임 전반에서 사용되는 열거형 정의
//

import Foundation
import SwiftUI
import CoreLocation

// MARK: - 아이템 등급
enum ItemGrade: Int, CaseIterable, Codable {
    case common = 0
    case intermediate = 1
    case advanced = 2
    case rare = 3
    case legendary = 4
    
    var displayName: String {
        switch self {
        case .common: return "일반"
        case .intermediate: return "중급"
        case .advanced: return "고급"
        case .rare: return "희귀"
        case .legendary: return "전설"
        }
    }
    
    var color: Color {
        switch self {
        case .common: return .gray
        case .intermediate: return .blue
        case .advanced: return .green
        case .rare: return .purple
        case .legendary: return .orange
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .common: return "일반"
        case .intermediate: return "중급"
        case .advanced: return "고급"
        case .rare: return "희귀"
        case .legendary: return "전설"
        }
    }

    var cyberpunkColor: Color {
        switch self {
        case .common: return .cyberpunkTextSecondary
        case .intermediate: return .cyberpunkCyan
        case .advanced: return .cyberpunkGreen
        case .rare: return .cyberpunkYellow
        case .legendary: return .cyberpunkGold
        }
    }
}

// MARK: - 라이센스 등급
enum LicenseLevel: Int, CaseIterable, Codable {
    case beginner = 0
    case intermediate = 1
    case advanced = 2
    case expert = 3
    case master = 4

    var displayName: String {
        switch self {
        case .beginner: return "초급상인"
        case .intermediate: return "중급상인"
        case .advanced: return "고급상인"
        case .expert: return "전문상인"
        case .master: return "마스터상인"
        }
    }

    var requiredLevel: Int {
        switch self {
        case .beginner: return 1
        case .intermediate: return 5
        case .advanced: return 15
        case .expert: return 30
        case .master: return 50
        }
    }
    
    var color: Color {
        switch self {
        case .beginner: return .gray
        case .intermediate: return .blue
        case .advanced: return .green
        case .expert: return .purple
        case .master: return .orange
        }
    }
    
    var requiredMoney: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 10000
        case .advanced: return 50000
        case .expert: return 200000
        case .master: return 1000000
        }
    }

    var maxInventoryBonus: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 5
        case .advanced: return 10
        case .expert: return 20
        case .master: return 30
        }
    }

    var trustPointsRequired: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 100
        case .advanced: return 300
        case .expert: return 700
        case .master: return 1500
        }
    }
    
    var requiredTrust: Int {
        switch self {
        case .beginner: return 0
        case .intermediate: return 100
        case .advanced: return 500
        case .expert: return 2000
        case .master: return 10000
        }
    }
}

// MARK: - 아이템 카테고리  
enum ItemCategory: String, CaseIterable, Codable {
    case food = "식료품"
    case craft = "공예품"
    case luxury = "명품"
    case general = "일반품"
    case electronics = "전자제품"
    case clothing = "의류"
    case jewelry = "보석"
    case art = "예술품"
    case antique = "골동품"
    case herb = "약초"
    case textile = "직물"
    case metal = "금속공예"
    case ceramic = "도자기"
    case book = "서적"
    case instrument = "악기"
    case toy = "장난감"
    case cosmetic = "화장품"
    case furniture = "가구"
    case tool = "도구"
    case vehicle = "운송수단"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .food: return "carrot.fill"
        case .craft: return "hammer.fill"
        case .luxury: return "gem"
        case .general: return "bag.fill"
        case .electronics: return "tv.fill"
        case .clothing: return "tshirt.fill"
        case .jewelry: return "diamond.fill"
        case .art: return "paintbrush.fill"
        case .antique: return "building.columns.fill"
        case .herb: return "leaf.fill"
        case .textile: return "scissors"
        case .metal: return "wrench.fill"
        case .ceramic: return "cup.and.saucer.fill"
        case .book: return "book.fill"
        case .instrument: return "music.note"
        case .toy: return "gamecontroller.fill"
        case .cosmetic: return "face.smiling.fill"
        case .furniture: return "chair.fill"
        case .tool: return "toolbox.fill"
        case .vehicle: return "car.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .red
        case .craft: return .brown
        case .luxury: return .purple
        case .general: return .blue
        case .electronics: return .cyan
        case .clothing: return .pink
        case .jewelry: return .yellow
        case .art: return .orange
        case .antique: return .brown
        case .herb: return .green
        case .textile: return .indigo
        case .metal: return .gray
        case .ceramic: return .blue
        case .book: return .brown
        case .instrument: return .orange
        case .toy: return .pink
        case .cosmetic: return .pink
        case .furniture: return .brown
        case .tool: return .gray
        case .vehicle: return .blue
        }
    }
}

// MARK: - 거래 모드
enum TradeMode: String, CaseIterable {
    case buy = "구매"
    case sell = "판매"
    case browse = "둘러보기"
    
    var displayName: String {
        return self.rawValue
    }
    
    var iconName: String {
        switch self {
        case .buy: return "cart.badge.plus"
        case .sell: return "dollarsign.circle"
        case .browse: return "eye"
        }
    }
    
    var color: Color {
        switch self {
        case .buy: return .green
        case .sell: return .orange
        case .browse: return .blue
        }
    }
}

// MARK: - 서울 구역 (지역별 가격 배수)
enum SeoulDistrict: String, CaseIterable, Codable {
    case gangnam = "강남구"
    case songpa = "송파구"
    case seocho = "서초구" 
    case jongno = "종로구"
    case jung = "중구"
    case gangdong = "강동구"
    case dongjak = "동작구"
    case gwanak = "관악구"
    case seoungnam = "성남시"
    case yongsan = "용산구"
    
    var displayName: String {
        return self.rawValue
    }
    
    // 카테고리별 가격 배수
    func priceMultiplier(for category: String) -> Double {
        switch self {
        case .gangnam, .seocho:
            // 강남, 서초는 명품/예술품 비싸고 일반품 저렴
            switch category {
            case "명품", "예술품", "보석": return 1.3
            case "전자제품", "화장품": return 1.2  
            case "식료품": return 0.9
            default: return 1.1
            }
        case .jongno, .jung:
            // 종로, 중구는 전통 공예품/골동품 비싸고 전자제품 저렴
            switch category {
            case "골동품", "공예품", "도자기": return 1.4
            case "서적", "예술품": return 1.2
            case "전자제품": return 0.8
            default: return 1.0
            }
        case .songpa, .gangdong:
            // 송파, 강동은 일반적인 가격
            return 1.0
        default:
            return 0.95
        }
    }
    
    var coordinate: (lat: Double, lng: Double) {
        switch self {
        case .gangnam: return (37.4979, 127.0276)
        case .songpa: return (37.5145, 127.1059)
        case .seocho: return (37.4837, 127.0324)
        case .jongno: return (37.5735, 126.9788)
        case .jung: return (37.5636, 126.9970)
        case .gangdong: return (37.5301, 127.1238)
        case .dongjak: return (37.5124, 126.9393)
        case .gwanak: return (37.4781, 126.9514)
        case .seoungnam: return (37.4449, 127.1388)
        case .yongsan: return (37.5326, 126.9900)
        }
    }
    
    // 좌표를 기반으로 가장 가까운 구역 찾기
    static func fromCoordinate(lat: Double, lng: Double) -> SeoulDistrict {
        let targetLocation = CLLocation(latitude: lat, longitude: lng)
        
        var closestDistrict = SeoulDistrict.gangnam
        var minDistance = Double.infinity
        
        for district in SeoulDistrict.allCases {
            let districtCoord = district.coordinate
            let districtLocation = CLLocation(latitude: districtCoord.lat, longitude: districtCoord.lng)
            let distance = targetLocation.distance(from: districtLocation)
            
            if distance < minDistance {
                minDistance = distance
                closestDistrict = district
            }
        }
        
        return closestDistrict
    }
}