---
type: guide
tags: [guide, testing]
updated: 2026-11-02
sources: [raw/2026-11-02-simulator-findings.md]
---
# Testing & debugging

Current verification status: see [[overview]].

```sh
# unit tests (Swift Testing, 17 tests)
xcodebuild test -scheme UMDEvents -destination 'platform=iOS Simulator,name=iPhone 18 Pro' -derivedDataPath build
# launch in Chinese, skip the notification prompt, open a story directly (DEBUG-only flags)
xcrun simctl launch <device> com.kinghua.UMDEvents -AppleLanguages "(zh-Hans)" -AppleLocale zh_CN \
  -skipNotificationPrompt -openArticle "diamondback|https://dbknews.com/?p=487323"
xcrun simctl io <device> screenshot out.png
# inspect the store
sqlite3 "$(find "$(xcrun simctl get_app_container <device> com.kinghua.UMDEvents data)" -name default.store)" \
  "select ZSOURCEID, ZDATEISESTIMATED, ZENRICHED, substr(ZTITLE,1,40) from ZARTICLE limit 20;"
```

- **Live feed check without the simulator:** compile the fetching files with a small `main.swift` via `swiftc`
  (`UMDEvents/Fetching/*.swift` + `Models/FeedSource.swift` + `Models/DefaultSources.swift`). Use top-level code, not
  `-parse-as-library`.
- **Must test on a device** (iPhone 15 Pro or newer, Apple Intelligence on): AI summaries, translation, background
  refresh (debugger command in [[background-refresh]]), notification delivery and deep link.
- Simulator limitations are listed in [[gotchas]].

- `UMDEventsTests/FeedFiltersTests.swift` covers multi-term search across fields, combined source/category/read filters, event time boundaries, and welcome/interest persistence using isolated UserDefaults.
- Latest native navigation revision builds successfully. The Chinese welcome page was visually inspected in the simulator; final tab overflow and all filter controls still need interactive visual verification.
