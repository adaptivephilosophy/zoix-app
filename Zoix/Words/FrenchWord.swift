import Foundation

struct FrenchWord: Equatable, Sendable, Codable {
    var french: String
    var english: String
    var partOfSpeech: String?
    var exampleFrench: String?
    var exampleEnglish: String?
    var source: Source

    enum Source: String, Equatable, Sendable, Codable {
        case liveFeed
        case bundled
    }

    init(
        french: String,
        english: String,
        partOfSpeech: String? = nil,
        exampleFrench: String? = nil,
        exampleEnglish: String? = nil,
        source: Source = .bundled
    ) {
        self.french = french
        self.english = english
        self.partOfSpeech = partOfSpeech
        self.exampleFrench = exampleFrench
        self.exampleEnglish = exampleEnglish
        self.source = source
    }
}

enum WordOfTheDayError: Error, Equatable {
    case unreadable
    case missingFields
}

enum WordDay {
    static let timeZone = TimeZone(identifier: "America/Los_Angeles")!

    static func dayKey(for date: Date) -> String {
        formatter.string(from: date)
    }

    static func calendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
