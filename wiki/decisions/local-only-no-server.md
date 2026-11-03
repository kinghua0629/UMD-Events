---
type: decision
tags: [decision, architecture]
status: accepted
date: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md]
---
# Decision: local only, no server

**Context.** Summaries must be produced by on-device Apple Intelligence, so a server could at most detect new
stories and send a silent push.
**Decision.** No server: [[background-refresh]] + local [[notifications]].
**Consequences.** Zero cost, no APNs or backend. Notification timing is controlled by iOS and can lag by hours.
If timeliness ever matters more, a tiny server that only sends silent pushes is the upgrade path; summarization
stays local either way.
