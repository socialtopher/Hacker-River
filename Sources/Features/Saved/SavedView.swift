import SwiftUI

struct SavedView: View {
    @Environment(BookmarkStore.self) private var bookmarks
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if bookmarks.items.isEmpty {
                    EmptyStateView(
                        systemImage: "bookmark",
                        title: "Nothing saved yet",
                        message: "Swipe a story or tap the bookmark icon to keep it here for later."
                    )
                    .background(Theme.background)
                } else {
                    list
                }
            }
            .navigationTitle("Saved")
            .toolbar {
                if !bookmarks.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                withAnimation { bookmarks.removeAll() }
                                Haptics.warning()
                            } label: {
                                Label("Remove All", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("Saved options")
                    }
                }
            }
            .navigationDestination(for: HNItem.self) { StoryDetailView(item: $0) }
            .navigationDestination(for: UserRoute.self) { UserView(username: $0.username) }
        }
    }

    private var list: some View {
        List {
            ForEach(bookmarks.items) { story in
                ZStack {
                    NavigationLink(value: story) { EmptyView() }.opacity(0)
                    StoryRow(item: story)
                }
                .padding(.horizontal, Spacing.l)
                .riverGlassCard()
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { bookmarks.remove(story.id) }
                        Haptics.soft()
                    } label: {
                        Label("Remove", systemImage: "bookmark.slash.fill")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Theme.background)
        .contentMargins(.vertical, Spacing.s, for: .scrollContent)
    }
}
