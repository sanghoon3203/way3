//
//  FontExtension.swift
//  way
//
//  Created by Claude on 8/28/25.
//

import SwiftUI

extension Font {
    // 조선백년체 폰트 적용
    static func chosun(_ size: CGFloat) -> Font {
        return .custom("ChosunCentennial", size: size)
    }
    
    // 기본 폰트 사이즈들
    static var chosunTitle: Font {
        return .chosun(24)
    }
    
    static var chosunHeadline: Font {
        return .chosun(18)
    }
    
    static var chosunBody: Font {
        return .chosun(16)
    }
    
    static var chosunCaption: Font {
        return .chosun(12)
    }
    
    static var chosunLarge: Font {
        return .chosun(32)
    }
    
    // Note: Detailed font definitions are moved to EnhancedFontSystem.swift to avoid conflicts
}