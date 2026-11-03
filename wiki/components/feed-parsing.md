---
type: component
tags: [component, parsing, networking]
updated: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# Feed parsing & fetching

All in `UMDEvents/Fetching/`, dependency-free ([[regex-html-instead-of-swiftsoup]]). Every parser outputs `FetchedItem`.

| File | Role |
|---|---|
| `FeedFetcher.swift` | `download(_:)` with a mobile Safari-like UA, 20 s timeout, non-2xx → `FeedError.badStatus`; `fetchAll` TaskGroup |
| `RSSParser.swift` | `XMLParser` delegate for RSS 2.0 + Atom (`link@href`, `id`, `updated`, `content:encoded`, CDATA) |
| `ICalParser.swift` | Unfolds lines, `PROP;PARAM=x:value`, UTC/TZID/date-only times (default America/New_York), unescapes `\n \, \;` |
| `HTMLListScraper.swift` | `htmlList` sources: anchors matching `HTMLListRule.linkPattern`, aria-label prefix titles, `splitLeadingDate` |
| `ArticleTextExtractor.swift` | Article page → `og:title`, `og:description`, `article:published_time`, `<p>` text inside `<article>`/`<main>` (≤8000 chars) |
| `HTMLText.swift` | `plain()`, `decodeEntities`, `attribute`, `metaContent`, `paragraphs` |
| `DateParsing.swift` | ISO 8601 (with/without fractional seconds) + several RFC 822 variants |

Tests: `UMDEventsTests/ParserTests.swift` use real-world fixtures (Diamondback RSS, TerpLink ICS, Maryland Today HTML).
Pitfalls are collected in [[gotchas]].
