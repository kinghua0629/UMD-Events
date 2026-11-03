---
type: component
tags: [component, swiftdata]
updated: 2026-11-02
---
# Data model

- `FeedSource` / `FeedKind` (`rss`, `ical`, `htmlList(HTMLListRule)`) / `FeedCategory` (`news`, `events`, `sports`,
  `department`): Codable structs in `UMDEvents/Models/FeedSource.swift`. Defaults are in `DefaultSources.swift`; custom
  sources are persisted by `AppSettings` (UserDefaults JSON).
- `Article` (`@Model`, `UMDEvents/Models/Article.swift`), unique `id = "<sourceID>|<guid>"`. Field groups:
  - content: `title`, `linkString`, `rawSummary` (short), `content` (long, summarizer input)
  - time: `published` (clamped to now), `firstSeen`, `dateIsEstimated`, `eventStart/End`, `location`
  - AI: `aiHeadline`, `aiSummary`, `aiKeyPoints`, `aiLanguage`, `summaryAttempts`
  - translation: `translatedTitle`, `translatedSummary`, `translationLanguage` ([[translation]])
  - state: `enriched`, `isRead`, `notified`
- `categoryRaw` is stored as a String so `#Predicate` can filter on it.
- Helpers: `apply(page:)`, `apply(summary:language:)`, `apply(translatedTitle:summary:language:)`,
  `displaySummary`, `fallbackSummary`, `listTitle`, `needsPageFetch`.
- Schema changes so far are additive (lightweight migration). Use a `VersionedSchema` before any rename or removal.
- `AppSettings` (UserDefaults): disabled source IDs, custom sources, notify categories (default news/sports/department),
  refresh interval (default 1 h), `knownSourceIDs`.

- `AppSettings.hasCompletedWelcome` and `interests` persist the first-run setup and preferred categories. Existing installations without these keys see the welcome once; all categories default selected. Preferences affect All only, leaving source enablement and notification choices independent.
- `FeedFilters` combines keyword terms with source/category/read/time constraints; date windows use event start when available and exclude future items, while Upcoming requires a future event start.
