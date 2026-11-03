import SwiftData
import SwiftUI

struct FeedListView: View {
    @Environment(AppEnvironment.self) private var environment
    @Query private var articles: [Article]

    init(category: FeedCategory?) {
        let eventsRaw = FeedCategory.events.rawValue
        switch category {
        case .some(.events):
            _articles = Query(filter: #Predicate<Article> { $0.categoryRaw == eventsRaw },
                              sort: [SortDescriptor(\Article.eventStart)])
        case .some(let category):
            let raw = category.rawValue
            _articles = Query(filter: #Predicate<Article> { $0.categoryRaw == raw },
                              sort: [SortDescriptor(\Article.published, order: .reverse)])
        case .none:
            // "All" leaves out events: there are many of them and they have their own tab.
            _articles = Query(filter: #Predicate<Article> { $0.categoryRaw != eventsRaw },
                              sort: [SortDescriptor(\Article.published, order: .reverse)])
        }
    }

    var body: some View {
        List {
            if !Summarizer.isAvailable {
                Section { AIStatusBanner(status: Summarizer.status) }
            }
            ForEach(articles) { article in
                NavigationLink(value: article.id) {
                    ArticleRow(article: article)
                }
            }
        }
        .listStyle(.plain)
        .overlay {
            if articles.isEmpty {
                if environment.isRefreshing {
                    ProgressView("Loading…")
                } else {
                    ContentUnavailableView("No Stories Yet", systemImage: "newspaper",
                                           description: Text("Pull down to refresh."))
                }
            }
        }
    }
}

struct AIStatusBanner: View {
    let status: AIStatus

    var body: some View {
        Label {
            Text(status.message)
        } icon: {
            Image(systemName: status.isAvailable ? "sparkles" : "exclamationmark.triangle")
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
}

struct ArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if !article.isRead {
                    Circle().fill(.tint).frame(width: 8, height: 8)
                }
                Text(article.sourceName)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                if article.hasAISummary {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundStyle(.purple)
                        .accessibilityLabel("AI summary")
                }
                if article.category != .events, !article.dateIsEstimated {
                    Text(article.published, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Text(article.listTitle)
                .font(.headline)
                .lineLimit(3)
            if let start = article.eventStart {
                Label {
                    Text(start, format: .dateTime.weekday(.abbreviated).month().day().hour().minute())
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.subheadline)
                if let location = article.location {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            let summary = article.displaySummary
            if !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}
