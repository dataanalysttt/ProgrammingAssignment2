import SwiftUI

/// Shared visual constants. Colors mostly resolve to system semantic colors so
/// light/dark mode and accessibility settings are respected automatically —
/// the one custom color is the accent, defined in Assets.xcassets/AccentColor
/// so it can be re-tinted in one place without touching code.
enum Theme {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 18
        static let control: CGFloat = 12
    }

    enum ColorToken {
        static let accent = Color.accentColor
        static let background = Color(uiColor: .systemGroupedBackground)
        static let cardBackground = Color(uiColor: .secondarySystemGroupedBackground)
        static let primaryText = Color.primary
        static let secondaryText = Color.secondary
        static let positive = Color.green
        static let negative = Color.red
    }

    enum Typography {
        static let largeTitle = Font.system(.largeTitle, design: .rounded, weight: .semibold)
        static let title = Font.system(.title2, design: .rounded, weight: .semibold)
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let caption = Font.system(.caption, design: .default)
    }
}
