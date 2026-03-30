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
                    LazyVStack(spacing: 28) {
                        ForEach(TimeOfDay.allCases, id: \.self) { time in
                            let banis = allBanis.filter { $0.time == time }
                            if !banis.isEmpty {
                                BaniTimeSection(time: time, banis: banis)
                            }
                        }
                    }
                    .padding(.horizontal, BaniTheme.screenPadding)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Bani")
            .navigationDestination(for: Int.self) { baniID in
                BaniReadView(baniID: baniID)
            }
            .background(BaniTheme.background)
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

// MARK: - Time of Day Section

struct BaniTimeSection: View {
    let time: TimeOfDay
    let banis: [Bani]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(time.rawValue, systemImage: time.icon)
                .font(.system(size: BaniTheme.sectionHeaderSize, weight: .semibold))
                .foregroundStyle(BaniTheme.saffron)
                .textCase(.uppercase)
                .tracking(1.5)

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
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(bani.unicode)
                    .font(.system(size: 20))
                    .foregroundStyle(BaniTheme.gurmukhiColor)
                Text(bani.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                HStack(spacing: 8) {
                    Text("~\(bani.durationMinutes) min")
                        .font(.caption2)
                        .foregroundStyle(BaniTheme.secondaryText)
                    if bani.isFetched {
                        Label("Downloaded", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(BaniTheme.saffron)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.quaternary)
        }
        .padding()
        .background(BaniTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: BaniTheme.cornerRadius))
        .shadow(color: .black.opacity(0.04), radius: 6, y: 3)
    }
}
