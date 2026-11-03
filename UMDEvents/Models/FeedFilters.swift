import Foundation

struct FeedFilters {
    enum ReadState: Hashable { case all, unread, read }
    enum Period: Hashable { case any, week, month, upcoming }

    var source = ""
    var category = ""
    var readState: ReadState = .all
    var period: Period = .any

    var isActive: Bool {
        !source.isEmpty || !category.isEmpty || readState != .all || period != .any
    }

    func matches(_ article: Article, searchText: String, now: Date = .now) -> Bool {
        guard source.isEmpty || article.sourceName == source,
              category.isEmpty || article.categoryRaw == category else { return false }
        if readState == .read && !article.isRead { return false }
        if readState == .unread && article.isRead { return false }
        switch period {
        case .any: break
        case .week, .month:
            let days = period == .week ? 7 : 30
            let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: now) ?? now
            let date = article.eventStart ?? article.published
            guard date >= cutoff && date <= now else { return false }
        case .upcoming:
            guard let start = article.eventStart, start >= now else { return false }
        }
        let terms = searchText.split(whereSeparator: { $0.isWhitespace })
        let text = [article.title, article.listTitle, article.rawSummary, article.aiSummary ?? "",
                    article.content ?? "", article.translatedSummary ?? "", article.sourceName,
                    article.location ?? ""].joined(separator: " ")
        return terms.allSatisfy { text.localizedStandardContains(String($0)) }
    }
}
