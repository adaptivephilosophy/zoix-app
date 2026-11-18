import Foundation

struct Article: Identifiable, Equatable, Sendable {
    var id: String
    var title: String
    var lastEdited: Date
    var created: Date
    var url: URL
    var kind: String
    var tags: [String]
}

struct ArticleFeed: Equatable, Sendable {
    var generatedAt: Date?
    var items: [Article]
}

enum ArticleFeedError: Error, Equatable, LocalizedError {
    case badResponse
    case http(Int)
    case empty
    case unreadable

    var errorDescription: String? {
        switch self {
        case .badResponse:
            return "The articles feed returned an unexpected response."
        case .http(let code):
            return "The articles feed returned HTTP \(code)."
        case .empty:
            return "The articles feed was empty."
        case .unreadable:
            return "The articles feed could not be read."
        }
    }
}

enum ArticleDecoder {
    private static let fractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func date(from string: String) -> Date? {
        fractional.date(from: string) ?? plain.date(from: string)
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unrecognized date")
            }
            return date
        }
        return decoder
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(fractional.string(from: date))
        }
        return encoder
    }

    static func decodeFeed(_ data: Data) throws -> ArticleFeed {
        try makeDecoder().decode(ArticleFeed.self, from: data)
    }

    static func encodeFeed(_ feed: ArticleFeed) throws -> Data {
        try makeEncoder().encode(feed)
    }
}

extension Article: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, title, lastEdited, created, url, kind, tags
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        let decodedTitle = try container.decode(String.self, forKey: .title)
        title = decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty, !title.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .title, in: container, debugDescription: "Article needs an id and a title")
        }
        lastEdited = try container.decode(Date.self, forKey: .lastEdited)
        created = try container.decodeIfPresent(Date.self, forKey: .created) ?? lastEdited
        url = try container.decode(URL.self, forKey: .url)
        guard url.scheme?.lowercased() == "https" else {
            throw DecodingError.dataCorruptedError(forKey: .url, in: container, debugDescription: "Article URL must be https")
        }
        kind = try container.decodeIfPresent(String.self, forKey: .kind) ?? ""
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(lastEdited, forKey: .lastEdited)
        try container.encode(created, forKey: .created)
        try container.encode(url, forKey: .url)
        try container.encode(kind, forKey: .kind)
        try container.encode(tags, forKey: .tags)
    }
}

extension ArticleFeed: Codable {}

enum ArticleDateFormat {
    static func string(from date: Date) -> String {
        formatter.string(from: date)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
