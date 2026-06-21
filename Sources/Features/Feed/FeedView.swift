import SwiftUI

/// The primary feeds screen: the live river with a pinned source selector, an
/// inbox count, and a "new posts" banner. Reading or dismissing a story flows it
/// out of the river.
struct FeedView: View {
    @State private var vm = FeedViewModel()
    @State private var path = NavigationPath()

    @Environment(SettingsStore.self) private var settings
    @Environment(RiverStore.self) private var river
    @Environment(BookmarkStore.self) private var bookmarks
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        HStack(spacing: 6) {
                            Image(systemName: "water.waves")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(settings.accent.color)
                            Text(title)
                                .font(.system(.headline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.textPrimary)
                        }
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityLabel(accessibilityTitle)
                    }
                }
                .safeAreaInset(edge: .top, spacing: 0) {
                    VStack(spacing: 0) {
                        FeedChipBar(selection: vm.mode) { mode in
                            Haptics.selection()
                            Task { await vm.switchTo(mode) }
                        }
                        if vm.pendingNewCount > 0 {
                            NewPostsBanner(count: vm.pendingNewCount) {
                                Haptics.tap()
                                Task { await vm.reload() }
                            }
                        }
                    }
                }
                .navigationDestination(for: HNItem.self) { StoryDetailView(item: $0) }
                .navigationDestination(for: UserRoute.self) { UserView(username: $0.username) }
        }
        .task {
            vm.configure(river: river, settings: settings)
            await vm.startIfNeeded()
            #if DEBUG
            if LaunchArgs.autoOpenFirst, path.isEmpty, let first = vm.visibleStories.first {
                path.append(first)
            }
            #endif
        }
        // Auto-refresh in the background while the feed is foregrounded.
        .task(id: refreshKey) {
            guard settings.autoRefreshMinutes > 0 else { return }
            let interval = UInt64(settings.autoRefreshMinutes) * 60 * 1_000_000_000
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval)
                guard !Task.isCancelled else { return }
                await vm.checkForNew()
            }
        }
    }

    /// Restart the auto-refresh loop when the interval changes or we return to
    /// the foreground.
    private var refreshKey: String { "\(settings.autoRefreshMinutes)-\(scenePhase == .active)" }

    private var title: String {
        guard case .river = vm.mode else { return vm.mode.title }
        let count = vm.inboxCount
        return count > 0 ? "Hacker River (\(count))" : "Hacker River"
    }

    private var accessibilityTitle: String {
        guard case .river = vm.mode else { return vm.mode.title }
        let count = vm.inboxCount
        return count > 0 ? "Hacker River, \(count) in inbox" : "Hacker River"
    }

    @ViewBuilder private var content: some View {
        switch vm.phase {
        case .loading where vm.stories.isEmpty:
            ScrollView { SkeletonList() }
                .background(Theme.background)
        case .failed(let message) where vm.stories.isEmpty:
            ScrollView {
                ErrorStateView(message: message) { Task { await vm.reload() } }
            }
            .background(Theme.background)
            .refreshable { await vm.reload() }
        default:
            storyList
        }
    }

    private var storyList: some View {
        List {
            if vm.visibleStories.isEmpty {
                EmptyStateView(
                    systemImage: "checkmark.circle",
                    title: "The river is calm",
                    message: "You're all caught up. New stories will flow in — pull to refresh."
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Theme.background)
            }

            ForEach(Array(vm.visibleStories.enumerated()), id: \.element.id) { index, story in
                ZStack {
                    NavigationLink(value: story) { EmptyView() }.opacity(0)
                    StoryRow(item: story, rank: index + 1) {
                        withAnimation { vm.dismiss(story) }
                        Haptics.soft()
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l))
                .listRowSeparatorTint(Theme.separator)
                .listRowBackground(Theme.background)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        bookmarks.toggle(story)
                        Haptics.soft()
                    } label: {
                        Label(bookmarks.isBookmarked(story) ? "Unsave" : "Save",
                              systemImage: bookmarks.isBookmarked(story) ? "bookmark.slash.fill" : "bookmark.fill")
                    }
                    .tint(Theme.upvote)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button {
                        withAnimation { vm.dismiss(story) }
                        Haptics.soft()
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
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .listRowBackground(Theme.background)
                .padding(.vertical, Spacing.s)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .refreshable { await vm.reload() }
    }
}

/// "● N new posts — tap to load" banner shown when background refresh finds
/// stories that aren't in the river yet. Tapping reloads the feed.
struct NewPostsBanner: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "circle.fill")
                    .font(.system(size: 7))
                Text("\(count) new \(count == 1 ? "post" : "posts") — tap to load")
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.s)
            .background(Theme.upvote)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(count) new posts. Tap to load.")
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview {
    FeedView()
        .environment(SettingsStore())
        .environment(BookmarkStore())
        .environment(RiverStore())
}
