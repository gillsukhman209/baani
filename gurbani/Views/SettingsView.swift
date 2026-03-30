import SwiftUI

struct SettingsView: View {
    @AppStorage("showTranslation") private var showTranslation = true
    @AppStorage("gurmukhiFontSize") private var gurmukhiFontSize = 1
    @AppStorage("hapticFeedback") private var hapticEnabled = true
    @AppStorage("preferredTranslationMode") private var translationMode = "Both"

    private var fontSizeLabel: String {
        switch gurmukhiFontSize {
        case 0: "Small"
        case 2: "Large"
        default: "Medium"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Display") {
                    Toggle("Show English Translation", isOn: $showTranslation)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gurmukhi Font Size: \(fontSizeLabel)")
                        Picker("Font Size", selection: $gurmukhiFontSize) {
                            Text("Small").tag(0)
                            Text("Medium").tag(1)
                            Text("Large").tag(2)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)

                    Toggle("Haptic Feedback", isOn: $hapticEnabled)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translation Style")
                        Picker("Translation Style", selection: $translationMode) {
                            Text("Simple").tag("Simple")
                            Text("Punjabi").tag("Punjabi")
                            Text("Scholar").tag("Scholar")
                            Text("Both").tag("Both")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)
                }

                Section("Preview") {
                    VStack(spacing: 8) {
                        Text("ੴ ਸਤਿ ਨਾਮੁ ਕਰਤਾ ਪੁਰਖੁ")
                            .font(.system(size: previewSize, weight: .bold))
                            .foregroundStyle(BaniTheme.gurmukhiColor)

                        if showTranslation {
                            Text(translationMode == "Simple"
                                 ? "One God, whose name is Truth, the Creator of everything"
                                 : "One Creator, Truth is the Name, Creative Being")
                                .font(.system(size: BaniTheme.translationSize))
                                .foregroundStyle(BaniTheme.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("About Bani") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bani helps you understand Gurbani word by word. Built for the Sikh diaspora — those who can recite but want to deeply understand what they read.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Built with love for the Sikh diaspora by a fellow Punjabi.")
                            .font(.caption)
                            .foregroundStyle(BaniTheme.secondaryText)

                        Text("Gurbani data provided by BaniDB — an open-source Gurbani database and API.")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var previewSize: CGFloat {
        switch gurmukhiFontSize {
        case 0: BaniTheme.gurmukhiSizeSmall
        case 2: BaniTheme.gurmukhiSizeLarge
        default: BaniTheme.gurmukhiSizeMedium
        }
    }
}
