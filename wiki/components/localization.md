---
type: component
tags: [component, localization]
updated: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md]
---
# Localization

Rule from the user: **follow the system language**.

- UI strings: `UMDEvents/Localizable.xcstrings` (source `en`, translations `zh-Hans`). Other system languages fall
  back to English UI. App name: `InfoPlist.xcstrings` (`CFBundleDisplayName` → "UMD 校园资讯").
- SwiftUI literals are keys. `LocalizedStringResource` is used for enums (`FeedCategory.title`, `AIStatus.message`).
  Interpolations become `%lld` keys (e.g. `"%lld new updates"`).
- AI summaries are written in the system language when the model supports it ([[summarizer]]). The original English
  title and summary can be translated on demand ([[translation]]).
- `xcodebuild` doesn't sync the catalog. New keys are added by hand (a python snippet in past sessions). Check
  coverage with the grep recipe in [[testing-and-debugging]].
- To add a language: add it to `knownRegions` in the project and translations in both catalogs.

- Welcome, interests, global/section search, filter options and no-results messages include Simplified Chinese translations. See [[ui]].
