import Foundation

enum WordOfTheDayService {
    /// Public French word-of-the-day feed: French word, English translation, and an example.
    /// No API key. Published by Transparent Language at wotd.transparent.com.
    ///
    /// TODO: If the Adaptive Philosophy Foundation publishes its own public
    /// mot-du-jour endpoint (a French word and an English meaning), replace
    /// this URL and update `WordOfTheDayParser` if the format differs.
    /// Do not point this at a private or invented API.
    static let liveFeedURL = URL(string: "https://wotd.transparent.com/rss/fr-widget.xml")!
}

enum WordOfTheDayParser {
    static func parse(_ data: Data) throws -> FrenchWord {
        let collector = Collector()
        let xml = XMLParser(data: data)
        xml.delegate = collector
        guard xml.parse() else {
            throw WordOfTheDayError.unreadable
        }
        let french = collector.values["word", default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        let english = collector.values["translation", default: ""].trimmingCharacters(in: .whitespacesAndNewlines)
        guard !french.isEmpty, !english.isEmpty else {
            throw WordOfTheDayError.missingFields
        }
        return FrenchWord(
            french: french,
            english: english,
            partOfSpeech: cleaned(collector.values["wordtype"]),
            exampleFrench: cleaned(collector.values["fnphrase"]),
            exampleEnglish: cleaned(collector.values["enphrase"]),
            source: .liveFeed
        )
    }

    private static func cleaned(_ value: String?) -> String? {
        let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private final class Collector: NSObject, XMLParserDelegate {
        var values: [String: String] = [:]
        private var text = ""
        private var element: String?

        func parser(
            _ parser: XMLParser,
            didStartElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?,
            attributes attributeDict: [String: String] = [:]
        ) {
            element = elementName.lowercased()
            text = ""
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) {
            text += string
        }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            if let string = String(data: CDATABlock, encoding: .utf8) {
                text += string
            }
        }

        func parser(
            _ parser: XMLParser,
            didEndElement elementName: String,
            namespaceURI: String?,
            qualifiedName qName: String?
        ) {
            if let element {
                values[element] = text
            }
            element = nil
            text = ""
        }
    }
}
