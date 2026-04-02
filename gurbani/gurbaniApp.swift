import SwiftUI
import SwiftData

@main
struct BaniApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Bani.self,
            BaniLine.self,
            WordCard.self,
            AppSession.self,
            ConversationMessage.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            if let appSupport = urls.first {
                let storeURL = appSupport.appendingPathComponent("default.store")
                try? FileManager.default.removeItem(at: storeURL)
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
                try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    @State private var baniService = BaniService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(baniService)
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}

// MARK: - Root View (onboarding gate)

struct RootView: View {
    @AppStorage("hasOnboarded") private var hasOnboarded = false
    @State private var navigateToPreferredBani: Int?

    var body: some View {
        if hasOnboarded {
            MainTabView(initialBaniID: navigateToPreferredBani)
                .onAppear { navigateToPreferredBani = nil }
        } else {
            OnboardingView { selectedBaniID in
                navigateToPreferredBani = selectedBaniID
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(.circular)
                .controlSize(.large)
                .tint(BaniTheme.saffron)
            Text("Loading...")
                .font(.headline)
                .foregroundStyle(BaniTheme.secondaryText)
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(BaniTheme.secondaryText)
                .padding(.horizontal, 32)
            Button("Try Again", action: onRetry)
                .buttonStyle(.borderedProminent)
                .tint(BaniTheme.saffron)
        }
    }
}
