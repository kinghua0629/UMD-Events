---
type: component
tags: [component, swiftui, ui]
updated: 2026-11-02
---
# UI

- `ContentView`: native `TabView`, ordered All, News, Search, Events, Sports, Departments. Search is a regular third tab so the system can display it centrally, rather than pinning a search-role tab to the trailing edge. Each page keeps its own `NavigationStack` and path. No custom bottom navigation is drawn. On compact iPhone layouts the system may group excess categories under More. Settings remains a toolbar gear. See [[bottom-tab-navigation]].
- `FeedListView`: `@Query` per category. "All" includes events and follows saved interests; global search includes all downloaded categories regardless of interests; Events is sorted by `eventStart` ascending; the rest by
  `published` descending. AI-unavailable banner, empty/loading/no-match states, pull to refresh. Each list retains independent search and filters for source, reading status and time (7/30 days or upcoming events); global search also filters by category. Search matches all whitespace-separated terms across original/translated titles, summaries, body, source and location.
- `ArticleRow`: unread dot, source, ✨ when an AI summary exists, relative date (hidden when `dateIsEstimated`),
  `listTitle`, event time/location, 3-line summary.
- `ArticleDetailView`: title, [[translation]] button, date or event info, `SummaryCard` (AI or original, key points,
  "Summarizing on device…"), "Read Full Article" (SFSafariViewController), share. Marks the article read and
  summarizes on demand.
- `WelcomeView`: first-run welcome with category interests, Get Started and Explore Everything. Preferences persist in UserDefaults and can be changed in Settings. Notification permission is requested after completion.
- `SettingsView`: editable interests, AI status, per-category notification toggles, refresh interval, test notification, per-source
  toggles, add/delete custom feeds, last refresh and per-source errors.
- Accent color UMD red `#E21833`; app icon generated with AppKit (red with "UMD" in white, gold bar).
