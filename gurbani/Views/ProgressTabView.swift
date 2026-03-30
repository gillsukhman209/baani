import SwiftUI
import SwiftData

struct ProgressTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ProgressViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Streak card
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(viewModel.currentStreak)")
                                .font(.system(size: 48, weight: .bold, design: .rounded))
                                .foregroundStyle(BaniTheme.saffron)
                            Text("day streak")
                                .font(.subheadline)
                                .foregroundStyle(BaniTheme.secondaryText)
                            Text(viewModel.streakMotivation)
                                .font(.caption)
                                .foregroundStyle(BaniTheme.secondaryText)
                                .padding(.top, 2)
                        }
                        Spacer()
                        Image(systemName: "flame.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(BaniTheme.saffron.opacity(0.3))
                    }
                    .baniCard()

                    // Stats grid — all saffron icons
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ProgressStatCard(
                            title: "Words Learned",
                            value: "\(viewModel.totalWordsLearned)",
                            icon: "textformat.abc"
                        )
                        ProgressStatCard(
                            title: "Lines Read",
                            value: "\(viewModel.totalLinesRead)",
                            icon: "text.alignleft"
                        )
                        ProgressStatCard(
                            title: "Completed",
                            value: String(format: "%.0f%%", viewModel.percentageRead),
                            icon: "book"
                        )
                        ProgressStatCard(
                            title: "Total Lines",
                            value: "\(viewModel.totalLines)",
                            icon: "list.number"
                        )
                    }

                    // Activity heatmap
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACTIVITY")
                            .font(.system(size: BaniTheme.sectionHeaderSize, weight: .semibold))
                            .foregroundStyle(BaniTheme.saffron)
                            .tracking(1.5)
                        HeatmapCalendarView(sessionDates: viewModel.sessionDates)
                    }
                    .baniCard()

                    // Per-bani progress
                    VStack(alignment: .leading, spacing: 12) {
                        Text("YOUR BANIS")
                            .font(.system(size: BaniTheme.sectionHeaderSize, weight: .semibold))
                            .foregroundStyle(BaniTheme.saffron)
                            .tracking(1.5)

                        if viewModel.baniProgressList.isEmpty {
                            Text("Start reading to see your progress here")
                                .font(.subheadline)
                                .foregroundStyle(BaniTheme.secondaryText)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.baniProgressList) { progress in
                                BaniProgressRow(progress: progress)
                            }
                        }
                    }
                    .baniCard()
                }
                .padding(BaniTheme.screenPadding)
            }
            .navigationTitle("Progress")
            .background(BaniTheme.background)
            .onAppear { viewModel.load(modelContext: modelContext) }
        }
    }
}

// MARK: - Stat Card (all saffron)

struct ProgressStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BaniTheme.saffron)
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundStyle(BaniTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .baniCard()
    }
}

// MARK: - Bani Progress Row

struct BaniProgressRow: View {
    let progress: BaniProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(progress.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(String(format: "%.0f%%", progress.percentage * 100))
                    .font(.caption)
                    .foregroundStyle(BaniTheme.secondaryText)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BaniTheme.trackGrey)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(BaniTheme.saffron)
                        .frame(width: geo.size.width * progress.percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Heatmap Calendar (weeks as columns, today bottom-right)

struct HeatmapCalendarView: View {
    let sessionDates: Set<String>

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    private var weeks: [[Date?]] {
        let calendar = Calendar.current
        let today = Date.now

        // Find the weekday of today (1=Sun in default, but we want Mon-Sun columns)
        // Go back 12 full weeks + partial current week
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...
        let mondayOffset = todayWeekday == 1 ? 6 : todayWeekday - 2
        let totalDays = 12 * 7 + mondayOffset + 1

        var allDates: [Date] = []
        for i in (0..<totalDays).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                allDates.append(date)
            }
        }

        // Group into weeks (7 days each, Mon=0)
        var result: [[Date?]] = []
        var currentWeek: [Date?] = []
        for date in allDates {
            currentWeek.append(date)
            if currentWeek.count == 7 {
                result.append(currentWeek)
                currentWeek = []
            }
        }
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 { currentWeek.append(nil) }
            result.append(currentWeek)
        }

        return result
    }

    private var monthLabels: [(String, Int)] {
        var labels: [(String, Int)] = []
        var lastMonth = -1
        for (weekIdx, week) in weeks.enumerated() {
            if let firstDate = week.first, let date = firstDate {
                let month = Calendar.current.component(.month, from: date)
                if month != lastMonth {
                    labels.append((monthFormatter.string(from: date), weekIdx))
                    lastMonth = month
                }
            }
        }
        return labels
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Month labels
            GeometryReader { geo in
                let weekWidth = (geo.size.width - CGFloat(weeks.count - 1) * 3) / CGFloat(weeks.count)
                ForEach(monthLabels, id: \.1) { label, weekIdx in
                    Text(label)
                        .font(.system(size: 9))
                        .foregroundStyle(BaniTheme.secondaryText)
                        .position(
                            x: CGFloat(weekIdx) * (weekWidth + 3) + weekWidth / 2,
                            y: 6
                        )
                }
            }
            .frame(height: 14)

            // Grid: rows = days (Mon-Sun), columns = weeks
            HStack(spacing: 3) {
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { dayIdx in
                            if let date = week[dayIdx] {
                                let dateStr = formatter.string(from: date)
                                let isActive = sessionDates.contains(dateStr)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(isActive ? BaniTheme.saffron : BaniTheme.saffron.opacity(0.08))
                                    .frame(width: 14, height: 14)
                            } else {
                                Color.clear
                                    .frame(width: 14, height: 14)
                            }
                        }
                    }
                }
            }
        }
    }
}
