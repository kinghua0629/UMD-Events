import Foundation

struct ArticlePage: Sendable, Equatable {
    var title: String?
    var description: String?
    var body: String
    var published: Date? = nil
}

/// Downloads an article page and pulls out the title, description and body text.
enum ArticleTextExtractor {
    static let maxBodyLength = 8_000
    private static let articleBlock = HTMLText.regex(#"<article\b[^>]*>(.*)</article>"#)
    private static let mainBlock = HTMLText.regex(#"<main\b[^>]*>(.*)</main>"#)

    static func fetch(_ url: URL) async throws -> ArticlePage {
        let data = try await FeedFetcher.download(url)
        return extract(html: String(decoding: data, as: UTF8.self))
    }

    static func extract(html: String) -> ArticlePage {
        let title = HTMLText.metaContent("og:title", in: html)
        let description = HTMLText.metaContent("og:description", in: html)
            ?? HTMLText.metaContent("description", in: html)

        let scope = firstGroup(articleBlock, in: html) ?? firstGroup(mainBlock, in: html) ?? html
        var paragraphs = HTMLText.paragraphs(in: scope)
        if paragraphs.isEmpty, scope != html { paragraphs = HTMLText.paragraphs(in: html) }

        var body = ""
        for p in paragraphs {
            if body.count + p.count > maxBodyLength { break }
            body += body.isEmpty ? p : "\n\n" + p
        }
        let published = DateParsing.parse(HTMLText.metaContent("article:published_time", in: html)
            ?? HTMLText.metaContent("og:published_time", in: html))
        return ArticlePage(title: title, description: description, body: body, published: published)
    }

    private static func firstGroup(_ re: NSRegularExpression, in s: String) -> String? {
        guard let m = re.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) else { return nil }
        return HTMLText.group(m, 1, in: s)
    }
}
