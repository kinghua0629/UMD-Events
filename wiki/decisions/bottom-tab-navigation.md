---
type: decision
tags: [decision, ui]
status: accepted
date: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md, raw/2026-11-02-simulator-findings.md]
---
# Decision: bottom tab bar for categories

**Before:** a segmented Picker in `.safeAreaInset(edge: .top)`, which also hid the large navigation title.
**After (user request):** a `TabView` with 5 category tabs. On iOS 26 it gets Liquid Glass for free and minimizes on
scroll. Settings stays a toolbar gear, because a 6th tab would collapse into "More" on iPhone. See [[ui]].
