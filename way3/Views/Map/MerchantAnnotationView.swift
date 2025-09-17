import SwiftUI
import CoreLocation

struct MerchantAnnotationView: View {
    let merchant: Merchant
    let userLocation: CLLocationCoordinate2D?

    var body: some View {
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
    }
}