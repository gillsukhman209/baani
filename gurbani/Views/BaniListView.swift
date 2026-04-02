import SwiftUI
import SwiftData

struct BaniListView: View {
    var initialBaniID: Int?
    @Environment(\.modelContext) private var modelContext
    @Environment(BaniService.self) private var baniService
    @Query(sort: \Bani.displayOrder) private var allBanis: [Bani]
    @State private var navigationPath = NavigationPath()
    @State private var hasNavigatedInitial = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                if allBanis.isEmpty {
                    LoadingView()
                        .padding(.top, 100)
                } else {
                    VStack(spacing: 32) {
                        // Hero header
                        VStack(spacing: 8) {
                            Text("ੴ")
                                .font(.system(size: 36))
                                .foregroundStyle(BaniTheme.accentColor)
                            Text("What will you read today?")
                                .font(.system(size: 15))
                                .foregroundStyle(BaniTheme.textSecondary)
                        }
                        .padding(.top, 8)

                        // Bani sections
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            let banis = allBanis.filter { $0.time == time }
                            if !banis.isEmpty {
                                BaniTimeSection(time: time, banis: banis)
                            }
                        }
                    }
                    .padding(.horizontal, BaniTheme.screenPadding)
                    .padding(.bottom, 24)
                }
            }
            .navigationTitle("Simple Gurbani")
            .navigationDestination(for: Int.self) { baniID in
                BaniReadView(baniID: baniID)
            }
            .background(BaniTheme.background.ignoresSafeArea())
            .toolbarBackground(BaniTheme.background, for: .navigationBar)
            .onAppear {
                baniService.seedBaniList(modelContext: modelContext)
                if let baniID = initialBaniID, !hasNavigatedInitial {
                    hasNavigatedInitial = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        navigationPath.append(baniID)
                    }
                }
            }
        }
    }
}

// MARK: - Time Section

struct BaniTimeSection: View {
    let time: TimeOfDay
    let banis: [Bani]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: time.icon)
                    .font(.system(size: 13))
                    .foregroundStyle(BaniTheme.accentColor)
                Text(time.rawValue)
                    .font(.system(size: BaniTheme.sectionHeaderSize, weight: .bold))
                    .foregroundStyle(BaniTheme.accentColor)
                    .textCase(.uppercase)
                    .tracking(2)
            }

            ForEach(banis, id: \.baniID) { bani in
                NavigationLink(value: bani.baniID) {
                    BaniRow(bani: bani)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Bani Row

struct BaniRow: View {
    let bani: Bani

    var body: some View {
        HStack(spacing: 16) {
            // Gold circle with first Gurmukhi char
            ZStack {
                Circle()
                    .fill(BaniTheme.accentColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Text(String(bani.unicode.prefix(1)))
                    .font(.system(size: 22))
                    .foregroundStyle(BaniTheme.accentColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(bani.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(BaniTheme.gurmukhiColor)
                Text(bani.unicode)
                    .font(.system(size: 14))
                    .foregroundStyle(BaniTheme.textSecondary)
                Text("~\(bani.durationMinutes) min")
                    .font(.system(size: 12))
                    .foregroundStyle(BaniTheme.textSecondary.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(BaniTheme.textSecondary.opacity(0.4))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(BaniTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: Color(hex: 0xC9B99A).opacity(0.12), radius: 6, y: 3)
    }
}
