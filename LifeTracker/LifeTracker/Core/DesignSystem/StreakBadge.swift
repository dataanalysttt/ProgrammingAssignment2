import SwiftUI

struct StreakBadge: View {
    var days: Int

    var body: some View {
        if days > 0 {
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.caption2)
                Text("\(days)")
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.orange)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.12), in: Capsule())
        }
    }
}
