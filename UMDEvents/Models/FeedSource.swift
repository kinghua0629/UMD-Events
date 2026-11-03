import Foundation

enum FeedCategory: String, Codable, CaseIterable, Identifiable, Sendable {
    case news
    case events
    case sports
    case department

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .news: "News"
        case .events: "Events"
        case .sports: "Sports"
        case .department: "Departments"
        }
    }

    var symbol: String {
        switch self {
        case .news: "newspaper"
        case .events: "calendar"
        case .sports: "sportscourt"
        case .department: "building.columns"
        }
    }
}

/// Rule for scraping a list page that has no RSS feed: every `<a>` whose absolute URL
/// matches `linkPattern` is treated as an article. If the anchor has an `aria-label`
/// starting with `titlePrefix` (e.g. "Read More about "), the rest is used as the title.
struct HTMLListRule: Codable, Hashable, Sendable {
    var linkPattern: String
    var titlePrefix: String?
}

enum FeedKind: Codable, Hashable, Sendable {
    case rss
    case ical
    case htmlList(HTMLListRule)
}

struct FeedSource: Codable, Hashable, Identifiable, Sendable {
    var id: String
    var name: String
    var url: URL
    var kind: FeedKind
    var category: FeedCategory
    var isCustom: Bool = false
}

/// A normalized item produced by any parser, before it is stored.
struct FetchedItem: Sendable, Equatable {
    var sourceID: String
    var guid: String
    var title: String
    var link: URL?
    var published: Date?
    var summary: String
    var content: String?
    var eventStart: Date?
    var eventEnd: Date?
    var location: String?

    var articleID: String { "\(sourceID)|\(guid)" }
}
