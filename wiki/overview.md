---
type: overview
tags: [overview]
updated: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md, raw/2026-11-02-initial-plan.md]
---
# UMD Events — overview

An iOS app that collects University of Maryland news, events, sports and department stories, summarizes them
**on the iPhone** with Apple Intelligence, and pushes **local** notifications. No server.

## Hard constraints (from the user)
- Summaries run on-device (Foundation Models) → [[summarizer]], [[local-only-no-server]].
- Devices without Apple Intelligence still work, showing the feed's own summary → [[summarizer]].
- Language follows the system: localized UI, summaries in the system language, and a Translate button for the
  original English text on non-English systems → [[localization]], [[translation]].
- Navigation lives at the bottom (Liquid Glass tab bar) → [[bottom-tab-navigation]], [[ui]].

## How it works (one paragraph)
[[background-refresh]] (or a pull-to-refresh) runs the [[refresh-pipeline]]: fetch every enabled source in
parallel ([[feed-parsing]]), store new items in SwiftData ([[data-model]]), fetch article pages for undated items,
summarize a few with Apple Intelligence, then post one [[notifications|notification]] for what's new.

## Sources
[[maryland-today]] · [[diamondback]] · [[terplink-events]] · [[maryland-athletics]] · [[umd-cs]] · [[umd-engineering]]
— and users can add their own RSS/iCal feeds ([[adding-a-source]]).

## Stack
SwiftUI + SwiftData ([[native-swiftui-over-cross-platform]]), iOS 26+, Swift 5 language mode, bundle ID `com.kinghua.UMDEvents` ([[bundle-identifier]]), no third-party dependencies
([[regex-html-instead-of-swiftsoup]]). Xcode project with folder-synchronized groups, so new files in
`UMDEvents/` are picked up automatically.

## Status (2026-11-02)
Builds, 13 unit tests pass, all six sources verified live. Not yet verified on a real device: AI summaries,
translation, background refresh timing, notification delivery — see [[testing-and-debugging]] and [[gotchas]].
