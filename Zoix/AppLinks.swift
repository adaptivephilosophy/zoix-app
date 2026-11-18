import Foundation

/// Public URLs the app is allowed to know about. Nothing here is a private API.
enum AppLinks {
    /// Homepage shown in the Home tab.
    static let homePage = URL(string: "https://zoix.ai")!

    /// Public articles JSON used by https://zoix.ai.
    /// The site reads `NEXT_PUBLIC_ARTICLES_API` and falls back to this URL.
    /// Checked 18 November 2026: one response, about 532 items, each with
    /// id, title, tags, kind, url, created, and lastEdited.
    static let articlesFeed = URL(string: "https://ap-notion-articles.vercel.app/api/articles")!

    /// Giving page opened in Safari, outside the app (App Store guideline 3.2.2).
    static let givingPage = URL(string: "https://www.paypal.com/ncp/payment/7LP669JW6TBYW")!

    /// Privacy policy committed in this repository. Used on the App Store listing.
    static let privacyPolicy = URL(string: "https://github.com/adaptivephilosophy/zoix-app/blob/main/docs/privacy.md")!

    static let contactEmail = "DanBoice@adaptivephilosophy.foundation"
}

enum AppInfo {
    static var versionLine: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
}
