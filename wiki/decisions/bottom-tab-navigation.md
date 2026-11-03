---
type: decision
tags: [decision, ui]
status: accepted
date: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md, raw/2026-11-02-native-tabs-request.md, raw/2026-11-02-centered-search-request.md]
---
# Decision: native bottom tab navigation

## Context
The user wants the system-native bottom navigation bar, with global Search in the middle. A custom centered bar was tried and rejected; layering it over a system tab bar also caused duplicate navigation.

## Decision
Use SwiftUI `TabView` exclusively, ordered All, News, Search, Events, Sports, Departments. Search is a regular third tab: the native `.search` role would give the system control of its trailing placement. Each page retains its own `NavigationStack` and article path. Settings stays a toolbar gear. There is no custom bottom bar or overlay.

## Consequences
Compact iPhone layouts may put excess tabs under the system More interface. Search is ordered third; exact layout is controlled by iOS. Category pages keep independent search/filter state, while Search covers every downloaded category regardless of interests. Notification links still select the article's category. See [[ui]], [[data-model]], and [[notifications]].
