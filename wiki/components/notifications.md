---
type: component
tags: [component, notifications]
updated: 2026-11-02
---
# Notifications

`UMDEvents/Notifications/Notifier.swift`, local only (`UNNotificationRequest` with a nil trigger).

- **One notification per refresh**: a single new item shows its title, source and summary, with `userInfo["articleID"]`
  for deep linking. Several items become "N new updates" plus the first three titles.
- **Readiness** ([[refresh-pipeline]] step 6): send once the item has an AI summary, OR AI is unavailable, OR it has
  ≥2 failed attempts, OR it's an event, OR it was first seen >6 h ago. Otherwise wait for the next run.
- Disabled categories: items are marked notified anyway, so turning a category on later doesn't dump a backlog.
- Tapping a notification: `AppDelegate` sets `AppEnvironment.pendingArticleID`, and `ContentView` switches to the
  item's category tab and pushes the article ([[ui]]).
- Foreground presentation: banner, list and sound.
- Permission is requested on first launch (skipped with the DEBUG flag `-skipNotificationPrompt`; see [[testing-and-debugging]]).
