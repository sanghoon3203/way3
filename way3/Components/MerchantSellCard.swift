//
//  MerchantSellCard.swift
//  way
//
//  Created by 김상훈 on 7/25/25.
//


// 📁 Views/Inventory/Components/MerchantSellCard.swift
import SwiftUI

struct MerchantSellCard: View {
    let merchant: Merchant
    let item: TradeItem
    let action: () -> Void
    
    private var estimatedPrice: Int {
        // 거리 보너스 계산 (임시로 1.2~1.5배)
        let bonus = Double.random(in: 1.2...1.5)
        return Int(Double(item.currentPrice) * bonus)
    }
    
    private var profit: Int {
        estimatedPrice - item.currentPrice
    }
    
    private var profitPercentage: Double    {
        (Double(profit) / Double(item.currentPrice)) * 100
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(merchant.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(merchant.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(merchant.district.rawValue)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("예상 판매가")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(estimatedPrice.formatted())원")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("+\(profitPercentage.formatted(.number.precision(.fractionLength(0))))% 수익")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
