import SwiftUI

@main
struct HackerRiverApp: App {
    @State private var settings = SettingsStore()
    @State private var bookmarks = BookmarkStore()
    @State private var river = RiverStore()
    @State private var linkOpener = LinkOpener()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(settings)
                .environment(bookmarks)
                .environment(river)
                .environment(linkOpener)
                .task {
                    // Purge expired ledger entries once at launch so the river is
                    // fresh before the first feed load runs.
                    river.cleanup(now: Date(), unseenTTL: settings.unseenTTL, tappedTTL: settings.tappedTTL)
                }
        }
    }
}
