import XCTest
@testable import HackerRiver

/// Ports the original web app's `ledger.test.ts` to the native `RiverStore`,
/// verifying the river's seen/tapped/dismissed lifecycle and TTL cleanup.
@MainActor
final class RiverStoreTests: XCTestCase {
    private let hour: TimeInterval = 3600
    private let day: TimeInterval = 86_400
    private var unseenTTL: TimeInterval { hour }
    private var tappedTTL: TimeInterval { 5 * 86_400 }

    private func makeStore() -> RiverStore {
        // Unique file per test so persisted state never leaks between cases.
        RiverStore(filename: "river-test-\(UUID().uuidString).json")
    }

    private func story(_ id: Int) -> HNItem {
        HNItem(id: id, type: "story", by: "tester", time: 1, title: "Story \(id)")
    }

    func testMarkSeenDoesNotResetFirstSeen() {
        let store = makeStore()
        let old = Date(timeIntervalSince1970: 1_000)
        store.markSeen([story(1)], now: old)
        let later = Date(timeIntervalSince1970: 5_000)
        store.markSeen([story(1), story(2)], now: later)
        XCTAssertEqual(store.entry(1)?.firstSeen, old)
        XCTAssertEqual(store.entry(2)?.firstSeen, later)
    }

    func testMarkTappedCapturesSnapshotAndReadState() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 2_000)
        store.markTapped(story(42), now: now)
        let e = store.entry(42)
        XCTAssertEqual(e?.tapped, true)
        XCTAssertEqual(e?.tappedAt, now)
        XCTAssertEqual(e?.snapshot?.id, 42)
        XCTAssertTrue(store.isRead(42))
    }

    func testDismissedNotInRecentlyRead() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 2_000)
        store.markDismissed(42, now: now)
        XCTAssertTrue(store.isDismissed(42))
        XCTAssertTrue(store.recentlyRead(now: now, tappedTTL: tappedTTL).isEmpty)
    }

    func testVisibilityRules() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 100_000)
        // Unseen ids are always visible.
        XCTAssertTrue(store.isVisibleInRiver(1, now: now, unseenTTL: unseenTTL))
        // Seen 30 minutes ago: still within the unseen TTL.
        store.markSeen([story(2)], now: now.addingTimeInterval(-30 * 60))
        XCTAssertTrue(store.isVisibleInRiver(2, now: now, unseenTTL: unseenTTL))
        // Seen 2 hours ago: expired.
        store.markSeen([story(3)], now: now.addingTimeInterval(-2 * hour))
        XCTAssertFalse(store.isVisibleInRiver(3, now: now, unseenTTL: unseenTTL))
        // Tapped and dismissed are both hidden from the live river.
        store.markTapped(story(4), now: now)
        XCTAssertFalse(store.isVisibleInRiver(4, now: now, unseenTTL: unseenTTL))
        store.markDismissed(5, now: now)
        XCTAssertFalse(store.isVisibleInRiver(5, now: now, unseenTTL: unseenTTL))
    }

    func testCleanupPurgesByDistinctTTLs() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 1_000_000)
        store.markSeen([story(10)], now: now.addingTimeInterval(-30 * 60)) // fresh untapped — keep
        store.markSeen([story(11)], now: now.addingTimeInterval(-2 * hour)) // expired untapped — purge
        store.markTapped(story(12), now: now.addingTimeInterval(-1 * day))  // tapped fresh — keep
        store.markTapped(story(13), now: now.addingTimeInterval(-6 * day))  // tapped expired — purge
        store.markDismissed(14, now: now.addingTimeInterval(-100 * day))    // dismissed — keep forever

        store.cleanup(now: now, unseenTTL: unseenTTL, tappedTTL: tappedTTL)

        XCTAssertNotNil(store.entry(10))
        XCTAssertNil(store.entry(11))
        XCTAssertNotNil(store.entry(12))
        XCTAssertNil(store.entry(13))
        XCTAssertNotNil(store.entry(14))
    }

    func testRecentlyReadSortedByTappedAtDescending() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 2_000_000)
        store.markTapped(story(1), now: now.addingTimeInterval(-20 * 60))
        store.markTapped(story(2), now: now.addingTimeInterval(-10 * 60))
        store.markSeen([story(3)], now: now) // untapped — excluded
        XCTAssertEqual(store.recentlyRead(now: now, tappedTTL: tappedTTL).map(\.id), [2, 1])
    }

    func testInboxCountsOnlyLiveStories() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 3_000_000)
        store.markSeen([story(2)], now: now.addingTimeInterval(-30 * 60)) // visible
        store.markSeen([story(3)], now: now.addingTimeInterval(-2 * hour)) // expired
        store.markTapped(story(4), now: now) // hidden
        store.markDismissed(5, now: now)     // hidden
        // id 1 is unseen → visible; 2 visible; 3/4/5 not → count == 2.
        let count = store.inboxCount(among: [1, 2, 3, 4, 5], now: now, unseenTTL: unseenTTL)
        XCTAssertEqual(count, 2)
    }

    func testMarkUnreadReturnsStoryToRiver() {
        let store = makeStore()
        let now = Date(timeIntervalSince1970: 4_000_000)
        // Seen long ago and then read.
        store.markSeen([story(7)], now: now.addingTimeInterval(-10 * day))
        store.markTapped(story(7), now: now.addingTimeInterval(-1 * day))
        XCTAssertFalse(store.isVisibleInRiver(7, now: now, unseenTTL: unseenTTL))
        // Returning it to the river resets the unseen clock so it shows again.
        store.markUnread(7, now: now)
        XCTAssertTrue(store.isVisibleInRiver(7, now: now, unseenTTL: unseenTTL))
    }
}
