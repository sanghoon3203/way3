
// 📁 Views/Inventory/Components/InventoryHeaderCard.swift - 재사용 가능한 컴포넌트
import SwiftUI

struct InventoryHeaderCard: View {
    let itemCount: Int
    let maxItems: Int
    let totalValue: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("보유 상품")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(itemCount)/\(maxItems)개")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("총 가치")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("\(totalValue.formatted())원")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            
            // 용량 바
            ProgressView(value: Double(itemCount), total: Double(maxItems))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}
