import XCTest
@testable import HackerRiver

/// Ports the merge/sort cases from the web app's `feed.test.ts` to the native
/// `FeedViewModel` helpers.
final class FeedLogicTests: XCTestCase {
    func testMergeDeduplicatesPreservingFirstSourceOrder() {
        XCTAssertEqual(
            FeedViewModel.mergeStoryIDs([[3, 2, 1], [2, 4], [4, 5]]),
            [3, 2, 1, 4, 5]
        )
    }

    func testRankSortKeepsMergeOrder() {
        let ids = [42, 7, 100, 3]
        XCTAssertEqual(FeedViewModel.sorted(ids, by: .rank), ids)
    }

    func testNewestSortOrdersByDescendingId() {
        XCTAssertEqual(
            FeedViewModel.sorted([1, 5, 3, 2, 4], by: .newest),
            [5, 4, 3, 2, 1]
        )
    }
}
