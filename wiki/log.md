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

## [2026-11-02] change | Welcome, interests and search

Added first-run welcome and persisted interests, a bottom global search entry, and independent per-section keyword/source/read/time filters. Global search covers all downloaded categories; All follows interests including events. Added Chinese strings and filter/settings regression tests. See [[ui]] and [[data-model]].

## [2026-11-02] change | Search as the final navigation tab

Moved global search from a bottom button/sheet into the final native Search tab, following the user clarification. Retains filters and a separate navigation stack. See [[ui]] and [[bottom-tab-navigation]].

## [2026-11-02] change | Center search navigation

Centered Search in a custom bottom navigation bar with equally sized category groups. Retained category pages and navigation stacks. See [[ui]] and [[bottom-tab-navigation]].

## [2026-11-02] change | Remove duplicate navigation layer

User reported a second navigation layer after centering Search. Removed the system TabView container while retaining independent navigation stacks in ZStack pages. Only the custom bottom bar remains. See [[ui]] and [[bottom-tab-navigation]].

## [2026-11-02] change | Restore native tab navigation

Removed custom navigation and ZStack switching at the user’s request. Restored native TabView with Search as the third regular tab. System overflow controls compact layouts. See [[ui]] and [[bottom-tab-navigation]].

## [2026-11-02] change | Reconcile wiki for GitHub publication

Rewrote [[bottom-tab-navigation]] around the final native TabView decision; updated [[overview]], [[localization]] and [[testing-and-debugging]] for welcome/preferences, search/filter behavior, test coverage and remaining visual checks.
