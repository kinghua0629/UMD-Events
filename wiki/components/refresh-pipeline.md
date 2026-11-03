---
type: component
tags: [component, background, swiftdata]
updated: 2026-11-02
sources: [raw/2026-11-02-initial-plan.md, raw/2026-11-02-feed-probe.md]
---
# Refresh pipeline

`UMDEvents/Background/RefreshPipeline.swift`: a `@ModelActor` with its own SwiftData context, so the same code runs
from pull-to-refresh and from [[background-refresh]]. Entry point: `AppEnvironment.refresh(summarizeLimit:)`
(10 in the foreground, 3 in the background).

## Steps
1. **Fetch**: `FeedFetcher.fetchAll` runs every enabled source in a TaskGroup ([[feed-parsing]]). Failures are
   collected per source name and shown in Settings → Status.
2. **Insert**: ID = `"<sourceID>|<guid>"`; existing IDs are skipped. Items from a source that has never succeeded
   before (`AppSettings.knownSourceIDs`) are inserted with `notified = true`, so a new source's backlog doesn't spam.
3. **Prune**: non-events older than 60 days (by `firstSeen`); events that ended over a day ago.
4. **fillMissingDates**: up to 40 `dateIsEstimated && !enriched` items get their article pages fetched **in parallel,
   with no AI**, for real dates, descriptions and body text. Without this, scraped stories all read "now" and
   crowd the top of the list.
5. **Enrich + summarize**: newest-first, `limit` non-event items without an AI summary (fewer than 2 attempts).
   Fetch the page if the text is thin, then call [[summarizer]]. If AI is unavailable, only enrich.
   Checks `Task.isCancelled` between items (background time runs out).
6. **Notify**: see [[notifications]] for readiness rules.

## Invariants
- Never notify for the first fetch of a source.
- Events: never auto-summarized, notifications opt-in.
- `Article.dateIsEstimated` is false for events (they have `eventStart`), otherwise events starve step 4 — see [[gotchas]].
