import SwiftUI

/// A feed (the river, or a single HN feed) rendered as a selectable list for the
/// desktop middle column.
struct DesktopFeedColumn: View {
    let mode: FeedMode
    @Binding var selection: HNItem?
    @State private var vm: FeedViewModel

    @Environment(RiverStore.self) private var river
    @Environment(SettingsStore.self) private var settings
    @Environment(BookmarkStore.self) private var bookmarks

    init(mode: FeedMode, selection: Binding<HNItem?>) {
        self.mode = mode
        _selection = selection
        _vm = State(initialValue: FeedViewModel(mode: mode))
    }

    private var navTitle: String {
        guard case .river = mode else { return mode.title }
        let count = vm.inboxCount
        return count > 0 ? "Hacker River (\(count))" : "Hacker River"
    }

    var body: some View {
        Group {
            switch vm.phase {
            case .loading where vm.stories.isEmpty:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message) where vm.stories.isEmpty:
                ErrorStateView(message: message) { Task { await vm.reload() } }
            default:
                list
            }
        }
        .navigationTitle(navTitle)
        .background(Theme.background)
        .task {
            vm.configure(river: river, settings: settings)
            await vm.startIfNeeded()
        }
    }

    private var list: some View {
        List(selection: $selection) {
            if vm.visibleStories.isEmpty {
                ContentUnavailableView {
                    Label("The river is calm", systemImage: "checkmark.circle")
                } description: {
                    Text("You're all caught up.")
                }
            }
            ForEach(Array(vm.visibleStories.enumerated()), id: \.element.id) { index, story in
                StoryRow(item: story, rank: index + 1) {
                    withAnimation { vm.dismiss(story) }
                }
                .tag(story)
                .listRowSeparatorTint(Theme.separator)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        bookmarks.toggle(story)
                    } label: {
                        Label(bookmarks.isBookmarked(story) ? "Unsave" : "Save",
                              systemImage: bookmarks.isBookmarked(story) ? "bookmark.slash.fill" : "bookmark.fill")
                    }
                    .tint(Theme.upvote)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        withAnimation { vm.dismiss(story) }
                    } label: {
                        Label("Dismiss", systemImage: "checkmark")
                    }
                    .tint(Theme.positive)
                }
                .task {
                    if vm.shouldLoadMore(at: story) { await vm.loadNextPage() }
                }
            }
            if vm.isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.inset)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .refreshable { await vm.reload() }
    }
}

/// Recently read stories for the desktop middle column.
struct DesktopRecentlyReadColumn: View {
    @Environment(RiverStore.self) private var river
    @Environment(SettingsStore.self) private var settings
    @Binding var selection: HNItem?

    private var items: [HNItem] {
        river.recentlyRead(now: Date(), tappedTTL: settings.tappedTTL)
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing read yet", systemImage: "book.closed")
                } description: {
                    Text("Stories you open will appear here.")
                }
            } else {
                List(selection: $selection) {
                    ForEach(items) { story in
                        StoryRow(item: story)
                            .tag(story)
                            .listRowSeparatorTint(Theme.separator)
                            .swipeActions {
                                Button(role: .destructive) {
                                    river.markDismissed(story.id)
                                } label: {
                                    Label("Remove", systemImage: "xmark")
                                }
                            }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .background(Theme.background)
            }
        }
        .navigationTitle("Recently Read")
        .background(Theme.background)
    }
}

/// Saved stories for the desktop middle column.
struct DesktopSavedColumn: View {
    @Environment(BookmarkStore.self) private var bookmarks
    @Binding var selection: HNItem?

    var body: some View {
        Group {
            if bookmarks.items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing saved", systemImage: "bookmark")
                } description: {
                    Text("Stories you save will appear here.")
                }
            } else {
                List(selection: $selection) {
                    ForEach(bookmarks.items) { story in
                        StoryRow(item: story)
                            .tag(story)
                            .listRowSeparatorTint(Theme.separator)
                            .swipeActions {
                                Button(role: .destructive) {
                                    bookmarks.remove(story.id)
                                } label: {
                                    Label("Remove", systemImage: "bookmark.slash.fill")
                                }
                            }
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .background(Theme.background)
            }
        }
        .navigationTitle("Saved")
        .background(Theme.background)
    }
}

/// Search for the desktop middle column.
struct DesktopSearchColumn: View {
    @State private var vm = SearchViewModel()
    @Binding var selection: HNItem?

    private var searchKey: String { "\(vm.query)|\(vm.mode.rawValue)" }

    var body: some View {
        Group {
            switch vm.phase {
            case .idle:
                ContentUnavailableView {
                    Label("Search Hacker News", systemImage: "magnifyingglass")
                } description: {
                    Text("Find stories and discussions by keyword.")
                }
            case .searching:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            case .empty:
                ContentUnavailableView.search(text: vm.query)
            case .failed(let message):
                ErrorStateView(message: message) { Task { await vm.runSearch() } }
            case .results:
                List(selection: $selection) {
                    ForEach(vm.results) { story in
                        StoryRow(item: story)
                            .tag(story)
                            .listRowSeparatorTint(Theme.separator)
                    }
                }
                .listStyle(.inset)
                .scrollContentBackground(.hidden)
                .background(Theme.background)
                .safeAreaInset(edge: .top) {
                    Picker("Sort", selection: Binding(
                        get: { vm.mode },
                        set: { newValue in Task { await vm.setMode(newValue) } }
                    )) {
                        ForEach(SearchMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(Spacing.s)
                    .background(.bar)
                }
            }
        }
        .navigationTitle("Search")
        .background(Theme.background)
        .searchable(text: $vm.query, prompt: "Search stories")
        .task(id: searchKey) {
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            await vm.runSearch()
        }
    }
}
