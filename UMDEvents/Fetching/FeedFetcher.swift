import Foundation

struct FetchResult: Sendable {
    var items: [FetchedItem] = []
    var succeededSourceIDs: Set<String> = []
    /// Source name -> error description.
    var failures: [String: String] = [:]
}

struct FeedFetcher: Sendable {
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 26_0 like Mac OS X) UMDEvents/1.0"

    static func download(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw FeedError.badStatus(http.statusCode)
        }
        return data
    }

    func fetch(_ source: FeedSource) async throws -> [FetchedItem] {
        let data = try await Self.download(source.url)
        switch source.kind {
        case .rss:
            return try RSSParser.parse(data, sourceID: source.id)
        case .ical:
            return ICalParser.parse(String(decoding: data, as: UTF8.self), sourceID: source.id)
        case .htmlList(let rule):
            return HTMLListScraper.parse(String(decoding: data, as: UTF8.self), baseURL: source.url,
                                         rule: rule, sourceID: source.id)
        }
    }

    func fetchAll(_ sources: [FeedSource]) async -> FetchResult {
        await withTaskGroup(of: (FeedSource, Result<[FetchedItem], Error>).self) { group in
            for source in sources {
                group.addTask {
                    do { return (source, .success(try await fetch(source))) }
                    catch { return (source, .failure(error)) }
                }
            }
            var result = FetchResult()
            for await (source, outcome) in group {
                switch outcome {
                case .success(let items):
                    result.items += items
                    result.succeededSourceIDs.insert(source.id)
                case .failure(let error):
                    result.failures[source.name] = error.localizedDescription
                }
            }
            return result
        }
    }
}
