import Foundation

/// Extracts article links from a news listing page that has no RSS feed.
enum HTMLListScraper {
    private static let anchor = HTMLText.regex(#"<a\b([^>]*)>(.*?)</a>"#)

    static func parse(_ html: String, baseURL: URL, rule: HTMLListRule, sourceID: String, limit: Int = 25) -> [FetchedItem] {
        guard let linkRegex = try? NSRegularExpression(pattern: rule.linkPattern) else { return [] }
        let prefix = rule.titlePrefix?.lowercased()

        var order: [String] = []
        var strongTitles: [String: String] = [:]
        var weakTitles: [String: String] = [:]

        for m in HTMLText.matches(anchor, in: html) {
            guard let attrs = HTMLText.group(m, 1, in: html),
                  let href = HTMLText.attribute("href", in: attrs),
                  let url = normalizedURL(href, base: baseURL)
            else { continue }
            let urlString = url.absoluteString
            guard linkRegex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)) != nil else { continue }

            if strongTitles[urlString] == nil && weakTitles[urlString] == nil { order.append(urlString) }

            if let prefix, let aria = HTMLText.attribute("aria-label", in: attrs),
               aria.lowercased().hasPrefix(prefix) {
                let title = aria.dropFirst(prefix.count).trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty, strongTitles[urlString] == nil { strongTitles[urlString] = title }
            }

            let inner = HTMLText.plain(HTMLText.group(m, 2, in: html) ?? "")
                .replacingOccurrences(of: "\n", with: " ")
            let isGeneric = inner.lowercased().hasPrefix("read more")
            if inner.count >= 12, !isGeneric, inner.count > (weakTitles[urlString]?.count ?? 0) {
                weakTitles[urlString] = inner
            }
        }

        var seen = Set<String>()
        return order.compactMap { urlString -> FetchedItem? in
            guard seen.insert(urlString).inserted,
                  let rawTitle = strongTitles[urlString] ?? weakTitles[urlString]
            else { return nil }
            let (date, title) = splitLeadingDate(rawTitle)
            return FetchedItem(sourceID: sourceID, guid: urlString, title: title,
                               link: URL(string: urlString), published: date, summary: "")
        }
        .prefix(limit)
        .map { $0 }
    }

    private static let leadingDate = HTMLText.regex(
        #"^((?:January|February|March|April|May|June|July|August|September|October|November|December) \d{1,2}, \d{4})\s+(.+)$"#, [])
    private static let leadingDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = ICalParser.defaultTimeZone
        f.dateFormat = "MMMM d, yyyy"
        return f
    }()

    /// Listing cards often render "October 23, 2026  Title"; split that into a date and a title.
    static func splitLeadingDate(_ text: String) -> (Date?, String) {
        guard let m = leadingDate.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let dateText = HTMLText.group(m, 1, in: text), let rest = HTMLText.group(m, 2, in: text),
              let date = leadingDateFormatter.date(from: dateText)
        else { return (nil, text) }
        // Midday so the date doesn't shift across time zones.
        return (date.addingTimeInterval(12 * 3600), rest)
    }

    /// Resolves relative links and drops query/fragment so the same story dedupes.
    static func normalizedURL(_ href: String, base: URL) -> URL? {
        guard let resolved = URL(string: href.trimmingCharacters(in: .whitespaces), relativeTo: base)?.absoluteURL,
              var components = URLComponents(url: resolved, resolvingAgainstBaseURL: false),
              let scheme = components.scheme, scheme.hasPrefix("http")
        else { return nil }
        components.query = nil
        components.fragment = nil
        if components.path.count > 1, components.path.hasSuffix("/") {
            components.path.removeLast()
        }
        return components.url
    }
}
