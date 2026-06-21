import SwiftUI

/// Horizontal, pinned source selector. The first chip is the merged River; the
/// rest focus a single Hacker News feed. Each chip pairs an icon with a label so
/// selection never relies on color alone, and exposes the `.isSelected` trait to
/// VoiceOver.
struct FeedChipBar: View {
    let selection: FeedMode
    let onSelect: (FeedMode) -> Void

    @Environment(SettingsStore.self) private var settings

    private var modes: [FeedMode] { [.river] + Feed.allCases.map(FeedMode.feed) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.s) {
                    ForEach(modes, id: \.self) { mode in
                        chip(mode)
                            .id(mode)
                    }
                }
                .padding(.horizontal, Spacing.l)
                .padding(.vertical, Spacing.m)
            }
            .onChange(of: selection) { _, newValue in
                withAnimation(.easeInOut) { proxy.scrollTo(newValue, anchor: .center) }
            }
        }
        .background(.bar)
        .overlay(alignment: .bottom) {
            Divider().background(Theme.hairline)
        }
    }

    private func chip(_ mode: FeedMode) -> some View {
        let isSelected = mode == selection
        return Button {
            onSelect(mode)
        } label: {
            HStack(spacing: 5) {
                Image(systemName: mode.systemImage)
                    .font(.system(size: 11, weight: .semibold))
                Text(mode.shortTitle)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .padding(.horizontal, Spacing.m)
            .padding(.vertical, 9)
            .foregroundStyle(isSelected ? Color.white : Theme.textSecondary)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? settings.accent.color : Theme.surface)
            )
            .overlay(
                Capsule(style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Theme.separator, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mode.title)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
