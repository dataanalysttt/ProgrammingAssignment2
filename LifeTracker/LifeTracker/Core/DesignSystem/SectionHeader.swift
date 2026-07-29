import SwiftUI

struct SectionHeader: View {
    var title: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.ColorToken.primaryText)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.ColorToken.accent)
            }
        }
    }
}
