---
type: source
tags: [source, department, html-scrape]
updated: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# A. James Clark School of Engineering (eng.umd.edu)

Category: Departments. Kind: `htmlList` (no RSS; `/news/rss` is 404).

- List URL: `https://eng.umd.edu/news`; link rule `^https://eng\.umd\.edu/news/story/[^/?#]+$`; `titlePrefix` "Read more about ".
- aria-label titles can be truncated ("…Future of Organ..."): the page's `og:title` replaces them during enrichment.
- Some cards use "October 23, 2026  Title" as link text → `HTMLListScraper.splitLeadingDate` turns that into a
  date + clean title.
- Some story pages have no publish-date meta, so those items keep `dateIsEstimated` and show no date in the UI.
- `og:title` is double-encoded (`&amp;amp;`) → `metaContent` decodes twice ([[gotchas]]).
