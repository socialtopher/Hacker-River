import SwiftUI

/// Three-pane desktop / large-iPad layout: a source-list sidebar (river, feeds +
/// library), a story list, and the discussion detail. Reuses the same rows,
/// detail view, and view models as the iPhone layout.
struct DesktopRootView: View {
    @Environment(SettingsStore.self) private var settings

    // Optional so the single-selection `List(selection:)` resolves to the
    // iOS/Catalyst-available initializer.
    @State private var section: DesktopSection? = .mode(.river)
    @State private var selectedStory: HNItem?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showSettings = false
    @State private var didInit = false

    enum DesktopSection: Hashable {
        case mode(FeedMode)
        case search
        case recentlyRead
        case saved
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            middleColumn
        } detail: {
            detailColumn
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 920, minHeight: 600)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .frame(minWidth: 440, minHeight: 620)
        }
        .onAppear {
            guard !didInit else { return }
            didInit = true
            #if DEBUG
            switch LaunchArgs.initialTab {
            case "search": section = .search
            case "read": section = .recentlyRead
            case "saved": section = .saved
            default: break
            }
            #endif
        }
    }

    // MARK: Sidebar

    private var sidebar: some View {
        List(selection: $section) {
            Section("River") {
                Label("Hacker River", systemImage: "water.waves")
                    .tag(DesktopSection.mode(.river))
            }
            Section("Feeds") {
                ForEach(Feed.allCases) { feed in
                    Label(feed.title, systemImage: feed.systemImage)
                        .tag(DesktopSection.mode(.feed(feed)))
                }
            }
            Section("Library") {
                Label("Search", systemImage: "magnifyingglass")
                    .tag(DesktopSection.search)
                Label("Recently Read", systemImage: "book")
                    .tag(DesktopSection.recentlyRead)
                Label("Saved", systemImage: "bookmark")
                    .tag(DesktopSection.saved)
            }
        }
        .navigationTitle("Hacker River")
        .navigationSplitViewColumnWidth(min: 208, ideal: 240, max: 300)
        .toolbar {
            ToolbarItem {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
                .help("Settings")
                .accessibilityLabel("Settings")
            }
        }
    }

    // MARK: Middle column (story list)

    @ViewBuilder private var middleColumn: some View {
        Group {
            switch section {
            case .mode(let mode):
                DesktopFeedColumn(mode: mode, selection: $selectedStory)
                    .id(mode)
            case .search:
                DesktopSearchColumn(selection: $selectedStory)
            case .recentlyRead:
                DesktopRecentlyReadColumn(selection: $selectedStory)
            case .saved:
                DesktopSavedColumn(selection: $selectedStory)
            case .none:
                DesktopFeedColumn(mode: .river, selection: $selectedStory)
            }
        }
        .navigationSplitViewColumnWidth(min: 320, ideal: 380, max: 520)
    }

    // MARK: Detail column (discussion)

    @ViewBuilder private var detailColumn: some View {
        if let story = selectedStory {
            NavigationStack {
                StoryDetailView(item: story)
                    .navigationDestination(for: UserRoute.self) { UserView(username: $0.username) }
                    .navigationDestination(for: HNItem.self) { StoryDetailView(item: $0) }
            }
            .id(story.id)
        } else {
            ContentUnavailableView {
                Label("Select a story", systemImage: "text.bubble")
            } description: {
                Text("Choose a story from the list to read the discussion.")
            }
            .background(Theme.background)
        }
    }
}
