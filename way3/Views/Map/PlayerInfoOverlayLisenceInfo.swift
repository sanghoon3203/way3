import SwiftUI

struct PlayerInfoOverlayLisenceInfo: View {
    @EnvironmentObject var gameManager: GameManager

    var body: some View {
        VStack {
            if let player = gameManager.currentPlayer {
                Text("라이선스: \(player.core.currentLicense.displayName)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
    }
}