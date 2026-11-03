import Foundation
import Translation

/// On-device translation (Apple Translation framework) of the original English text into
/// the system language. AI summaries are already generated in the system language, so this
/// covers what the AI doesn't rewrite: titles and original summaries.
enum TranslationSupport {
    /// All built-in UMD sources publish in English.
    static let sourceLanguage = Locale.Language(identifier: "en")

    static var targetLanguage: Locale.Language {
        Locale.Language(identifier: Locale.preferredLanguages.first ?? "en")
    }

    /// Stable key stored with a translation so a later system-language change invalidates it.
    static var targetKey: String { targetLanguage.minimalIdentifier }

    /// Only offer translation when the system language isn't English.
    static var isNeeded: Bool { targetLanguage.languageCode != .english }

    /// False when Apple doesn't support this language pair at all. A pair that is supported
    /// but not downloaded yet still returns true: the system asks the user to download it.
    static func isSupported() async -> Bool {
        let status = await LanguageAvailability().status(from: sourceLanguage, to: targetLanguage)
        return status != .unsupported
    }

    static func configuration() -> TranslationSession.Configuration {
        TranslationSession.Configuration(source: sourceLanguage, target: targetLanguage)
    }
}
