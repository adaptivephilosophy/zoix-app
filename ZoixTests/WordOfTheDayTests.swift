import XCTest
@testable import Zoix

final class WordOfTheDayTests: XCTestCase {
    func testBundledListIsUsable() {
        XCTAssertGreaterThanOrEqual(BundledFrenchWords.all.count, 30)
        var seen = Set<String>()
        for word in BundledFrenchWords.all {
            XCTAssertFalse(word.french.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertFalse(word.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertEqual(word.source, .bundled)
            XCTAssertTrue(seen.insert(word.french.lowercased()).inserted, word.french)
        }
    }

    func testBundledWordIsStableAndChangesAtPacificMidnight() {
        var utc = Calendar(identifier: .gregorian)
        utc.timeZone = TimeZone(secondsFromGMT: 0)!
        // 06:30 UTC is still December 31 in Pacific time whether the offset
        // is UTC-8 or UTC-7. 09:00 UTC is January 1 in both.
        let before = utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 6, minute: 30))!
        let after = utc.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: 9, minute: 0))!
        XCTAssertEqual(BundledFrenchWords.word(on: before), BundledFrenchWords.word(on: before))
        XCTAssertEqual(WordDay.dayKey(for: before), "2025-12-31")
        XCTAssertEqual(WordDay.dayKey(for: after), "2026-01-01")
        XCTAssertNotEqual(BundledFrenchWords.word(on: before).french, BundledFrenchWords.word(on: after).french)
    }

    func testParsesTransparentLanguageFeed() throws {
        let word = try WordOfTheDayParser.parse(Data(WordSamples.feed.utf8))
        XCTAssertEqual(word.french, "grognon")
        XCTAssertEqual(word.english, "grumpy")
        XCTAssertEqual(word.partOfSpeech, "adjective")
        XCTAssertEqual(word.exampleFrench, "Je dois avouer que je suis assez grognon si je ne dors pas assez.")
        XCTAssertEqual(word.exampleEnglish, "I must confess that I am rather grumpy if I don't get enough sleep.")
        XCTAssertEqual(word.source, .liveFeed)
    }

    func testParserRejectsEmptyAndIncompleteFeeds() {
        XCTAssertThrowsError(try WordOfTheDayParser.parse(Data()))
        let incomplete = "<words><word>bonjour</word></words>"
        XCTAssertThrowsError(try WordOfTheDayParser.parse(Data(incomplete.utf8))) { error in
            XCTAssertEqual(error as? WordOfTheDayError, .missingFields)
        }
    }

    func testLiveFeedURLIsThePublicTransparentLanguageFeed() {
        XCTAssertEqual(
            WordOfTheDayService.liveFeedURL.absoluteString,
            "https://wotd.transparent.com/rss/fr-widget.xml"
        )
    }
}

enum WordSamples {
    static let feed = """
    <xml xmlns:wotd="http://www.transparent.com/word-of-the-day/">
    <words>
    <date>11-18-2026</date>
    <langname>French</langname>
    <wordtype>adjective</wordtype>
    <word>grognon</word>
    <translation>grumpy</translation>
    <fnphrase>Je dois avouer que je suis assez grognon si je ne dors pas assez.</fnphrase>
    <enphrase>I must confess that I am rather grumpy if I don't get enough sleep.</enphrase>
    </words>
    </xml>
    """
}
