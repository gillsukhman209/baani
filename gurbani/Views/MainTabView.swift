import SwiftUI

struct MainTabView: View {
    var initialBaniID: Int?
    @State private var selectedTab = "Read"
    @State private var pendingAskQuestion: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Read", systemImage: "book", value: "Read") {
                BaniListView(initialBaniID: initialBaniID)
            }
            Tab("Learn", systemImage: "sparkles", value: "Learn") {
                LearnView()
            }
            Tab("Progress", systemImage: "chart.bar", value: "Progress") {
                ProgressTabView()
            }
            Tab("Ask", systemImage: "bubble.left.and.bubble.right.fill", value: "Ask") {
                AskView(pendingQuestion: $pendingAskQuestion)
            }
            Tab("Settings", systemImage: "gear", value: "Settings") {
                SettingsView()
            }
        }
        .tint(BaniTheme.saffron)
        .onReceive(NotificationCenter.default.publisher(for: .askAboutLine)) { notification in
            if let question = notification.object as? String {
                pendingAskQuestion = question
                selectedTab = "Ask"
            }
        }
    }
}
