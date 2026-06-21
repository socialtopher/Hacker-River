import SwiftUI

struct SettingsView: View {
    @Environment(SettingsStore.self) private var settings
    @Environment(RiverStore.self) private var readStore
    @Environment(BookmarkStore.self) private var bookmarks
    @Environment(\.openURL) private var openURL

    @State private var confirmClearRead = false
    @State private var cacheSize = 0

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            Form {
                appearanceSection($settings)
                riverSection($settings)
                readingSection($settings)
                accessibilitySection($settings)
                personalizeSection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .tint(settings.accent.color)
            .labelStyle(SettingsLabelStyle())
            .environment(\.defaultMinListRowHeight, 46)
            .task { cacheSize = await DiskCache.shared.sizeInBytes() }
        }
    }

    // MARK: Appearance

    private func appearanceSection(_ settings: Bindable<SettingsStore>) -> some View {
        Section("Appearance") {
            Picker(selection: settings.appearance) {
                ForEach(AppAppearance.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            } label: {
                Label("Theme", systemImage: "circle.lefthalf.filled")
            }
            .pickerStyle(.menu)

            VStack(alignment: .leading, spacing: Spacing.l) {
                Label("Accent", systemImage: "paintpalette")
                AccentPicker(selection: settings.accent)
            }
            .padding(.vertical, Spacing.s)
        }
    }

    // MARK: River

    private func riverSection(_ settings: Bindable<SettingsStore>) -> some View {
        Group {
            Section {
                Picker(selection: settings.autoRefreshMinutes) {
                    Text("1 min").tag(1)
                    Text("5 min").tag(5)
                    Text("15 min").tag(15)
                    Text("30 min").tag(30)
                    Text("Off").tag(0)
                } label: {
                    Label("Auto-Refresh", systemImage: "arrow.clockwise")
                }

                Picker(selection: settings.riverSort) {
                    ForEach(RiverSort.allCases) { sort in
                        Label(sort.title, systemImage: sort.systemImage).tag(sort)
                    }
                } label: {
                    Label("Sort River By", systemImage: "arrow.up.arrow.down")
                }

                Picker(selection: settings.unseenTTLHours) {
                    Text("30 min").tag(0.5)
                    Text("1 hour").tag(1.0)
                    Text("2 hours").tag(2.0)
                    Text("4 hours").tag(4.0)
                } label: {
                    Label("Keep Unread For", systemImage: "hourglass")
                }

                Picker(selection: settings.tappedTTLDays) {
                    Text("1 day").tag(1)
                    Text("3 days").tag(3)
                    Text("5 days").tag(5)
                    Text("7 days").tag(7)
                } label: {
                    Label("Keep Read For", systemImage: "calendar")
                }
            } header: {
                Text("River")
            } footer: {
                Text("Unread stories flow out of the feed after the time above; stories you open move to Recently Read until they expire. Dismissed stories never return.")
            }

            Section {
                ForEach(Feed.allCases) { feed in
                    Toggle(isOn: Binding(
                        get: { settings.wrappedValue.riverSources.contains(feed) },
                        set: { isOn in
                            if isOn { settings.wrappedValue.riverSources.insert(feed) }
                            else { settings.wrappedValue.riverSources.remove(feed) }
                        }
                    )) {
                        Label(feed.title, systemImage: feed.systemImage)
                    }
                }
            } header: {
                Text("River Sources")
            } footer: {
                Text("Which Hacker News feeds are merged into the river.")
            }
        }
    }

    // MARK: Reading

    private func readingSection(_ settings: Bindable<SettingsStore>) -> some View {
        Section("Reading") {
            Picker(selection: settings.defaultFeed) {
                ForEach(Feed.allCases) { feed in
                    Label(feed.title, systemImage: feed.systemImage).tag(feed)
                }
            } label: {
                Label("Default Feed", systemImage: "list.bullet.rectangle")
            }

            Toggle(isOn: settings.openLinksInApp) {
                Label("Open Links in App", systemImage: "safari")
            }
            Toggle(isOn: settings.readerMode) {
                Label("Use Reader When Available", systemImage: "doc.plaintext")
            }
            .disabled(!settings.wrappedValue.openLinksInApp)
            Toggle(isOn: settings.markReadOnOpen) {
                Label("Mark Stories Read on Open", systemImage: "checkmark.circle")
            }
        }
    }

    // MARK: Accessibility

    private func accessibilitySection(_ settings: Bindable<SettingsStore>) -> some View {
        Section {
            Toggle(isOn: settings.underlineLinks) {
                Label("Underline Links", systemImage: "underline")
            }
            Toggle(isOn: settings.distinguishWithoutColor) {
                Label("Color-Blind Friendly Cues", systemImage: "circle.dashed")
            }
            Toggle(isOn: settings.showRankNumbers) {
                Label("Show Rank Numbers", systemImage: "number")
            }
            Toggle(isOn: settings.hapticsEnabled) {
                Label("Haptic Feedback", systemImage: "iphone.radiowaves.left.and.right")
            }
        } header: {
            Text("Accessibility")
        } footer: {
            Text("Adds shapes and labels so status never depends on color alone. The app also follows your system accessibility settings.")
        }
    }

    // MARK: Personalize

    private var personalizeSection: some View {
        Section {
            Button {
                Haptics.tap()
                withAnimation { settings.hasCompletedOnboarding = false }
            } label: {
                Label("Personalize Again", systemImage: "wand.and.stars")
            }
        } footer: {
            Text("Re-run the quick setup to retune the app to your preferences.")
        }
    }

    // MARK: Data

    private var dataSection: some View {
        Section("Data") {
            Button(role: .destructive) {
                confirmClearRead = true
            } label: {
                Label("Reset River History", systemImage: "arrow.counterclockwise")
            }
            .confirmationDialog("Reset the river?", isPresented: $confirmClearRead, titleVisibility: .visible) {
                Button("Reset", role: .destructive) {
                    readStore.clear()
                    Haptics.warning()
                }
            } message: {
                Text("Clears the seen, read, and dismissed ledger. Every story will appear fresh again.")
            }

            HStack {
                Label("Saved Stories", systemImage: "bookmark")
                Spacer()
                Text("\(bookmarks.items.count)")
                    .foregroundStyle(Theme.textSecondary)
            }
            HStack {
                Label("Offline Cache", systemImage: "internaldrive")
                Spacer()
                Text(cacheSize.formatted(.byteCount(style: .file)))
                    .foregroundStyle(Theme.textSecondary)
                    .monospacedDigit()
            }
            Button(role: .destructive) {
                Task {
                    await DiskCache.shared.clear()
                    cacheSize = 0
                    Haptics.warning()
                }
            } label: {
                Label("Clear Offline Cache", systemImage: "trash")
            }
        }
    }

    // MARK: About

    private var aboutSection: some View {
        Section("About") {
            HStack {
                Label("Version", systemImage: "info.circle")
                Spacer()
                Text(appVersion).foregroundStyle(Theme.textSecondary)
            }
            Button {
                openURL(URL(string: "https://news.ycombinator.com")!)
            } label: {
                Label("Hacker News", systemImage: "globe")
            }
            Button {
                openURL(URL(string: "https://github.com/HackerNews/API")!)
            } label: {
                Label("Powered by the HN API", systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}

/// Consistent settings rows: a fixed-width icon column, generous icon-to-title
/// spacing, and vertical padding so rows breathe and icons never clip.
struct SettingsLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.m) {
            configuration.icon
                .font(.system(size: 16))
                .frame(width: 26, alignment: .center)
            configuration.title
        }
        .padding(.vertical, 4)
    }
}

/// Row of accent swatches; selection shown with a ring + checkmark (not color alone).
struct AccentPicker: View {
    @Binding var selection: AccentTheme

    var body: some View {
        HStack(spacing: Spacing.l) {
            ForEach(AccentTheme.allCases) { accent in
                Button {
                    selection = accent
                    Haptics.selection()
                } label: {
                    Circle()
                        .fill(accent.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            if accent == selection {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay(
                            Circle().strokeBorder(
                                accent == selection ? Theme.textPrimary : Color.clear,
                                lineWidth: 2
                            )
                            .padding(-3)
                        )
                        .padding(3)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accent.title)
                .accessibilityAddTraits(accent == selection ? [.isButton, .isSelected] : .isButton)
            }
            Spacer()
        }
    }
}
