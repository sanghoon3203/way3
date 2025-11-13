import SwiftUI

/// Stub placeholder while the shop/auction experience gets rebuilt.
struct ShopView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)

                Text("상점 시스템 개편 중")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("새로운 상점/경매 경험을 준비하고 있어요.\n완료되면 이 화면에서 바로 만나볼 수 있습니다.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("상점")
        }
    }
}
