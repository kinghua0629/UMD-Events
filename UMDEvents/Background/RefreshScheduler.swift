import BackgroundTasks
import Foundation

enum RefreshScheduler {
    static let taskIdentifier = "com.kinghua.UMDEvents.refresh"

    /// Asks iOS to wake the app no earlier than `interval` from now. iOS picks the actual time.
    static func schedule(after interval: TimeInterval) {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: interval)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("BGTaskScheduler submit failed: \(error)")
        }
    }

    @MainActor
    static func handleBackgroundRefresh() async {
        schedule(after: AppSettings.shared.refreshInterval)
        // Background refresh gets ~30 s, so only summarize a few articles per run.
        await AppEnvironment.shared.refresh(summarizeLimit: 3)
    }
}
