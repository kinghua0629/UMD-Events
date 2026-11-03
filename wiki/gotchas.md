---
type: synthesis
tags: [gotchas, lessons]
updated: 2026-11-02
sources: [raw/2026-11-02-simulator-findings.md, raw/2026-11-02-feed-probe.md]
---
# Gotchas & lessons learned

Context: [[overview]].

## Data / parsing
- **`HTMLText.plain` early return** skipped whitespace normalization for tag-free text (ICS descriptions kept trailing
  spaces). Fixed: always normalize. ([[feed-parsing]])
- **Events starved `fillMissingDates`**: events have no `published`, so they were flagged `dateIsEstimated` and filled
  the 40-item batch. Fixed: estimated only when there's no `eventStart` either. ([[refresh-pipeline]])
- **Undated scraped stories all showed "now"** and sorted on top. Fixed by fetching their pages immediately, and
  hiding the date while it's still estimated.
- **Long-running TerpLink "events"** (Aug–May club operations) crowded the list. Fixed with the 12 h start window. ([[terplink-events]])
- **Double-encoded `og:title`** on eng.umd.edu. ([[umd-engineering]])
- **`cs.umd.edu/news/rss.xml` returns 200 HTML**: always check the content type, not just the status. ([[umd-cs]])

## Simulator
- Foundation Models: `modelNotReady` → AI path untested there. ([[summarizer]])
- Translation: every pair `.unsupported` → button force-shown under `targetEnvironment(simulator)`. ([[translation]])
- `simctl privacy grant notifications` fails (TCC). A pending permission prompt survives reinstall until reboot;
  use `-skipNotificationPrompt`.

## SwiftUI
- A segmented Picker in `.safeAreaInset(edge: .top)` hid the large title → replaced by tabs ([[bottom-tab-navigation]]).
- `await` inside `&&` is an autoclosure error: write `if a { x = await f() }`.
