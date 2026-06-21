import Foundation
import Observation

/// A single story's place in the river.
///
/// Ported from the original Hacker River web app's `localStorage` "seen ledger"
/// (`src/lib/ledger.ts`). Every story the app shows is recorded here so it can
/// flow out of the feed over time:
///
/// - **Unseen** — not in the ledger. Shown, then recorded with `firstSeen = now`.
/// - **Seen, not tapped** — visible until `unseenTTL` elapses from `firstSeen`,
///   then hidden. The clock never resets on re-render or relaunch.
/// - **Tapped** — opened by the user. Moves to "Recently Read" until `tappedTTL`
///   elapses from `tappedAt`, then hidden.
/// - **Dismissed** — checked off (✓). Hidden immediately, forever.
struct RiverEntry: Codable, Hashable {
    var firstSeen: Date
    var tapped: Bool = false
    var tappedAt: Date?
    var dismissed: Bool = false
    var dismissedAt: Date?
    /// Snapshot of the story, kept for tapped items so "Recently Read" renders
    /// instantly and offline after relaunch (the feed no longer holds it).
    var snapshot: HNItem?
}

/// The river ledger: which stories have flowed in, been read, or been dismissed,
/// with per-state TTLs so the feed stays fresh and never shows the same post
/// twice. Backed by a JSON file in Application Support (entries are richer than
/// `UserDefaults` arrays, and the read snapshots make Recently Read work offline).
///
/// Exposes `isRead` / `markRead` / `markUnread` / `clear` so it is a drop-in
/// replacement for Ember's original `ReadStore` (a tap *is* a read here), plus
/// the river-specific `markSeen` / `markDismissed` / `recentlyRead` / `cleanup`.
@Observable
final class RiverStore {
    private(set) var entries: [Int: RiverEntry] = [:]

    private let fileURL: URL
    /// Hard cap so the ledger can't grow without bound (TTL cleanup is the
    /// primary mechanism; this is a backstop if cleanup is never triggered).
    private let maxEntries = 5_000

    init(filename: String = "river-ledger.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent(filename)
        load()
    }

    // MARK: Queries

    func entry(_ id: Int) -> RiverEntry? { entries[id] }

    /// A tap is a read; used by rows to dim visited stories.
    func isRead(_ id: Int) -> Bool { entries[id]?.tapped ?? false }

    func isDismissed(_ id: Int) -> Bool { entries[id]?.dismissed ?? false }

    /// Whether an *untapped* story should appear in the live feed: unseen stories
    /// are always visible; seen-but-untapped stories are visible until the unseen
    /// TTL elapses; dismissed or tapped stories are not. Mirrors
    /// `isUntappedVisible` in the original `ledger.ts`.
    func isVisibleInRiver(_ id: Int, now: Date, unseenTTL: TimeInterval) -> Bool {
        guard let e = entries[id] else { return true }
        if e.dismissed || e.tapped { return false }
        return now.timeIntervalSince(e.firstSeen) < unseenTTL
    }

    func isTappedVisible(_ e: RiverEntry?, now: Date, tappedTTL: TimeInterval) -> Bool {
        guard let e, e.tapped, let tappedAt = e.tappedAt else { return false }
        return now.timeIntervalSince(tappedAt) < tappedTTL
    }

    /// Number of live (unseen or seen-but-fresh) stories among the given ids —
    /// the feed's "inbox" count.
    func inboxCount(among ids: [Int], now: Date, unseenTTL: TimeInterval) -> Int {
        ids.reduce(0) { $0 + (isVisibleInRiver($1, now: now, unseenTTL: unseenTTL) ? 1 : 0) }
    }

    /// Tapped stories still within their TTL, newest read first, for Recently Read.
    func recentlyRead(now: Date, tappedTTL: TimeInterval) -> [HNItem] {
        entries
            .filter { isTappedVisible($0.value, now: now, tappedTTL: tappedTTL) }
            .compactMap { _, e in e.snapshot.map { ($0, e.tappedAt ?? e.firstSeen) } }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    // MARK: Mutations

    /// Record stories as seen on first appearance (sets `firstSeen`); no-op for
    /// stories already in the ledger so the unseen clock never resets.
    func markSeen(_ items: [HNItem], now: Date = .now) {
        var changed = false
        for item in items where entries[item.id] == nil {
            entries[item.id] = RiverEntry(firstSeen: now)
            changed = true
        }
        if changed { persist() }
    }

    /// Mark a story read by id (a tap). Kept for drop-in compatibility with the
    /// original `ReadStore`; prefer `markTapped(_:)` so a snapshot is captured.
    func markRead(_ id: Int, now: Date = .now) {
        var e = entries[id] ?? RiverEntry(firstSeen: now)
        e.tapped = true
        e.tappedAt = now
        e.dismissed = false
        e.dismissedAt = nil
        entries[id] = e
        persist()
    }

    /// Mark a story tapped/read, capturing a snapshot for Recently Read.
    func markTapped(_ item: HNItem, now: Date = .now) {
        var e = entries[item.id] ?? RiverEntry(firstSeen: now)
        e.tapped = true
        e.tappedAt = now
        e.dismissed = false
        e.dismissedAt = nil
        e.snapshot = item
        entries[item.id] = e
        persist()
    }

    /// Return a story to the live river: clears the tapped/dismissed state and
    /// resets the unseen clock so it shows again instead of being filtered out as
    /// an old, already-expired entry.
    func markUnread(_ id: Int, now: Date = .now) {
        guard var e = entries[id] else { return }
        e.tapped = false
        e.tappedAt = nil
        e.dismissed = false
        e.dismissedAt = nil
        e.firstSeen = now
        entries[id] = e
        persist()
    }

    /// Dismiss a story (✓): hidden from the feed immediately and permanently,
    /// without moving to Recently Read.
    func markDismissed(_ id: Int, now: Date = .now) {
        var e = entries[id] ?? RiverEntry(firstSeen: now)
        e.dismissed = true
        e.dismissedAt = now
        e.tapped = false
        e.tappedAt = nil
        e.snapshot = nil
        entries[id] = e
        persist()
    }

    func clear() {
        entries = [:]
        persist()
    }

    // MARK: Cleanup

    /// Purge entries whose TTL has fully elapsed. Dismissed entries are kept
    /// (they must never reappear); untapped entries expire by `unseenTTL`, tapped
    /// entries by `tappedTTL`. Mirrors `cleanupLedger` in `ledger.ts`.
    func cleanup(now: Date = .now, unseenTTL: TimeInterval, tappedTTL: TimeInterval) {
        var next = entries.filter { _, e in
            if e.dismissed { return true }
            if e.tapped { return isTappedVisible(e, now: now, tappedTTL: tappedTTL) }
            return now.timeIntervalSince(e.firstSeen) < unseenTTL
        }
        if next.count > maxEntries {
            // Backstop: keep the most recently active entries.
            let kept = next.sorted { lastTouch($0.value) > lastTouch($1.value) }.prefix(maxEntries)
            next = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
        }
        if next != entries {
            entries = next
            persist()
        }
    }

    private func lastTouch(_ e: RiverEntry) -> Date {
        max(e.firstSeen, e.tappedAt ?? .distantPast, e.dismissedAt ?? .distantPast)
    }

    // MARK: Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Int: RiverEntry].self, from: data) else { return }
        entries = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
