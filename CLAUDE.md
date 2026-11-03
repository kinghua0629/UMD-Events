# UMD Events — agent guide

iOS app (SwiftUI + SwiftData, iOS 26+) that aggregates UMD news/events/sports/department stories, summarizes them
on-device with Apple Intelligence, offers on-device translation, and sends local notifications. No server, no
third-party dependencies. Start with `wiki/index.md` → `wiki/overview.md`.

## Build & test
```sh
xcodebuild test -scheme UMDEvents -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build
python3 tools/wiki_lint.py
```
The Xcode project uses folder-synchronized groups, so files added under `UMDEvents/` or `UMDEventsTests/` are picked
up without editing `project.pbxproj`. More recipes (launch flags, screenshots, sqlite): `wiki/guides/testing-and-debugging.md`.

## Code conventions
- Swift 5 language mode; UI types are `@MainActor`; background work goes through the `RefreshPipeline` `@ModelActor`.
- User-facing strings are SwiftUI literals or `String(localized:)`; add every new key with its `zh-Hans` translation
  to `UMDEvents/Localizable.xcstrings` (xcodebuild does not sync catalogs).
- Language rule: follow the system language. AI output uses the system language; original English text gets the
  Translate button only on non-English systems.
- Never notify for a source's first fetch; events are never auto-summarized. See `wiki/components/refresh-pipeline.md`.
- DEBUG-only launch flags: `-skipNotificationPrompt`, `-openArticle <articleID>`.

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
