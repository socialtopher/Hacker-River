import SwiftUI

/// How the live river feed is ordered.
enum RiverSort: String, CaseIterable, Identifiable, Codable {
    case rank, newest
    var id: String { rawValue }
    var title: String {
        switch self {
        case .rank: "HN Rank"
        case .newest: "Newest"
        }
    }
    var systemImage: String {
        switch self {
        case .rank: "flame"
        case .newest: "clock"
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable, Codable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .dark: "moon.fill"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// User preferences, persisted to `UserDefaults` and observed app-wide.
@Observable
final class SettingsStore {
    var appearance: AppAppearance {
        didSet { store(appearance.rawValue, .appearance) }
    }
    var accent: AccentTheme {
        didSet { store(accent.rawValue, .accent) }
    }
    var defaultFeed: Feed {
        didSet { store(defaultFeed.rawValue, .defaultFeed) }
    }
    var openLinksInApp: Bool {
        didSet { store(openLinksInApp, .openLinksInApp) }
    }
    var readerMode: Bool {
        didSet { store(readerMode, .readerMode) }
    }
    var markReadOnOpen: Bool {
        didSet { store(markReadOnOpen, .markReadOnOpen) }
    }
    var hapticsEnabled: Bool {
        didSet {
            store(hapticsEnabled, .haptics)
            Haptics.isEnabled = hapticsEnabled
        }
    }

    // MARK: Accessibility

    /// Underline links inside comments/text for users who can't rely on color.
    var underlineLinks: Bool {
        didSet { store(underlineLinks, .underlineLinks) }
    }
    /// Force color-independent status cues (read badges, status shapes) on,
    /// regardless of the system "Differentiate Without Color" setting.
    var distinguishWithoutColor: Bool {
        didSet { store(distinguishWithoutColor, .distinguishWithoutColor) }
    }
    /// Show the numeric rank badge on story rows (extra non-color ordering cue).
    var showRankNumbers: Bool {
        didSet { store(showRankNumbers, .showRankNumbers) }
    }

    // MARK: River

    /// Background auto-refresh interval in minutes; `0` means off.
    var autoRefreshMinutes: Int {
        didSet { store(autoRefreshMinutes, .autoRefreshMinutes) }
    }
    /// How long an untapped story stays in the feed after first being seen.
    var unseenTTLHours: Double {
        didSet { store(unseenTTLHours, .unseenTTLHours) }
    }
    /// How long a tapped story stays in Recently Read.
    var tappedTTLDays: Int {
        didSet { store(tappedTTLDays, .tappedTTLDays) }
    }
    /// Ordering of the live river feed.
    var riverSort: RiverSort {
        didSet { store(riverSort.rawValue, .riverSort) }
    }
    /// Which HN feeds are merged into the river. Persisted as raw strings.
    var riverSources: Set<Feed> {
        didSet { store(riverSources.map(\.rawValue), .riverSources) }
    }

    /// Unseen TTL as a duration.
    var unseenTTL: TimeInterval { unseenTTLHours * 3600 }
    /// Tapped TTL as a duration.
    var tappedTTL: TimeInterval { Double(tappedTTLDays) * 86_400 }

    /// The river's feeds in canonical order, falling back to Top if empty.
    var orderedRiverSources: [Feed] {
        let ordered = Feed.allCases.filter { riverSources.contains($0) }
        return ordered.isEmpty ? [.top] : ordered
    }

    /// Whether the first-run personalization flow has been completed.
    var hasCompletedOnboarding: Bool {
        didSet { store(hasCompletedOnboarding, .onboarded) }
    }

    static let defaultRiverSources: Set<Feed> = [.top, .new, .ask, .show, .job]

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        appearance = AppAppearance(rawValue: defaults.string(forKey: Key.appearance.rawValue) ?? "") ?? .system
        accent = AccentTheme(rawValue: defaults.string(forKey: Key.accent.rawValue) ?? "") ?? .ember
        defaultFeed = Feed(rawValue: defaults.string(forKey: Key.defaultFeed.rawValue) ?? "") ?? .top
        openLinksInApp = defaults.object(forKey: Key.openLinksInApp.rawValue) as? Bool ?? true
        readerMode = defaults.object(forKey: Key.readerMode.rawValue) as? Bool ?? false
        markReadOnOpen = defaults.object(forKey: Key.markReadOnOpen.rawValue) as? Bool ?? true
        hapticsEnabled = defaults.object(forKey: Key.haptics.rawValue) as? Bool ?? true
        underlineLinks = defaults.object(forKey: Key.underlineLinks.rawValue) as? Bool ?? true
        distinguishWithoutColor = defaults.object(forKey: Key.distinguishWithoutColor.rawValue) as? Bool ?? false
        showRankNumbers = defaults.object(forKey: Key.showRankNumbers.rawValue) as? Bool ?? true
        autoRefreshMinutes = defaults.object(forKey: Key.autoRefreshMinutes.rawValue) as? Int ?? 5
        unseenTTLHours = defaults.object(forKey: Key.unseenTTLHours.rawValue) as? Double ?? 1
        tappedTTLDays = defaults.object(forKey: Key.tappedTTLDays.rawValue) as? Int ?? 5
        riverSort = RiverSort(rawValue: defaults.string(forKey: Key.riverSort.rawValue) ?? "") ?? .rank
        if let raw = defaults.array(forKey: Key.riverSources.rawValue) as? [String] {
            let parsed = Set(raw.compactMap(Feed.init(rawValue:)))
            riverSources = parsed.isEmpty ? SettingsStore.defaultRiverSources : parsed
        } else {
            riverSources = SettingsStore.defaultRiverSources
        }
        hasCompletedOnboarding = defaults.object(forKey: Key.onboarded.rawValue) as? Bool ?? false
        Haptics.isEnabled = hapticsEnabled
    }

    private enum Key: String {
        case appearance = "settings.appearance"
        case accent = "settings.accent"
        case defaultFeed = "settings.defaultFeed"
        case openLinksInApp = "settings.openLinksInApp"
        case readerMode = "settings.readerMode"
        case markReadOnOpen = "settings.markReadOnOpen"
        case haptics = "settings.haptics"
        case underlineLinks = "settings.underlineLinks"
        case distinguishWithoutColor = "settings.distinguishWithoutColor"
        case showRankNumbers = "settings.showRankNumbers"
        case autoRefreshMinutes = "settings.autoRefreshMinutes"
        case unseenTTLHours = "settings.unseenTTLHours"
        case tappedTTLDays = "settings.tappedTTLDays"
        case riverSort = "settings.riverSort"
        case riverSources = "settings.riverSources"
        case onboarded = "settings.hasCompletedOnboarding"
    }

    private func store(_ value: Any, _ key: Key) {
        defaults.set(value, forKey: key.rawValue)
    }
}
