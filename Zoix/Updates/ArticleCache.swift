import Foundation

/// Last successful articles feed, kept on device so the list still opens offline.
struct ArticleCache: Sendable {
    var directory: URL

    static var live: ArticleCache {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return ArticleCache(directory: base.appendingPathComponent("ZoixArticles", isDirectory: true))
    }

    var fileURL: URL {
        directory.appendingPathComponent("articles.json")
    }

    func load() throws -> ArticleFeed? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try ArticleDecoder.decodeFeed(data)
    }

    func save(_ feed: ArticleFeed) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try ArticleDecoder.encodeFeed(feed)
        try data.write(to: fileURL, options: .atomic)
    }
}
