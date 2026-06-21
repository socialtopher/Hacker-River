import SwiftUI

/// Stories you've read recently, kept for the "Keep Read For" window before they
/// flow out of the river for good. The web app's collapsed "Recently Read"
/// section, promoted to its own screen.
struct RecentlyReadView: View {
    @Environment(RiverStore.self) private var river
    @Environment(SettingsStore.self) private var settings
    @State private var path = NavigationPath()

    private var items: [HNItem] {
        river.recentlyRead(now: Date(), tappedTTL: settings.tappedTTL)
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if items.isEmpty {
                    EmptyStateView(
                        systemImage: "book.closed",
                        title: "Nothing read yet",
                        message: "Stories you open flow here and stay for a while, so you can find your way back."
                    )
                    .background(Theme.background)
                } else {
                    list
                }
            }
            .navigationTitle("Recently Read")
            .toolbar {
                if !items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                withAnimation {
                                    for item in items { river.markDismissed(item.id) }
                                }
                                Haptics.warning()
                            } label: {
                                Label("Clear Recently Read", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Recently Read options")
                    }
                }
            }
            .navigationDestination(for: HNItem.self) { StoryDetailView(item: $0) }
            .navigationDestination(for: UserRoute.self) { UserView(username: $0.username) }
        }
    }

    private var list: some View {
        List {
            ForEach(items) { story in
                ZStack {
                    NavigationLink(value: story) { EmptyView() }.opacity(0)
                    StoryRow(item: story)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: Spacing.l, bottom: 0, trailing: Spacing.l))
                .listRowSeparatorTint(Theme.separator)
                .listRowBackground(Theme.background)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { river.markDismissed(story.id) }
                        Haptics.soft()
                    } label: {
                        Label("Remove", systemImage: "xmark")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        withAnimation { river.markUnread(story.id) }
                        Haptics.soft()
                    } label: {
                        Label("Back to River", systemImage: "arrow.uturn.backward")
                    }
                    .tint(Theme.link)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }
}

#Preview {
    RecentlyReadView()
        .environment(RiverStore())
        .environment(SettingsStore())
        .environment(BookmarkStore())
}
