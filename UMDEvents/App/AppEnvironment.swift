import Foundation
import Observation
import SwiftData

/// App-wide services and refresh state.
@Observable @MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    @ObservationIgnored let container: ModelContainer
    @ObservationIgnored private let pipeline: RefreshPipeline

    private(set) var isRefreshing = false
    private(set) var lastRefresh: Date?
    private(set) var lastFailures: [String: String] = [:]
    /// Pending deep link from a tapped notification.
    var pendingArticleID: String?

    private init() {
        do {
            container = try ModelContainer(for: Article.self)
        } catch {
            print("Persistent store failed (\(error)); falling back to in-memory store")
            container = try! ModelContainer(for: Article.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        }
        pipeline = RefreshPipeline(modelContainer: container)
    }

    var isStale: Bool {
        guard let lastRefresh else { return true }
        return Date().timeIntervalSince(lastRefresh) > 15 * 60
    }

    func refresh(summarizeLimit: Int) async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }

        let settings = AppSettings.shared
        let report = await pipeline.refresh(
            sources: settings.enabledSources,
            knownSourceIDs: settings.knownSourceIDs,
            notifyCategories: settings.notifyCategories,
            summarizeLimit: summarizeLimit)
        settings.knownSourceIDs.formUnion(report.succeededSourceIDs)
        lastFailures = report.failures
        lastRefresh = .now
    }

    /// On-demand summary for the article currently on screen.
    func summarize(_ article: Article) async {
        guard Summarizer.isAvailable, !article.hasAISummary else { return }
        if !article.enriched {
            article.enriched = true
            if article.needsPageFetch, let url = article.link,
               let page = try? await ArticleTextExtractor.fetch(url) {
                article.apply(page: page)
            }
        }
        do {
            let summary = try await Summarizer.shared.summarize(title: article.title, text: article.textForSummary)
            article.apply(summary: summary, language: Summarizer.outputLocale.identifier)
        } catch {
            article.summaryAttempts += 1
        }
        try? container.mainContext.save()
    }

    func deleteArticles(fromSource sourceID: String) {
        try? container.mainContext.delete(model: Article.self, where: #Predicate { $0.sourceID == sourceID })
        try? container.mainContext.save()
    }
}
