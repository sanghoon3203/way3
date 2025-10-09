//
//  Font+ChosunSystem.swift
//  way3
//
//  Created by Claude on 17/09/2025.
//  Chosun 폰트 시스템 - 앱 전체 기본 폰트 설정
//

import SwiftUI
import UIKit

// MARK: - Chosun Font System
extension Font {
    // Primary font family name
    static let chosunFontName = "ChosunCentennial"

    // MARK: - Heading Styles
    static var chosunH1: Font {
        Font.custom(chosunFontName, size: 24, relativeTo: .title)
    }

    static var chosunH2: Font {
        Font.custom(chosunFontName, size: 20, relativeTo: .headline)
    }

    static var chosunH3: Font {
        Font.custom(chosunFontName, size: 18, relativeTo: .headline)
    }

    // MARK: - Body Styles
    static var chosunBody: Font {
        Font.custom(chosunFontName, size: 16, relativeTo: .body)
    }

    static var chosunBodyBold: Font {
        Font.custom(chosunFontName, size: 16, relativeTo: .body)
            .weight(.semibold)
    }

    static var chosunSubhead: Font {
        Font.custom(chosunFontName, size: 15, relativeTo: .subheadline)
    }

    // MARK: - Small Text Styles
    static var chosunCaption: Font {
        Font.custom(chosunFontName, size: 14, relativeTo: .caption)
    }

    static var chosunSmall: Font {
        Font.custom(chosunFontName, size: 12, relativeTo: .caption2)
    }

    // MARK: - Special Styles
    static var chosunTitle: Font {
        Font.custom(chosunFontName, size: 28, relativeTo: .largeTitle)
            .weight(.bold)
    }

    static var chosunButton: Font {
        Font.custom(chosunFontName, size: 16, relativeTo: .body)
            .weight(.medium)
    }

    // MARK: - Fallback Font Check
    static func chosunOrFallback(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if UIFont(name: chosunFontName, size: size) != nil {
            return Font.custom(chosunFontName, size: size).weight(weight)
        } else {
            // Fallback to system font if Chosun font is not available
            switch weight {
            case .bold, .heavy, .black:
                return .system(size: size, weight: weight)
            case .medium, .semibold:
                return .system(size: size, weight: weight)
            default:
                return .system(size: size)
            }
        }
    }
}

// MARK: - UIFont Extension for UIKit Components
extension UIFont {
    static let chosunFontName = "ChosunCentennial"

    // MARK: - UIFont Chosun Variants
    static func chosunFont(size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        if let font = UIFont(name: chosunFontName, size: size) {
            return font
        }
        // Fallback to system font
        return UIFont.systemFont(ofSize: size, weight: weight)
    }

    static var chosunH1: UIFont {
        return chosunFont(size: 24, weight: .bold)
    }

    static var chosunH2: UIFont {
        return chosunFont(size: 20, weight: .semibold)
    }

    static var chosunBody: UIFont {
        return chosunFont(size: 16, weight: .regular)
    }

    static var chosunCaption: UIFont {
        return chosunFont(size: 14, weight: .regular)
    }

    static var chosunSmall: UIFont {
        return chosunFont(size: 12, weight: .regular)
    }
}

// MARK: - Global Font Override for System Components
struct ChosunFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.chosunBody)
    }
}

extension View {
    func defaultChosunFont() -> some View {
        self.modifier(ChosunFontModifier())
    }
}

// MARK: - App-wide Font Configuration
class FontSystemManager {
    static func setupAppFonts() {
        // Override default UIKit fonts
        setupNavigationBarFonts()
        setupTabBarFonts()
        setupButtonFonts()
    }

    private static func setupNavigationBarFonts() {
        let appearance = UINavigationBarAppearance()
        appearance.titleTextAttributes = [
            .font: UIFont.chosunFont(size: 18, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        appearance.largeTitleTextAttributes = [
            .font: UIFont.chosunFont(size: 28, weight: .bold),
            .foregroundColor: UIColor.label
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private static func setupTabBarFonts() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()

        // Normal state
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: UIFont.chosunFont(size: 12, weight: .regular),
            .foregroundColor: UIColor.systemGray
        ]

        // Selected state
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: UIFont.chosunFont(size: 12, weight: .medium),
            .foregroundColor: UIColor.systemBlue
        ]

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }

    private static func setupButtonFonts() {
        UIButton.appearance().titleLabel?.font = UIFont.chosunFont(size: 16, weight: .medium)
    }
}

// MARK: - Font Validation
extension FontSystemManager {
    static func validateChosunFont() -> Bool {
        return UIFont(name: UIFont.chosunFontName, size: 16) != nil
    }

    static func debugAvailableFonts() {
        print("🔤 Available Font Families:")
        for family in UIFont.familyNames.sorted() {
            print("Family: \(family)")
            for name in UIFont.fontNames(forFamilyName: family) {
                print("  - \(name)")
            }
        }
    }
}