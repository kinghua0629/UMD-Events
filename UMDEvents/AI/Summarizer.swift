import Foundation
import FoundationModels

@Generable
struct NewsSummary: Sendable, Equatable {
    @Guide(description: "A concise headline of at most 12 words")
    var headline: String

    @Guide(description: "A 2-3 sentence summary of the most important information for students")
    var summary: String

    @Guide(description: "Up to 3 short key points, such as dates, places, deadlines or actions", .maximumCount(3))
    var keyPoints: [String]
}

enum AIStatus: Sendable, Equatable {
    case available
    case deviceNotEligible
    case notEnabled
    case modelNotReady
    case unavailable

    var isAvailable: Bool { self == .available }

    var message: LocalizedStringResource {
        switch self {
        case .available: "Apple Intelligence is ready. Summaries are generated on this iPhone."
        case .deviceNotEligible: "This device doesn't support Apple Intelligence. Showing original summaries."
        case .notEnabled: "Turn on Apple Intelligence in Settings to get AI summaries."
        case .modelNotReady: "The Apple Intelligence model is still downloading. Showing original summaries for now."
        case .unavailable: "Apple Intelligence is unavailable. Showing original summaries."
        }
    }
}

/// On-device summarization with the Foundation Models framework.
actor Summarizer {
    static let shared = Summarizer()

    nonisolated static var status: AIStatus {
        switch SystemLanguageModel.default.availability {
        case .available: .available
        case .unavailable(.deviceNotEligible): .deviceNotEligible
        case .unavailable(.appleIntelligenceNotEnabled): .notEnabled
        case .unavailable(.modelNotReady): .modelNotReady
        case .unavailable: .unavailable
        }
    }

    nonisolated static var isAvailable: Bool { status.isAvailable }

    /// The system's preferred language if the model supports it, otherwise English.
    nonisolated static var outputLocale: Locale {
        let preferred = Locale(identifier: Locale.preferredLanguages.first ?? "en")
        return SystemLanguageModel.default.supportsLocale(preferred) ? preferred : Locale(identifier: "en")
    }

    nonisolated static func languageName(for locale: Locale) -> String {
        let language = locale.language
        var identifier = language.languageCode?.identifier ?? "en"
        if let script = language.script?.identifier { identifier += "-\(script)" }
        return Locale(identifier: "en_US").localizedString(forIdentifier: identifier) ?? "English"
    }

    func summarize(title: String, text: String) async throws -> NewsSummary {
        let language = Self.languageName(for: Self.outputLocale)
        let instructions = """
        You summarize University of Maryland campus news and events for students. \
        Only use facts stated in the provided article; never invent details. \
        Always write the headline, summary and key points in \(language), \
        even when the article is written in another language.
        """

        var budget = 4_000
        while true {
            let session = LanguageModelSession(instructions: instructions)
            let prompt = """
            Summarize this article.

            Title: \(title)

            Article:
            \(text.prefix(budget))
            """
            do {
                return try await session.respond(to: prompt, generating: NewsSummary.self).content
            } catch let error as LanguageModelSession.GenerationError {
                if case .exceededContextWindowSize = error, budget > 1_000 {
                    budget /= 2
                    continue
                }
                throw error
            }
        }
    }
}
