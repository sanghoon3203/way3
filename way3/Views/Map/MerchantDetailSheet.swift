import SwiftUI

struct MerchantDetailSheet: View {
    let merchant: Merchant

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(merchant.name)
                .font(.title2)
                .fontWeight(.bold)

            Text("상인 유형: \(merchant.type.displayName)")
                .font(.body)

            Text("지역: \(merchant.district.displayName)")
                .font(.body)

            Text("필요 라이선스: \(merchant.requiredLicense.displayName)")
                .font(.body)

            Spacer()

            Button("거래하기") {
                // 거래 로직
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}