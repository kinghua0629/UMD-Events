import Foundation
import SwiftData

@Model
final class Article {
    @Attribute(.unique) var id: String
    var sourceID: String
    var sourceName: String
    var categoryRaw: String
    var title: String
    var linkString: String?
    var published: Date
    var firstSeen: Date
    var eventStart: Date?
    var eventEnd: Date?
    var location: String?

    /// Short description from the feed (or og:description), plain text.
    var rawSummary: String
    /// Longer plain-text body used as input for summarization.
    var content: String?

    var aiHeadline: String?
    var aiSummary: String?
    var aiKeyPoints: [String] = []
    var aiLanguage: String?
    var summaryAttempts: Int = 0

    /// On-device translation of the original title/summary (see TranslationSupport).
    var translatedTitle: String?
    var translatedSummary: String?
    var translationLanguage: String?

    /// True when the feed had no date and `published` is just the first-seen time.
    var dateIsEstimated: Bool = false
    var enriched: Bool = false
    var isRead: Bool = false
    var notified: Bool = false

    init(item: FetchedItem, source: FeedSource, now: Date = .now) {
        id = item.articleID
        sourceID = source.id
        sourceName = source.name
        categoryRaw = source.category.rawValue
        title = item.title
        linkString = item.link?.absoluteString
        published = min(item.published ?? now, now)
        dateIsEstimated = item.published == nil && item.eventStart == nil
        firstSeen = now
        eventStart = item.eventStart
        eventEnd = item.eventEnd
        location = item.location
        rawSummary = item.summary
        content = item.content
    }

    var category: FeedCategory { FeedCategory(rawValue: categoryRaw) ?? .news }
    var link: URL? { linkString.flatMap(URL.init(string:)) }
    var hasAISummary: Bool { aiSummary != nil }

    /// Summary shown when no AI summary exists.
    var fallbackSummary: String {
        if !rawSummary.isEmpty { return rawSummary }
        if let content, !content.isEmpty { return String(content.prefix(400)) }
        return ""
    }

    var displaySummary: String { aiSummary ?? fallbackSummary }

    /// True if a translation exists for the given language key.
    func hasTranslation(for languageKey: String) -> Bool {
        translationLanguage == languageKey && translatedTitle != nil
    }

    /// Title for lists: the translation into the current system language when there is one.
    var listTitle: String {
        hasTranslation(for: TranslationSupport.targetKey) ? translatedTitle ?? title : title
    }

    func apply(translatedTitle: String?, summary: String?, language: String) {
        self.translatedTitle = translatedTitle
        self.translatedSummary = summary
        translationLanguage = language
    }

    var textForSummary: String {
        if let content, content.count > rawSummary.count { return content }
        return rawSummary
    }

    /// Whether fetching the article page would add useful text.
    var needsPageFetch: Bool {
        guard category != .events, link != nil else { return false }
        return (content?.count ?? 0) < 600 || rawSummary.isEmpty || titleLooksTruncated
    }

    private var titleLooksTruncated: Bool { title.hasSuffix("...") || title.hasSuffix("…") }

    func apply(page: ArticlePage) {
        if page.body.count > (content?.count ?? 0) { content = page.body }
        if rawSummary.isEmpty, let description = page.description, !description.isEmpty {
            rawSummary = description
        }
        if dateIsEstimated, let date = page.published, date <= .now {
            published = date
            dateIsEstimated = false
        }
        if titleLooksTruncated, let pageTitle = page.title, !pageTitle.isEmpty {
            title = pageTitle
        }
    }

    func apply(summary: NewsSummary, language: String) {
        aiHeadline = summary.headline
        aiSummary = summary.summary
        aiKeyPoints = summary.keyPoints
        aiLanguage = language
    }
}
