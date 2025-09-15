// 📁 Core/GameStatisticsManager.swift - 게임 통계 관리 전담
import Foundation
import SwiftUI

class GameStatisticsManager: ObservableObject {
    // MARK: - Published Properties
    @Published var gameStats = GameStatistics()
    
    // MARK: - Public Methods
    func updateGameStatistics(profit: Int, trade: Bool, trustPoints: Int) async {
        await MainActor.run {
            if trade {
                self.gameStats.totalTrades += 1
            }
            
            if profit > 0 {
                self.gameStats.totalProfit += profit
            }
            
            self.gameStats.level = self.calculateLevel(from: trustPoints)
            self.gameStats.experience = trustPoints
        }
    }
    
    func updateLevel(from trustPoints: Int) {
        gameStats.level = calculateLevel(from: trustPoints)
        gameStats.experience = trustPoints
    }
    
    func resetStatistics() {
        gameStats = GameStatistics()
    }
    
    func addPlayTime(_ timeInterval: TimeInterval) {
        gameStats.playTime += timeInterval
    }
    
    // MARK: - Private Methods
    private func calculateLevel(from trustPoints: Int) -> Int {
        return max(1, trustPoints / 100 + 1)
    }
    
    // MARK: - Statistics Queries
    func getAverageTradeProfit() -> Int {
        guard gameStats.totalTrades > 0 else { return 0 }
        return gameStats.totalProfit / gameStats.totalTrades
    }
    
    func getTradingEfficiency() -> Double {
        guard gameStats.playTime > 0 else { return 0.0 }
        return Double(gameStats.totalTrades) / (gameStats.playTime / 3600.0) // 시간당 거래 횟수
    }
    
    func getFormattedPlayTime() -> String {
        let hours = Int(gameStats.playTime) / 3600
        let minutes = (Int(gameStats.playTime) % 3600) / 60
        return String(format: "%d시간 %d분", hours, minutes)
    }
}

// MARK: - Game Statistics Model
struct GameStatistics {
    var level: Int = 1
    var experience: Int = 0
    var totalTrades: Int = 0
    var totalProfit: Int = 0
    var playTime: TimeInterval = 0
    
    // MARK: - Additional Statistics
    var bestSingleTrade: Int = 0
    var favoriteDistrict: SeoulDistrict?
    var mostTradedItem: String?
    var achievementCount: Int = 0
    
    mutating func updateBestTrade(_ profit: Int) {
        if profit > bestSingleTrade {
            bestSingleTrade = profit
        }
    }
    
    mutating func incrementAchievements() {
        achievementCount += 1
    }
}