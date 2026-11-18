import XCTest
@testable import Zoix

final class ArticleLogicTests: XCTestCase {
    func testDecodesLiveFeedShape() throws {
        let feed = try ArticleDecoder.decodeFeed(Data(ArticleSamples.liveShape.utf8))
        XCTAssertEqual(feed.items.count, 2)
        XCTAssertEqual(feed.items[0].title, "Tuesday, Nov 17, 2026")
        XCTAssertEqual(feed.items[0].tags, [])
        XCTAssertEqual(feed.items[0].kind, "Page")
        XCTAssertEqual(
            feed.items[0].url.absoluteString,
            "https://adaptivephilosophy.notion.site/Tuesday-Nov-17-2026-41ba657440a58189946ffcdbed575d5b"
        )
        XCTAssertEqual(feed.items[1].tags, ["public", "News"])
        XCTAssertNotNil(feed.generatedAt)
    }

    func testRejectsNonHTTPSArticleURL() {
        let json = """
        {"items":[{"id":"1","title":"T","lastEdited":"2026-11-17T16:38:00.000Z","url":"http://example.com/a","kind":"Page","tags":[]}]}
        """
        XCTAssertThrowsError(try ArticleDecoder.decodeFeed(Data(json.utf8)))
    }

    func testMissingTagsAndKindStillDecode() throws {
        let json = """
        {"items":[{"id":"1","title":"Hello","lastEdited":"2026-11-17T16:38:00Z","url":"https://example.test/1"}]}
        """
        let feed = try ArticleDecoder.decodeFeed(Data(json.utf8))
        XCTAssertEqual(feed.items[0].tags, [])
        XCTAssertEqual(feed.items[0].kind, "")
        XCTAssertEqual(feed.items[0].created, feed.items[0].lastEdited)
    }

    func testCacheRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let feed = try ArticleDecoder.decodeFeed(Data(ArticleSamples.liveShape.utf8))
        let cache = ArticleCache(directory: directory)
        try cache.save(feed)
        let loaded = try XCTUnwrap(cache.load())
        XCTAssertEqual(loaded.items.map(\.id), feed.items.map(\.id))
        XCTAssertEqual(loaded.items.map(\.title), feed.items.map(\.title))
        XCTAssertEqual(loaded.items.map(\.tags), feed.items.map(\.tags))
        for (lhs, rhs) in zip(loaded.items, feed.items) {
            XCTAssertEqual(lhs.lastEdited.timeIntervalSince1970, rhs.lastEdited.timeIntervalSince1970, accuracy: 0.001)
        }
    }

    func testSearchSortAndTagFilter() throws {
        let newer = try ArticleSamples.make(id: "n", title: "Newer", lastEdited: "2026-11-17T16:38:00.000Z", kind: "Notes", tags: ["News"])
        let older = try ArticleSamples.make(id: "o", title: "Older", lastEdited: "2026-11-15T16:38:00.000Z", kind: "Notes", tags: ["Philosophy"])
        let alpha = try ArticleSamples.make(id: "a", title: "Alpha", lastEdited: "2026-11-17T16:38:00.000Z", kind: "Page", tags: ["News", "public"])
        let articles = [older, newer, alpha]

        let newest = ArticleQuery(newestFirst: true).filtered(articles).map(\.title)
        XCTAssertEqual(newest, ["Alpha", "Newer", "Older"])

        let oldest = ArticleQuery(newestFirst: false).filtered(articles).map(\.title)
        XCTAssertEqual(oldest, ["Older", "Alpha", "Newer"])

        let byTitle = ArticleQuery(searchText: "  newer  ").filtered(articles).map(\.title)
        XCTAssertEqual(byTitle, ["Newer"])

        // "new" matches the title Newer and the tag News on Alpha.
        let byTitleOrTag = ArticleQuery(searchText: "new").filtered(articles).map(\.title)
        XCTAssertEqual(byTitleOrTag, ["Alpha", "Newer"])

        let byTag = ArticleQuery(searchText: "phil").filtered(articles).map(\.title)
        XCTAssertEqual(byTag, ["Older"])

        let kindIsNotSearchable = ArticleQuery(searchText: "page").filtered(articles)
        XCTAssertTrue(kindIsNotSearchable.isEmpty)

        let news = ArticleQuery(tag: "news").filtered(articles).map(\.title)
        XCTAssertEqual(news, ["Alpha", "Newer"])

        let both = ArticleQuery(searchText: "alpha", tag: "News").filtered(articles).map(\.title)
        XCTAssertEqual(both, ["Alpha"])

        XCTAssertEqual(ArticleQuery.tags(in: articles), ["News", "Philosophy", "public"])
    }

    func testScreenshotSampleIsOffline() {
        XCTAssertFalse(ScreenshotSample.isEnabled)
        XCTAssertEqual(ScreenshotSample.argument, "-ZoixScreenshotSample")
        let articles = ScreenshotSample.articles()
        XCTAssertEqual(articles.count, 3)
        XCTAssertTrue(articles.allSatisfy { $0.url.scheme == "https" })
        XCTAssertFalse(ScreenshotSample.homeHTML.isEmpty)
    }

    func testKnownLinks() {
        XCTAssertEqual(AppLinks.homePage.absoluteString, "https://zoix.ai")
        XCTAssertEqual(AppLinks.articlesFeed.absoluteString, "https://ap-notion-articles.vercel.app/api/articles")
        XCTAssertEqual(AppLinks.givingPage.absoluteString, "https://www.paypal.com/ncp/payment/7LP669JW6TBYW")
        XCTAssertEqual(
            AppLinks.privacyPolicy.absoluteString,
            "https://adaptivephilosophy.github.io/zoix-app/privacy.html"
        )
        XCTAssertEqual(
            AppLinks.supportPage.absoluteString,
            "https://adaptivephilosophy.github.io/zoix-app/support.html"
        )
        XCTAssertEqual(ExternalLinkPolicy.decision(for: AppLinks.givingPage), .openOutsideApp)
        XCTAssertEqual(ExternalLinkPolicy.decision(for: AppLinks.homePage), .loadInWebView)
    }
}

enum ArticleSamples {
    static let liveShape = """
    {
      "source": {"name": "Adaptive Philosophy Foundation"},
      "generatedAt": "2026-11-18T06:00:30.075Z",
      "generatedBy": "test",
      "items": [
        {
          "id": "41ba6574-40a5-8189-946f-fcdbed575d5b",
          "title": "Tuesday, Nov 17, 2026",
          "lastEdited": "2026-11-17T16:38:00.000Z",
          "created": "2026-11-17T16:38:00.000Z",
          "url": "https://adaptivephilosophy.notion.site/Tuesday-Nov-17-2026-41ba657440a58189946ffcdbed575d5b",
          "kind": "Page",
          "tags": []
        },
        {
          "id": "404a6574-40a5-81e8-9939-ed6f08181fc7",
          "title": "Daily Log",
          "lastEdited": "2026-11-17T05:25:00.000Z",
          "created": "2026-10-25T16:04:00.000Z",
          "url": "https://adaptivephilosophy.notion.site/Daily-Log",
          "kind": "Notes",
          "tags": ["public", "News"]
        }
      ]
    }
    """

    static func make(
        id: String,
        title: String,
        lastEdited: String,
        created: String? = nil,
        kind: String = "Notes",
        tags: [String] = []
    ) throws -> Article {
        let createdValue = created ?? lastEdited
        let tagJSON = tags.map { "\"\($0)\"" }.joined(separator: ",")
        let json = """
        {"items":[{"id":"\(id)","title":"\(title)","lastEdited":"\(lastEdited)","created":"\(createdValue)","url":"https://example.test/\(id)","kind":"\(kind)","tags":[\(tagJSON)]}]}
        """
        return try ArticleDecoder.decodeFeed(Data(json.utf8)).items[0]
    }
}
