//
//  InventoryItemCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Inventory/Components/InventoryItemCard.swift
import SwiftUI

struct InventoryItemCard: View {
    let item: TradeItem
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                // 아이템 등급 표시
                HStack {
                    Text(item.grade.displayName)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(gradeColor(item.grade))
                        .cornerRadius(6)
                    
                    Spacer()
                    
                    Image(systemName: "tag")
                        .foregroundColor(.secondary)
                }
                
                // 아이템 정보
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(item.currentPrice.formatted())원")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
            }
            .padding()
            .frame(height: 120)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 등급별 색상
    private func gradeColor(_ grade: ItemGrade) -> Color {
        switch grade {
        case .common: return .gray
        case .intermediate: return .blue
        case .advanced: return .teal
        case .rare: return .yellow
        case .legendary: return .red
        }
    }
}
