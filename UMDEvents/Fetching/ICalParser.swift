import Foundation

/// Minimal iCalendar (RFC 5545) VEVENT parser.
enum ICalParser {
    static let defaultTimeZone = TimeZone(identifier: "America/New_York") ?? .current

    /// Returns events that haven't ended and start between 12 h ago and `horizon` from `now`,
    /// sorted by start. Long-running "events" that began earlier (e.g. semester-long club
    /// operations) are dropped so they don't crowd the list.
    static func parse(_ text: String, sourceID: String, now: Date = .now,
                      horizon: TimeInterval = 7 * 86_400, limit: Int = 150) -> [FetchedItem] {
        var events: [FetchedItem] = []
        var props: [String: (value: String, params: [String: String])]?

        for line in unfold(text) {
            if line == "BEGIN:VEVENT" {
                props = [:]
            } else if line == "END:VEVENT" {
                if let p = props, let item = makeItem(p, sourceID: sourceID) { events.append(item) }
                props = nil
            } else if props != nil, let (name, params, value) = splitProperty(line), props?[name] == nil {
                props?[name] = (value, params)
            }
        }

        let earliestStart = now.addingTimeInterval(-12 * 3600)
        let end = now.addingTimeInterval(horizon)
        return events
            .filter { item in
                guard let start = item.eventStart else { return false }
                return (item.eventEnd ?? start) >= now && start >= earliestStart && start <= end
            }
            .sorted { ($0.eventStart ?? .distantFuture) < ($1.eventStart ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }

    /// Joins folded lines (continuation lines start with a space or tab).
    static func unfold(_ text: String) -> [String] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        var lines: [String] = []
        for raw in normalized.split(separator: "\n", omittingEmptySubsequences: false) {
            if (raw.hasPrefix(" ") || raw.hasPrefix("\t")), !lines.isEmpty {
                lines[lines.count - 1] += raw.dropFirst()
            } else {
                lines.append(String(raw))
            }
        }
        return lines
    }

    private static func splitProperty(_ line: String) -> (String, [String: String], String)? {
        guard let colon = line.firstIndex(of: ":") else { return nil }
        let head = line[..<colon]
        let value = String(line[line.index(after: colon)...])
        let parts = head.split(separator: ";")
        guard let first = parts.first else { return nil }
        var params: [String: String] = [:]
        for part in parts.dropFirst() {
            let kv = part.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                params[kv[0].uppercased()] = kv[1].trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
        return (first.uppercased(), params, value)
    }

    static func unescape(_ s: String) -> String {
        var out = ""
        var iterator = s.makeIterator()
        while let c = iterator.next() {
            guard c == "\\", let next = iterator.next() else { out.append(c); continue }
            switch next {
            case "n", "N": out.append("\n")
            default: out.append(next)
            }
        }
        return out
    }

    static func parseDate(_ value: String, params: [String: String]) -> Date? {
        let v = value.trimmingCharacters(in: .whitespaces)
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.calendar = Calendar(identifier: .gregorian)
        let tz = params["TZID"].flatMap(TimeZone.init(identifier:)) ?? defaultTimeZone
        if v.hasSuffix("Z") {
            f.timeZone = TimeZone(identifier: "UTC")
            f.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        } else if v.count == 8 {
            f.timeZone = tz
            f.dateFormat = "yyyyMMdd"
        } else {
            f.timeZone = tz
            f.dateFormat = "yyyyMMdd'T'HHmmss"
        }
        return f.date(from: v)
    }

    private static func makeItem(_ p: [String: (value: String, params: [String: String])], sourceID: String) -> FetchedItem? {
        guard let summary = p["SUMMARY"].map({ unescape($0.value) }), !summary.isEmpty,
              let startProp = p["DTSTART"], let start = parseDate(startProp.value, params: startProp.params)
        else { return nil }

        let end = p["DTEND"].flatMap { parseDate($0.value, params: $0.params) }
        let urlString = p["URL"].map { unescape($0.value) }
        let uid = p["UID"].map { unescape($0.value) }

        var description = p["DESCRIPTION"].map { unescape($0.value) } ?? ""
        if let range = description.range(of: "Additional Information can be found at:") {
            description = String(description[..<range.lowerBound])
        }
        description = HTMLText.plain(description)

        return FetchedItem(
            sourceID: sourceID,
            guid: uid ?? urlString ?? "\(summary)-\(start.timeIntervalSince1970)",
            title: summary,
            link: urlString.flatMap(URL.init(string:)),
            published: nil,
            summary: String(description.prefix(RSSParser.maxSummaryLength)),
            content: description.isEmpty ? nil : description,
            eventStart: start,
            eventEnd: end,
            location: p["LOCATION"].map { unescape($0.value) }.flatMap { $0.isEmpty ? nil : $0 }
        )
    }
}
