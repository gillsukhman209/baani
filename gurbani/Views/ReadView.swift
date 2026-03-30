import SwiftUI
import SwiftData

// MARK: - Bani Read View

struct BaniReadView: View {
    let baniID: Int
    @Environment(\.modelContext) private var modelContext
    @Environment(BaniService.self) private var baniService
    @Environment(\.dismiss) private var dismiss
    @AppStorage("showTranslation") private var showTranslation = true
    @AppStorage("gurmukhiFontSize") private var gurmukhiFontSize = 1
    @AppStorage("hasUsedWordTap") private var hasUsedWordTap = false
    @State private var viewModel = ReadViewModel()
    @State private var addedToast = false
    @State private var showTooltip = false

    @Query private var baniMeta: [Bani]

    init(baniID: Int) {
        self.baniID = baniID
        _baniMeta = Query(filter: #Predicate<Bani> { $0.baniID == baniID })
    }

    private var bani: Bani? { baniMeta.first }

    private var gurmukhiSize: CGFloat {
        switch gurmukhiFontSize {
        case 0: BaniTheme.gurmukhiSizeSmall
        case 2: BaniTheme.gurmukhiSizeLarge
        default: BaniTheme.gurmukhiSizeMedium
        }
    }

    var body: some View {
        Group {
            if baniService.isFetchingBani && viewModel.items.isEmpty {
                ProgressView()
                    .progressViewStyle(.circular)
                    .controlSize(.large)
                    .tint(BaniTheme.saffron)
            } else if viewModel.items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "text.book.closed")
                        .font(.system(size: 40))
                        .foregroundStyle(.quaternary)
                    Text("Could not load this bani.")
                        .foregroundStyle(BaniTheme.secondaryText)
                    Button("Try Again") {
                        Task {
                            await baniService.fetchBani(id: baniID, modelContext: modelContext)
                            viewModel.loadPauris(baniID: baniID, modelContext: modelContext)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BaniTheme.saffron)
                }
            } else {
                readingContent
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(bani?.name ?? "Bani")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Circle()
                        .fill(BaniTheme.cardBackground)
                        .frame(width: 36, height: 36)
                        .overlay {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(BaniTheme.navy)
                        }
                        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                }
            }
        }
        .task {
            await baniService.fetchBani(id: baniID, modelContext: modelContext)
            viewModel.loadPauris(baniID: baniID, modelContext: modelContext)
            if !hasUsedWordTap && !viewModel.items.isEmpty {
                try? await Task.sleep(for: .seconds(1))
                showTooltip = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .simpleTranslationsReady)) { notification in
            if let notifBaniID = notification.object as? Int, notifBaniID == baniID {
                viewModel.loadPauris(baniID: baniID, modelContext: modelContext)
            }
        }
        .sheet(isPresented: $viewModel.showWordSheet) {
            viewModel.checkWordInDeck(modelContext: modelContext)
        } content: {
            WordDetailSheet(
                word: viewModel.selectedWord,
                rawWord: viewModel.selectedRawWord ?? "",
                sectionContext: viewModel.selectedSectionContext ?? "",
                lineContext: viewModel.selectedLineContext ?? "",
                isInDeck: viewModel.isWordInDeck,
                onAddToReview: {
                    let added = viewModel.addToReviewDeck(modelContext: modelContext)
                    if added { addedToast = true }
                }
            )
            .presentationDetents([.medium])
            .presentationCornerRadius(BaniTheme.sheetCornerRadius)
        }
        .overlay(alignment: .bottom) {
            if addedToast {
                ToastView(message: "Added to review deck")
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { addedToast = false }
                        }
                    }
            }
        }
        .animation(.easeInOut, value: addedToast)
        .background(BaniTheme.background)
    }

    // MARK: - Reading Content (flat LazyVStack)

    private var readingContent: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Bani header (pinned outside lazy area for instant render)
                baniHeader
                    .padding(.horizontal, BaniTheme.screenPadding)
                    .padding(.bottom, 24)

                // Flat list of items
                ForEach(viewModel.items) { item in
                    switch item {
                    case .sectionHeader(_, let title):
                        VStack(alignment: .leading, spacing: 6) {
                            Text(title)
                                .font(.system(size: BaniTheme.sectionHeaderSize, weight: .semibold))
                                .foregroundStyle(BaniTheme.saffron)
                                .textCase(.uppercase)
                                .tracking(1.5)
                            Rectangle()
                                .fill(BaniTheme.saffron)
                                .frame(height: 1)
                        }
                        .padding(.horizontal, BaniTheme.screenPadding)
                        .padding(.bottom, 16)

                    case .line(let line):
                        BaniLineView(
                            line: line,
                            gurmukhiSize: gurmukhiSize,
                            showTranslation: showTranslation,
                            translationMode: viewModel.translationMode,
                            showTooltip: showTooltip && viewModel.items.first(where: {
                                if case .line = $0 { return true }
                                return false
                            })?.id == item.id,
                            onWordTap: { word in
                                viewModel.tapWord(word, line: line)
                                showTooltip = false
                            },
                            onMarkRead: { viewModel.markLineRead(line) },
                            onAskAbout: { question in
                                NotificationCenter.default.post(
                                    name: .askAboutLine,
                                    object: question
                                )
                            }
                        )
                        .padding(.horizontal, BaniTheme.screenPadding)

                    case .divider(let id):
                        if id.hasPrefix("gap-") {
                            Spacer().frame(height: 32)
                        } else {
                            Rectangle()
                                .fill(BaniTheme.divider)
                                .frame(height: 0.5)
                                .padding(.vertical, 12)
                                .padding(.horizontal, BaniTheme.screenPadding)
                        }
                    }
                }

                Spacer().frame(height: 60)
            }
        }
    }

    // MARK: - Bani Header

    private var baniHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(bani?.unicode ?? "")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(BaniTheme.gurmukhiColor)

            if let bani {
                Text("\(bani.author) · ~\(bani.durationMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(BaniTheme.secondaryText)
            }

            HStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(BaniTheme.trackGrey)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(BaniTheme.saffron)
                            .frame(width: max(0, geo.size.width * viewModel.readProgress), height: 3)
                    }
                }
                .frame(height: 3)

                Text(viewModel.readPercentText)
                    .font(.system(size: 12))
                    .foregroundStyle(BaniTheme.secondaryText)
                    .fixedSize()
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Single Line View (optimized)

struct BaniLineView: View {
    let line: BaniLine
    let gurmukhiSize: CGFloat
    let showTranslation: Bool
    let translationMode: TranslationMode
    let showTooltip: Bool
    let onWordTap: (String) -> Void
    let onMarkRead: () -> Void
    var onAskAbout: ((String) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Single tappable Text — no FlowLayout, no per-word views
            ZStack(alignment: .topLeading) {
                Text(line.unicode)
                    .font(.system(size: gurmukhiSize, weight: .bold))
                    .foregroundStyle(BaniTheme.gurmukhiColor)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(BaniTheme.saffron.opacity(0.2))
                            .frame(height: 0.5)
                            .offset(y: -2)
                    }

                if showTooltip {
                    Text("Tap any word to learn its meaning")
                        .font(.caption2)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(BaniTheme.navy.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .offset(y: -28)
                }
            }
            .onTapGesture { location in
                let tappedWord = hitTestWord(in: line.unicode, at: location, fontSize: gurmukhiSize)
                if let word = tappedWord {
                    onWordTap(word)
                }
            }

            // Translations
            if showTranslation {
                switch translationMode {
                case .simple:
                    let text = line.simpleTranslation ?? line.translation
                    if !text.isEmpty {
                        Text(text)
                            .font(.system(size: BaniTheme.translationSize))
                            .foregroundStyle(BaniTheme.secondaryText)
                    }
                case .punjabi:
                    let text = line.punjabiTranslation ?? line.translation
                    if !text.isEmpty {
                        Text(text)
                            .font(.system(size: BaniTheme.translationSize + 2))
                            .foregroundStyle(BaniTheme.secondaryText)
                    }
                case .scholar:
                    if !line.translation.isEmpty {
                        Text(line.translation)
                            .font(.system(size: BaniTheme.translationSize))
                            .foregroundStyle(BaniTheme.secondaryText)
                    }
                case .both:
                    VStack(alignment: .leading, spacing: 6) {
                        let simple = line.simpleTranslation
                        if let simple, !simple.isEmpty {
                            Text(simple)
                                .font(.system(size: BaniTheme.translationSize))
                                .foregroundStyle(BaniTheme.secondaryText)
                        } else {
                            Text("Translating...")
                                .font(.system(size: BaniTheme.translationSize))
                                .foregroundStyle(BaniTheme.secondaryText.opacity(0.4))
                                .italic()
                        }
                        if !line.translation.isEmpty {
                            Text(line.translation)
                                .font(.system(size: BaniTheme.translationSize))
                                .foregroundStyle(BaniTheme.secondaryText.opacity(0.6))
                        }
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .onAppear { onMarkRead() }
        .contextMenu {
            Button {
                let translation = line.simpleTranslation ?? line.translation
                let question = "Can you explain this line to me: \(line.unicode) — \(translation)"
                onAskAbout?(question)
            } label: {
                Label("Ask about this line", systemImage: "bubble.left.and.bubble.right")
            }
        }
    }

    // Approximate word hit-testing from tap location
    private func hitTestWord(in text: String, at location: CGPoint, fontSize: CGFloat) -> String? {
        let words = text.components(separatedBy: " ").filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }

        // Estimate character width for Gurmukhi at this font size
        let charWidth = fontSize * 0.55
        var x: CGFloat = 0
        let screenWidth = UIScreen.main.bounds.width - BaniTheme.screenPadding * 2
        var wordRects: [(String, CGRect)] = []
        var y: CGFloat = 0
        let lineHeight = fontSize * 1.3

        for word in words {
            let wordWidth = CGFloat(word.count) * charWidth
            let spaceWidth = charWidth

            if x + wordWidth > screenWidth && x > 0 {
                x = 0
                y += lineHeight
            }

            wordRects.append((word, CGRect(x: x, y: y, width: wordWidth, height: lineHeight)))
            x += wordWidth + spaceWidth
        }

        // Find which word was tapped
        for (word, rect) in wordRects {
            let expandedRect = rect.insetBy(dx: -4, dy: -4)
            if expandedRect.contains(location) {
                return word
            }
        }

        // Fallback: return closest word
        var closestWord = words.first
        var closestDist = CGFloat.infinity
        for (word, rect) in wordRects {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let dist = hypot(location.x - center.x, location.y - center.y)
            if dist < closestDist {
                closestDist = dist
                closestWord = word
            }
        }
        return closestWord
    }
}

// MARK: - Translation Row

struct TranslationRow: View {
    let label: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .textCase(.uppercase)
                .tracking(0.5)
                .foregroundStyle(color)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .fixedSize()
            Text(text)
                .font(.system(size: BaniTheme.translationSize))
                .foregroundStyle(BaniTheme.secondaryText)
        }
    }
}

// MARK: - Toast

struct ToastView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(BaniTheme.navy.opacity(0.9))
            .clipShape(Capsule())
            .padding(.bottom, 24)
    }
}
