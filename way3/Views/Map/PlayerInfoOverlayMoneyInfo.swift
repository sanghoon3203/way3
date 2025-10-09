import SwiftUI

struct PlayerInfoOverlayMoneyInfo: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        VStack {
            if let player = gameManager.currentPlayer {
                Text("💰 \(player.core.money)원")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}