import SwiftUI
import SwiftData

struct AskView: View {
    @Binding var pendingQuestion: String?
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AskViewModel()
    @State private var chips: [String] = []
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    chatList
                }
                inputBar
            }
            .background(BaniTheme.background.ignoresSafeArea())
            .navigationTitle("Ask")
            .toolbarBackground(BaniTheme.background, for: .navigationBar)
            .toolbar {
                if !viewModel.messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                viewModel.showDeleteConfirmation = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(BaniTheme.rose)
                            }
                            Button {
                                viewModel.showClearConfirmation = true
                            } label: {
                                Image(systemName: "square.and.pencil")
                                    .foregroundStyle(BaniTheme.accentColor)
                            }
                        }
                    }
                }
            }
            .confirmationDialog("Start a new conversation?", isPresented: $viewModel.showClearConfirmation) {
                Button("Clear conversation", role: .destructive) {
                    viewModel.clearConversation(modelContext: modelContext)
                    chips = viewModel.suggestedQuestions
                }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete all chat history?", isPresented: $viewModel.showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) {
                    viewModel.clearConversation(modelContext: modelContext)
                    chips = viewModel.suggestedQuestions
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete your entire conversation history.")
            }
            .onAppear {
                viewModel.loadMessages(modelContext: modelContext)
                if chips.isEmpty { chips = viewModel.suggestedQuestions }
                if let question = pendingQuestion, !question.isEmpty {
                    pendingQuestion = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.sendMessage(question, modelContext: modelContext)
                    }
                }
            }
            .onChange(of: pendingQuestion) {
                if let question = pendingQuestion, !question.isEmpty {
                    pendingQuestion = nil
                    viewModel.loadMessages(modelContext: modelContext)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        viewModel.sendMessage(question, modelContext: modelContext)
                    }
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ScrollView {
            VStack(spacing: 28) {
                Spacer().frame(height: 32)

                ZStack {
                    Circle()
                        .fill(BaniTheme.accentColor.opacity(0.08))
                        .frame(width: 110, height: 110)
                    Text("ੴ")
                        .font(.system(size: 52))
                        .foregroundStyle(BaniTheme.accentColor)
                }

                VStack(spacing: 8) {
                    Text("Your Gurbani guide")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                    Text("Ask anything about Sikhi, Gurbani, or history.")
                        .font(.system(size: 15))
                        .foregroundStyle(BaniTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(chips, id: \.self) { question in
                        Button {
                            viewModel.sendMessage(question, modelContext: modelContext)
                        } label: {
                            Text(question)
                                .font(.system(size: 13))
                                .foregroundStyle(BaniTheme.gurmukhiColor)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(BaniTheme.accentColor.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, BaniTheme.screenPadding)

                Spacer()
            }
            .onTapGesture { isInputFocused = false }
        }
    }

    // MARK: - Chat List

    private var chatList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.messages, id: \.id) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isTyping, let last = viewModel.messages.last, last.isAssistant, last.content.isEmpty {
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, BaniTheme.screenPadding)
                .padding(.vertical, 16)
            }
            .onTapGesture { isInputFocused = false }
            .onChange(of: viewModel.messages.count) { scrollToBottom(proxy) }
            .onChange(of: viewModel.messages.last?.content) { scrollToBottom(proxy) }
            .onAppear { scrollToBottom(proxy) }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let last = viewModel.messages.last {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Ask about Gurbani...", text: $viewModel.inputText, axis: .vertical)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(BaniTheme.inputBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .onSubmit {
                    viewModel.sendMessage(modelContext: modelContext)
                }

            Button {
                viewModel.sendMessage(modelContext: modelContext)
                isInputFocused = false
            } label: {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty
                            ? BaniTheme.trackColor
                            : BaniTheme.accentColor
                    )
                    .clipShape(Circle())
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isTyping)
        }
        .padding(.horizontal, BaniTheme.screenPadding)
        .padding(.vertical, 10)
        .background(
            BaniTheme.cardBackground
                .shadow(color: Color(hex: 0xC9B99A).opacity(0.1), radius: 4, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

// MARK: - Chat Bubble

struct ChatBubble: View {
    let message: ConversationMessage

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }()

    var body: some View {
        if message.isError {
            errorBubble
        } else if message.isUser {
            userBubble
        } else {
            assistantBubble
        }
    }

    private var userBubble: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(BaniTheme.goldGradient)
                .clipShape(BubbleShape(isUser: true))

            Text(Self.timeFormatter.string(from: message.timestamp))
                .font(.system(size: 10))
                .foregroundStyle(BaniTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var assistantBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text("ੴ")
                    .font(.system(size: 16))
                    .foregroundStyle(BaniTheme.accentColor)
                    .frame(width: 24)
                    .padding(.top, 6)

                GurbaniAwareText(content: message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(BaniTheme.cardBackground)
                    .clipShape(BubbleShape(isUser: false))
                    .shadow(color: Color(hex: 0xC9B99A).opacity(0.1), radius: 4, y: 2)
            }

            Text(Self.timeFormatter.string(from: message.timestamp))
                .font(.system(size: 10))
                .foregroundStyle(BaniTheme.textSecondary)
                .padding(.leading, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var errorBubble: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(BaniTheme.rose.opacity(0.8))
            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(BaniTheme.rose.opacity(0.9))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(BaniTheme.rose.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 18
        let flat: CGFloat = 4

        if isUser {
            return Path { p in
                p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
                p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + r), radius: r)
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - flat))
                p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - flat, y: rect.maxY), radius: flat)
                p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
                p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - r), radius: r)
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
                p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + r, y: rect.minY), radius: r)
            }
        } else {
            return Path { p in
                p.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
                p.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
                p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + r), radius: r)
                p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
                p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - r, y: rect.maxY), radius: r)
                p.addLine(to: CGPoint(x: rect.minX + flat, y: rect.maxY))
                p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - flat), radius: flat)
                p.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
                p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + r, y: rect.minY), radius: r)
            }
        }
    }
}

// MARK: - Gurmukhi-Aware Text

struct GurbaniAwareText: View {
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { _, line in
                if containsGurmukhi(line) && !containsLatin(line) {
                    Text(line)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(BaniTheme.gurmukhiColor)
                } else if line.hasPrefix("- ") || line.hasPrefix("• ") {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .foregroundStyle(BaniTheme.textSecondary)
                        Text(parseBold(String(line.dropFirst(2))))
                            .font(.subheadline)
                    }
                } else if !line.isEmpty {
                    Text(parseBold(line))
                        .font(.subheadline)
                }
            }
        }
    }

    private func containsGurmukhi(_ text: String) -> Bool {
        text.unicodeScalars.contains { $0.value >= 0x0A00 && $0.value <= 0x0A7F }
    }

    private func containsLatin(_ text: String) -> Bool {
        text.unicodeScalars.contains { ($0.value >= 0x0041 && $0.value <= 0x005A) || ($0.value >= 0x0061 && $0.value <= 0x007A) }
    }

    private func parseBold(_ text: String) -> AttributedString {
        var result = AttributedString()
        let parts = text.components(separatedBy: "**")
        for (i, part) in parts.enumerated() {
            var chunk = AttributedString(part)
            if i % 2 == 1 { chunk.font = .subheadline.bold() }
            result.append(chunk)
        }
        return result
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    @State private var dotIndex = 0

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("ੴ")
                .font(.system(size: 16))
                .foregroundStyle(BaniTheme.accentColor)
                .frame(width: 24)
                .padding(.top, 6)

            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(BaniTheme.accentColor.opacity(0.4))
                        .frame(width: 7, height: 7)
                        .offset(y: dotIndex == i ? -4 : 0)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(BaniTheme.cardBackground)
            .clipShape(BubbleShape(isUser: false))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.4).repeatForever(autoreverses: true)) {
                dotIndex = 2
            }
        }
    }
}
