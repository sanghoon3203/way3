import SwiftUI
import AVKit
import os

// MARK: - UI Pieces

struct TypewriterText: View {
    @ObservedObject var engine: TypewriterEngine
    let lineHeight: CGFloat

    var body: some View {
        Text(engine.displayed)
            .font(.system(size: 17, weight: .regular, design: .rounded))
            .foregroundStyle(Color.white)
            .lineSpacing(6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: lineHeight, alignment: .topLeading)
            .animation(.linear(duration: 0.02), value: engine.displayed)
    }
}

struct HeroDialogueOverlay: View {
    let speaker: String?
    @ObservedObject var engine: TypewriterEngine

    var body: some View {
        VStack(spacing: 10) {
            if let name = speaker, !name.isEmpty {
                HStack {
                    Text(name.uppercased())
                        .font(.system(size: 12, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Color.cyan)
                    Spacer()
                }
            }
            TypewriterText(engine: engine, lineHeight: 90)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0.09, green: 0.09, blue: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

struct BottomProceedBar: View {
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: isCompleted ? "arrow.right.circle.fill" : "bolt.fill")
                        .font(.system(size: 18, weight: .heavy))
                    Text(isCompleted ? "NEXT" : "CONTINUE")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                }
                .foregroundStyle(Color.black)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.yellow)
                        .shadow(color: .yellow.opacity(0.4), radius: 10, x: 0, y: 6)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)
        }
        .background(
            LinearGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.25)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct DecisionChoiceList: View {
    let decision: VNDecisionContent
    let onChoice: (VNChoice) -> Void

    var body: some View {
        VStack(spacing: 12) {
            ForEach(decision.choices) { choice in
                Button(action: { onChoice(choice) }) {
                    HStack {
                        Text(choice.text)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cyberpunkYellow.opacity(0.9))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 28)
    }
}

struct PendingNodeOverlay: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.cyberpunkTextSecondary)
            .multilineTextAlignment(.center)
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.cyberpunkPanelBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.cyberpunkBorder, lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 28)
    }
}

// MARK: - StoryView

struct StoryView: View {
    @State private var currentNodeID: String
    @State private var node: VNNode?
    @StateObject private var engine = TypewriterEngine()   // ✅ 안정화
    @Environment(\.dismiss) private var dismiss
    @State private var showExitConfirmation = false
    @State private var lastBackgroundName: String?

    let returnToMapOnCompletion: Bool
    let onStoryComplete: (() -> Void)?

    init(startNodeID: String = "prologue_01", returnToMapOnCompletion: Bool = false, onComplete: (() -> Void)? = nil) {
        _currentNodeID = State(initialValue: startNodeID)
        self.returnToMapOnCompletion = returnToMapOnCompletion
        self.onStoryComplete = onComplete
    }

    var body: some View {
        ZStack {
            backgroundLayer
            characterLayer
            VStack(spacing: 0) {
                Spacer()
                nodeInteractionLayer
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topTrailing) {
            ExitButton {
                if engine.isCompleted {
                    showExitConfirmation = true
                } else {
                    showExitConfirmation = true
                }
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
        .onAppear {
            AppLog.story.info("📺 StoryView appear startNode=\(self.currentNodeID, privacy: .public)")
            loadNodeAndStart(id: currentNodeID)
        }

        // (선택) 상단 디버그 HUD
        .overlay(alignment: .topLeading) {
            debugHUD
        }
        .alert("스토리를 종료할까요?", isPresented: $showExitConfirmation) {
            Button("취소", role: .cancel) { }
            Button("종료", role: .destructive) {
                finishStory()
            }
        } message: {
            Text("진행 중인 스토리를 종료하면 현재 노드에서 종료됩니다.")
        }
    }

    private var backgroundLayer: some View {
        Group {
            let backgroundName = resolvedBackgroundName()
            if let name = backgroundName,
               let ui = UIImage(named: name) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(
                    colors: [.black, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
    }

    private var characterLayer: some View {
        Group {
            if let sprite = currentDialogue?.characterSprite,
               !sprite.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let trimmed = sprite.trimmingCharacters(in: .whitespaces)
                if let movieName = resolvedMovieName(from: trimmed) {
                    VStack {
                        Spacer()
                        CharacterOneShotVideoView(resourceName: movieName)
                            .frame(height: 320)
                            .shadow(color: .cyan.opacity(0.4), radius: 12)
                    }
                    .padding(.bottom, 140)
                } else if let ui = UIImage(named: trimmed) {
                    VStack {
                        Spacer()
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 320)
                            .shadow(color: .cyan.opacity(0.4), radius: 12)
                    }
                    .padding(.bottom, 140)
                }
            }
        }
    }

    @ViewBuilder
    private var nodeInteractionLayer: some View {
        switch node?.type ?? .dialogue {
        case .dialogue:
            HeroDialogueOverlay(speaker: currentSpeakerName, engine: engine)
            BottomProceedBar(isCompleted: engine.isCompleted) { nextPressed() }
        case .decision:
            if let decision = node?.decision {
                HeroDialogueOverlay(speaker: decision.speakerDisplayName ?? currentSpeakerName, engine: engine)
                DecisionChoiceList(decision: decision, onChoice: handleDecisionChoice)
            } else {
                PendingNodeOverlay(message: "선택지가 준비되지 않았습니다.")
            }
        case .conditional:
            PendingNodeOverlay(message: "조건을 확인하는 중입니다...")
        case .questGate:
            PendingNodeOverlay(message: "퀘스트 게이트를 처리하는 중입니다...")
        }
    }

    private var currentDialogue: VNDialogueContent? {
        node?.dialogue
    }

    private var currentSpeakerName: String? {
        node?.displaySpeaker
    }

    private func loadNodeAndStart(id: String) {
        AppLog.story.info("🔄 loadNode id=\(id, privacy: .public)")
        guard let n = VNLoader.loadNode(id: id) else {
            AppLog.story.error("❌ failed to load node id=\(id, privacy: .public)")
            return
        }
        currentNodeID = id
        node = n
        AppLog.story.info("✅ node loaded: \(n.nodeId, privacy: .public) type=\(n.type.rawValue, privacy: .public) next=\(n.primaryNextNodeId ?? "nil", privacy: .public)")

        if let bg = n.dialogue?.backgroundImage,
           !bg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastBackgroundName = bg
        }

        engine.stop()

        switch n.type {
        case .dialogue:
            configureDialogueNode(n)
        case .decision:
            configureDecisionNode(n)
        case .conditional:
            resolveConditionalNode(n)
        case .questGate:
            handleQuestGateNode(n)
        }
    }

    private func nextPressed() {
        AppLog.story.info("👉 button tapped (isCompleted=\(self.engine.isCompleted, privacy: .public))")
        if engine.isCompleted == false {
            AppLog.story.debug("⏭️ skip remaining")
            engine.skipOrNext()
            return
        }

        if let node {
            QuestManager.shared.recordDialogueEvent(nodeId: node.nodeId)
        }

        if let next = node?.dialogue?.nextNodeId, !next.isEmpty {
            AppLog.story.info("➡️ go next node=\(next, privacy: .public)")
            advance(to: next)
        } else {
            AppLog.story.info("🏁 no next node. end of story.")
            finishStory()
        }
    }

    private func configureDialogueNode(_ node: VNNode) {
        guard let dialogue = node.dialogue else {
            engine.configure(text: "", blipKey: nil)
            engine.start()
            return
        }

        if let bg = dialogue.backgroundImage,
           !bg.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lastBackgroundName = bg
        }

        if let sfx = dialogue.soundEffect, !sfx.isEmpty {
            AppLog.story.debug("🔔 one-shot sfx=\(sfx, privacy: .public)")
            SFXManager.shared.play(sfx)
        }

        let blip = CharacterBlip.blipKey(for: dialogue.speakerId)
        AppLog.story.info("🔊 blipKey=\(blip ?? "nil", privacy: .public)")
        engine.configure(text: dialogue.text, blipKey: (blip?.isEmpty == true) ? nil : blip)
        engine.start()
    }

    private func configureDecisionNode(_ node: VNNode) {
        let promptText = node.decision?.prompt ?? node.dialogue?.text ?? ""
        if promptText.isEmpty {
            engine.configure(text: "", blipKey: nil)
        } else {
            engine.configure(text: promptText, blipKey: nil)
            engine.start()
        }
    }

    private func handleDecisionChoice(_ choice: VNChoice) {
        AppLog.story.info("🧭 decision choice=\(choice.id, privacy: .public) next=\(choice.nextNodeId ?? "nil", privacy: .public)")
        if let node {
            QuestManager.shared.recordDialogueEvent(nodeId: node.nodeId)
        }
        guard let next = choice.nextNodeId, !next.isEmpty else {
            finishStory()
            return
        }
        advance(to: next)
    }

    private func resolveConditionalNode(_ node: VNNode) {
        guard let conditional = node.conditional else { return }
        let progress = ProgressManager.shared.progress
        let satisfied = conditional.condition.isSatisfied(by: progress)
        AppLog.story.info("🔀 conditional \(node.nodeId, privacy: .public) result=\(satisfied)")
        let next = satisfied ? conditional.successNodeId : conditional.failureNodeId
        advance(to: next)
    }

    private func handleQuestGateNode(_ node: VNNode) {
        guard let gate = node.questGate else { return }
        AppLog.story.info("🛰️ quest gate node=\(node.nodeId, privacy: .public) quest=\(gate.questId, privacy: .public)")
        if gate.autoStart, let quest = MainQuestRepository.quest(withId: gate.questId) {
            QuestManager.shared.enqueueMainQuest(quest)
        }
        if let next = gate.nextNodeId, !next.isEmpty {
            advance(to: next)
        } else {
            finishStory()
        }
    }

    private func advance(to nextId: String) {
        currentNodeID = nextId
        DispatchQueue.main.async {
            self.loadNodeAndStart(id: nextId)
        }
    }

    private func resolvedBackgroundName() -> String? {
        if let current = currentDialogue?.backgroundImage,
           !current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           UIImage(named: current) != nil {
            return current
        }
        return lastBackgroundName
    }

    private func resolvedMovieName(from resource: String) -> String? {
        let lower = resource.lowercased()
        if lower.hasSuffix(".mov") || lower.hasSuffix(".mp4") {
            return resource
        }
        return nil
    }

    private func finishStory() {
        onStoryComplete?()
        if returnToMapOnCompletion {
            GameManager.shared.activeMainTab = 0
        }
        dismiss()
    }

    private var debugHUD: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("node: \(node?.nodeId ?? "nil")")
            Text("type: \(node?.type.rawValue ?? "nil")")
            Text("next: \(node?.primaryNextNodeId ?? "nil")")
            Text("speaker: \(currentSpeakerName ?? "nil")")
            Text("done: \(engine.isCompleted.description)")
        }
        .font(.system(size: 10, weight: .regular, design: .monospaced))
        .foregroundColor(.white.opacity(0.8))
        .padding(8)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .padding(.top, 8)
        .padding(.leading, 8)
    }
}

// MARK: - Character Video Player

struct CharacterOneShotVideoView: View {
    let resourceName: String
    @State private var player: AVPlayer?
    @State private var completionObserver: Any?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                prepareAndPlay()
            }
            .onDisappear {
                teardown()
            }
            .disabled(true)
            .aspectRatio(contentMode: .fit)
    }

    private func prepareAndPlay() {
        guard player == nil else {
            player?.seek(to: .zero)
            player?.play()
            return
        }

        guard let url = locateVideoURL() else {
            return
        }

        let player = AVPlayer(url: url)
        self.player = player
        player.play()

        completionObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.player?.seek(to: .zero)
            self?.player?.pause()
        }
    }

    private func teardown() {
        player?.pause()
        if let observer = completionObserver {
            NotificationCenter.default.removeObserver(observer)
            completionObserver = nil
        }
    }

    private func locateVideoURL() -> URL? {
        let sanitized = resourceName.replacingOccurrences(of: "\\", with: "/")
        let components = sanitized.split(separator: "/")
        let filePart = components.last.map(String.init) ?? sanitized

        let nameComponents = filePart.split(separator: ".")
        let baseName: String
        let ext: String

        if nameComponents.count > 1 {
            ext = String(nameComponents.last!)
            baseName = nameComponents.dropLast().joined(separator: ".")
        } else {
            baseName = filePart
            ext = "mov"
        }

        if components.count > 1 {
            let directory = components.dropLast().joined(separator: "/")
            return Bundle.main.url(forResource: baseName, withExtension: ext, subdirectory: directory)
        }

        return Bundle.main.url(forResource: baseName, withExtension: ext)
    }
}

// MARK: - Exit Button

private struct ExitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundColor(.black)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cyberpunkYellow)
                        .shadow(color: .cyberpunkYellow.opacity(0.35), radius: 8, x: 0, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyberpunkBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}
