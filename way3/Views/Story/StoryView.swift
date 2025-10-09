import SwiftUI
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

// MARK: - StoryView

struct StoryView: View {
    @State private var currentNodeID: String
    @State private var node: VNNode?
    @StateObject private var engine = TypewriterEngine()   // ✅ 안정화
    @Environment(\.dismiss) private var dismiss

    let onStoryComplete: (() -> Void)?

    init(startNodeID: String = "prologue_01", onComplete: (() -> Void)? = nil) {
        _currentNodeID = State(initialValue: startNodeID)
        self.onStoryComplete = onComplete
    }

    var body: some View {
        ZStack {
            // 1) 배경
            if let bg = node?.background_image, let ui = UIImage(named: bg) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(colors: [.black, .black.opacity(0.8)],
                               startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            }

            // 2) 캐릭터 스프라이트
            if let sprite = node?.character_sprite, let ui = UIImage(named: sprite) {
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

            // 3) 대사 + 하단 진행 바
            VStack(spacing: 0) {
                Spacer()
                HeroDialogueOverlay(speaker: node?.character_id, engine: engine)
                BottomProceedBar(isCompleted: engine.isCompleted) { nextPressed() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            AppLog.story.info("📺 StoryView appear startNode=\(self.currentNodeID, privacy: .public)")
            loadNodeAndStart(id: currentNodeID)
        }

        // (선택) 상단 디버그 HUD
        .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 4) {
                Text("node: \(node?.node_id ?? "nil")")
                Text("next: \(node?.next_node_id ?? "nil")")
                Text("speaker: \(node?.character_id ?? "nil")")
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

    private func loadNodeAndStart(id: String) {
        AppLog.story.info("🔄 loadNode id=\(id, privacy: .public)")
        guard let n = VNLoader.loadNode(id: id) else {
            AppLog.story.error("❌ failed to load node id=\(id, privacy: .public)")
            return
        }
        self.node = n
        AppLog.story.info("✅ node loaded: \(n.node_id, privacy: .public) next=\(n.next_node_id ?? "nil", privacy: .public) speaker=\(n.character_id ?? "nil", privacy: .public)")

        // 정책상 효과음 미사용이면 주석 유지/삭제
        /*
        if let sfx = n.sound_effect {
            AppLog.story.debug("🔔 one-shot sfx=\(sfx, privacy: .public)")
            SFXManager.shared.play(sfx)
        }
        */

        let blip = CharacterBlip.blipKey(for: n.character_id)
        AppLog.story.info("🔊 blipKey=\(blip ?? "nil", privacy: .public)")
        engine.configure(text: n.dialogue_text, blipKey: (blip?.isEmpty == true) ? nil : blip)
        engine.start()
    }

    private func nextPressed() {
        AppLog.story.info("👉 button tapped (isCompleted=\(self.engine.isCompleted, privacy: .public))")
        if engine.isCompleted == false {
            AppLog.story.debug("⏭️ skip remaining")
            engine.skipOrNext()
            return
        }

        if let currentNode = node?.node_id {
            QuestManager.shared.recordDialogueEvent(nodeId: currentNode)
        }

        if let next = node?.next_node_id, !next.isEmpty {
            AppLog.story.info("➡️ go next node=\(next, privacy: .public)")
            currentNodeID = next
            loadNodeAndStart(id: next)
        } else {
            AppLog.story.info("🏁 no next node. end of story.")
            onStoryComplete?()
            dismiss()
        }
    }
}
