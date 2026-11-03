---
type: decision
tags: [decision, sources, events]
status: accepted
date: 2026-11-02
sources: [raw/2026-11-02-feed-probe.md]
---
# Decision: TerpLink ICS instead of calendar.umd.edu

calendar.umd.edu is a JavaScript web-component app with no RSS/ICS endpoint (all probes 404 or HTML). TerpLink
publishes all public UMD events as ICS → [[terplink-events]]. Trade-off: mostly student-org events, so some official
calendar events may be missing.
