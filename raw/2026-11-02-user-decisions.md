# User decisions — 2026-11-02

Recorded verbatim/near-verbatim from the planning and follow-up conversation.

## Initial request
> 我想要构建一个ios app，我想要做一个可以收集学校的新闻的app，并且通过iPhone本地的apple intelligence总结内容并推送消息

## Planning answers
- News sources: Maryland Today, The Diamondback, UMD events calendar, department/club websites, **plus sports news** (added by user).
- Push mechanism: **pure local, no server** (BGAppRefreshTask + local notifications; accepted that iOS controls timing).
- Devices without Apple Intelligence: **fall back to the feed's own summary**.
- Language: **follow the system language** (UI and summaries).

## Follow-ups (same day)
1. Asked whether a cross-platform framework would have problems with Liquid Glass. Answer given: self-drawing
   frameworks (Flutter, Compose MP) don't get real Liquid Glass; native-control frameworks (React Native, MAUI) get it
   for system bars only. Bigger issue: Foundation Models, BGTaskScheduler and notifications are Swift-native anyway.
   Recommendation: stay SwiftUI; if Android is ever needed, share parsing logic via Kotlin Multiplatform.
2. > 能不能导航栏做在最底下？ → moved category navigation to a bottom TabView.
3. > 我想让语言跟随系统默认，如果不是英语的话，可以增加一个翻译button，而且可以的话，给项目加一个wiki,follow这个pattern: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
   → added an on-device Translate button (non-English systems only) and this wiki.
