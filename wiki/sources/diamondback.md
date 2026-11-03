---
type: source
tags: [source, news, rss]
updated: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# The Diamondback (dbknews.com)

Independent student newspaper. Category: News. Kind: `rss` (WordPress).

- Feed: `https://dbknews.com/feed/` — RSS 2.0 with `content:encoded` (full article HTML), so no page fetch is needed
  before summarizing. ~10 items.
- Dates are RFC 822 (`Tue, 03 Nov 2026 02:31:33 +0000`).
- Titles use numeric entities (`&#8217;`) — handled by `HTMLText.decodeEntities` ([[feed-parsing]]).
- Covers sports too (e.g. basketball recaps), which overlaps with [[maryland-athletics]]; no cross-source dedupe yet.
