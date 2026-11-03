---
type: component
tags: [component, swiftui, ui]
updated: 2026-11-02
---
# UI

- `ContentView`: `TabView` with 5 tabs (All, News, Events, Sports, Departments), each with its own
  `NavigationStack` and path. `.tabBarMinimizeBehavior(.onScrollDown)`. Settings is a gear button in every tab's
  toolbar (6 tabs would trigger "More") → [[bottom-tab-navigation]].
- `FeedListView`: `@Query` per category. "All" excludes events; Events is sorted by `eventStart` ascending; the rest by
  `published` descending. AI-unavailable banner, empty/loading states, pull to refresh.
- `ArticleRow`: unread dot, source, ✨ when an AI summary exists, relative date (hidden when `dateIsEstimated`),
  `listTitle`, event time/location, 3-line summary.
- `ArticleDetailView`: title, [[translation]] button, date or event info, `SummaryCard` (AI or original, key points,
  "Summarizing on device…"), "Read Full Article" (SFSafariViewController), share. Marks the article read and
  summarizes on demand.
- `SettingsView`: AI status, per-category notification toggles, refresh interval, test notification, per-source
  toggles, add/delete custom feeds, last refresh and per-source errors.
- Accent color UMD red `#E21833`; app icon generated with AppKit (red with "UMD" in white, gold bar).
