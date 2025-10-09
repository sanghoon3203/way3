//
//  CyberpunkComponents.swift
//  way3 - Way Trading Game
//
//  재사용 가능한 사이버펑크 스타일 UI 컴포넌트들
//  기존 JRPG 기능을 유지하면서 사이버펑크 테마 적용
//

import SwiftUI

// MARK: - Cyberpunk Dialogue Interface (JRPG 기능 유지)
struct CyberpunkDialogueBox: View {
    let merchantName: String
    let displayedText: String
    let isTypingComplete: Bool
    let showNextArrow: Bool
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Technical Header with Merchant Name
            HStack {
                Text("COMM_LINK")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                Text(merchantName.uppercased())
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkYellow)
                    .fontWeight(.semibold)

                // Connection Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.cyberpunkGreen)
                        .frame(width: 6, height: 6)
                        .animation(CyberpunkAnimations.slowGlow, value: UUID())

                    Text("CONNECTED")
                        .font(.cyberpunkTechnical())
                        .foregroundColor(.cyberpunkGreen)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.cyberpunkDarkBg)
            .overlay(
                Rectangle()
                    .fill(Color.cyberpunkYellow)
                    .frame(height: 1),
                alignment: .bottom
            )

            // Message Content Area
            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayedText)
                        .font(.cyberpunkBody())
                        .foregroundColor(.cyberpunkTextPrimary)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(minHeight: 80)

            // Action Area
            HStack {
                // Data transfer animation (while typing)
                if !isTypingComplete {
                    HStack(spacing: 2) {
                        ForEach(0..<3) { index in
                            Rectangle()
                                .fill(Color.cyberpunkCyan)
                                .frame(width: 3, height: 3)
                                .opacity(0.6)
                                .scaleEffect(dataTransferAnimation(index: index))
                                .animation(
                                    Animation.linear(duration: 0.8)
                                        .repeatForever()
                                        .delay(Double(index) * 0.15),
                                    value: UUID()
                                )
                        }

                        Text("DATA_TRANSFER")
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkCyan)
                    }
                }

                Spacer()

                // Continue prompt
                if showNextArrow {
                    Button(action: onContinue) {
                        HStack(spacing: 4) {
                            Text("CONTINUE")
                                .font(.cyberpunkTechnical())
                                .foregroundColor(.cyberpunkYellow)

                            Text(">")
                                .font(.cyberpunkCaption())
                                .foregroundColor(.cyberpunkYellow)
                                .offset(x: sin(Date().timeIntervalSince1970 * 3) * 2)
                                .animation(
                                    CyberpunkAnimations.slowGlow,
                                    value: UUID()
                                )
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
        .background(Color.cyberpunkCardBg)
        .cyberpunkCard()
    }

    private func dataTransferAnimation(index: Int) -> CGFloat {
        let time = Date().timeIntervalSince1970
        return 1.0 + sin(time * 2 + Double(index) * 0.5) * 0.4
    }
}

// MARK: - Cyberpunk Choice Menu (JRPG 스타일 선택지 유지)
struct CyberpunkChoiceMenu: View {
    let choices: [(text: String, action: () -> Void)]

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Menu Header
            HStack {
                Text("ACTION_MENU")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                Text("[SELECT]")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkYellow)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.cyberpunkDarkBg)
            .overlay(
                Rectangle()
                    .fill(Color.cyberpunkCyan)
                    .frame(height: 1),
                alignment: .bottom
            )

            // Choice Buttons
            VStack(alignment: .leading, spacing: 1) {
                ForEach(Array(choices.enumerated()), id: \.offset) { index, choice in
                    CyberpunkChoiceButton(
                        text: choice.text,
                        action: choice.action,
                        isHighlighted: false
                    )
                }
            }
            .padding(4)
        }
        .background(Color.cyberpunkPanelBg)
        .cyberpunkCard()
        .frame(width: 200)
    }
}

// MARK: - Cyberpunk Choice Button
struct CyberpunkChoiceButton: View {
    let text: String
    let action: () -> Void
    let isHighlighted: Bool
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack {
                // Selection Indicator
                Text(">")
                    .font(.cyberpunkCaption())
                    .foregroundColor(.cyberpunkYellow)
                    .opacity(isHighlighted ? 1.0 : 0.0)
                    .animation(.easeInOut(duration: 0.2), value: isHighlighted)

                Text(text)
                    .font(.cyberpunkBody())
                    .foregroundColor(isHighlighted ? .cyberpunkYellow : .cyberpunkTextPrimary)
                    .fontWeight(isHighlighted ? .semibold : .medium)

                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .fill(isHighlighted ? Color.cyberpunkYellow.opacity(0.1) : Color.clear)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isHighlighted ? Color.cyberpunkYellow.opacity(0.6) : Color.clear,
                                lineWidth: 0.5
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: CGFloat.infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }, perform: {})
    }
}

// MARK: - Generic Item Card Template
// Note: Specific item cards are implemented in their respective view files

// MARK: - Cyberpunk Inventory Grid
struct CyberpunkInventoryGrid<Item: Identifiable, ItemView: View>: View {
    let items: [Item]
    let columns: Int
    let emptySlots: Int
    let itemView: (Item) -> ItemView

    init(
        items: [Item],
        columns: Int = 3,
        emptySlots: Int = 6,
        @ViewBuilder itemView: @escaping (Item) -> ItemView
    ) {
        self.items = items
        self.columns = columns
        self.emptySlots = emptySlots
        self.itemView = itemView
    }

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(minimum: 100, maximum: 150)), count: columns),
            spacing: CyberpunkLayout.gridSpacing
        ) {
            // Filled slots
            ForEach(items) { item in
                itemView(item)
            }

            // Empty slots
            ForEach(0..<emptySlots, id: \.self) { _ in
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 120)
                    .cyberpunkGridSlot(isEmpty: true)
            }
        }
    }
}

// MARK: - Cyberpunk Section Header
struct CyberpunkSectionHeader: View {
    let title: String
    let subtitle: String?
    let rightContent: String?

    init(title: String, subtitle: String? = nil, rightContent: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.rightContent = rightContent
    }

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title.uppercased())
                        .font(.cyberpunkHeading())
                        .foregroundColor(.cyberpunkYellow)
                        .fontWeight(.bold)

                    if let subtitle = subtitle {
                        Text(subtitle.uppercased())
                            .font(.cyberpunkTechnical())
                            .foregroundColor(.cyberpunkTextSecondary)
                    }
                }

                Spacer()

                if let rightContent = rightContent {
                    Text(rightContent.uppercased())
                        .font(.cyberpunkCaption())
                        .foregroundColor(.cyberpunkGreen)
                        .fontWeight(.semibold)
                }
            }

            // Decorative line
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.cyberpunkYellow, .cyberpunkCyan, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
        }
        .padding(.horizontal, CyberpunkLayout.screenPadding)
    }
}

// MARK: - Cyberpunk Status Panel
struct CyberpunkStatusPanel: View {
    let title: String
    let statusItems: [(label: String, value: String, color: Color)]

    var body: some View {
        VStack(spacing: 0) {
            // Panel Header
            HStack {
                Text(title.uppercased())
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkTextSecondary)

                Spacer()

                Text("SYS_ACTIVE")
                    .font(.cyberpunkTechnical())
                    .foregroundColor(.cyberpunkGreen)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.cyberpunkDarkBg)

            // Status Items
            VStack(spacing: 1) {
                ForEach(Array(statusItems.enumerated()), id: \.offset) { _, item in
                    CyberpunkDataDisplay(
                        label: item.label,
                        value: item.value,
                        valueColor: item.color
                    )
                }
            }
            .padding(4)
        }
        .cyberpunkPanel()
    }
}

// MARK: - Cyberpunk Button
struct CyberpunkButton: View {
    let title: String
    let style: CyberpunkButtonStyle
    let action: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title.uppercased())
                    .font(.cyberpunkButton())
                    .foregroundColor(style.textColor)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .cyberpunkButton(style: style, isPressed: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: CGFloat.infinity, pressing: { isPressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = isPressing
            }
        }, perform: {})
    }
}

// Note: ItemGrade cyberpunk color extension is now in GameEnums.swift