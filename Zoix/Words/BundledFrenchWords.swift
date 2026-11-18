import Foundation

/// Starter list used when the live word-of-the-day feed cannot be reached.
/// The word changes at midnight Pacific Time, which is Olympia's time zone.
enum BundledFrenchWords {
    static func word(on date: Date) -> FrenchWord {
        let day = WordDay.calendar().ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (day - 1) % all.count
        return all[index]
    }

    static let all: [FrenchWord] = [
        FrenchWord(french: "bonjour", english: "hello", partOfSpeech: "interjection", exampleFrench: "Bonjour, comment allez-vous ?", exampleEnglish: "Hello, how are you?"),
        FrenchWord(french: "merci", english: "thank you", partOfSpeech: "interjection"),
        FrenchWord(french: "apprendre", english: "to learn", partOfSpeech: "verb"),
        FrenchWord(french: "penser", english: "to think", partOfSpeech: "verb"),
        FrenchWord(french: "question", english: "a question", partOfSpeech: "noun"),
        FrenchWord(french: "réponse", english: "an answer", partOfSpeech: "noun"),
        FrenchWord(french: "livre", english: "a book", partOfSpeech: "noun"),
        FrenchWord(french: "idée", english: "an idea", partOfSpeech: "noun"),
        FrenchWord(french: "temps", english: "time", partOfSpeech: "noun"),
        FrenchWord(french: "jour", english: "a day", partOfSpeech: "noun"),
        FrenchWord(french: "ami", english: "a friend", partOfSpeech: "noun"),
        FrenchWord(french: "chemin", english: "a path", partOfSpeech: "noun"),
        FrenchWord(french: "lumière", english: "light", partOfSpeech: "noun"),
        FrenchWord(french: "écouter", english: "to listen", partOfSpeech: "verb"),
        FrenchWord(french: "parler", english: "to speak", partOfSpeech: "verb"),
        FrenchWord(french: "comprendre", english: "to understand", partOfSpeech: "verb"),
        FrenchWord(french: "chercher", english: "to search", partOfSpeech: "verb"),
        FrenchWord(french: "trouver", english: "to find", partOfSpeech: "verb"),
        FrenchWord(french: "donner", english: "to give", partOfSpeech: "verb"),
        FrenchWord(french: "ensemble", english: "together"),
        FrenchWord(french: "espoir", english: "hope", partOfSpeech: "noun"),
        FrenchWord(french: "courage", english: "courage", partOfSpeech: "noun"),
        FrenchWord(french: "calme", english: "calm"),
        FrenchWord(french: "curieux", english: "curious"),
        FrenchWord(french: "sage", english: "wise"),
        FrenchWord(french: "simple", english: "simple"),
        FrenchWord(french: "vrai", english: "true"),
        FrenchWord(french: "juste", english: "fair"),
        FrenchWord(french: "monde", english: "the world", partOfSpeech: "noun"),
        FrenchWord(french: "maison", english: "a house", partOfSpeech: "noun"),
        FrenchWord(french: "école", english: "a school", partOfSpeech: "noun"),
        FrenchWord(french: "travail", english: "work", partOfSpeech: "noun"),
        FrenchWord(french: "repos", english: "rest", partOfSpeech: "noun"),
        FrenchWord(french: "matin", english: "morning", partOfSpeech: "noun"),
        FrenchWord(french: "soir", english: "evening", partOfSpeech: "noun"),
        FrenchWord(french: "eau", english: "water", partOfSpeech: "noun"),
        FrenchWord(french: "pain", english: "bread", partOfSpeech: "noun"),
        FrenchWord(french: "main", english: "a hand", partOfSpeech: "noun"),
        FrenchWord(french: "cœur", english: "heart", partOfSpeech: "noun"),
        FrenchWord(french: "voix", english: "a voice", partOfSpeech: "noun"),
        FrenchWord(french: "mot", english: "a word", partOfSpeech: "noun"),
        FrenchWord(french: "histoire", english: "a story", partOfSpeech: "noun"),
        FrenchWord(french: "communauté", english: "a community", partOfSpeech: "noun"),
        FrenchWord(french: "bienvenue", english: "welcome"),
        FrenchWord(french: "aujourd'hui", english: "today"),
        FrenchWord(french: "demain", english: "tomorrow"),
        FrenchWord(french: "hier", english: "yesterday"),
        FrenchWord(french: "toujours", english: "always"),
        FrenchWord(french: "parfois", english: "sometimes"),
        FrenchWord(french: "pourquoi", english: "why"),
        FrenchWord(french: "parce que", english: "because"),
        FrenchWord(french: "peut-être", english: "maybe"),
        FrenchWord(french: "s'il vous plaît", english: "please"),
        FrenchWord(french: "de rien", english: "you're welcome"),
        FrenchWord(french: "à bientôt", english: "see you soon"),
        FrenchWord(french: "bonne journée", english: "have a good day"),
        FrenchWord(french: "gentil", english: "kind"),
        FrenchWord(french: "doux", english: "gentle"),
        FrenchWord(french: "clair", english: "clear"),
        FrenchWord(french: "ouvert", english: "open")
    ]
}
