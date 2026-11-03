---
type: decision
tags: [decision, project]
status: accepted
date: 2026-11-02
---
# Decision: bundle ID `com.kinghua.UMDEvents`

The plan said `edu.umd.events`. Changed to avoid implying the university publishes the app. The background task ID
follows it: `com.kinghua.UMDEvents.refresh` ([[background-refresh]]). If renamed, update `project.pbxproj`,
`Info.plist` and `RefreshScheduler.taskIdentifier` together.
