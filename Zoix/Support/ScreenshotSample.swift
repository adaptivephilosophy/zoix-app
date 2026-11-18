import Foundation

/// Offline content for App Store screenshots. The UI test passes `-ZoixScreenshotSample`.
/// Normal launches never read this.
enum ScreenshotSample {
    static let argument = "-ZoixScreenshotSample"

    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains(argument)
    }

    static func articles(now: Date = sampleDate) -> [Article] {
        [
            make("sample-research", "Research and topics", "Page", ["Philosophy"], now),
            make("sample-notes", "November 2026 notes", "Notes", ["Notes"], now),
            make("sample-french", "Études françaises", "Page", ["Language"], now)
        ]
    }

    static let homeHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      body { margin: 0; background: #06182c; color: #fdfdce;
             font: 17px -apple-system, sans-serif; }
      main { padding: 28px 20px; }
      h1 { font-size: 28px; margin: 0 0 8px; }
      p { margin: 0 0 22px; color: #1bbce3; }
      article { padding: 14px 0; border-top: 1px solid #1bbce3; }
      h2 { font-size: 18px; margin: 0 0 4px; }
      small { color: #fdfdce; }
    </style>
    </head>
    <body>
    <main>
      <h1>Adaptive Philosophy</h1>
      <p>Recent writing</p>
      <article><h2>Research and topics</h2><small>Philosophy</small></article>
      <article><h2>November 2026 notes</h2><small>Notes</small></article>
      <article><h2>Études françaises</h2><small>Language</small></article>
    </main>
    </body>
    </html>
    """

    private static let sampleDate = Date(timeIntervalSince1970: 1_763_424_000)

    private static func make(_ id: String, _ title: String, _ kind: String, _ tags: [String], _ date: Date) -> Article {
        Article(
            id: id,
            title: title,
            lastEdited: date,
            created: date,
            url: URL(string: "https://zoix.ai/")!,
            kind: kind,
            tags: tags
        )
    }
}
