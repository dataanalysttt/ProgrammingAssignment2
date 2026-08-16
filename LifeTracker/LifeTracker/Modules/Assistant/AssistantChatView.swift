import SwiftUI
import SwiftData

/// A chat window over your own data, answered entirely on-device via Apple's
/// Foundation Models framework — no network call is ever made. The model only
/// sees a compact summary of what's in the app (see AssistantContextBuilder),
/// so it can't answer from outside knowledge even if asked to.
struct AssistantChatView: View {
    @StateObject private var service = AssistantService()
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var moduleSettings: ModuleSettingsStore

    @State private var draft = ""
    @State private var isLoadingContext = true

    var body: some View {
        VStack(spacing: 0) {
            if let availabilityMessage = service.availabilityMessage {
                EmptyStateView(
                    systemImage: "sparkles",
                    title: "Assistant Unavailable",
                    message: availabilityMessage
                )
                .frame(maxHeight: .infinity)
            } else if isLoadingContext {
                ProgressView()
                    .frame(maxHeight: .infinity)
            } else {
                messageList
                inputBar
            }
        }
        .background(Theme.ColorToken.background)
        .navigationTitle("Assistant")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await loadContext() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(isLoadingContext)
            }
        }
        .task {
            await loadContext()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    if service.messages.isEmpty {
                        EmptyStateView(
                            systemImage: "bubble.left.and.bubble.right",
                            title: "Ask about your data",
                            message: "Runs entirely on-device — nothing you type ever leaves this phone. Try \"How's my sleep been this week?\" or \"What are my active goals?\""
                        )
                        .padding(.top, Theme.Spacing.xl)
                    }
                    ForEach(service.messages) { message in
                        bubble(for: message)
                            .id(message.id)
                    }
                    if service.isResponding {
                        HStack(spacing: Theme.Spacing.sm) {
                            ProgressView()
                            Text("Thinking…")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.ColorToken.secondaryText)
                        }
                    }
                }
                .padding(Theme.Spacing.md)
            }
            .onChange(of: service.messages.count) { _, _ in
                guard let last = service.messages.last else { return }
                withAnimation {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }

    private func bubble(for message: AssistantService.ChatMessage) -> some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .font(Theme.Typography.body)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .foregroundStyle(message.role == .user ? Color.white : Theme.ColorToken.primaryText)
                .background(
                    message.role == .user ? Theme.ColorToken.accent : Theme.ColorToken.cardBackground,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.control, style: .continuous)
                )
            if message.role == .assistant { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            TextField("Ask about your data…", text: $draft, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
            Button {
                let text = draft
                draft = ""
                Task { await service.send(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || service.isResponding)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.ColorToken.background)
    }

    private func loadContext() async {
        isLoadingContext = true
        let summary = await AssistantContextBuilder.build(context: context, moduleSettings: moduleSettings)
        service.refreshContext(summary)
        isLoadingContext = false
    }
}
