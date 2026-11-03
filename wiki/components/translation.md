---
type: component
tags: [component, ai, translation, localization]
updated: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md, raw/2026-11-02-simulator-findings.md]
---
# Translation (Apple Translation framework)

User requirement: when the system language isn't English, offer a **Translate** button.

- `UMDEvents/AI/TranslationSupport.swift`: source is always `en` (all built-in sources are English); the target is
  `Locale.preferredLanguages.first`. `isNeeded` = target language code isn't English. `isSupported()` uses
  `LanguageAvailability().status`; `.supported` (not downloaded yet) counts as available, because the system prompts
  for the download.
- `ArticleDetailView`: the button sits under the title. Tapping sets/invalidates a `TranslationSession.Configuration`,
  and `.translationTask` translates the **title** and the **original summary** in one batch (`clientIdentifier`
  "title"/"summary"). It then toggles between "Show Original" and "Show Translation".
- Results are persisted on `Article` (`translatedTitle`, `translatedSummary`, `translationLanguage`). If the system
  language changes, the stored translation is ignored (`hasTranslation(for:)`). Lists show the translated title (`listTitle`).
- AI summaries are already in the system language, so they're never translated.
- Runs fully on-device, consistent with [[local-only-no-server]].

⚠️ The **Simulator reports every pair as unsupported**, so the button is force-shown under
`#if targetEnvironment(simulator)`, and tapping it there shows the failure message. Verify on a device ([[gotchas]]).
