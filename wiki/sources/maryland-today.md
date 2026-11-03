---
type: source
tags: [source, news, html-scrape]
updated: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# Maryland Today (today.umd.edu)

UMD's official news site. Category: News. Kind: `htmlList` — **no RSS feed exists**.

- List URL: `https://today.umd.edu/`
- Link rule: `^https://today\.umd\.edu/[a-z0-9]+(-[a-z0-9]+){3,}$` (≥4-word slugs, skips nav pages like `/campus-community`)
- Title: `aria-label="Read More about <Title>"` (`titlePrefix`), otherwise the longest anchor text.
- No dates on the listing → items start as `dateIsEstimated`; the [[refresh-pipeline]] fetches each page right away
  and reads `article:published_time` / `og:description` / body paragraphs ([[feed-parsing]]).
- `og:title` is just "Maryland Today" — never use it as a story title (only used when a title is truncated).

Code: `UMDEvents/Models/DefaultSources.swift`. Related: [[regex-html-instead-of-swiftsoup]], [[gotchas]].
