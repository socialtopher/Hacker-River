import Foundation
import Observation

enum LoadPhase: Equatable {
    case loading
    case loaded
    case failed(String)
}

/// What a feed screen is showing: the merged river across the user's chosen
/// sources, or a single Hacker News feed focused via the chip bar / sidebar.
enum FeedMode: Hashable {
    case river
    case feed(Feed)

    var title: String {
        switch self {
        case .river: "Hacker River"
        case .feed(let f): f.title
        }
    }
    var shortTitle: String {
        switch self {
        case .river: "River"
        case .feed(let f): f.shortTitle
        }
    }
    var systemImage: String {
        switch self {
        case .river: "water.waves"
        case .feed(let f): f.systemImage
        }
    }
}

/// Drives a feed. In `.river` mode it merges the user's chosen HN feeds, filters
/// everything through the river ledger (so seen-and-expired, tapped, and
/// dismissed stories flow out), tracks the inbox count, and detects new arrivals
/// for the "N new posts" banner. In `.feed` mode it behaves like a plain HN feed
/// (still honoring dismissals). Items page in batches and per-item failures are
/// tolerated. Port of the web app's `feed.ts` + `App.tsx` load logic.
@MainActor
@Observable
final class FeedViewModel {
    private(set) var mode: FeedMode
    private(set) var stories: [HNItem] = []
    private(set) var phase: LoadPhase = .loading
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = true
    private(set) var pendingNewCount = 0

    /// Ids passing the river filter at load time, in display order. We page items
    /// from this list.
    private var visibleIDs: [Int] = []
    /// Every id returned by the most recent id fetch — used to detect genuinely
    /// new arrivals on background refresh.
    private var knownIDs: Set<Int> = []
    private var nextIndex = 0
    private let pageSize = 20

    private let service: HNServicing
    private var river: RiverStore?
    private var settings: SettingsStore?

    init(mode: FeedMode = .river, service: HNServicing = LiveHNService.shared) {
        self.mode = mode
        self.service = service
    }

    /// Desktop columns construct view models per single feed.
    convenience init(feed: Feed, service: HNServicing = LiveHNService.shared) {
        self.init(mode: .feed(feed), service: service)
    }

    /// Inject the shared stores. Called from the view's `.task` before loading,
    /// since SwiftUI environment isn't available at `@State` init time.
    func configure(river: RiverStore, settings: SettingsStore) {
        self.river = river
        self.settings = settings
    }

    // MARK: Derived state

    /// Stories still visible right now — reacts live to taps and dismissals so a
    /// story leaves the list the moment it's read or checked off.
    var visibleStories: [HNItem] {
        guard let river, let settings else { return stories }
        let now = Date()
        switch mode {
        case .river:
            return stories.filter { river.isVisibleInRiver($0.id, now: now, unseenTTL: settings.unseenTTL) }
        case .feed:
            // A focused feed shows everything except things you've checked off.
            return stories.filter { !river.isDismissed($0.id) }
        }
    }

    /// The "inbox" — how many live stories are waiting across the whole id list.
    var inboxCount: Int {
        guard case .river = mode, let river, let settings else { return visibleStories.count }
        return river.inboxCount(among: Array(knownIDs), now: Date(), unseenTTL: settings.unseenTTL)
    }

    // MARK: Loading

    /// Initial load; no-op once populated (so tab switches don't refetch) and
    /// after a failure (the error view offers an explicit retry instead).
    func startIfNeeded() async {
        guard stories.isEmpty else { return }
        if case .failed = phase { return }
        await reload()
    }

    func reload() async {
        cleanup()
        do {
            let ids = try await fetchIDs()
            knownIDs = Set(ids)
            let now = Date()
            let filtered = filterVisible(ids, now: now)
            visibleIDs = sortIDs(filtered)
            nextIndex = 0
            canLoadMore = true
            stories = []
            stories = try await fetchPage()
            phase = .loaded
            pendingNewCount = 0
        } catch {
            if stories.isEmpty { phase = .failed(message(for: error)) }
        }
    }

    func loadNextPage() async {
        guard phase == .loaded, canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        if let more = try? await fetchPage() {
            stories.append(contentsOf: more)
        }
    }

    func switchTo(_ newMode: FeedMode) async {
        guard newMode != mode else { return }
        mode = newMode
        stories = []
        visibleIDs = []
        knownIDs = []
        nextIndex = 0
        canLoadMore = true
        pendingNewCount = 0
        phase = .loading
        await reload()
    }

    /// Background check: refresh the id list and count brand-new arrivals (ids we
    /// haven't seen, that aren't already dismissed or read). Drives the banner.
    func checkForNew() async {
        guard phase == .loaded else { return }
        cleanup()
        guard let ids = try? await fetchIDs() else { return }
        let known = knownIDs
        let river = self.river
        pendingNewCount = ids.filter { id in
            guard !known.contains(id) else { return false }
            guard let river else { return true }
            return !river.isDismissed(id) && !river.isRead(id)
        }.count
    }

    func shouldLoadMore(at item: HNItem) -> Bool {
        let visible = visibleStories
        guard let index = visible.firstIndex(of: item) else { return false }
        return index >= visible.count - 4
    }

    // MARK: Actions

    /// Mark a story read (a tap) — moves it to Recently Read and out of the feed.
    func markTapped(_ item: HNItem) {
        river?.markTapped(item)
    }

    /// Dismiss a story (✓) — removes it from the feed immediately and for good.
    func dismiss(_ item: HNItem) {
        river?.markDismissed(item.id)
    }

    // MARK: Internals

    private func cleanup() {
        guard let river, let settings else { return }
        river.cleanup(now: Date(), unseenTTL: settings.unseenTTL, tappedTTL: settings.tappedTTL)
    }

    private func filterVisible(_ ids: [Int], now: Date) -> [Int] {
        guard let river, let settings else { return ids }
        switch mode {
        case .river:
            return ids.filter { river.isVisibleInRiver($0, now: now, unseenTTL: settings.unseenTTL) }
        case .feed:
            return ids.filter { !river.isDismissed($0) }
        }
    }

    private func sortIDs(_ ids: [Int]) -> [Int] {
        // Sorting only reorders the live river; focused feeds keep HN's order.
        guard case .river = mode, let settings else { return ids }
        return Self.sorted(ids, by: settings.riverSort)
    }

    /// Order ids by the river sort. Rank keeps merge order (≈ HN rank, Top first);
    /// newest puts higher item ids (more recent) first.
    nonisolated static func sorted(_ ids: [Int], by sort: RiverSort) -> [Int] {
        switch sort {
        case .rank: return ids
        case .newest: return ids.sorted(by: >)
        }
    }

    private func fetchIDs() async throws -> [Int] {
        switch mode {
        case .feed(let feed):
            return try await service.storyIDs(for: feed)
        case .river:
            let feeds = settings?.orderedRiverSources ?? [.top]
            var lists: [[Int]] = []
            for feed in feeds {
                // Tolerate a single failing source so the river still flows.
                let ids = (try? await service.storyIDs(for: feed)) ?? []
                lists.append(ids)
            }
            return mergeIDs(lists)
        }
    }

    private func mergeIDs(_ groups: [[Int]]) -> [Int] { Self.mergeStoryIDs(groups) }

    /// Dedupe across sources, preserving first-seen order. Port of `mergeStoryIds`.
    nonisolated static func mergeStoryIDs(_ groups: [[Int]]) -> [Int] {
        var seen = Set<Int>()
        var merged: [Int] = []
        for group in groups {
            for id in group where !seen.contains(id) {
                seen.insert(id)
                merged.append(id)
            }
        }
        return merged
    }

    private func fetchPage() async throws -> [HNItem] {
        guard nextIndex < visibleIDs.count else {
            canLoadMore = false
            return []
        }
        let end = min(nextIndex + pageSize, visibleIDs.count)
        let slice = Array(visibleIDs[nextIndex..<end])
        let items = try await service.items(slice)
        nextIndex = end
        canLoadMore = nextIndex < visibleIDs.count
        let cleaned = items.filter(isFeedStory)
        river?.markSeen(cleaned)
        return cleaned
    }

    /// Live stories only: drop dead/deleted/untitled and non-story kinds. Jobs are
    /// kept (the river includes the Jobs feed); comments/polls are not.
    private func isFeedStory(_ item: HNItem) -> Bool {
        guard !item.isDead, !item.isDeleted, item.title?.isEmpty == false else { return false }
        return item.kind == .story || item.kind == .job
    }

    private func message(for error: Error) -> String {
        (error as? HNError)?.errorDescription ?? error.localizedDescription
    }
}
