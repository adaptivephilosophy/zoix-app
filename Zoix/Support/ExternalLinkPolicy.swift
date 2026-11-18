import Foundation

/// Where a link tapped in the Home web view should go.
enum WebViewDecision: Equatable {
    /// Keep browsing inside the Home tab.
    case loadInWebView
    /// Leave the app. https links open in Safari; mailto and tel open their system apps.
    case openOutsideApp
    /// Drop the navigation. Used for schemes the app does not handle.
    case cancel
}

/// Sends donation, checkout, and payment links out of the web view.
///
/// App Store guideline 3.2.2: until Apple has approved the organization as a
/// nonprofit, gifts have to be completed outside the app. PayPal, Stripe,
/// Cash App, and other giving links on zoix.ai therefore open in Safari.
enum ExternalLinkPolicy {
    static func decision(for url: URL) -> WebViewDecision {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == "mailto" || scheme == "tel" {
            return .openOutsideApp
        }
        if scheme == "http" || scheme == "https" {
            return isGivingLink(url) ? .openOutsideApp : .loadInWebView
        }
        if scheme == "about" {
            return .loadInWebView
        }
        return .cancel
    }

    static func isGivingLink(_ url: URL) -> Bool {
        let host = (url.host ?? "").lowercased()
        if paymentHosts.contains(where: { host == $0 || host.hasSuffix(".\($0)") }) {
            return true
        }
        if host == "github.com" || host == "www.github.com" {
            if url.path.lowercased().hasPrefix("/sponsors") {
                return true
            }
        }
        let segments = url.path.lowercased().split(separator: "/").map(String.init)
        if segments.contains(where: { givingSegments.contains($0) }) {
            return true
        }
        if let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in items where givingSegments.contains(item.name.lowercased()) {
                return true
            }
        }
        return false
    }

    private static let paymentHosts = [
        "paypal.com",
        "paypal.me",
        "stripe.com",
        "cash.app"
    ]

    /// Path segments and query names that mark a page as a gift or a checkout.
    private static let givingSegments: Set<String> = [
        "donate",
        "donation",
        "donations",
        "checkout",
        "payment",
        "payments",
        "fund",
        "giving",
        "give"
    ]
}
