import Foundation

enum FeedError: LocalizedError {
    case badStatus(Int)
    case unparseable

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): "HTTP \(code)"
        case .unparseable: "Feed could not be parsed"
        }
    }
}

/// Parses RSS 2.0 and Atom feeds.
final class RSSParser: NSObject, XMLParserDelegate {
    static let maxSummaryLength = 1_000
    static let maxContentLength = 8_000

    static func parse(_ data: Data, sourceID: String) throws -> [FetchedItem] {
        let delegate = RSSParser(sourceID: sourceID)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        let ok = parser.parse()
        if !ok && delegate.items.isEmpty {
            throw parser.parserError ?? FeedError.unparseable
        }
        return delegate.items
    }

    private let sourceID: String
    private(set) var items: [FetchedItem] = []
    private var fields: [String: String]?
    private var atomLink: String?
    private var text = ""

    private init(sourceID: String) {
        self.sourceID = sourceID
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        if elementName == "item" || elementName == "entry" {
            fields = [:]
            atomLink = nil
        } else if fields != nil, elementName == "link", let href = attributeDict["href"] {
            let rel = attributeDict["rel"] ?? "alternate"
            if rel == "alternate", atomLink == nil { atomLink = href }
        }
        text = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        text += string
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        text += String(decoding: CDATABlock, as: UTF8.self)
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        guard var current = fields else { return }
        if elementName == "item" || elementName == "entry" {
            if let item = makeItem(current) { items.append(item) }
            fields = nil
            return
        }
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty, current[elementName] == nil {
            current[elementName] = value
            fields = current
        }
        text = ""
    }

    private func makeItem(_ f: [String: String]) -> FetchedItem? {
        let title = HTMLText.plain(f["title"] ?? "")
        let linkString = f["link"] ?? atomLink
        let link = linkString.flatMap { URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        guard !title.isEmpty || link != nil else { return nil }

        let summaryHTML = f["description"] ?? f["summary"] ?? ""
        let contentHTML = f["content:encoded"] ?? f["content"]
        var summary = HTMLText.plain(summaryHTML)
        let content = contentHTML.map { String(HTMLText.plain($0).prefix(Self.maxContentLength)) }
        if summary.isEmpty, let content { summary = content }

        let guid = f["guid"] ?? f["id"] ?? linkString ?? title
        return FetchedItem(
            sourceID: sourceID,
            guid: guid,
            title: title.isEmpty ? (linkString ?? "") : title,
            link: link,
            published: DateParsing.parse(f["pubDate"] ?? f["published"] ?? f["updated"] ?? f["dc:date"]),
            summary: String(summary.prefix(Self.maxSummaryLength)),
            content: content
        )
    }
}
