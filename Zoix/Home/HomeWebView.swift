import SwiftUI
import UIKit
import WebKit

/// Home tab: zoix.ai in a web view. Giving and payment links leave the app.
struct HomeWebView: UIViewRepresentable {
    @ObservedObject var browser: HomeBrowser

    func makeCoordinator() -> Coordinator {
        Coordinator(browser: browser)
    }

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        let background = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1)
        webView.backgroundColor = background
        webView.scrollView.backgroundColor = background
        webView.isOpaque = true
        #if DEBUG
        webView.isInspectable = true
        #endif
        context.coordinator.browser = browser
        browser.attach(webView)
        if webView.url == nil {
            browser.goHome()
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.browser = browser
        browser.attach(uiView)
        uiView.allowsBackForwardNavigationGestures = true
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var browser: HomeBrowser

        init(browser: HomeBrowser) {
            self.browser = browser
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            browser.errorMessage = nil
            browser.isLoading = true
            browser.syncNavigationState()
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            browser.isLoading = false
            browser.errorMessage = nil
            browser.syncNavigationState()
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handle(error)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            switch ExternalLinkPolicy.decision(for: url) {
            case .loadInWebView:
                decisionHandler(.allow)
            case .openOutsideApp:
                SafariOpener.open(url)
                decisionHandler(.cancel)
            case .cancel:
                decisionHandler(.cancel)
            }
        }

        /// `target="_blank"` links (the homepage uses them for gifts and articles).
        /// Loading them here keeps them in this web view, so Back can return.
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            guard let url = navigationAction.request.url else { return nil }
            switch ExternalLinkPolicy.decision(for: url) {
            case .loadInWebView:
                webView.load(URLRequest(url: url))
            case .openOutsideApp:
                SafariOpener.open(url)
            case .cancel:
                break
            }
            return nil
        }

        private func handle(_ error: Error) {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                browser.syncNavigationState()
                return
            }
            browser.isLoading = false
            browser.errorMessage = "Check the connection and try again."
            browser.syncNavigationState()
        }
    }
}
