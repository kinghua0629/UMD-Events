# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

iOS app (SwiftUI + SwiftData, iOS 26+) that aggregates UMD news/events/sports/department stories, summarizes them
on-device with Apple Intelligence (Foundation Models), offers on-device translation (Translation framework), and
sends local notifications. No server, no third-party dependencies. Deeper context: `wiki/index.md` → `wiki/overview.md`.

## Commands
```sh
# build + all tests (Swift Testing, UMDEventsTests/ParserTests.swift)
xcodebuild test -scheme UMDEvents -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build
# a single suite or test (note the trailing "()" for a test function)
xcodebuild test ... '-only-testing:UMDEventsTests/ICalParserTests'
xcodebuild test ... '-only-testing:UMDEventsTests/ICalParserTests/unfoldsLines()'
# wiki health check
python3 tools/wiki_lint.py
```
- The project uses folder-synchronized groups: new files under `UMDEvents/` or `UMDEventsTests/` need no
  `project.pbxproj` edit. `UMDEvents/Info.plist` is excluded from resources there and merged with generated keys.
- Hitting the real feeds without the simulator: compile a top-level `main.swift` together with `UMDEvents/Fetching/*.swift`,
  `UMDEvents/Models/FeedSource.swift` and `UMDEvents/Models/DefaultSources.swift` using `swiftc` (all macOS-compatible).
- DEBUG-only launch flags for `xcrun simctl launch`: `-skipNotificationPrompt`, `-openArticle <articleID>`;
  add `-AppleLanguages "(zh-Hans)"` to test Chinese. Screenshot and sqlite recipes: `wiki/guides/testing-and-debugging.md`.
- Simulator can't exercise AI summaries (`modelNotReady`) or translation (every pair `.unsupported`, so the
  button is force-shown under `targetEnvironment(simulator)`). Verify those on a device.

## Architecture
- **Two SwiftData contexts.** `AppEnvironment` (`@MainActor` singleton, `UMDEvents/App/`) owns the `ModelContainer`.
  Views read through `@Query` on the main context. All fetching and writing during refresh happens in `RefreshPipeline`,
  a `@ModelActor` with its own context. The same pipeline serves pull-to-refresh (summarize limit 10) and the
  `BGAppRefreshTask` (limit 3, since background runs get ~30 s). The main context only writes for on-demand work on
  the screen in front of the user (detail-view summarize/translate, deleting a custom source).
- **Refresh order** (`UMDEvents/Background/RefreshPipeline.swift`): fetch all sources in parallel → insert new
  `Article`s → prune → fetch pages for undated items (no AI) → enrich + summarize newest N → post a single notification.
- **Sources are data, not code.** A `FeedSource` is `.rss`, `.ical`, or `.htmlList(HTMLListRule)` (a regex over
  absolute link URLs plus an aria-label title prefix, for sites without feeds). Built-ins live in
  `UMDEvents/Models/DefaultSources.swift`; user feeds are stored in `AppSettings` (UserDefaults). Every parser outputs `FetchedItem`.
- **Article identity is `"<sourceID>|<guid>"`.** Changing a source `id` re-inserts and re-notifies everything. This
  ID is also the notification deep-link payload: `AppDelegate` → `AppEnvironment.pendingArticleID` → `ContentView`
  picks the tab from the sourceID prefix.
- **Fallback chain for summary text:** `aiSummary` → `rawSummary` (feed/og:description) → start of `content`.
  `Summarizer` (actor) writes in the system language when the model supports it, otherwise English; after 2 failures it
  stops retrying. Translation covers only the original title and summary, since the AI text is already localized.
- **HTML handling** is regex-based (`UMDEvents/Fetching/HTMLText.swift`), deliberately without SwiftSoup.

## Invariants
- Never notify for a source's first successful fetch (`AppSettings.knownSourceIDs`); disabled notification
  categories still mark items notified. Events are never auto-summarized; event notifications are off by default.
- `Article.dateIsEstimated` must stay false for events (they have `eventStart`), or they crowd out real undated stories.
- Swift 5 language mode; UI types are `@MainActor`.
- User-facing strings are SwiftUI literals or `String(localized:)`. Add every new key with its `zh-Hans` translation to
  `UMDEvents/Localizable.xcstrings` by hand (xcodebuild doesn't sync catalogs).
- Bundle ID and the background-task ID (`com.kinghua.UMDEvents.refresh`) appear in `project.pbxproj`, `Info.plist`
  and `RefreshScheduler.taskIdentifier`; change them together.

---

# Wiki schema (LLM-maintained knowledge base)

Follows the "LLM Wiki" pattern (karpathy gist 442a6bf555914893e9891c11519de94f). Three layers:

| Layer | Path | Who writes it |
|---|---|---|
| Raw sources | `raw/` | Humans (or the agent capturing a conversation/probe verbatim). **Immutable**: never edit or delete. |
| Wiki | `wiki/` | The agent only. Humans read it (Obsidian works: open the repo as a vault). |
| Schema | this file | Co-evolved by the human and the agent. |

## Layout
- `wiki/index.md`: catalog of every page, `[[page]] — one-line summary`, grouped by category. Read it first.
- `wiki/log.md`: append-only, entries start `## [YYYY-MM-DD] <op> | <title>` with op ∈ ingest, query, lint, change.
- `wiki/overview.md`: the big picture and current status.
- `wiki/sources/`: one page per news source (entity pages).
- `wiki/components/`: one page per subsystem (pipeline, summarizer, translation, parsing, UI…).
- `wiki/decisions/`: ADR-style decisions (context → decision → consequences, `status:` in frontmatter).
- `wiki/guides/`: how-tos.
- `wiki/gotchas.md`: bugs hit and lessons learned.

## Page conventions
- YAML frontmatter on every page except index/log: `type`, `tags`, `updated` (or `date` for decisions), and
  `sources` (raw files it draws on, when any).
- Link with Obsidian wikilinks `[[page-name]]` (file stem, unique across the wiki). Link generously; every page needs
  at least one inbound link besides index/log.
- Reference code by repo-relative path (`UMDEvents/Background/RefreshPipeline.swift`). Explain the *why* and the
  non-obvious; don't duplicate code.
- Mark unverified claims (e.g. "not yet verified on device"). When new information contradicts a page, update it and
  note what changed, rather than silently overwriting.

## Workflows
- **Ingest** (`ingest raw/<file>`): read the source, summarize the key takeaways for the user, then create/update every
  affected page (often 5–15), update `index.md`, append to `log.md`.
- **Change** (after any code change in this repo, without being asked): update the affected component/source/decision
  pages and `gotchas.md` if a bug taught something, then add a `change` entry to `log.md`. If the change came from a
  user request or a new finding, capture that first as a dated file in `raw/`.
- **Query**: read `index.md`, drill into pages, answer with `[[links]]`. If the answer is reusable (a comparison, an
  analysis, a decision), file it as a new page and log it as `query`.
- **Lint** (`lint the wiki`, and after big ingests): run `python3 tools/wiki_lint.py` (broken links, orphans, pages
  missing from the index, missing frontmatter). Then check by reading: contradictions, stale claims (compare with
  the code), concepts that deserve their own page, `updated` dates. Fix, then log as `lint`.
