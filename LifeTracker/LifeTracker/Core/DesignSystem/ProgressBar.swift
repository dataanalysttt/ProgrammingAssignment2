import SwiftUI

/// A thin, rounded progress bar used for goal completion. Deliberately not a
/// ring/gauge — flat bars read calmer in a list of several goals at once.
struct ProgressBar: View {
    /// 0...1
    var fraction: Double
    var tint: Color = Theme.ColorToken.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ColorToken.secondaryText.opacity(0.15))
                Capsule()
                    .fill(tint)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 8)
    }
}
