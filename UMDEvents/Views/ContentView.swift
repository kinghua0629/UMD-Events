import SwiftUI

enum AppTab: Hashable {
    case all
    case category(FeedCategory)
}

struct ContentView: View {
    @Environment(AppEnvironment.self) private var environment
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase
    @State private var selection: AppTab = .all
    /// Each tab keeps its own navigation stack.
    @State private var paths: [AppTab: [String]] = [:]
    @State private var showSettings = false

    var body: some View {
        TabView(selection: $selection) {
            Tab("All", systemImage: "square.stack", value: AppTab.all) {
                feed(.all)
            }
            ForEach(FeedCategory.allCases) { category in
                Tab(value: AppTab.category(category)) {
                    feed(.category(category))
                } label: {
                    Label { Text(category.title) } icon: { Image(systemName: category.symbol) }
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .task {
            #if DEBUG
            let arguments = ProcessInfo.processInfo.arguments
            let skipPrompt = arguments.contains("-skipNotificationPrompt")
            // `-openArticle <id>` opens a story on launch (for screenshots/manual testing).
            if let i = arguments.firstIndex(of: "-openArticle"), i + 1 < arguments.count {
                environment.pendingArticleID = arguments[i + 1]
            }
            #else
            let skipPrompt = false
            #endif
            if !skipPrompt { await Notifier.requestAuthorization() }
            if environment.isStale { await environment.refresh(summarizeLimit: 10) }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, environment.isStale else { return }
            Task { await environment.refresh(summarizeLimit: 10) }
        }
        .onChange(of: environment.pendingArticleID, initial: true) { _, id in
            guard let id else { return }
            openFromNotification(id)
            environment.pendingArticleID = nil
        }
    }

    private func feed(_ tab: AppTab) -> some View {
        NavigationStack(path: pathBinding(tab)) {
            FeedListView(category: category(of: tab))
                .navigationTitle(title(of: tab))
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Settings", systemImage: "gearshape") { showSettings = true }
                    }
                }
                .refreshable { await environment.refresh(summarizeLimit: 10) }
                .navigationDestination(for: String.self) { id in
                    ArticleDetailView(articleID: id)
                }
        }
    }

    private func category(of tab: AppTab) -> FeedCategory? {
        if case .category(let category) = tab { return category }
        return nil
    }

    private func title(of tab: AppTab) -> Text {
        switch tab {
        case .all: Text("UMD Events")
        case .category(let category): Text(category.title)
        }
    }

    private func pathBinding(_ tab: AppTab) -> Binding<[String]> {
        Binding { paths[tab] ?? [] } set: { paths[tab] = $0 }
    }

    /// Opens the article in its category's tab (article IDs are "sourceID|guid").
    private func openFromNotification(_ id: String) {
        let sourceID = String(id.prefix { $0 != "|" })
        let tab = settings.allSources.first { $0.id == sourceID }.map { AppTab.category($0.category) } ?? .all
        selection = tab
        paths[tab] = [id]
    }
}
