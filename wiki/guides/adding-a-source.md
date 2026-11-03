---
type: guide
tags: [guide, sources]
updated: 2026-11-02
---
# Adding a source

**Users:** Settings → Add Custom Feed (RSS/Atom or iCal; `webcal://` is accepted).

**Developers (built-in source):**
1. Probe first: `curl -sL -A "Mozilla/5.0" -o /dev/null -w "%{http_code} %{content_type}" <url>`. Beware of 200 + HTML
   (see [[umd-cs]]). Look for `href="...(rss|feed)..."` on the site's news page.
2. Add a `FeedSource` to `UMDEvents/Models/DefaultSources.swift` with a stable `id` (it's part of every article ID;
   changing it re-notifies everything).
3. No feed → `.htmlList(HTMLListRule(linkPattern:titlePrefix:))`. Anchor the regex and match absolute URLs after
   normalization (no query/fragment/trailing slash).
4. Add a fixture test in `UMDEventsTests/ParserTests.swift`, run the live check ([[testing-and-debugging]]), and
   write a page under `wiki/sources/` + update [[index]].
