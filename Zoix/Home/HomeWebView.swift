import SwiftUI
import UIKit
import WebKit

/// Home tab: zoix.ai in a web view. Giving and payment links leave the app.
struct HomeWebView: UIViewRepresentable {
    var reloadToken: Int
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(isLoading: $isLoading, errorMessage: $errorMessage, reloadToken: reloadToken)
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
        context.coordinator.webView = webView
        context.coordinator.loadHome()
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.isLoading = $isLoading
        context.coordinator.errorMessage = $errorMessage
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            context.coordinator.reload()
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var isLoading: Binding<Bool>
        var errorMessage: Binding<String?>
        var lastReloadToken: Int
        weak var webView: WKWebView?

        init(isLoading: Binding<Bool>, errorMessage: Binding<String?>, reloadToken: Int) {
            self.isLoading = isLoading
            self.errorMessage = errorMessage
            self.lastReloadToken = reloadToken
        }

        func loadHome() {
            guard let webView else { return }
            errorMessage.wrappedValue = nil
            isLoading.wrappedValue = true
            webView.load(URLRequest(url: AppLinks.homePage))
        }

        func reload() {
            guard let webView else { return }
            errorMessage.wrappedValue = nil
            isLoading.wrappedValue = true
            if webView.url == nil {
                webView.load(URLRequest(url: AppLinks.homePage))
            } else {
                webView.reload()
            }
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            isLoading.wrappedValue = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading.wrappedValue = false
            errorMessage.wrappedValue = nil
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
                return
            }
            isLoading.wrappedValue = false
            errorMessage.wrappedValue = "Check the connection and try again."
        }
    }
}
