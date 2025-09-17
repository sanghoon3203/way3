//
//  SkillTreeView.swift
//  way3 - Way Trading Game Skill System
//
//  서버 연동 스킬 트리 인터페이스
//

import SwiftUI
import Foundation

// MARK: - 서버 스킬 데이터 모델
struct SkillCategory {
    let category: String
    let name: String
    let skills: [ServerSkill]
}

struct ServerSkill: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let tier: Int
    let currentLevel: Int
    let maxLevel: Int
    let canUnlock: Bool
    let isUnlocked: Bool
    let nextLevelCost: Int?
    let effects: [SkillEffect]
    let nextLevelEffects: [SkillEffect]?
    let prerequisites: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, description, tier, currentLevel, maxLevel
        case canUnlock, isUnlocked, nextLevelCost, effects
        case nextLevelEffects, prerequisites
    }
}

struct SkillEffect: Codable {
    let name: String
    let value: Double
    let description: String
}

struct SkillTreeResponse: Codable {
    let success: Bool
    let data: SkillTreeData?
    let error: String?
}

struct SkillTreeData: Codable {
    let skillTree: [SkillCategoryData]
    let availablePoints: Int
    let playerLevel: Int
}

struct SkillCategoryData: Codable {
    let category: String
    let name: String
    let skills: [ServerSkill]
}

// MARK: - 스킬 트리 메인 뷰
struct SkillTreeView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedSkill: ServerSkill?
    @State private var showingSkillDetail = false
    @State private var skillTree: [SkillCategory] = []
    @State private var availablePoints = 0
    @State private var playerLevel = 1
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                // 기본 배경
                LinearGradient(colors: [Color.gray.opacity(0.1), Color.white], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView("스킬 트리 로딩 중...")
                        .font(.custom("ChosunCentennial", size: 16))
                } else if let errorMessage = errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.custom("ChosunCentennial", size: 16))
                            .foregroundColor(.secondary)

                        Button("다시 시도") {
                            loadSkillTree()
                        }
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(.blue)
                        .padding(.top)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 헤더
                            skillTreeHeader

                            // 스킬 카테고리별 표시
                            ForEach(skillTree, id: \.category) { category in
                                skillCategorySection(category)
                            }

                            // 하단 여백
                            Spacer(minLength: 100)
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .navigationTitle("스킬 트리")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.custom("ChosunCentennial", size: 16))
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.orange)
                        Text("\(availablePoints)")
                            .font(.custom("ChosunCentennial", size: 16))
                            .fontWeight(.semibold)
                    }
                }
            })
        }
        .onAppear {
            loadSkillTree()
        }
        .sheet(isPresented: $showingSkillDetail) {
            if let skill = selectedSkill {
                SkillDetailSheet(skill: skill, availablePoints: availablePoints) {
                    loadSkillTree() // 스킬 업그레이드 후 새로고침
                }
            }
        }
    }

    // MARK: - 헤더 섹션
    private var skillTreeHeader: some View {
        VStack(spacing: 16) {
            // 타이틀
            HStack {
                Image(systemName: "brain")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)

                Text("스킬 트리")
                    .font(.custom("ChosunCentennial", size: 24))
                    .fontWeight(.bold)

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("스킬 포인트")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.secondary)

                    Text("\(availablePoints)")
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
            }

            // 설명
            Text("스킬을 업그레이드하여 거래 능력을 향상시키세요.\n레벨업을 통해 스킬 포인트를 획득할 수 있습니다.")
                .font(.custom("ChosunCentennial", size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)

            Text("플레이어 레벨: \(playerLevel)")
                .font(.custom("ChosunCentennial", size: 16))
                .foregroundColor(.blue)
                .fontWeight(.medium)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
        .padding(.top, 8)
    }

    // MARK: - 스킬 카테고리 섹션
    private func skillCategorySection(_ category: SkillCategory) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 카테고리 헤더
            Text(category.name)
                .font(.custom("ChosunCentennial", size: 20))
                .fontWeight(.bold)
                .foregroundColor(.primary)

            // 스킬 그리드
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(category.skills.sorted { $0.tier < $1.tier }) { skill in
                    SkillCard(skill: skill) {
                        selectedSkill = skill
                        showingSkillDetail = true
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(radius: 2)
        )
    }

    // MARK: - API 호출
    private func loadSkillTree() {
        isLoading = true
        errorMessage = nil

        guard let authToken = authManager.currentToken else {
            errorMessage = "로그인이 필요합니다"
            isLoading = false
            return
        }

        Task {
            do {
                let url = URL(string: "http://localhost:3001/api/skills/tree")!
                var request = URLRequest(url: url)
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(SkillTreeResponse.self, from: data)

                await MainActor.run {
                    if response.success, let skillData = response.data {
                        self.skillTree = skillData.skillTree.map { categoryData in
                            SkillCategory(
                                category: categoryData.category,
                                name: categoryData.name,
                                skills: categoryData.skills
                            )
                        }
                        self.availablePoints = skillData.availablePoints
                        self.playerLevel = skillData.playerLevel
                    } else {
                        self.errorMessage = response.error ?? "스킬 트리 로딩 실패"
                    }
                    self.isLoading = false
                }

            } catch {
                await MainActor.run {
                    self.errorMessage = "네트워크 오류: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - 스킬 카드
struct SkillCard: View {
    let skill: ServerSkill
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // 스킬 아이콘
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(skillColor.opacity(0.2))
                        .frame(height: 60)

                    Image(systemName: skillIcon)
                        .font(.system(size: 24))
                        .foregroundColor(skillColor)
                }

                VStack(spacing: 4) {
                    // 스킬 이름
                    Text(skill.name)
                        .font(.custom("ChosunCentennial", size: 14))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .foregroundColor(.primary)

                    // 레벨 정보
                    Text("\(skill.currentLevel)/\(skill.maxLevel)")
                        .font(.custom("ChosunCentennial", size: 12))
                        .foregroundColor(.secondary)

                    // 업그레이드 비용
                    if let cost = skill.nextLevelCost, skill.currentLevel < skill.maxLevel {
                        Text("비용: \(cost)P")
                            .font(.custom("ChosunCentennial", size: 11))
                            .foregroundColor(.blue)
                            .fontWeight(.medium)
                    } else if skill.currentLevel >= skill.maxLevel {
                        Text("MAX")
                            .font(.custom("ChosunCentennial", size: 11))
                            .foregroundColor(.green)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(skill.isUnlocked ? skillColor : Color.gray.opacity(0.3), lineWidth: skill.isUnlocked ? 2 : 1)
                    )
            )
            .opacity(skill.canUnlock || skill.isUnlocked ? 1.0 : 0.5)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var skillColor: Color {
        switch skill.tier {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var skillIcon: String {
        // 스킬 이름에 따라 아이콘 결정
        if skill.name.contains("거래") { return "handshake" }
        else if skill.name.contains("분석") { return "chart.line.uptrend.xyaxis" }
        else if skill.name.contains("협상") { return "person.2" }
        else if skill.name.contains("예측") { return "brain" }
        else if skill.name.contains("관계") { return "heart" }
        else if skill.name.contains("보관") { return "archivebox" }
        else { return "star" }
    }
}

// MARK: - 스킬 상세 시트
struct SkillDetailSheet: View {
    let skill: ServerSkill
    let availablePoints: Int
    let onUpgrade: () -> Void

    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var isUpgrading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 스킬 아이콘
                ZStack {
                    Circle()
                        .fill(skillColor.opacity(0.2))
                        .frame(width: 80, height: 80)

                    Image(systemName: skillIcon)
                        .font(.system(size: 32))
                        .foregroundColor(skillColor)
                }

                VStack(spacing: 8) {
                    Text(skill.name)
                        .font(.custom("ChosunCentennial", size: 24))
                        .fontWeight(.bold)

                    Text(skill.description)
                        .font(.custom("ChosunCentennial", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("레벨 \(skill.currentLevel)/\(skill.maxLevel) • 티어 \(skill.tier)")
                        .font(.custom("ChosunCentennial", size: 14))
                        .foregroundColor(.blue)
                        .fontWeight(.medium)
                }

                // 현재 효과
                if !skill.effects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("현재 효과")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)

                        ForEach(skill.effects, id: \.name) { effect in
                            Text(effect.description)
                                .font(.custom("ChosunCentennial", size: 14))
                                .foregroundColor(.primary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.secondarySystemBackground))
                    )
                }

                // 다음 레벨 효과
                if let nextEffects = skill.nextLevelEffects, !nextEffects.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("다음 레벨 효과")
                            .font(.custom("ChosunCentennial", size: 18))
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)

                        ForEach(nextEffects, id: \.name) { effect in
                            Text(effect.description)
                                .font(.custom("ChosunCentennial", size: 14))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.1))
                    )
                }

                Spacer()

                // 업그레이드 버튼
                if skill.currentLevel < skill.maxLevel {
                    Button(action: upgradeSkill) {
                        HStack {
                            if isUpgrading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                Text("업그레이드 (\(skill.nextLevelCost ?? 0)P)")
                            }
                        }
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(canUpgrade ? Color.blue : Color.gray)
                        )
                    }
                    .disabled(!canUpgrade || isUpgrading)
                } else {
                    Text("최대 레벨 달성")
                        .font(.custom("ChosunCentennial", size: 18))
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.green.opacity(0.2))
                        )
                }
            }
            .padding()
            .navigationTitle("스킬 정보")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                    .font(.custom("ChosunCentennial", size: 16))
                }
            }
        }
    }

    private var canUpgrade: Bool {
        guard let cost = skill.nextLevelCost else { return false }
        return skill.canUnlock && availablePoints >= cost && skill.currentLevel < skill.maxLevel
    }

    private var skillColor: Color {
        switch skill.tier {
        case 1: return .green
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var skillIcon: String {
        if skill.name.contains("거래") { return "handshake" }
        else if skill.name.contains("분석") { return "chart.line.uptrend.xyaxis" }
        else if skill.name.contains("협상") { return "person.2" }
        else if skill.name.contains("예측") { return "brain" }
        else if skill.name.contains("관계") { return "heart" }
        else if skill.name.contains("보관") { return "archivebox" }
        else { return "star" }
    }

    private func upgradeSkill() {
        guard let authToken = authManager.currentToken else { return }

        isUpgrading = true

        Task {
            do {
                let url = URL(string: "http://localhost:3001/api/skills/\(skill.id)/upgrade")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let (data, _) = try await URLSession.shared.data(for: request)
                let response = try JSONDecoder().decode(SkillTreeResponse.self, from: data)

                await MainActor.run {
                    if response.success {
                        onUpgrade()
                        dismiss()
                    }
                    isUpgrading = false
                }

            } catch {
                await MainActor.run {
                    isUpgrading = false
                }
            }
        }
    }
}

#Preview {
    SkillTreeView()
        .environmentObject(AuthManager.shared)
}