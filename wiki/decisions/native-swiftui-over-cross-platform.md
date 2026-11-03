---
type: decision
tags: [decision, architecture, platform]
status: accepted
date: 2026-11-02
sources: [raw/2026-11-02-user-decisions.md]
---
# Decision: native SwiftUI rather than a cross-platform framework

Filed from a Q&A ("would cross-platform break Liquid Glass?").
- Self-drawing frameworks (Flutter, Compose Multiplatform) can't render real Liquid Glass; community packages only
  imitate it. Native-control frameworks (React Native, .NET MAUI) get it for system bars only, not custom views.
- More important: the core features ([[summarizer]], [[translation]], [[background-refresh]], [[notifications]]) are
  Swift-only Apple APIs and would need native bridges anyway. Android has no Foundation Models equivalent.
- If Android is ever needed: share `UMDEvents/Fetching/` logic via Kotlin Multiplatform and keep native UIs.
(Ecosystem support changes quickly; re-check before relying on this.)
