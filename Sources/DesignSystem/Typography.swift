import SwiftUI

/// The bundled reading typeface. `Font.custom` falls back to the system font
/// automatically if it isn't available, so every call site is safe.
enum Typeface {
    static let reader = "Inter"
}

extension Font {
    /// Inter at a fixed point size that still scales with Dynamic Type via the
    /// given text style.
    static func reader(_ size: CGFloat,
                       _ weight: Font.Weight = .regular,
                       relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(Typeface.reader, size: size, relativeTo: style).weight(weight)
    }

    /// Rounded brand font that still scales with Dynamic Type.
    static func brand(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

/// Centralized type scale. Reading text (titles, body, comments) uses Inter for
/// a clean, modern reading feel; dense metadata and code stay on the system
/// fonts where they render crispest at small sizes.
enum AppFont {
    // Brand / large display
    static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let navTitle = Font.system(.title3, design: .rounded).weight(.bold)

    // Reading text — Inter
    static let articleTitle = Font.reader(23, .bold, relativeTo: .title2)
    static let storyTitle = Font.reader(16.5, .semibold, relativeTo: .headline)
    static let storyTitleCompact = Font.reader(15, .semibold, relativeTo: .subheadline)
    static let body = Font.reader(16, .regular, relativeTo: .callout)
    static let comment = Font.reader(15.5, .regular, relativeTo: .callout)

    // Metadata / chrome — system
    static let meta = Font.system(.caption).weight(.medium)
    static let metaStrong = Font.system(.caption).weight(.semibold)
    static let mono = Font.system(.footnote, design: .monospaced)

    /// Comfortable leading for running reading text.
    static let readingLineSpacing: CGFloat = 4
}
