import SwiftUI
import CoreLocation

struct MerchantAnnotationView: View {
    let merchant: Merchant
    let userLocation: CLLocationCoordinate2D?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack {
                Image(systemName: "storefront.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)

                Text(merchant.name)
                    .font(.caption)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(4)
            }
            .frame(width: 60, height: 60)

            // 🆕 Story indicator badge
            if merchant.hasActiveStory {
                storyIndicatorBadge
            }
        }
    }

    // 🆕 Story indicator badge view
    private var storyIndicatorBadge: some View {
        ZStack {
            Circle()
                .fill(storyBadgeColor)
                .frame(width: 18, height: 18)

            Image(systemName: storyBadgeIcon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white)
        }
        .offset(x: 8, y: -8)
        .shadow(radius: 2)
    }

    // Badge color based on story role
    private var storyBadgeColor: Color {
        switch merchant.storyRole {
        case .main:
            return .orange  // Main story - orange/gold
        case .side:
            return .purple  // Side story - purple
        case .vendorOnly, .none:
            return .clear
        }
    }

    // Badge icon based on story role
    private var storyBadgeIcon: String {
        switch merchant.storyRole {
        case .main:
            return "star.fill"  // Main story star
        case .side:
            return "book.fill"  // Side story book
        case .vendorOnly, .none:
            return ""
        }
    }
}