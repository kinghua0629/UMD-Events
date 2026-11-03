---
type: component
tags: [component, background, ios]
updated: 2026-11-02
sources: [raw/2026-11-02-initial-plan.md]
---
# Background refresh

- `BGAppRefreshTask` with identifier `com.kinghua.UMDEvents.refresh` (listed in `UMDEvents/Info.plist` along with
  `UIBackgroundModes: fetch`).
- Scheduled whenever the scene enters the background (`RefreshScheduler.schedule(after:)`, earliest = user setting).
  It is rescheduled at the start of each run.
- Handled with SwiftUI `.backgroundTask(.appRefresh(...))` → `RefreshScheduler.handleBackgroundRefresh()` →
  [[refresh-pipeline]] with `summarizeLimit: 3` (about 30 s of runtime).
- iOS decides the real timing based on how often the app is used. This is the accepted cost of
  [[local-only-no-server]].
- Debug trigger (paused in the Xcode debugger):
  `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.kinghua.UMDEvents.refresh"]`
