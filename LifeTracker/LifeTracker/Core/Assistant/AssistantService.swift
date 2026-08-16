import Foundation
import FoundationModels

/// Wraps Apple's on-device Foundation Models framework (Apple Intelligence) so
/// the Assistant module can answer questions using nothing but a summary of
/// your own data (see AssistantContextBuilder). The model itself runs entirely
/// on this phone — no network request is ever made, on-brand with the rest of
/// this app's "everything stays local" rule.
@MainActor
final class AssistantService: ObservableObject {
    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: Role
        var text: String

        enum Role { case user, assistant }
    }

    @Published private(set) var messages: [ChatMessage] = []
    @Published private(set) var isResponding = false

    private var session: LanguageModelSession?

    var availabilityMessage: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence, so the on-device assistant can't run here."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Turn on Apple Intelligence in Settings > Apple Intelligence & Siri to use the assistant."
        case .unavailable(.modelNotReady):
            return "The on-device model is still downloading. Try again in a bit."
        case .unavailable:
            return "The on-device assistant isn't available right now."
        }
    }

    var isAvailable: Bool { availabilityMessage == nil }

    /// Starts (or restarts) a session grounded in a fresh snapshot of your data.
    /// Call this whenever the chat is opened, and again if you want the
    /// assistant to see anything you've logged since the conversation started.
    func refreshContext(_ dataSummary: String) {
        let instructions = """
        You are the built-in assistant for Life Tracker, a private, on-device \
        personal tracking app. Answer questions using ONLY the data provided \
        below about the user's own trackers, goals, food, investments, and \
        health metrics. Never use outside knowledge, never guess, and never \
        make up a number that isn't in the data. If the answer isn't in the \
        data, say plainly that you don't have that information yet rather \
        than inventing an answer. Be concise and conversational.

        DATA:
        \(dataSummary)
        """
        session = LanguageModelSession(instructions: instructions)
        messages.removeAll()
    }

    func send(_ text: String) async {
        guard let session else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(ChatMessage(role: .user, text: trimmed))
        isResponding = true
        defer { isResponding = false }

        do {
            let response = try await session.respond(to: trimmed)
            messages.append(ChatMessage(role: .assistant, text: response.content))
        } catch {
            messages.append(ChatMessage(
                role: .assistant,
                text: "Sorry, I couldn't answer that: \(error.localizedDescription)"
            ))
        }
    }
}
