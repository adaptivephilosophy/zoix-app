import Foundation
import Observation

@MainActor
@Observable
final class ArticleStore {
    private(set) var articles: [Article] = []
    private(set) var generatedAt: Date?
    private(set) var isLoading = false
    private(set) var status: Status = .idle

    enum Status: Equatable {
        case idle
        case loaded
        case showingCached(String)
        case failed(String)
    }

    private let session: URLSession
    private let cache: ArticleCache
    private let feedURL: URL

    init(session: URLSession = .shared, cache: ArticleCache = .live, feedURL: URL = AppLinks.articlesFeed) {
        self.session = session
        self.cache = cache
        self.feedURL = feedURL
    }

    /// Fills the list for screenshots. Does not touch the network or the cache.
    func showSample() {
        articles = ScreenshotSample.articles()
        generatedAt = articles.first?.lastEdited
        status = .loaded
        isLoading = false
    }

    func loadCachedThenRefresh() async {
        if articles.isEmpty, let cached = try? cache.load(), !cached.items.isEmpty {
            articles = cached.items
            generatedAt = cached.generatedAt
        }
        await refresh()
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let feed = try await Self.fetchFeed(session: session, url: feedURL)
            articles = feed.items
            generatedAt = feed.generatedAt
            status = .loaded
            try? cache.save(feed)
        } catch {
            if articles.isEmpty, let cached = try? cache.load(), !cached.items.isEmpty {
                articles = cached.items
                generatedAt = cached.generatedAt
                status = .showingCached(Self.message(for: error, hasArticles: true))
            } else if !articles.isEmpty {
                status = .showingCached(Self.message(for: error, hasArticles: true))
            } else {
                status = .failed(Self.message(for: error, hasArticles: false))
            }
        }
    }

    static func fetchFeed(session: URLSession, url: URL) async throws -> ArticleFeed {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Zoix/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 30
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw ArticleFeedError.badResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw ArticleFeedError.http(http.statusCode)
        }
        let feed: ArticleFeed
        do {
            feed = try ArticleDecoder.decodeFeed(data)
        } catch {
            throw ArticleFeedError.unreadable
        }
        guard !feed.items.isEmpty else {
            throw ArticleFeedError.empty
        }
        return feed
    }

    static func message(for error: Error, hasArticles: Bool) -> String {
        let saved = hasArticles ? " Showing the last saved articles." : ""
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .cannotFindHost, .cannotConnectToHost:
                return "You appear to be offline." + saved
            case .timedOut:
                return "The articles feed timed out." + saved
            default:
                break
            }
        }
        if let feedError = error as? ArticleFeedError {
            return (feedError.errorDescription ?? "The articles feed could not be read.") + saved
        }
        return "The articles could not be refreshed." + saved
    }
}
