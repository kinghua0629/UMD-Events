import Foundation
import SwiftData

struct RefreshReport: Sendable {
    var newCount = 0
    var summarizedCount = 0
    var succeededSourceIDs: Set<String> = []
    var failures: [String: String] = [:]
}

/// Fetch → store → enrich/summarize → notify. Runs on its own SwiftData context so it
/// works the same from the foreground and from a background refresh task.
@ModelActor
actor RefreshPipeline {
    func refresh(sources: [FeedSource], knownSourceIDs: Set<String>,
                 notifyCategories: Set<FeedCategory>, summarizeLimit: Int) async -> RefreshReport {
        let fetched = await FeedFetcher().fetchAll(sources)
        var report = RefreshReport(succeededSourceIDs: fetched.succeededSourceIDs, failures: fetched.failures)

        let sourcesByID = Dictionary(sources.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        var seen = Set(((try? modelContext.fetch(FetchDescriptor<Article>())) ?? []).map(\.id))
        let now = Date()
        for item in fetched.items {
            guard let source = sourcesByID[item.sourceID], seen.insert(item.articleID).inserted else { continue }
            let article = Article(item: item, source: source, now: now)
            // The first time a source is fetched, don't notify for its whole backlog.
            article.notified = !knownSourceIDs.contains(source.id)
            modelContext.insert(article)
            report.newCount += 1
        }
        prune(now: now)
        try? modelContext.save()

        await fillMissingDates()

        report.summarizedCount = await enrichAndSummarize(limit: summarizeLimit)
        await notify(categories: notifyCategories)
        return report
    }

    // MARK: - Steps

    private func enrichAndSummarize(limit: Int) async -> Int {
        guard limit > 0 else { return 0 }
        let eventsRaw = FeedCategory.events.rawValue
        let aiAvailable = Summarizer.isAvailable

        var descriptor: FetchDescriptor<Article>
        if aiAvailable {
            descriptor = FetchDescriptor(
                predicate: #Predicate { $0.aiSummary == nil && $0.summaryAttempts < 2 && $0.categoryRaw != eventsRaw },
                sortBy: [SortDescriptor(\.published, order: .reverse)])
        } else {
            descriptor = FetchDescriptor(
                predicate: #Predicate { !$0.enriched && $0.categoryRaw != eventsRaw },
                sortBy: [SortDescriptor(\.published, order: .reverse)])
        }
        descriptor.fetchLimit = limit
        guard let articles = try? modelContext.fetch(descriptor) else { return 0 }

        var summarized = 0
        for article in articles {
            if Task.isCancelled { break }
            if !article.enriched {
                article.enriched = true
                if article.needsPageFetch, let url = article.link,
                   let page = try? await ArticleTextExtractor.fetch(url) {
                    article.apply(page: page)
                }
            }
            if aiAvailable, !Task.isCancelled {
                do {
                    let summary = try await Summarizer.shared.summarize(title: article.title, text: article.textForSummary)
                    article.apply(summary: summary, language: Summarizer.outputLocale.identifier)
                    summarized += 1
                } catch {
                    article.summaryAttempts += 1
                }
            }
            try? modelContext.save()
        }
        return summarized
    }

    /// Scraped listings have no dates, so fetch those article pages right away (in parallel,
    /// no AI involved) to get real publish dates, descriptions and body text.
    private func fillMissingDates() async {
        var descriptor = FetchDescriptor<Article>(predicate: #Predicate { $0.dateIsEstimated && !$0.enriched })
        descriptor.fetchLimit = 40
        guard let articles = try? modelContext.fetch(descriptor), !articles.isEmpty else { return }

        let targets = articles.compactMap { a in a.link.map { (a.id, $0) } }
        let pages = await withTaskGroup(of: (String, ArticlePage?).self) { group in
            for (id, url) in targets {
                group.addTask { (id, try? await ArticleTextExtractor.fetch(url)) }
            }
            var result: [String: ArticlePage] = [:]
            for await (id, page) in group { if let page { result[id] = page } }
            return result
        }
        for article in articles {
            article.enriched = true
            if let page = pages[article.id] { article.apply(page: page) }
        }
        try? modelContext.save()
    }

    private func notify(categories: Set<FeedCategory>) async {
        let descriptor = FetchDescriptor<Article>(
            predicate: #Predicate { !$0.notified },
            sortBy: [SortDescriptor(\.published, order: .reverse)])
        guard let pending = try? modelContext.fetch(descriptor), !pending.isEmpty else { return }

        let aiAvailable = Summarizer.isAvailable
        let now = Date()
        var items: [NotificationItem] = []
        for article in pending {
            guard categories.contains(article.category) else {
                article.notified = true
                continue
            }
            // Wait for the AI summary unless it can't come (or is taking too long).
            let ready = article.hasAISummary || !aiAvailable || article.summaryAttempts >= 2
                || article.category == .events || now.timeIntervalSince(article.firstSeen) > 6 * 3600
            guard ready else { continue }
            article.notified = true
            items.append(NotificationItem(id: article.id, title: article.title,
                                          body: article.displaySummary, source: article.sourceName))
        }
        try? modelContext.save()
        await Notifier.post(items)
    }

    private func prune(now: Date) {
        let eventsRaw = FeedCategory.events.rawValue
        let cutoff = now.addingTimeInterval(-60 * 86_400)
        try? modelContext.delete(model: Article.self,
                                 where: #Predicate { $0.categoryRaw != eventsRaw && $0.firstSeen < cutoff })

        let eventCutoff = now.addingTimeInterval(-86_400)
        let events = (try? modelContext.fetch(FetchDescriptor<Article>(predicate: #Predicate { $0.categoryRaw == eventsRaw }))) ?? []
        for event in events where (event.eventEnd ?? event.eventStart ?? now) < eventCutoff {
            modelContext.delete(event)
        }
    }
}
