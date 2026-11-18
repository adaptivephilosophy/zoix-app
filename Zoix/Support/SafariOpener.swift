import UIKit

/// Opens a URL in the system handler. https giving links open in Safari, not in a web view.
enum SafariOpener {
    static func open(_ url: URL) {
        Task { @MainActor in
            UIApplication.shared.open(url)
        }
    }
}
