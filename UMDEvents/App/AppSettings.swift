import Foundation
import Observation

@Observable @MainActor
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let disabled = "disabledSourceIDs"
        static let custom = "customSources"
        static let notify = "notifyCategories"
        static let interval = "refreshInterval"
        static let known = "knownSourceIDs"
    }

    private let defaults = UserDefaults.standard

    var disabledSourceIDs: Set<String> {
        didSet { defaults.set(Array(disabledSourceIDs), forKey: Keys.disabled) }
    }

    var customSources: [FeedSource] {
        didSet { defaults.set(try? JSONEncoder().encode(customSources), forKey: Keys.custom) }
    }

    var notifyCategories: Set<FeedCategory> {
        didSet { defaults.set(notifyCategories.map(\.rawValue), forKey: Keys.notify) }
    }

    var refreshInterval: TimeInterval {
        didSet { defaults.set(refreshInterval, forKey: Keys.interval) }
    }

    /// Sources fetched successfully at least once (their backlog is never notified).
    var knownSourceIDs: Set<String> {
        didSet { defaults.set(Array(knownSourceIDs), forKey: Keys.known) }
    }

    private init() {
        disabledSourceIDs = Set(defaults.stringArray(forKey: Keys.disabled) ?? [])
        customSources = defaults.data(forKey: Keys.custom)
            .flatMap { try? JSONDecoder().decode([FeedSource].self, from: $0) } ?? []
        notifyCategories = defaults.stringArray(forKey: Keys.notify)
            .map { Set($0.compactMap(FeedCategory.init(rawValue:))) } ?? [.news, .sports, .department]
        let interval = defaults.double(forKey: Keys.interval)
        refreshInterval = interval > 0 ? interval : 3600
        knownSourceIDs = Set(defaults.stringArray(forKey: Keys.known) ?? [])
    }

    var allSources: [FeedSource] { DefaultSources.all + customSources }
    var enabledSources: [FeedSource] { allSources.filter { !disabledSourceIDs.contains($0.id) } }

    func isEnabled(_ source: FeedSource) -> Bool { !disabledSourceIDs.contains(source.id) }

    func setEnabled(_ source: FeedSource, _ enabled: Bool) {
        if enabled { disabledSourceIDs.remove(source.id) } else { disabledSourceIDs.insert(source.id) }
    }
}
