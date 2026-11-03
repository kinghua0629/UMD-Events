import Foundation
import Testing
@testable import UMDEvents

struct RSSParserTests {
    @Test func parsesRSS2WithCDATAAndEntities() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:content="http://purl.org/rss/1.0/modules/content/">
        <channel><title>The Diamondback</title>
        <item>
          <title>Maryland men&#8217;s basketball wins opener</title>
          <link>https://dbknews.com/2026/11/02/recap/</link>
          <guid isPermaLink="false">https://dbknews.com/?p=123</guid>
          <pubDate>Tue, 03 Nov 2026 02:31:33 +0000</pubDate>
          <description><![CDATA[<p>The Terps beat Bucknell <b>96-67</b>.</p>]]></description>
          <content:encoded><![CDATA[<p>Full story paragraph one.</p><p>Paragraph two.</p>]]></content:encoded>
        </item>
        <item><title>Second</title><link>https://dbknews.com/b/</link></item>
        </channel></rss>
        """
        let items = try RSSParser.parse(Data(xml.utf8), sourceID: "dbk")
        #expect(items.count == 2)
        let first = try #require(items.first)
        #expect(first.title == "Maryland men\u{2019}s basketball wins opener")
        #expect(first.link == URL(string: "https://dbknews.com/2026/11/02/recap/"))
        #expect(first.guid == "https://dbknews.com/?p=123")
        #expect(first.summary == "The Terps beat Bucknell 96-67.")
        #expect(first.content == "Full story paragraph one.\nParagraph two.")
        #expect(first.published == Date(timeIntervalSince1970: 1_793_673_093))
        #expect(items[1].guid == "https://dbknews.com/b/")
    }

    @Test func parsesAtom() throws {
        let xml = """
        <feed xmlns="http://www.w3.org/2005/Atom">
          <entry>
            <title>Atom Story</title>
            <link rel="alternate" href="https://example.edu/story"/>
            <id>tag:example.edu,2026:1</id>
            <updated>2026-11-01T12:00:00Z</updated>
            <summary>Short &amp; sweet</summary>
          </entry>
        </feed>
        """
        let item = try #require(try RSSParser.parse(Data(xml.utf8), sourceID: "x").first)
        #expect(item.title == "Atom Story")
        #expect(item.link == URL(string: "https://example.edu/story"))
        #expect(item.guid == "tag:example.edu,2026:1")
        #expect(item.summary == "Short & sweet")
        #expect(item.published == ISO8601DateFormatter().date(from: "2026-11-01T12:00:00Z"))
    }

    @Test func throwsOnGarbage() {
        #expect(throws: (any Error).self) { try RSSParser.parse(Data("<html><p>nope".utf8), sourceID: "x") }
    }
}

struct ICalParserTests {
    let ics = """
    BEGIN:VCALENDAR\r
    VERSION:2.0\r
    BEGIN:VEVENT\r
    CATEGORIES:Arts\r
    DESCRIPTION:These practices are the space and time we use to rehearse our \r
     dances. \\n\\nHosted by: Unbound Dance Team\\n\\nAdditional Information can b\r
     e found at: https://terplink.umd.edu/event/12707368\r
    DTEND:20261103T041500Z\r
    DTSTART:20261103T014500Z\r
    LOCATION:Eppley Recreation Center\r
    SUMMARY:Unbound Practices\r
    UID:https://terplink.umd.edu/event/12707368\r
    URL:https://terplink.umd.edu/event/12707368\r
    END:VEVENT\r
    BEGIN:VEVENT\r
    DTSTART;TZID=America/New_York:20261104T120000\r
    SUMMARY:Lunch\\, with friends\r
    UID:lunch-1\r
    END:VEVENT\r
    BEGIN:VEVENT\r
    DTSTART:20261001T120000Z\r
    DTEND:20261001T130000Z\r
    SUMMARY:Past event\r
    UID:past\r
    END:VEVENT\r
    BEGIN:VEVENT\r
    DTSTART:20260901T040000Z\r
    DTEND:20261231T040000Z\r
    SUMMARY:Semester-long club operations\r
    UID:long-running\r
    END:VEVENT\r
    BEGIN:VEVENT\r
    DTSTART:20261201T120000Z\r
    SUMMARY:Too far away\r
    UID:far\r
    END:VEVENT\r
    END:VCALENDAR\r
    """

    let now = ISO8601DateFormatter().date(from: "2026-11-03T00:00:00Z")!

    @Test func parsesUpcomingEventsWithinHorizon() throws {
        let items = ICalParser.parse(ics, sourceID: "tl", now: now)
        #expect(items.map(\.guid) == ["https://terplink.umd.edu/event/12707368", "lunch-1"])

        let first = items[0]
        #expect(first.title == "Unbound Practices")
        #expect(first.location == "Eppley Recreation Center")
        #expect(first.link == URL(string: "https://terplink.umd.edu/event/12707368"))
        #expect(first.eventStart == ISO8601DateFormatter().date(from: "2026-11-03T01:45:00Z"))
        #expect(first.summary == "These practices are the space and time we use to rehearse our dances.\n\nHosted by: Unbound Dance Team")

        #expect(items[1].title == "Lunch, with friends")
        // 12:00 Eastern (EST, UTC-5) on Nov 4.
        #expect(items[1].eventStart == ISO8601DateFormatter().date(from: "2026-11-04T17:00:00Z"))
    }

    @Test func unfoldsLines() {
        #expect(ICalParser.unfold("A:one\r\n two\r\nB:x") == ["A:onetwo", "B:x"])
    }
}

struct HTMLTests {
    @Test func plainTextStripsTagsAndDecodes() {
        let html = "<p>Hello&nbsp;<b>world</b> &amp; friends&#8217;</p><script>var x=1;</script><p>Line&#x32;</p>"
        #expect(HTMLText.plain(html) == "Hello world & friends\u{2019}\nLine2")
    }

    @Test func metaAndAttributes() {
        let html = #"<head><meta property="og:title" content="A &amp; B"><meta name="description" content='Desc'></head>"#
        #expect(HTMLText.metaContent("og:title", in: html) == "A & B")
        #expect(HTMLText.metaContent("description", in: html) == "Desc")
        #expect(HTMLText.attribute("href", in: #" data-href="no" href="yes""#) == "yes")
    }

    @Test func scrapesMarylandTodayStyleListing() throws {
        let html = """
        <a href="https://today.umd.edu/ready-for-election-day-heres-how-where-and-when-to-vote" slot="image" aria-label="Ready for Election Day?: I Stock Thumbnail"><img></a>
        <a href="https://today.umd.edu/ready-for-election-day-heres-how-where-and-when-to-vote" aria-label="Read More about Ready for Election Day? Here&#8217;s How">Read More</a>
        <a href="/indigenous-artifacts-return-to-communities-digitally">Indigenous Artifacts Return to Communities Digitally</a>
        <a href="https://today.umd.edu/campus-community">Campus &amp; Community</a>
        <a href="https://other.edu/some-long-story-slug-here">Elsewhere story title</a>
        """
        let source = try #require(DefaultSources.all.first { $0.id == "maryland-today" })
        guard case .htmlList(let rule) = source.kind else { Issue.record("expected htmlList"); return }
        let items = HTMLListScraper.parse(html, baseURL: source.url, rule: rule, sourceID: source.id)
        #expect(items.map(\.title) == [
            "Ready for Election Day? Here\u{2019}s How",
            "Indigenous Artifacts Return to Communities Digitally",
        ])
        #expect(items[1].link == URL(string: "https://today.umd.edu/indigenous-artifacts-return-to-communities-digitally"))
    }

    @Test func splitsLeadingDateFromTitle() {
        let (date, title) = HTMLListScraper.splitLeadingDate("October 23, 2026  Meet the Clark Scholars Class of \u{2019}30")
        #expect(title == "Meet the Clark Scholars Class of \u{2019}30")
        #expect(date == ISO8601DateFormatter().date(from: "2026-10-23T16:00:00Z"))
        #expect(HTMLListScraper.splitLeadingDate("Plain Title").1 == "Plain Title")
    }

    @Test func extractsArticleBody() {
        let html = """
        <html><head><meta property="og:title" content="Full Title"><meta property="og:description" content="Teaser"><meta property="article:published_time" content="2026-11-02T10:56:00-05:00" /></head>
        <body><nav><p>Navigation link that is long enough to count as a paragraph</p></nav>
        <article><p>Short</p><p>This is the first real paragraph of the article body text.</p>
        <p>And this is the second paragraph, which is also long enough.</p></article></body></html>
        """
        let page = ArticleTextExtractor.extract(html: html)
        #expect(page.title == "Full Title")
        #expect(page.description == "Teaser")
        #expect(page.published == ISO8601DateFormatter().date(from: "2026-11-02T15:56:00Z"))
        #expect(page.body == "This is the first real paragraph of the article body text.\n\nAnd this is the second paragraph, which is also long enough.")
    }
}

struct DateParsingTests {
    @Test(arguments: [
        "Tue, 03 Nov 2026 02:31:33 +0000",
        "Tue, 03 Nov 2026 02:31:33 GMT",
        "2026-11-03T02:31:33Z",
        "2026-11-03T02:31:33.000Z",
    ])
    func parsesCommonFormats(_ input: String) {
        #expect(DateParsing.parse(input) == Date(timeIntervalSince1970: 1_793_673_093))
    }
}

struct ArticleTests {
    let source = FeedSource(id: "s", name: "S", url: URL(string: "https://e.edu")!, kind: .rss, category: .news)

    @Test func fallbackAndPageEnrichment() {
        let item = FetchedItem(sourceID: "s", guid: "g", title: "A long title that got cut...",
                               link: URL(string: "https://e.edu/a"), published: nil, summary: "")
        let article = Article(item: item, source: source)
        #expect(article.id == "s|g")
        #expect(article.needsPageFetch)
        #expect(article.displaySummary == "")

        article.apply(page: ArticlePage(title: "A long title that got cut off", description: "Teaser", body: "Body text"))
        #expect(article.dateIsEstimated)  // page had no publish date
        #expect(article.title == "A long title that got cut off")
        #expect(article.rawSummary == "Teaser")
        #expect(article.textForSummary == "Body text")
        #expect(article.displaySummary == "Teaser")

        article.apply(summary: NewsSummary(headline: "H", summary: "AI", keyPoints: ["k"]), language: "zh-Hans")
        #expect(article.displaySummary == "AI")
        #expect(article.hasAISummary)
    }

    @Test func futureDatesAreClamped() {
        let now = Date()
        let item = FetchedItem(sourceID: "s", guid: "g", title: "T", link: nil,
                               published: now.addingTimeInterval(86_400), summary: "")
        #expect(Article(item: item, source: source, now: now).published == now)
    }
}
