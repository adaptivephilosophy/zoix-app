import XCTest
@testable import Zoix

final class StoreTests: XCTestCase {
    private var directory: URL!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        ArticleStubURLProtocol.storage = .init()
        WordStubURLProtocol.storage = .init()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        directory = nil
        super.tearDown()
    }

    func testRefreshSavesArticles() async throws {
        ArticleStubURLProtocol.storage.data = Data(ArticleSamples.liveShape.utf8)
        let store = await makeArticleStore()
        await store.refresh()
        let articles = await store.articles
        let status = await store.status
        XCTAssertEqual(articles.map(\.title), ["Tuesday, Nov 17, 2026", "Daily Log"])
        XCTAssertEqual(status, .loaded)
        let cached = try ArticleCache(directory: directory.appendingPathComponent("articles")).load()
        XCTAssertEqual(cached?.items.count, 2)
    }

    func testFailedRefreshKeepsSavedArticles() async throws {
        let cache = ArticleCache(directory: directory.appendingPathComponent("articles"))
        let feed = try ArticleDecoder.decodeFeed(Data(ArticleSamples.liveShape.utf8))
        try cache.save(feed)
        ArticleStubURLProtocol.storage.error = URLError(.notConnectedToInternet)
        let store = await ArticleStore(
            session: StubSession.make(protocolClass: ArticleStubURLProtocol.self),
            cache: cache,
            feedURL: URL(string: "https://example.test/articles")!
        )
        await store.loadCachedThenRefresh()
        let articles = await store.articles
        let status = await store.status
        XCTAssertEqual(articles.count, 2)
        guard case .showingCached(let message) = status else {
            return XCTFail("Expected saved articles, got \(status)")
        }
        XCTAssertTrue(message.contains("offline"))
    }

    func testHTTPErrorWithoutCacheFails() async {
        ArticleStubURLProtocol.storage.status = 503
        ArticleStubURLProtocol.storage.data = Data("{}".utf8)
        let store = await makeArticleStore()
        await store.refresh()
        let articles = await store.articles
        let status = await store.status
        XCTAssertEqual(articles.count, 0)
        guard case .failed(let message) = status else {
            return XCTFail("Expected a failure, got \(status)")
        }
        XCTAssertTrue(message.contains("503"))
    }

    func testLiveWordReplacesBundledWordAndIsCached() async throws {
        WordStubURLProtocol.storage.data = Data(WordSamples.feed.utf8)
        let now = Date(timeIntervalSince1970: 1_763_424_000)
        let store = await makeWordStore()
        await store.load(now: now)
        let word = await store.word
        XCTAssertEqual(word.french, "grognon")
        XCTAssertEqual(word.english, "grumpy")
        XCTAssertEqual(word.source, .liveFeed)
        let cached = try WordCache(directory: directory.appendingPathComponent("words")).load()
        XCTAssertEqual(cached?.word.french, "grognon")
        XCTAssertEqual(cached?.dayKey, WordDay.dayKey(for: now))
    }

    func testWordFeedFailureUsesBundledList() async {
        WordStubURLProtocol.storage.error = URLError(.notConnectedToInternet)
        let now = Date(timeIntervalSince1970: 1_763_424_000)
        let store = await makeWordStore()
        await store.load(now: now)
        let word = await store.word
        XCTAssertEqual(word, BundledFrenchWords.word(on: now))
        XCTAssertEqual(word.source, .bundled)
    }

    func testTodaysCachedLiveWordIsUsedOffline() async throws {
        let now = Date(timeIntervalSince1970: 1_763_424_000)
        let cache = WordCache(directory: directory.appendingPathComponent("words"))
        let saved = FrenchWord(french: "calme", english: "calm", source: .liveFeed)
        try cache.save(CachedWord(dayKey: WordDay.dayKey(for: now), word: saved))
        WordStubURLProtocol.storage.error = URLError(.notConnectedToInternet)
        let store = await WordOfTheDayStore(
            session: StubSession.make(protocolClass: WordStubURLProtocol.self),
            cache: cache,
            feedURL: URL(string: "https://example.test/word")!
        )
        await store.load(now: now)
        let word = await store.word
        XCTAssertEqual(word.french, "calme")
        XCTAssertEqual(word.source, .liveFeed)
    }

    private func makeArticleStore() async -> ArticleStore {
        await ArticleStore(
            session: StubSession.make(protocolClass: ArticleStubURLProtocol.self),
            cache: ArticleCache(directory: directory.appendingPathComponent("articles")),
            feedURL: URL(string: "https://example.test/articles")!
        )
    }

    private func makeWordStore() async -> WordOfTheDayStore {
        await WordOfTheDayStore(
            session: StubSession.make(protocolClass: WordStubURLProtocol.self),
            cache: WordCache(directory: directory.appendingPathComponent("words")),
            feedURL: URL(string: "https://example.test/word")!
        )
    }
}
