# UMD 校园新闻 iOS App（本地 Apple Intelligence 总结 + 推送）

## Context
在空目录 `/Users/kinghua/UMD-Events` 中从零构建一个 iOS app：聚合 UMD 的多个新闻/活动来源，用 iPhone 本地的 Apple Intelligence（Foundation Models 框架）生成摘要，并通过**本地通知**推送新内容。用户确认：
- 来源：Maryland Today、The Diamondback、UMD 活动日历、院系/社团网站、体育新闻（UMTerps）
- 纯本地，不要服务器（BGAppRefreshTask 后台刷新，iOS 决定执行时机）
- 不支持 Apple Intelligence 的设备：降级为 RSS 自带简介
- 语言：界面本地化，摘要跟随系统语言

环境：Xcode 27.2，有 iPhone 18 Pro 等模拟器；无 xcodegen/tuist。

## 技术选型
- SwiftUI + SwiftData，最低 iOS 26（Foundation Models 最低版本）
- `FoundationModels`：`SystemLanguageModel.default.availability` 检测；`LanguageModelSession` + `@Generable` 结构化输出
- `BackgroundTasks`：`BGAppRefreshTask`（标识 `edu.umd.events.refresh`）
- `UserNotifications`：本地通知
- 解析：Foundation `XMLParser` 自写 RSS/Atom 解析器；iCal 简易解析器；HTML 用 SPM 依赖 **SwiftSoup**（仅用于无 RSS 的院系/社团网站）
- 工程创建：手写 `project.yml` 不可用（无 xcodegen）→ 用 Xcode 模板结构手动生成 `.xcodeproj`（或 `brew install xcodegen` 后用 project.yml，实施时二选一，优先 xcodegen 以便维护）

## 目录结构
```
UMDEvents/
  App/UMDEventsApp.swift          # 入口，注册 BG 任务，ModelContainer
  Models/Article.swift            # @Model: id(guid/url hash), sourceID, title, link, published, rawSummary, body, aiSummary, isRead, notified
  Models/Source.swift             # 来源定义: id, name, kind(.rss/.ical/.html), url, category(news/events/sports/dept), enabled, htmlSelectors?
  Sources/DefaultSources.swift    # 内置来源列表
  Fetching/FeedFetcher.swift      # 并发抓取所有启用来源 (TaskGroup)，去重入库
  Fetching/RSSParser.swift        # RSS 2.0 + Atom
  Fetching/ICalParser.swift       # 活动日历 .ics
  Fetching/HTMLScraper.swift      # SwiftSoup + 每个站点的 CSS 选择器
  Fetching/ArticleTextExtractor.swift # 抓正文（取 <article>/<p>），截断到模型上下文限制内
  AI/Summarizer.swift             # Foundation Models 封装 + 降级逻辑
  Background/RefreshScheduler.swift # 注册/调度 BGAppRefreshTask，执行 抓取→总结→通知
  Notifications/Notifier.swift    # 权限请求，合并通知（单条/“N 条新动态”摘要）
  Views/FeedView.swift            # 分类 Tab（新闻/活动/体育/院系）+ 列表
  Views/ArticleDetailView.swift   # AI 摘要卡片 + 原文链接 (SFSafariViewController)
  Views/SettingsView.swift        # 来源开关、推送开关/分类、刷新频率、添加自定义 RSS
  Resources/Localizable.xcstrings # 中/英
```

## 关键实现
1. **来源**（`DefaultSources.swift`）：Maryland Today RSS、Diamondback RSS、UMD 活动日历（calendar.umd.edu 的 RSS/iCal）、UMTerps 体育 RSS、几个院系站点（HTML 选择器）。实施第一步先用 WebFetch 逐个核实 feed URL 是否可用，不可用的改用 HTML 抓取。用户可在设置里添加自定义 RSS/iCal URL。
2. **Summarizer**：
   - `availability == .available` → 新建 `LanguageModelSession(instructions:)`，instructions 要求用 `Locale.current` 对应语言输出；`@Generable struct NewsSummary { headline: String; summary: String (2-3 句); keyPoints: [String]; eventDate: String? }`
   - 输入 = 标题 + 正文（截断约 3000 字符以适配上下文窗口），捕获 `exceededContextWindowSize` 时进一步截断重试
   - 不可用（设备不支持/未开启/模型未下载）→ 返回 `rawSummary`（去 HTML 标签），UI 标注“原文简介”
   - 串行处理（模型同一时间只处理一个请求），后台任务中每次最多总结 ~5 篇，剩余留到下次或前台打开时
3. **后台刷新**（`RefreshScheduler`）：Info.plist 加 `BGTaskSchedulerPermittedIdentifiers` 与 `UIBackgroundModes: fetch`；`.backgroundTask(.appRefresh(...))` SwiftUI 修饰符处理；每次执行后重新 `submit`，`earliestBeginDate` = 用户设置（默认 1 小时）；设置 expirationHandler 时取消任务并保存进度。
4. **通知**：只为 `notified == false` 且已有摘要的新文章发；新文章 1 条→标题+AI 摘要；多条→“N 条新动态”+前两条标题；按分类开关过滤；点通知深链到详情页。
5. **前台**：下拉刷新走同一 pipeline；打开 app 时补总结积压文章。

## 实施顺序
1. 创建 Xcode 工程（iOS 26 target、SwiftSoup SPM、BG/通知 capability）
2. 核实来源 URL → 写 `DefaultSources`
3. 解析器 + FeedFetcher + SwiftData 模型
4. Summarizer（含降级）
5. 列表/详情/设置 UI + 本地化
6. 后台刷新 + 通知

## 验证
- 单元测试（Swift Testing）：RSSParser/ICalParser 用保存的样例 feed；去重逻辑；Summarizer 降级分支
- `xcodebuild -scheme UMDEvents -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build test`
- 模拟器运行（Mac 启用 Apple Intelligence 时模拟器可用 Foundation Models）：检查各来源有数据、摘要生成、系统语言切换中/英
- 后台任务调试：暂停调试器执行 `e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"edu.umd.events.refresh"]`，确认收到本地通知
- 真机（iPhone 15 Pro+）验证实际后台调度与通知；在不支持设备/关闭 Apple Intelligence 时验证降级显示
