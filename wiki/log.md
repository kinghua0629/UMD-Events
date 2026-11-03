# Wiki log

Append-only. Each entry starts with `## [YYYY-MM-DD] <op> | <title>` (op: ingest, query, lint, change).
`grep "^## \[" wiki/log.md | tail -5` shows recent activity.

## [2026-11-02] ingest | Initial plan and user decisions
Created [[overview]], [[local-only-no-server]], [[bundle-identifier]] from `raw/2026-11-02-initial-plan.md` and
`raw/2026-11-02-user-decisions.md`.

## [2026-11-02] ingest | Feed probe
Created the six source pages, [[feed-parsing]], [[terplink-instead-of-calendar]], [[regex-html-instead-of-swiftsoup]].

## [2026-11-02] change | First implementation
Documented [[refresh-pipeline]], [[summarizer]], [[data-model]], [[background-refresh]], [[notifications]], [[ui]],
[[localization]]. Logged parsing bugs in [[gotchas]].

## [2026-11-02] query | Cross-platform vs Liquid Glass
Filed the answer as [[native-swiftui-over-cross-platform]].

## [2026-11-02] change | Bottom tab navigation
[[bottom-tab-navigation]]; updated [[ui]].

## [2026-11-02] change | Translate button
Created [[translation]] from the user request and `raw/2026-11-02-simulator-findings.md`; updated [[data-model]],
[[localization]], [[gotchas]].

## [2026-11-02] lint | Initial health check
Ran `tools/wiki_lint.py`; no broken links or orphans.
