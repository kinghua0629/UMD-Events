import SwiftUI
import SwiftData
import UserNotifications

@main
struct UMDEventsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    @State private var environment = AppEnvironment.shared
    @State private var settings = AppSettings.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(environment)
                .environment(settings)
        }
        .modelContainer(environment.container)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background {
                RefreshScheduler.schedule(after: settings.refreshInterval)
            }
        }
        .backgroundTask(.appRefresh(RefreshScheduler.taskIdentifier)) {
            await RefreshScheduler.handleBackgroundRefresh()
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        guard let id = response.notification.request.content.userInfo[Notifier.articleIDKey] as? String else { return }
        await MainActor.run { AppEnvironment.shared.pendingArticleID = id }
    }
}
