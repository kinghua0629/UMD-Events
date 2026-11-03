import Foundation
import Testing
@testable import UMDEvents

struct FeedFiltersTests {
    private func article() -> Article {
        let source = FeedSource(id: "test", name: "Campus", url: URL(string: "https://example.com")!,
                                kind: .rss, category: .events)
        return Article(item: FetchedItem(sourceID: source.id, guid: "1", title: "Robotics Workshop",
                                         summary: "Build a robot", location: "College Park"), source: source)
    }

    @Test func searchMatchesMultipleTermsAcrossFields() {
        let item = article()
        #expect(FeedFilters().matches(item, searchText: "ROBOTICS park"))
        #expect(!FeedFilters().matches(item, searchText: "robotics football"))
        #expect(FeedFilters().matches(item, searchText: "  \n "))
    }

    @Test func filtersCombineSourceCategoryAndReadStatus() {
        let item = article()
        var filters = FeedFilters(source: "Campus", category: "events", readState: .unread)
        #expect(filters.matches(item, searchText: ""))
        item.isRead = true
        #expect(!filters.matches(item, searchText: ""))
        filters.readState = .read
        filters.category = "news"
        #expect(!filters.matches(item, searchText: ""))
    }

    @Test func upcomingRequiresFutureEventAndRecentExcludesFuture() {
        let item = article()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var filters = FeedFilters(period: .upcoming)
        #expect(!filters.matches(item, searchText: "", now: now))
        item.eventStart = now.addingTimeInterval(3600)
        #expect(filters.matches(item, searchText: "", now: now))
        filters.period = .week
        #expect(!filters.matches(item, searchText: "", now: now))
        item.eventStart = now.addingTimeInterval(-3600)
        #expect(filters.matches(item, searchText: "", now: now))
        item.eventStart = now.addingTimeInterval(-8 * 86400)
        #expect(!filters.matches(item, searchText: "", now: now))
    }

    @Test @MainActor func welcomeAndInterestsPersist() throws {
        let suite = "WelcomeTests-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let settings = AppSettings(defaults: defaults)
        #expect(!settings.hasCompletedWelcome)
        #expect(settings.interests == Set(FeedCategory.allCases))
        settings.interests = [.sports]
        settings.hasCompletedWelcome = true
        let restored = AppSettings(defaults: defaults)
        #expect(restored.hasCompletedWelcome)
        #expect(restored.interests == [.sports])
    }
}
