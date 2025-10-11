//
//  QuestDetailView.swift
//  way3
//
//  퀘스트 상세 및 인증 UI
//  Trading (영수증 OCR) / Delivery (GPS) / Dialogue (스토리)
//

import SwiftUI
import CoreLocation
import PhotosUI

private struct StoryLaunchKey: Identifiable {
    let id: String
}

struct QuestDetailView: View {
    let quest: SubQuest
    let merchantId: String

    @EnvironmentObject var questManager: QuestManager
    @EnvironmentObject var progressManager: ProgressManager
    @EnvironmentObject var locationManager: LocationManager
    @EnvironmentObject var gameManager: GameManager

    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var isSuccess = false
    @State private var isProcessing = false

    @State private var currentDistance: Double = 0
    @State private var distanceTimer: Timer?
    @State private var activeStory: StoryLaunchKey?
    @State private var isStoryCompleting = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Quest info
                questInfoCard

                // Quest requirements
                requirementsCard

                // Quest rewards
                rewardsCard

                // Verification UI
                verificationSection

                // Result message
                if showResult {
                    resultCard
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color.cyberpunkDarkBg)
        .navigationTitle(quest.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .fullScreenCover(item: $activeStory) { launch in
            StoryView(startNodeID: launch.id) {
                Task { await completeDialogueQuest() }
            }
            .background(Color.black.ignoresSafeArea())
        }
        .onChange(of: selectedImage) { _, newImage in
            if let image = newImage {
                executeTrading(image: image)
            }
        }
        .onAppear {
            if quest.type == .delivery {
                startDistanceTracking()
            }
        }
        .onDisappear {
            stopDistanceTracking()
        }
    }

    // MARK: - UI Components

    private var questInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: quest.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.cyberpunkCyan)

                VStack(alignment: .leading, spacing: 4) {
                    Text(quest.typeDescription)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyberpunkCyan)

                    Text(quest.title)
                        .font(.cyberpunkTitle(size: 18))
                        .foregroundColor(.cyberpunkTextPrimary)
                }

                Spacer()

                if questManager.isQuestCompleted(quest.quest_id) {
                    VStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                        Text("완료")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
            }

            Divider().background(Color.cyberpunkBorder)

            Text(quest.getDescription())
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextSecondary)
        }
        .padding(16)
        .background(Color.cyberpunkCardBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.cyberpunkYellow, lineWidth: 1))
        .padding(.horizontal, 12)
    }

    private var requirementsCard: some View {
        let progress = progressManager.progress
        let playerLevel = gameManager.currentPlayer?.core.level ?? 1
        let meetsLevel = quest.requirements.required_level.map { playerLevel >= $0 } ?? true
        let hasItems = quest.requirements.requiredItems.allSatisfy { progress.hasKeyItem($0) }
        let hasStoryPieces = quest.requirements.requiredStoryPieces.allSatisfy { progress.hasStoryPiece($0) }
        let hasMainQuests = quest.requirements.requiredMainQuests.allSatisfy { progress.isMainQuestCompleted($0) }
        let hasSubQuests = quest.requirements.requiredSubQuests.allSatisfy { progress.isSubQuestCompleted($0) }

        return VStack(alignment: .leading, spacing: 12) {
            Text("REQUIREMENTS")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.cyberpunkYellow)

            switch quest.type {
            case .trading:
                if let minPurchase = quest.requirements.min_purchase {
                    requirementRow(icon: "won.sign.circle.fill", text: "최소 구매금액: ₩\(minPurchase)")
                }
                if let location = quest.requirements.location {
                    requirementRow(icon: "location.circle.fill", text: "반경 \(location.radius)m 내")
                    if locationManager.isLocationAvailable {
                        let userLoc = locationManager.currentLocation
                        let merchantLoc = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                        let distance = userLoc.distance(to: merchantLoc)
                        requirementRow(
                            icon: "figure.walk.circle.fill",
                            text: "현재 거리: \(String(format: "%.0f", distance))m",
                            color: distance <= Double(location.radius) ? .green : .cyberpunkError
                        )
                    }
                }

            case .delivery:
                if let target = quest.requirements.target_location {
                    requirementRow(icon: "mappin.circle.fill", text: "목표 지점 반경 \(target.radius)m")
                    requirementRow(
                        icon: "figure.walk.circle.fill",
                        text: "현재 거리: \(String(format: "%.0f", currentDistance))m",
                        color: currentDistance <= Double(target.radius) ? .green : .cyberpunkError
                    )
                }
                if let timeLimit = quest.requirements.time_limit {
                    requirementRow(icon: "clock.circle.fill", text: "제한시간: \(timeLimit / 60)분")
                }

            case .dialogue:
                requirementRow(icon: "bubble.left.and.bubble.right.fill", text: "대화 완료 필요")
            }

            if let requiredLevel = quest.requirements.required_level {
                requirementRow(icon: "arrow.up.circle.fill", text: "필요 레벨: \(requiredLevel)", color: meetsLevel ? .cyberpunkTextPrimary : .cyberpunkError)
            }

            if !quest.requirements.requiredItems.isEmpty {
                requirementRow(
                    icon: "cube.box.fill",
                    text: "필요 아이템: \(quest.requirements.requiredItems.joined(separator: ", "))",
                    color: hasItems ? .cyberpunkTextPrimary : .cyberpunkError
                )
            }

            if !quest.requirements.requiredStoryPieces.isEmpty {
                requirementRow(
                    icon: "doc.plaintext.fill",
                    text: "필요 스토리 조각: \(quest.requirements.requiredStoryPieces.joined(separator: ", "))",
                    color: hasStoryPieces ? .cyberpunkTextPrimary : .cyberpunkError
                )
            }

            if !quest.requirements.requiredMainQuests.isEmpty {
                requirementRow(
                    icon: "checkmark.shield.fill",
                    text: "필요 메인 퀘스트: \(quest.requirements.requiredMainQuests.joined(separator: ", "))",
                    color: hasMainQuests ? .cyberpunkTextPrimary : .cyberpunkError
                )
            }

            if !quest.requirements.requiredSubQuests.isEmpty {
                requirementRow(
                    icon: "list.bullet.clipboard.fill",
                    text: "필요 서브 퀘스트: \(quest.requirements.requiredSubQuests.joined(separator: ", "))",
                    color: hasSubQuests ? .cyberpunkTextPrimary : .cyberpunkError
                )
            }
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
    }


    private var rewardsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("REWARDS")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.cyberpunkYellow)

            if let money = quest.rewards.money, money > 0 {
                rewardRow(icon: "won.sign.circle.fill", text: "₩\(money.formatted())")
            }
            if let exp = quest.rewards.exp, exp > 0 {
                rewardRow(icon: "star.circle.fill", text: "EXP +\(exp)")
            }
            if !quest.rewards.storyPieceIds.isEmpty {
                rewardRow(icon: "doc.text.circle.fill", text: "스토리 조각: \(quest.rewards.storyPieceIds.joined(separator: ", "))")
            }
            if !quest.rewards.inventoryItems.isEmpty {
                rewardRow(icon: "shippingbox.fill", text: "아이템: \(quest.rewards.inventoryItems.joined(separator: ", "))")
            }
            if !quest.rewards.keyItems.isEmpty {
                rewardRow(icon: "key.fill", text: "증표/키 아이템: \(quest.rewards.keyItems.joined(separator: ", "))")
            }
            if let relationship = quest.rewards.relationshipChange {
                rewardRow(icon: "heart.circle.fill", text: "신뢰도 +\(relationship.trust)")
            }
        }
        .padding(16)
        .background(Color.cyberpunkPanelBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 12)
    }

    private var verificationSection: some View {
        VStack(spacing: 16) {
            if !metaRequirementsMet {
                Text("필수 조건을 먼저 충족해야 진행할 수 있습니다.")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkError)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            switch quest.type {
            case .trading:
                tradingVerificationButton.disabled(!metaRequirementsMet)
            case .delivery:
                deliveryVerificationButton.disabled(!metaRequirementsMet)
            case .dialogue:
                dialogueVerificationButton.disabled(!metaRequirementsMet)
            }
        }
        .padding(.horizontal, 12)
    }

    private var tradingVerificationButton: some View {
        Button {
            showImagePicker = true
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 20))
                }
                Text(isProcessing ? "영수증 확인 중..." : "영수증 촬영하기")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isProcessing ? Color.cyberpunkTextSecondary : Color.cyberpunkYellow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isProcessing || progressManager.progress.isQuestCompleted(quest.quest_id))
    }

    private var deliveryVerificationButton: some View {
        Button {
            executeDelivery()
        } label: {
            HStack {
                if isProcessing {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "location.fill")
                        .font(.system(size: 20))
                }
                Text(isProcessing ? "위치 확인 중..." : "도착 확인하기")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isProcessing ? Color.cyberpunkTextSecondary : Color.cyberpunkYellow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isProcessing || questManager.isQuestCompleted(quest.quest_id))
    }

    private var dialogueVerificationButton: some View {
        Button {
            launchDialogueStory()
        } label: {
            HStack {
                if isStoryCompleting {
                    ProgressView()
                        .tint(.black)
                } else {
                    Image(systemName: "play.fill")
                        .font(.system(size: 20))
                }
                Text(isStoryCompleting ? "검증 처리 중..." : "대화 시작하기")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(dialogueButtonAvailable ? Color.cyberpunkYellow : Color.cyberpunkCardBg)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!dialogueButtonAvailable)
    }

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSuccess ? .green : .cyberpunkError)

                Text(isSuccess ? "SUCCESS" : "FAILED")
                    .font(.system(size: 12, weight: .black, design: .monospaced))
                    .foregroundColor(isSuccess ? .green : .cyberpunkError)

                Spacer()
            }

            Text(resultMessage)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)

            if isSuccess {
                Button("완료") {
                    dismiss()
                }
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.cyberpunkYellow)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(isSuccess ? Color.green.opacity(0.1) : Color.cyberpunkError.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(
            isSuccess ? Color.green : Color.cyberpunkError,
            lineWidth: 2
        ))
        .padding(.horizontal, 12)
    }

    // MARK: - Helper Views

    private func requirementRow(icon: String, text: String, color: Color = .cyberpunkTextPrimary) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(text)
                .font(.cyberpunkCaption())
                .foregroundColor(color)
        }
    }

    private var metaRequirementsMet: Bool {
        let playerLevel = gameManager.currentPlayer?.core.level ?? 1
        return quest.requirements.meetsMetaRequirements(progress: progressManager.progress, playerLevel: playerLevel)
    }

    private var dialogueButtonAvailable: Bool {
        guard !questManager.isQuestCompleted(quest.quest_id),
              !isProcessing,
              !isStoryCompleting else { return false }
        return dialogueStartNode != nil
    }

    private var dialogueStartNode: String? {
        quest.requirements.storyNodeStart ?? quest.requirements.storyNodeComplete
    }

    private func rewardRow(icon: String, text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.cyberpunkYellow)
            Text(text)
                .font(.cyberpunkBody())
                .foregroundColor(.cyberpunkTextPrimary)
        }
    }

    // MARK: - Quest Execution

    private func launchDialogueStory() {
        guard let startNode = dialogueStartNode else {
            isSuccess = false
            resultMessage = "스토리 노드 정보가 정의되지 않았습니다."
            showResult = true
            return
        }
        activeStory = StoryLaunchKey(id: startNode)
    }

    private func executeTrading(image: UIImage) {
        guard !questManager.isQuestCompleted(quest.quest_id) else { return }

        isProcessing = true

        Task {
            do {
                let result = try await questManager.executeTradingQuest(
                    quest: quest,
                    receiptImage: image,
                    userLocation: locationManager.currentLocation
                )

                await MainActor.run {
                    isSuccess = result.success
                    resultMessage = result.message
                    showResult = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    resultMessage = error.localizedDescription
                    showResult = true
                    isProcessing = false
                }
            }
        }
    }

    private func executeDelivery() {
        guard !questManager.isQuestCompleted(quest.quest_id) else { return }

        isProcessing = true

        Task {
            do {
                let userLocation = CLLocation(
                    latitude: locationManager.currentLocation.latitude,
                    longitude: locationManager.currentLocation.longitude
                )

                let result = try await questManager.executeDeliveryQuest(
                    quest: quest,
                    userLocation: userLocation
                )

                await MainActor.run {
                    isSuccess = result.success
                    resultMessage = result.message
                    showResult = true
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    isSuccess = false
                    resultMessage = error.localizedDescription
                    showResult = true
                    isProcessing = false
                }
            }
        }
    }

    // MARK: - Distance Tracking

    private func startDistanceTracking() {
        guard quest.type == .delivery,
              let target = quest.requirements.target_location else { return }

        let targetLoc = CLLocationCoordinate2D(
            latitude: target.latitude,
            longitude: target.longitude
        )

        // Initial distance
        currentDistance = locationManager.currentLocation.distance(to: targetLoc)

        // Update every 2 seconds
        distanceTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            currentDistance = locationManager.currentLocation.distance(to: targetLoc)
        }
    }

    private func stopDistanceTracking() {
        distanceTimer?.invalidate()
        distanceTimer = nil
    }

    // MARK: - Dialogue Completion

    private func completeDialogueQuest() async {
        guard !questManager.isQuestCompleted(quest.quest_id) else { return }
        guard let completionNode = quest.requirements.storyNodeComplete else {
            await MainActor.run {
                isSuccess = false
                resultMessage = "스토리 완료 노드가 설정되어 있지 않습니다."
                showResult = true
            }
            return
        }

        await MainActor.run {
            isStoryCompleting = true
            showResult = false
        }

        do {
            let result = try await questManager.executeDialogueQuest(
                quest: quest,
                completedStoryNode: completionNode
            )
            await MainActor.run {
                isSuccess = result.success
                resultMessage = result.message
                showResult = true
            }
        } catch {
            await MainActor.run {
                isSuccess = false
                resultMessage = error.localizedDescription
                showResult = true
            }
        }

        await MainActor.run {
            isStoryCompleting = false
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
