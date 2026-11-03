---
type: source
tags: [source, sports, rss]
updated: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# Maryland Athletics (umterps.com)

Category: Sports. Kind: `rss`.

- Feed: `https://umterps.com/rss?path=general` (Sidearm Sports). `rss.aspx` also returns 200 but with no content type.
- `<description>` starts with an `<img>` tag; `HTMLText.plain` strips it ([[feed-parsing]]).
- Each item has a `<category>` naming the sport (Field Hockey, Basketball…) — not used yet; could power per-sport filters.
