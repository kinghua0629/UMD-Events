---
type: source
tags: [source, events, ical]
updated: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# TerpLink public events (terplink.umd.edu)

Campus Labs Engage instance listing student-org and campus public events. Category: Events. Kind: `ical`.
Replaces calendar.umd.edu, which has no feed → [[terplink-instead-of-calendar]].

- Feed: `https://terplink.umd.edu/events.ics` (also `events.rss`, which embeds dates in HTML microformats — the ICS is cleaner).
- Folded lines, UTC `DTSTART/DTEND`, `UID` = event URL, `X-HOSTS`, multiple `CATEGORIES`.
- DESCRIPTION ends with "Additional Information can be found at: <url>" — stripped by the parser.
- Volume: hundreds of events over ~6 weeks. Parser keeps only events starting between 12 h ago and 7 days ahead,
  max 150, and drops long-running "events" (semester-long club operations) — see [[gotchas]].
- Events are **not** auto-summarized in the background and notifications for Events are **off by default**
  ([[refresh-pipeline]], [[notifications]]). Opening an event summarizes it on demand.
- Events are excluded from the "All" tab and sorted by start time in their own tab ([[ui]]).
