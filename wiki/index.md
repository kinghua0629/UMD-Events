# Wiki index

Catalog of every page. Read this first when answering a question; update it on every ingest.
Format: `[[page]]` — one-line summary.

## Overview
- [[overview]] — what the app is, constraints, how it works, current status
- [[gotchas]] — bugs hit, simulator limitations, lessons learned

## Sources (entities)
- [[maryland-today]] — official news; HTML scrape (no RSS), dates from article pages
- [[diamondback]] — student newspaper; WordPress RSS with full content
- [[terplink-events]] — public events ICS; 12 h–7 d window, not auto-summarized
- [[maryland-athletics]] — umterps.com RSS; sports
- [[umd-cs]] — CS department RSS at /feeds/news/all (beware the HTML "rss.xml")
- [[umd-engineering]] — Clark School; HTML scrape, truncated titles and date-prefixed cards

## Components
- [[refresh-pipeline]] — fetch → insert → prune → fill dates → summarize → notify
- [[summarizer]] — Foundation Models, @Generable summary, language and fallback rules
- [[translation]] — on-device Translate button for non-English systems
- [[feed-parsing]] — RSS/Atom, iCal, HTML list scraping, article extraction
- [[data-model]] — FeedSource, Article (@Model), AppSettings
- [[background-refresh]] — BGAppRefreshTask scheduling and debugging
- [[notifications]] — one-per-refresh local notifications, readiness, deep link
- [[ui]] — tabs, list, detail, settings
- [[localization]] — string catalogs, follow-the-system language rule

## Decisions
- [[local-only-no-server]] — no backend; iOS controls refresh timing
- [[regex-html-instead-of-swiftsoup]] — zero dependencies
- [[terplink-instead-of-calendar]] — calendar.umd.edu has no feed
- [[bottom-tab-navigation]] — categories as a bottom Liquid Glass tab bar
- [[native-swiftui-over-cross-platform]] — Liquid Glass and Apple-only APIs
- [[bundle-identifier]] — com.kinghua.UMDEvents

## Guides
- [[adding-a-source]] — probing feeds, DefaultSources, htmlList rules
- [[testing-and-debugging]] — test/launch/screenshot/sqlite recipes, device-only checks

## Raw sources (immutable, in `raw/`)
- `raw/2026-11-02-initial-plan.md` — the approved implementation plan
- `raw/2026-11-02-user-decisions.md` — the user's requirements and follow-up requests
- `raw/2026-11-02-feed-probe.md` — which UMD URLs have feeds, plus HTML structure notes
- `raw/2026-11-02-simulator-findings.md` — what the simulator can't do

- `raw/2026-11-02-welcome-search-request.md` — welcome, interest selection, global and per-section search/filter request

- `raw/2026-11-02-search-tab-clarification.md` — global search belongs in the final navigation item

- `raw/2026-11-02-centered-search-request.md` — center the bottom search item

- `raw/2026-11-02-duplicate-navigation-report.md` — duplicate navigation layer after centering search

- `raw/2026-11-02-native-tabs-request.md` — restore system-native navigation instead of a custom bar
