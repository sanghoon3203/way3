import SwiftUI

// MARK: - Story Hub

enum StoryHubFilter: String, CaseIterable, Identifiable {
    case main = "메인 스토리"
    case merchant = "상인 서브"

    var id: String { rawValue }
}

private struct NodeKey: Identifiable { let id: String }

struct StoryHubTabView: View {
    @State private var filter: StoryHubFilter = .main
    @State private var storyChapters: [StoryChapterDefinition] = []
    @State private var merchantEpisodes: [MerchantEpisodeMeta] = []
    @State private var startNode: String?
    @State private var selectedEpisode: StoryEpisodeDefinition?

    @EnvironmentObject private var progressManager: ProgressManager

    private var knownMerchantIds: [String] {
        [
            "merchant_seoyena",
            "merchant_minji",
            "merchant_haerin",
            "merchant_joongi",
            "merchant_sunwoo",
            "merchant_jiyoung"
        ]
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header
                segmentedControl
                Divider().overlay(Color.cyberpunkBorder)

                Group {
                    switch filter {
                    case .main: mainList
                    case .merchant: merchantList
                    }
                }
                .animation(.easeInOut, value: filter)
            }
            .background(Color.cyberpunkDarkBg)
            .navigationTitle("스토리")
            .navigationBarTitleDisplayMode(.inline)
        }
        .fullScreenCover(item: Binding(
            get: { startNode.map { NodeKey(id: $0) } },
            set: { _ in
                startNode = nil
                selectedEpisode = nil
            }
        )) { key in
            StoryView(startNodeID: key.id) {
                if let episode = selectedEpisode {
                    StoryFlowManager.shared.handleEpisodeCompletion(episode)
                }
            }
            .background(Color.black.ignoresSafeArea())
        }
        .onAppear(perform: loadData)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("STORY HUB")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(.cyberpunkYellow)
                Text("메인/서브 스토리 시작")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkTextSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.cyberpunkPanelBg)
    }

    private var segmentedControl: some View {
        HStack(spacing: 8) {
            ForEach(StoryHubFilter.allCases) { item in
                Button {
                    filter = item
                } label: {
                    Text(item.rawValue)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(filter == item ? .black : .cyberpunkTextSecondary)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(filter == item ? Color.cyberpunkYellow : Color.cyberpunkCardBg)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(filter == item ? Color.cyberpunkYellow : Color.cyberpunkBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cyberpunkDarkBg)
    }

    // MARK: - Main Story List

    private var mainList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(storyChapters) { chapter in
                    let isLocked = !chapter.isUnlocked(progress: progressManager.progress)

                    NavigationLink {
                        StoryChapterDetailView(chapter: chapter) { episode in
                            selectedEpisode = episode
                            startNode = episode.storyNodeId
                        }
                        .environmentObject(progressManager)
                    } label: {
                        StoryChapterCard(
                            chapter: chapter,
                            progress: progressManager.progress,
                            isLocked: isLocked
                        )
                    }
                    .disabled(isLocked)
                    .buttonStyle(.plain)
                    .opacity(isLocked ? 0.65 : 1.0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color.cyberpunkDarkBg)
    }

    // MARK: - Merchant Story List

    private var merchantList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(merchantEpisodes) { episode in
                    let locked = episode.locked ?? false
                    StoryCard(
                        title: episode.title,
                        subtitle: "@\(episode.merchant_id) • \(episode.episode_id)",
                        tagLeft: "EP",
                        tagRight: locked ? "LOCKED" : "READY",
                        tagRightColor: locked ? .cyberpunkError : .cyberpunkYellow,
                        primaryTitle: locked ? "잠금" : "시작",
                        secondaryTitle: "처음부터",
                        onPrimary: { if !locked { startNode = episode.entry_node } },
                        onSecondary: { startNode = episode.entry_node }
                    )
                }
            }
            .padding(12)
        }
        .background(Color.cyberpunkDarkBg)
    }

    // MARK: - Data

    private func loadData() {
        storyChapters = StoryChapterRepository.loadChapters()
        merchantEpisodes = StoryLibrary.loadMerchantEpisodes(merchantIds: knownMerchantIds)
            .sorted { ($0.merchant_id, $0.episode_id) < ($1.merchant_id, $1.episode_id) }
    }
}

// MARK: - Chapter Card

private struct StoryChapterCard: View {
    let chapter: StoryChapterDefinition
    let progress: PlayerProgress
    let isLocked: Bool

    private var totalEpisodes: Int {
        max(chapter.totalEpisodeCount(), 1)
    }

    private var completedEpisodes: Int {
        chapter.completedEpisodeCount(progress: progress)
    }

    private var progressRatio: Double {
        Double(completedEpisodes) / Double(totalEpisodes)
    }

    private var statusText: String {
        if chapter.isCompleted(progress: progress) {
            return "CLEAR"
        }
        return isLocked ? "LOCKED" : "ACTIVE"
    }

    private var statusColor: Color {
        if chapter.isCompleted(progress: progress) { return .green }
        return isLocked ? .cyberpunkError : .cyberpunkYellow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CH.\(chapter.order)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyberpunkCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyberpunkCyan.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Text(statusText)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(chapter.title)
                .font(.cyberpunkTitle(size: 18))
                .foregroundColor(.cyberpunkTextPrimary)
                .lineLimit(2)

            Text("\(completedEpisodes)/\(totalEpisodes) 에피소드 완료")
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.cyberpunkBorder)
                        .frame(height: 4)

                    Rectangle()
                        .fill(isLocked ? Color.cyberpunkBorder.opacity(0.6) : Color.cyberpunkYellow)
                        .frame(width: geo.size.width * CGFloat(progressRatio), height: 4)
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
        }
        .padding(16)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    chapter.isCompleted(progress: progress) ? Color.green.opacity(0.4) : Color.cyberpunkBorder,
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Merchant Story Card

private struct StoryCard: View {
    let title: String
    let subtitle: String
    let tagLeft: String
    let tagRight: String
    let tagRightColor: Color
    var primaryTitle: String = "시작"
    var secondaryTitle: String = "처음부터"
    let onPrimary: () -> Void
    let onSecondary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tagLeft)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyberpunkCyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.cyberpunkCyan.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                Spacer()

                Text(tagRight)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(tagRightColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tagRightColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            Text(title)
                .font(.cyberpunkTitle(size: 18))
                .foregroundColor(.cyberpunkTextPrimary)
                .lineLimit(2)

            Text(subtitle)
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)

            HStack(spacing: 10) {
                Button(primaryTitle, action: onPrimary)
                    .buttonStyle(.borderedProminent)
                    .disabled(tagRight == "LOCKED")
                Button(secondaryTitle, action: onSecondary)
                    .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyberpunkBorder, lineWidth: 1))
        .padding(.horizontal, 12)
    }
}
