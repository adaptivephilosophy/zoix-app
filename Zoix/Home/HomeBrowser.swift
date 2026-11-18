import Combine
import Foundation
import WebKit

/// Back, forward, and return-home state for the Home web view.
final class HomeBrowser: ObservableObject {
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published var isLoading = true
    @Published var errorMessage: String?

    private weak var webView: WKWebView?
    private var observations: [NSKeyValueObservation] = []

    func attach(_ webView: WKWebView) {
        guard self.webView !== webView else { return }
        self.webView = webView
        observations = [
            webView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] view, _ in
                let value = view.canGoBack
                DispatchQueue.main.async { self?.canGoBack = value }
            },
            webView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] view, _ in
                let value = view.canGoForward
                DispatchQueue.main.async { self?.canGoForward = value }
            }
        ]
        syncNavigationState()
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    /// Loads https://zoix.ai. Does nothing when that page is already showing.
    /// Screenshot runs load a bundled page instead, so the capture does not wait on the network.
    func goHome() {
        guard let webView else { return }
        if ScreenshotSample.isEnabled {
            errorMessage = nil
            isLoading = true
            webView.loadHTMLString(ScreenshotSample.homeHTML, baseURL: AppLinks.homePage)
            return
        }
        if let url = webView.url, AppLinks.isHomepage(url) {
            return
        }
        errorMessage = nil
        isLoading = true
        webView.load(URLRequest(url: AppLinks.homePage))
    }

    func reload() {
        guard let webView else { return }
        if ScreenshotSample.isEnabled {
            goHome()
            return
        }
        errorMessage = nil
        isLoading = true
        if webView.url == nil {
            webView.load(URLRequest(url: AppLinks.homePage))
        } else {
            webView.reload()
        }
    }

    func syncNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
    }
}
