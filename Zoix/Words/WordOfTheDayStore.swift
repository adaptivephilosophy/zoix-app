import Foundation
import Observation

struct CachedWord: Codable, Equatable, Sendable {
    var dayKey: String
    var word: FrenchWord
}

struct WordCache: Sendable {
    var directory: URL

    static var live: WordCache {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return WordCache(directory: base.appendingPathComponent("ZoixWords", isDirectory: true))
    }

    var fileURL: URL {
        directory.appendingPathComponent("word.json")
    }

    func load() throws -> CachedWord? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(CachedWord.self, from: data)
    }

    func save(_ cached: CachedWord) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(cached)
        try data.write(to: fileURL, options: .atomic)
    }
}

@MainActor
@Observable
final class WordOfTheDayStore {
    private(set) var word: FrenchWord
    private(set) var isLoading = false

    private let session: URLSession
    private let cache: WordCache
    private let feedURL: URL

    init(session: URLSession = .shared, cache: WordCache = .live, feedURL: URL = WordOfTheDayService.liveFeedURL) {
        self.session = session
        self.cache = cache
        self.feedURL = feedURL
        self.word = BundledFrenchWords.word(on: Date())
    }

    /// Shows a bundled word for screenshots. Does not request the live feed.
    func showSample(now: Date = Date()) {
        word = BundledFrenchWords.word(on: now)
        isLoading = false
    }

    /// Shows today's cached live word when one exists. Otherwise shows the bundled word,
    /// then replaces it if the public feed answers.
    func load(now: Date = Date(), force: Bool = false) async {
        let key = WordDay.dayKey(for: now)
        if !force, let cached = try? cache.load(), cached.dayKey == key, cached.word.source == .liveFeed {
            word = cached.word
            return
        }
        word = BundledFrenchWords.word(on: now)
        isLoading = true
        defer { isLoading = false }
        do {
            var request = URLRequest(url: feedURL)
            request.timeoutInterval = 20
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("Zoix/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return
            }
            let live = try WordOfTheDayParser.parse(data)
            word = live
            try? cache.save(CachedWord(dayKey: key, word: live))
        } catch {
            // The bundled word stays on screen.
        }
    }
}
