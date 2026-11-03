import Foundation

/// Small, dependency-free HTML helpers (regex based; good enough for feeds and article pages).
enum HTMLText {
    static func regex(_ pattern: String,
                      _ options: NSRegularExpression.Options = [.caseInsensitive, .dotMatchesLineSeparators]) -> NSRegularExpression {
        // Patterns are compile-time constants or escaped input, so failure is a programmer error.
        try! NSRegularExpression(pattern: pattern, options: options)
    }

    private static let hiddenBlocks = regex(#"<(script|style|noscript|svg|figure|figcaption)\b.*?</\1>"#)
    private static let comments = regex(#"<!--.*?-->"#)
    private static let blockBreak = regex(#"<(br|/p|/div|/li|/h[1-6]|/tr|/blockquote)\b[^>]*>"#)
    private static let tag = regex(#"<[^>]+>"#)
    private static let spaces = regex(#"[ \t ]+"#, [])
    private static let manyNewlines = regex(#"\n{3,}"#, [])
    private static let entity = regex(#"&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);"#, [])
    private static let metaTag = regex(#"<meta\b[^>]*>"#)
    private static let paragraph = regex(#"<p\b[^>]*>(.*?)</p>"#)

    static func replace(_ re: NSRegularExpression, in s: String, with template: String) -> String {
        re.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template)
    }

    static func matches(_ re: NSRegularExpression, in s: String) -> [NSTextCheckingResult] {
        re.matches(in: s, range: NSRange(s.startIndex..., in: s))
    }

    static func group(_ match: NSTextCheckingResult, _ index: Int, in s: String) -> String? {
        guard index < match.numberOfRanges, let range = Range(match.range(at: index), in: s) else { return nil }
        return String(s[range])
    }

    /// Converts an HTML fragment to readable plain text.
    static func plain(_ html: String) -> String {
        var s = html
        if s.contains("<") {
            s = replace(comments, in: s, with: "")
            s = replace(hiddenBlocks, in: s, with: " ")
            s = replace(blockBreak, in: s, with: "\n")
            s = replace(tag, in: s, with: "")
        }
        s = decodeEntities(s)
        s = replace(spaces, in: s, with: " ")
        s = s.split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
        s = replace(manyNewlines, in: s, with: "\n\n")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let namedEntities: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "rsquo": "\u{2019}", "lsquo": "\u{2018}", "rdquo": "\u{201D}", "ldquo": "\u{201C}",
        "ndash": "\u{2013}", "mdash": "\u{2014}", "hellip": "\u{2026}", "bull": "\u{2022}",
        "middot": "\u{00B7}", "copy": "\u{00A9}", "reg": "\u{00AE}", "trade": "\u{2122}",
        "eacute": "\u{00E9}", "egrave": "\u{00E8}", "aacute": "\u{00E1}", "ntilde": "\u{00F1}",
        "uuml": "\u{00FC}", "ouml": "\u{00F6}", "auml": "\u{00E4}", "ccedil": "\u{00E7}",
    ]

    static func decodeEntities(_ s: String) -> String {
        guard s.contains("&") else { return s }
        let ns = s as NSString
        var out = ""
        var last = 0
        for m in entity.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
            out += ns.substring(with: NSRange(location: last, length: m.range.location - last))
            let name = ns.substring(with: m.range(at: 1))
            out += resolveEntity(name) ?? ns.substring(with: m.range)
            last = m.range.location + m.range.length
        }
        out += ns.substring(from: last)
        return out
    }

    private static func resolveEntity(_ name: String) -> String? {
        let code: UInt32?
        if name.hasPrefix("#x") || name.hasPrefix("#X") {
            code = UInt32(name.dropFirst(2), radix: 16)
        } else if name.hasPrefix("#") {
            code = UInt32(name.dropFirst(), radix: 10)
        } else {
            return namedEntities[name] ?? namedEntities[name.lowercased()]
        }
        guard let code, let scalar = Unicode.Scalar(code) else { return nil }
        return String(Character(scalar))
    }

    /// Value of an attribute inside a single tag's text, e.g. `href` in `<a href="...">`.
    static func attribute(_ name: String, in tagText: String) -> String? {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        let re = regex(#"(?:^|\s)"# + escaped + #"\s*=\s*(?:"([^"]*)"|'([^']*)')"#)
        guard let m = re.firstMatch(in: tagText, range: NSRange(tagText.startIndex..., in: tagText)) else { return nil }
        let value = group(m, 1, in: tagText) ?? group(m, 2, in: tagText)
        return value.map(decodeEntities)
    }

    /// Content of `<meta property="key">` or `<meta name="key">`.
    static func metaContent(_ key: String, in html: String) -> String? {
        let wanted = key.lowercased()
        for m in matches(metaTag, in: html) {
            guard let tagText = group(m, 0, in: html) else { continue }
            let k = attribute("property", in: tagText) ?? attribute("name", in: tagText)
            if k?.lowercased() == wanted,
               let content = attribute("content", in: tagText)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty {
                // Some CMSs double-encode meta content ("&amp;amp;").
                return decodeEntities(content)
            }
        }
        return nil
    }

    /// Plain-text paragraphs that look like body copy.
    static func paragraphs(in html: String, minLength: Int = 40) -> [String] {
        matches(paragraph, in: html).compactMap { m in
            guard let inner = group(m, 1, in: html) else { return nil }
            let text = plain(inner).replacingOccurrences(of: "\n", with: " ")
            return text.count >= minLength ? text : nil
        }
    }
}
