//
//  StoryChapterDetailView.swift
//  way3
//
//  챕터 → 구역 → 에피소드 진행 화면
//

import SwiftUI

struct StoryChapterDetailView: View {
    let chapter: StoryChapterDefinition
    let onStartEpisode: (StoryEpisodeDefinition) -> Void

    @EnvironmentObject private var progressManager: ProgressManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                chapterHeader

                ForEach(chapter.districts) { district in
                    districtSection(district)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.cyberpunkDarkBg.ignoresSafeArea())
        .navigationTitle(chapter.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: autoUnlockEpisodesIfNeeded)
    }

    // MARK: - Sections

    private var chapterHeader: some View {
        let total = chapter.totalEpisodeCount()
        let completed = chapter.completedEpisodeCount(progress: progressManager.progress)
        let isCompleted = chapter.isCompleted(progress: progressManager.progress)
        let statusText = isCompleted ? "CLEAR" : "\(completed)/\(total) 완료"

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CHAPTER \(chapter.order)")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.cyberpunkYellow)
                Spacer()
                Text(statusText)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(isCompleted ? .green : .cyberpunkYellow)
            }

            Text(chapter.title)
                .font(.cyberpunkTitle(size: 22))
                .foregroundColor(.cyberpunkTextPrimary)
                .multilineTextAlignment(.leading)

            if let reward = chapter.completionReward {
                StoryRewardView(reward: reward)
            }
        }
        .padding(20)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 16)
    }

    private func districtSection(_ district: StoryDistrictDefinition) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(district.name)
                .font(.cyberpunkHeading(size: 16))
                .foregroundColor(.cyberpunkTextPrimary)

            VStack(spacing: 10) {
                ForEach(district.sortedEpisodes) { episode in
                    episodeRow(episode)
                }
            }
        }
        .padding(16)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyberpunkBorder, lineWidth: 1))
        .padding(.horizontal, 16)
    }

    private func episodeRow(_ episode: StoryEpisodeDefinition) -> some View {
        let progress = progressManager.progress
        let isCompleted = episode.isCompleted(progress: progress)
        let isUnlocked = episode.isUnlocked(progress: progress)

        return HStack(spacing: 12) {
            statusIcon(isCompleted: isCompleted, isUnlocked: isUnlocked)

            VStack(alignment: .leading, spacing: 4) {
                Text(episode.title)
                    .font(.cyberpunkBody())
                    .foregroundColor(.cyberpunkTextPrimary)

                if let questId = episode.postQuestId, !questId.isEmpty {
                    Text("후속 퀘스트: \(questId)")
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextSecondary)
                }
            }

            Spacer()

            Button {
                onStartEpisode(episode)
            } label: {
                Text(isCompleted ? "재생" : "시작")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isUnlocked)
            .opacity(isUnlocked ? 1.0 : 0.4)
        }
        .padding(12)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func statusIcon(isCompleted: Bool, isUnlocked: Bool) -> some View {
        let imageName: String
        let color: Color

        if isCompleted {
            imageName = "checkmark.circle.fill"
            color = .green
        } else if isUnlocked {
            imageName = "play.circle.fill"
            color = .cyberpunkYellow
        } else {
            imageName = "lock.fill"
            color = .cyberpunkError
        }

        return Image(systemName: imageName)
            .font(.system(size: 22))
            .foregroundColor(color)
            .frame(width: 32, height: 32)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - Auto Unlock

    private func autoUnlockEpisodesIfNeeded() {
        let progress = progressManager.progress

        for episode in chapter.allEpisodes where episode.shouldAutoUnlock(progress: progress) {
            progressManager.unlockEpisode(episode.episodeId)
        }
    }
}

// MARK: - Reward View

private struct StoryRewardView: View {
    let reward: StoryCompletionReward

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("챕터 완료 보상")
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(.cyberpunkYellow)

            if let keyItem = reward.keyItem, !keyItem.isEmpty {
                label("증표 아이템", value: keyItem)
            }
            if let money = reward.money {
                label("골드코인", value: "\(money.formatted())")
            }
            if let exp = reward.exp {
                label("경험치", value: "\(exp.formatted())")
            }
        }
        .padding(12)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func label(_ title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)
            Text(value)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
        }
    }
}
