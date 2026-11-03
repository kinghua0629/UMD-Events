---
type: component
tags: [component, ai, foundation-models]
updated: 2026-11-02
sources: [raw/2026-11-02-initial-plan.md, raw/2026-11-02-simulator-findings.md]
---
# Summarizer (Apple Intelligence / Foundation Models)

`UMDEvents/AI/Summarizer.swift`: an `actor` that calls the on-device `SystemLanguageModel` via `LanguageModelSession`.

- **Output**: `@Generable struct NewsSummary { headline, summary (2–3 sentences), keyPoints (≤3) }` — guided generation,
  no JSON parsing.
- **Language**: `Locale.preferredLanguages.first` if `SystemLanguageModel.default.supportsLocale(_:)`, otherwise English.
  The instructions name the language explicitly ("…in Chinese, Simplified…"). Stored in `Article.aiLanguage`.
- **Context window**: input truncated to 4000 characters; on `exceededContextWindowSize` the budget halves (down to 1000).
- **Failure handling**: any error → `summaryAttempts += 1`; after 2 attempts the article falls back permanently.
- **Availability → UI** (`AIStatus`): `deviceNotEligible`, `notEnabled`, `modelNotReady`, other. The list shows a banner
  with the reason, and cards are labeled "Original Summary" vs "Apple Intelligence Summary" ([[ui]]).
- A new session per article (no shared transcript); calls are serialized by the actor.

Not yet verified: real output quality and speed; the simulator reported `modelNotReady` ([[gotchas]]).
Related: [[translation]] covers the text the AI doesn't rewrite (titles, original summaries).
