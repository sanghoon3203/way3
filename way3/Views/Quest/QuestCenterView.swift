//
//  QuestCenterView.swift
//  way3
//
//  메인/서브 퀘스트 진행 현황을 한눈에 보여주는 허브
//

import SwiftUI

struct QuestCenterView: View {
    @EnvironmentObject private var questManager: QuestManager
    @EnvironmentObject private var progressManager: ProgressManager
    @EnvironmentObject private var gameManager: GameManager

    @State private var selectedSubQuest: SubQuestItem?
    @State private var selectedMainQuest: MainQuestDefinition?

    private var playerLevel: Int {
        gameManager.currentPlayer?.core.level ?? 1
    }

    private var subQuestItems: [SubQuestItem] {
        let districts = DistrictLoader.loadDistricts()
        return districts.flatMap { district in
            district.merchant.sub_quests.map { quest in
                SubQuestItem(
                    quest: quest,
                    districtName: district.name,
                    merchantName: district.merchant.name,
                    merchantId: district.merchant.merchant_id
                )
            }
        }
        .filter {
            let questId = $0.quest.quest_id
            return questManager.isSubQuestUnlocked(questId) && !progressManager.isSubQuestCompleted(questId)
        }
        .sorted { $0.districtName < $1.districtName }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    mainQuestSection
                    subQuestSection
                }
                .padding(.vertical, 20)
            }
            .background(Color.cyberpunkDarkBg.ignoresSafeArea())
            .navigationTitle("")
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(item: $selectedSubQuest) { item in
            NavigationStack {
                QuestDetailView(quest: item.quest, merchantId: item.merchantId)
                    .environmentObject(questManager)
                    .environmentObject(progressManager)
                    .environmentObject(gameManager)
                    .navigationTitle("")
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
        .sheet(item: $selectedMainQuest) { quest in
            NavigationStack {
                MainQuestDetailView(quest: quest)
                    .environmentObject(questManager)
                    .environmentObject(progressManager)
                    .environmentObject(gameManager)
                    .navigationTitle("")
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }

    // MARK: - Sections

    private var mainQuestSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "MAIN QUESTS", systemImage: "flag.fill")

            if questManager.queuedMainQuests.isEmpty {
                emptyState(text: "활성화된 메인 퀘스트가 없습니다.\n스토리를 진행해 새로운 메인 퀘스트를 발견하세요.")
            } else {
                ForEach(questManager.queuedMainQuests, id: \.questId) { quest in
                    let completedSet = Set(progressManager.completedObjectives(for: quest.questId))
                    MainQuestCard(
                        quest: quest,
                        progress: progressManager.progress,
                        playerLevel: playerLevel,
                        completedObjectiveIndices: completedSet
                    ) {
                        selectedMainQuest = quest
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var subQuestSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "SUB QUESTS", systemImage: "list.bullet.clipboard")

            if subQuestItems.isEmpty {
                emptyState(text: "모든 서브 퀘스트를 완료했습니다!\n새로운 지역을 탐험해보세요.")
            } else {
                ForEach(subQuestItems) { item in
                    SubQuestCard(
                        item: item,
                        progress: progressManager.progress,
                        playerLevel: playerLevel
                    ) {
                        selectedSubQuest = item
                    }
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helpers

    private func sectionHeader(title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundColor(.cyberpunkYellow)
            Text(title)
                .font(.cyberpunkHeading(size: 14))
                .foregroundColor(.cyberpunkTextPrimary)
            Spacer()
        }
    }

    private func emptyState(text: String) -> some View {
        Text(text)
            .font(.cyberpunkCaption())
            .foregroundColor(.cyberpunkTextSecondary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cyberpunkPanelBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Supporting Models

private struct SubQuestItem: Identifiable, Hashable {
    let quest: SubQuest
    let districtName: String
    let merchantName: String
    let merchantId: String

    var id: String { quest.quest_id }
}

// MARK: - Main Quest Card

private struct MainQuestCard: View {
    let quest: MainQuestDefinition
    let progress: PlayerProgress
    let playerLevel: Int
    let completedObjectiveIndices: Set<Int>
    let onTap: () -> Void

    private var requirementsMet: Bool {
        quest.requirements.isSatisfied(by: progress, playerLevel: playerLevel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("메인 퀘스트")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyberpunkCyan)
                    Text(quest.title)
                        .font(.cyberpunkTitle(size: 18))
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(2)
                    Text(quest.description)
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextSecondary)
                        .lineLimit(3)
                }
                Spacer()
                statusBadge
            }

            VStack(alignment: .leading, spacing: 6) {
                requirementRow(title: "필요 레벨", value: "\(quest.requirements.requiredLevel)", satisfied: playerLevel >= quest.requirements.requiredLevel)
                if !quest.requirements.requiredEpisodes.isEmpty {
                    let satisfied = quest.requirements.requiredEpisodes.allSatisfy { progress.isEpisodeCompleted($0) }
                    requirementRow(title: "필요 에피소드", value: quest.requirements.requiredEpisodes.joined(separator: ", "), satisfied: satisfied)
                }
                if !quest.requirements.requiredItems.isEmpty {
                    requirementRow(title: "필요 아이템", value: quest.requirements.requiredItems.joined(separator: ", "), satisfied: quest.requirements.requiredItems.allSatisfy { progress.hasKeyItem($0) })
                }
                if quest.objectiveCount > 0 {
                    let completedObjectives = completedObjectiveIndices.count
                    requirementRow(title: "목표 진행", value: "\(completedObjectives)/\(quest.objectiveCount)", satisfied: completedObjectives == quest.objectiveCount)
                }
            }

            Button(action: onTap) {
                Text(requirementsMet ? "상세 보기" : "요구 조건 확인")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(requirementsMet ? Color.cyberpunkYellow : Color.cyberpunkCardBg)
                    .foregroundColor(requirementsMet ? .black : .cyberpunkTextSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(requirementsMet ? Color.cyberpunkYellow : Color.cyberpunkBorder, lineWidth: 1))
    }

    private var statusBadge: some View {
        Text(requirementsMet ? "READY" : "LOCKED")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(requirementsMet ? .cyberpunkYellow : .cyberpunkError)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((requirementsMet ? Color.cyberpunkYellow : Color.cyberpunkError).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func requirementRow(title: String, value: String, satisfied: Bool) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.cyberpunkCaption())
                .foregroundColor(.cyberpunkTextSecondary)
            Spacer()
            Text(value)
                .font(.cyberpunkBody())
                .foregroundColor(satisfied ? .cyberpunkTextPrimary : .cyberpunkError)
        }
    }
}

// MARK: - Sub Quest Card

private struct SubQuestCard: View {
    let item: SubQuestItem
    let progress: PlayerProgress
    let playerLevel: Int
    let onTap: () -> Void

    private var requirementsMet: Bool {
        item.quest.requirements.meetsMetaRequirements(progress: progress, playerLevel: playerLevel)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.districtName)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyberpunkCyan)
                    Text(item.quest.typeDescription.uppercased())
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyberpunkTextSecondary)
                    Text(item.quest.title)
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextPrimary)
                    Text("상인: \(item.merchantName)")
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkTextSecondary)
                }
                Spacer()
                statusBadge
            }

            VStack(alignment: .leading, spacing: 4) {
                requirementIndicator(
                    title: "요약",
                    satisfied: true,
                    detail: item.quest.getDescription()
                )

                ForEach(Array(keyRequirementDetails.enumerated()), id: \.offset) { _, detail in
                    requirementIndicator(title: detail.title, satisfied: detail.satisfied, detail: detail.text)
                }

                requirementIndicator(
                    title: "레벨",
                    satisfied: item.quest.requirements.required_level.map { playerLevel >= $0 } ?? true
                )
                
                let requiredItems = item.quest.requirements.requiredItems ?? []
                if !requiredItems.isEmpty {
                    let satisfied = requiredItems.allSatisfy { progress.hasKeyItem($0) }
                    let text = requiredItems.joined(separator: ", ")
                    requirementIndicator(title: "아이템", satisfied: satisfied, detail: text)
                }
                
                let requiredStoryPieces = item.quest.requirements.requiredStoryPieces
                if !requiredStoryPieces.isEmpty {
                    let satisfied = requiredStoryPieces.allSatisfy { progress.hasStoryPiece($0) }
                    let text = requiredStoryPieces.joined(separator: ", ")
                    requirementIndicator(title: "스토리 조각", satisfied: satisfied, detail: text)
                }
            }

            Button(action: onTap) {
                Text(requirementsMet ? "상세 보기" : "조건 확인")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(requirementsMet ? Color.cyberpunkYellow : Color.cyberpunkCardBg)
                    .foregroundColor(requirementsMet ? .black : .cyberpunkTextSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(requirementsMet ? Color.cyberpunkYellow.opacity(0.5) : Color.cyberpunkBorder, lineWidth: 1))
    }

    private var statusBadge: some View {
        Text(requirementsMet ? "AVAILABLE" : "LOCKED")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(requirementsMet ? .cyberpunkYellow : .cyberpunkError)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background((requirementsMet ? Color.cyberpunkYellow : Color.cyberpunkError).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var keyRequirementDetails: [(title: String, text: String, satisfied: Bool)] {
        var rows: [(String, String, Bool)] = []
        let req = item.quest.requirements

        switch item.quest.type {
        case .trading:
            if let location = req.location {
                rows.append((
                    "거래 위치",
                    "반경 \(location.radius)m, lat \(String(format: "%.4f", location.latitude)), lng \(String(format: "%.4f", location.longitude))",
                    true
                ))
            }
            if let minPurchase = req.min_purchase {
                rows.append((
                    "최소 구매",
                    "₩\(minPurchase.formatted()) 이상",
                    true
                ))
            }
        case .delivery:
            if let target = req.target_location {
                rows.append((
                    "목표 지점",
                    "반경 \(target.radius)m, lat \(String(format: "%.4f", target.latitude)), lng \(String(format: "%.4f", target.longitude))",
                    true
                ))
            }
            if let timeLimit = req.time_limit {
                rows.append((
                    "제한 시간",
                    "\(timeLimit / 60)분",
                    true
                ))
            }
        case .dialogue:
            if let storyNode = req.story_node_start ?? req.story_node_complete {
                rows.append((
                    "스토리 시작",
                    storyNode,
                    true
                ))
            }
        }

        return rows
    }

    private func requirementIndicator(title: String, satisfied: Bool, detail: String? = nil) -> some View {
        HStack(spacing: 6) {
            Image(systemName: satisfied ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(satisfied ? .green : .cyberpunkError)
                .font(.system(size: 12, weight: .bold))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cyberpunkCaption())
                    .foregroundColor(satisfied ? .cyberpunkTextSecondary : .cyberpunkError)
                if let detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(.cyberpunkTextSecondary)
                }
            }
        }
    }
}

// MARK: - Main Quest Detail

private struct MainQuestDetailView: View {
    let quest: MainQuestDefinition

    @EnvironmentObject private var questManager: QuestManager
    @EnvironmentObject private var progressManager: ProgressManager
    @EnvironmentObject private var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss

    @State private var showResult: Bool = false
    @State private var resultMessage: String = ""
    @State private var isSuccess: Bool = false

    private var playerLevel: Int {
        gameManager.currentPlayer?.core.level ?? 1
    }

    private var requirementsMet: Bool {
        quest.requirements.isSatisfied(by: progressManager.progress, playerLevel: playerLevel)
    }

    private var completedObjectiveIndices: Set<Int> {
        Set(progressManager.completedObjectives(for: quest.questId))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                requirementsCard
                objectivesCard
                rewardsCard

                Button(action: completeQuest) {
                    Text(requirementsMet ? "퀘스트 완료 처리" : "요구 조건 미충족")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(requirementsMet ? Color.cyberpunkYellow : Color.cyberpunkCardBg)
                        .foregroundColor(requirementsMet ? .black : .cyberpunkTextSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(!requirementsMet)

                if showResult {
                    resultBanner
                }
            }
            .padding(20)
        }
        .background(Color.cyberpunkDarkBg.ignoresSafeArea())
        .navigationTitle(quest.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(quest.title)
                .font(.cyberpunkTitle(size: 22))
                .foregroundColor(.cyberpunkTextPrimary)
            Text(quest.description)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
        }
    }

    private var requirementsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("요구 조건")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.cyberpunkYellow)

            requirementRow(
                title: "필요 레벨 \(quest.requirements.requiredLevel)",
                satisfied: playerLevel >= quest.requirements.requiredLevel
            )

            if !quest.requirements.requiredEpisodes.isEmpty {
                let satisfied = quest.requirements.requiredEpisodes.allSatisfy { progressManager.isEpisodeCompleted($0) }
                requirementRow(
                    title: "에피소드: \(quest.requirements.requiredEpisodes.joined(separator: ", "))",
                    satisfied: satisfied
                )
            }

            if !quest.requirements.requiredItems.isEmpty {
                requirementRow(
                    title: "아이템: \(quest.requirements.requiredItems.joined(separator: ", "))",
                    satisfied: quest.requirements.requiredItems.allSatisfy { progressManager.progress.hasKeyItem($0) }
                )
            }

            if quest.objectiveCount > 0 {
                let completed = progressManager.completedObjectives(for: quest.questId).count
                requirementRow(
                    title: "목표 진행 \(completed)/\(quest.objectiveCount)",
                    satisfied: completed == quest.objectiveCount
                )
            }
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var objectivesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("목표")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.cyberpunkYellow)

            ForEach(quest.objectives.indices, id: \.self) { idx in
                let objective = quest.objectives[idx]
                let isCompleted = completedObjectiveIndices.contains(idx)
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : objective.systemIconName)
                        .foregroundColor(isCompleted ? .green : .cyberpunkCyan)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(objective.displayDescription)
                            .font(.cyberpunkBody())
                            .foregroundColor(isCompleted ? .green : .cyberpunkTextPrimary)
                        if let desc = objective.description {
                            Text(desc)
                                .font(.cyberpunkCaption())
                                .foregroundColor(.cyberpunkTextSecondary)
                        }
                    }
                    Spacer()
                }
                .padding(10)
                .background(isCompleted ? Color.green.opacity(0.12) : Color.cyberpunkCardBg)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("보상")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.cyberpunkYellow)

            let rewards = quest.rewards.asQuestRewards()

            if let money = rewards.money {
                rewardRow(icon: "won.sign.circle.fill", text: "골드 +\(money.formatted())")
            }
            if let exp = rewards.exp {
                rewardRow(icon: "star.circle.fill", text: "경험치 +\(exp)")
            }
            if !rewards.storyPieceIds.isEmpty {
                rewardRow(icon: "doc.text.fill", text: "스토리 조각: \(rewards.storyPieceIds.joined(separator: ", "))")
            }
            if !rewards.keyItems.isEmpty {
                rewardRow(icon: "key.fill", text: "증표/키 아이템: \(rewards.keyItems.joined(separator: ", "))")
            }
            if let relationship = rewards.relationshipChange {
                rewardRow(icon: "heart.fill", text: "신뢰도 +\(relationship.trust)")
            }
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var resultBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(isSuccess ? .green : .cyberpunkError)
                .font(.system(size: 20))
            Text(resultMessage)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
            Spacer()
        }
        .padding(14)
        .background((isSuccess ? Color.green : Color.cyberpunkError).opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func requirementRow(title: String, satisfied: Bool) -> some View {
        HStack {
            Image(systemName: satisfied ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(satisfied ? .green : .cyberpunkError)
            Text(title)
                .font(.cyberpunkBody())
                .foregroundColor(satisfied ? .cyberpunkTextPrimary : .cyberpunkError)
        }
    }

    private func rewardRow(icon: String, text: String) -> some View {
        HStack {
            Image(systemName: icon).foregroundColor(.cyberpunkYellow)
            Text(text)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
        }
    }

    private func completeQuest() {
        let success = questManager.completeMainQuest(quest)
        isSuccess = success
        resultMessage = success ? "보상이 지급되었습니다." : "요구 조건이 충족되지 않았습니다."
        showResult = true

        if success {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                dismiss()
            }
        }
    }
}

private extension MainQuestObjective {
    var systemIconName: String {
        switch type {
        case .delivery: return "location.fill"
        case .trading: return "creditcard.fill"
        case .dialogue: return "bubble.left.and.bubble.right.fill"
        case .interact: return "hand.tap.fill"
        }
    }
}
