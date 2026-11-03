import SwiftData
import SwiftUI

struct FeedListView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppSettings.self) private var settings
    @Query private var articles: [Article]
    private let category: FeedCategory?
    private let globalSearch: Bool
    @State private var searchText = ""
    @State private var filters = FeedFilters()

    private var visibleArticles: [Article] {
        articles.filter { article in
            (globalSearch || category != nil || settings.interests.contains(article.category))
                && filters.matches(article, searchText: searchText)
        }
    }

    private var sources: [String] { Array(Set(articles.map(\.sourceName))).sorted() }

    init(category: FeedCategory?, globalSearch: Bool = false) {
        self.category = category
        self.globalSearch = globalSearch
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
            _articles = Query(sort: [SortDescriptor(\Article.published, order: .reverse)])
        }
    }

    var body: some View {
        List {
            if !Summarizer.isAvailable {
                Section { AIStatusBanner(status: Summarizer.status) }
            }
            ForEach(visibleArticles) { article in
                NavigationLink(value: article.id) {
                    ArticleRow(article: article)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: globalSearch ? "Search all content" : "Search this section")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Picker("Source", selection: $filters.source) {
                        Text("All Sources").tag("")
                        ForEach(sources, id: \.self) { Text($0).tag($0) }
                    }
                    Picker("Reading Status", selection: $filters.readState) {
                        Text("All Stories").tag(FeedFilters.ReadState.all)
                        Text("Unread").tag(FeedFilters.ReadState.unread)
                        Text("Read").tag(FeedFilters.ReadState.read)
                    }
                    Picker("Time Range", selection: $filters.period) {
                        Text("Any Time").tag(FeedFilters.Period.any)
                        Text("Past 7 Days").tag(FeedFilters.Period.week)
                        Text("Past 30 Days").tag(FeedFilters.Period.month)
                        Text("Upcoming Events").tag(FeedFilters.Period.upcoming)
                    }
                    if globalSearch {
                        Picker("Category", selection: $filters.category) {
                            Text("All").tag("")
                            ForEach(FeedCategory.allCases) { Text($0.title).tag($0.rawValue) }
                        }
                    }
                    Button("Reset Filters") { filters = FeedFilters() }
                } label: {
                    Label("Filters", systemImage: filters.isActive
                          ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .overlay {
            if visibleArticles.isEmpty {
                if environment.isRefreshing && articles.isEmpty {
                    ProgressView("Loading…")
                } else if !searchText.isEmpty || filters.isActive {
                    ContentUnavailableView("No Results", systemImage: "magnifyingglass",
                                           description: Text("Try another keyword or reset the filters."))
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
