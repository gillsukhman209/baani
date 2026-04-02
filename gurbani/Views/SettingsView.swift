import SwiftUI

struct SettingsView: View {
    @AppStorage("gurmukhiFontSize") private var gurmukhiFontSize = 1
    @AppStorage("hapticFeedback") private var hapticEnabled = true
    @AppStorage("englishMode") private var englishMode = "Simple"
    @AppStorage("showPunjabi") private var showPunjabi = true

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
                Section("Translations") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("English")
                        Picker("English", selection: $englishMode) {
                            Text("Off").tag("Off")
                            Text("Simple").tag("Simple")
                            Text("Scholar").tag("Scholar")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.vertical, 4)

                    Toggle("Punjabi (ਪੰਜਾਬੀ)", isOn: $showPunjabi)
                        .tint(BaniTheme.accentColor)
                }

                Section("Display") {
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
                        .tint(BaniTheme.accentColor)
                }

                Section("Preview") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ੴ ਸਤਿ ਨਾਮੁ ਕਰਤਾ ਪੁਰਖੁ")
                            .font(.system(size: previewSize, weight: .bold))
                            .foregroundStyle(BaniTheme.gurmukhiColor)

                        if showPunjabi {
                            Text("ਸਭ ਕੁਝ ਬਣਾਉਣ ਵਾਲਾ ਇੱਕ ਰੱਬ, ਜਿਸ ਦਾ ਨਾਮ ਸੱਚ ਹੈ")
                                .font(.system(size: BaniTheme.translationSize + 2))
                                .foregroundStyle(BaniTheme.textSecondary)
                        }

                        if englishMode == "Simple" {
                            Text("One God, whose name is Truth, the Creator of everything")
                                .font(.system(size: BaniTheme.translationSize))
                                .foregroundStyle(BaniTheme.textSecondary.opacity(showPunjabi ? 0.7 : 1.0))
                        } else if englishMode == "Scholar" {
                            Text("One Creator, Truth is the Name, Creative Being")
                                .font(.system(size: BaniTheme.translationSize))
                                .foregroundStyle(BaniTheme.textSecondary.opacity(showPunjabi ? 0.7 : 1.0))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
                }

                Section("About Simple Gurbani") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Simple Gurbani helps you understand Gurbani word by word. Built for the Sikh diaspora — those who can recite but want to deeply understand what they read.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Built with love for the Sikh diaspora by a fellow Punjabi.")
                            .font(.caption)
                            .foregroundStyle(BaniTheme.textSecondary)

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
            .scrollContentBackground(.hidden)
            .background(BaniTheme.background.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbarBackground(BaniTheme.background, for: .navigationBar)
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
