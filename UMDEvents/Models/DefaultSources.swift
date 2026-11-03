import Foundation

enum DefaultSources {
    static let all: [FeedSource] = [
        FeedSource(
            id: "maryland-today",
            name: "Maryland Today",
            url: URL(string: "https://today.umd.edu/")!,
            kind: .htmlList(HTMLListRule(
                linkPattern: #"^https://today\.umd\.edu/[a-z0-9]+(-[a-z0-9]+){3,}$"#,
                titlePrefix: "Read More about "
            )),
            category: .news
        ),
        FeedSource(
            id: "diamondback",
            name: "The Diamondback",
            url: URL(string: "https://dbknews.com/feed/")!,
            kind: .rss,
            category: .news
        ),
        FeedSource(
            id: "terplink-events",
            name: "TerpLink Events",
            url: URL(string: "https://terplink.umd.edu/events.ics")!,
            kind: .ical,
            category: .events
        ),
        FeedSource(
            id: "umterps",
            name: "Maryland Athletics",
            url: URL(string: "https://umterps.com/rss?path=general")!,
            kind: .rss,
            category: .sports
        ),
        FeedSource(
            id: "umd-cs",
            name: "UMD Computer Science",
            url: URL(string: "https://www.cs.umd.edu/feeds/news/all")!,
            kind: .rss,
            category: .department
        ),
        FeedSource(
            id: "umd-eng",
            name: "Clark School of Engineering",
            url: URL(string: "https://eng.umd.edu/news")!,
            kind: .htmlList(HTMLListRule(
                linkPattern: #"^https://eng\.umd\.edu/news/story/[^/?#]+$"#,
                titlePrefix: "Read more about "
            )),
            category: .department
        ),
    ]
}
