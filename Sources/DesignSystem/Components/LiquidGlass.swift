import SwiftUI

/// A small compatibility layer that uses the system Liquid Glass renderer on
/// iOS 26 and keeps the same translucent hierarchy on earlier releases.
struct RiverGlassCapsule: ViewModifier {
    var interactive = false

    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            content.glassEffect(interactive ? .regular.interactive() : .regular, in: .capsule)
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay {
                Capsule(style: .continuous)
                    .strokeBorder(.white.opacity(0.18), lineWidth: 0.5)
            }
    }
}

struct RiverGlassCard: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
#if compiler(>=6.2)
        if #available(iOS 26.0, macCatalyst 26.0, *) {
            content.glassEffect(.regular, in: .rect(cornerRadius: Radius.l))
        } else {
            fallback(content)
        }
#else
        fallback(content)
#endif
    }

    private func fallback(_ content: Content) -> some View {
        content
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Radius.l, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.l, style: .continuous)
                    .strokeBorder(Theme.separator, lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

extension View {
    func riverGlassCapsule(interactive: Bool = false) -> some View {
        modifier(RiverGlassCapsule(interactive: interactive))
    }

    func riverGlassCard() -> some View {
        modifier(RiverGlassCard())
    }
}
