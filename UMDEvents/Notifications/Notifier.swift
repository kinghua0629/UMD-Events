import Foundation
import UserNotifications

struct NotificationItem: Sendable {
    var id: String
    var title: String
    var body: String
    var source: String
}

enum Notifier {
    static let articleIDKey = "articleID"

    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Posts one notification per refresh: the story itself if there's one, a digest otherwise.
    static func post(_ items: [NotificationItem]) async {
        guard let first = items.first else { return }
        let content = UNMutableNotificationContent()
        content.threadIdentifier = "umd-news"
        content.sound = .default
        if items.count == 1 {
            content.title = first.title
            content.subtitle = first.source
            content.body = String(first.body.prefix(240))
            content.userInfo = [articleIDKey: first.id]
        } else {
            content.title = String(localized: "\(items.count) new updates")
            content.body = items.prefix(3).map { "• \($0.title)" }.joined(separator: "\n")
        }
        await add(content)
    }

    static func sendTest() async {
        await requestAuthorization()
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Test notification")
        content.body = String(localized: "Notifications are working.")
        content.sound = .default
        await add(content)
    }

    private static func add(_ content: UNNotificationContent) async {
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
