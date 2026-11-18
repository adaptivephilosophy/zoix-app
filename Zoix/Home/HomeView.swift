import SwiftUI

struct HomeView: View {
    @ObservedObject var browser: HomeBrowser
    var words: WordOfTheDayStore
    @Binding var tab: AppTab
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                browserBar
                ZStack {
                    HomeWebView(browser: browser)
                    if let errorMessage = browser.errorMessage {
                        errorPane(errorMessage)
                    } else if browser.isLoading {
                        ProgressView("Loading zoix.ai")
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(homeStatusIdentifier)
                .overlay(alignment: .topLeading) {
                    statusMarker(homeStatusIdentifier)
                }
                wordLine
            }
            .navigationTitle("Zoix")
            .navigationBarTitleDisplayMode(.inline)
            .donateButton()
            .zoixScreen()
        }
    }

    private func statusMarker(_ identifier: String) -> some View {
        Color.clear
            .frame(width: 4, height: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityIdentifier(identifier)
            .accessibilityLabel(identifier)
            .allowsHitTesting(false)
    }

    private var homeStatusIdentifier: String {
        if browser.errorMessage != nil {
            return "home-error"
        }
        if browser.isLoading {
            return "home-loading"
        }
        return "home-ready"
    }

    private var browserBar: some View {
        HStack(spacing: 4) {
            barButton("chevron.backward", label: "Back", enabled: browser.canGoBack) {
                browser.goBack()
            }
            barButton("chevron.forward", label: "Forward", enabled: browser.canGoForward) {
                browser.goForward()
            }
            Button {
                browser.goHome()
            } label: {
                Label("Home", systemImage: "house")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ZoixPalette.navy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ZoixPalette.cyan, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Returns to zoix.ai")
            Spacer(minLength: 8)
            barButton("arrow.clockwise", label: "Reload", enabled: true) {
                browser.reload()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(ZoixPalette.background)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(ZoixPalette.cardBorder)
                .frame(height: 1)
        }
    }

    private func barButton(
        _ symbol: String,
        label: String,
        enabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.body.weight(.semibold))
                .foregroundStyle(ZoixPalette.primaryText)
                .frame(width: 44, height: 36)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    /// One line under the page, so the site keeps the screen.
    private var wordLine: some View {
        Button {
            tab = .word
        } label: {
            HStack(spacing: 6) {
                Text("Mot du jour")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colorScheme == .light ? ZoixPalette.navy : ZoixPalette.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background {
                        if colorScheme == .light {
                            Capsule().fill(ZoixPalette.cyan)
                        }
                    }
                    .layoutPriority(1)
                Text(words.word.french)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ZoixPalette.primaryText)
                    .lineLimit(1)
                    .layoutPriority(1)
                Text("·")
                    .font(.subheadline)
                    .foregroundStyle(ZoixPalette.primaryText)
                Text(words.word.english)
                    .font(.subheadline)
                    .foregroundStyle(ZoixPalette.primaryText)
                    .lineLimit(1)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ZoixPalette.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(ZoixPalette.background)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ZoixPalette.cardBorder)
                .frame(height: 1)
        }
        .accessibilityLabel("Word of the day, \(words.word.french), \(words.word.english)")
        .accessibilityHint("Opens the word of the day")
    }

    private func errorPane(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.largeTitle)
                .foregroundStyle(ZoixPalette.primaryText)
            Text("zoix.ai did not load")
                .font(.headline)
                .foregroundStyle(ZoixPalette.primaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(ZoixPalette.primaryText)
                .multilineTextAlignment(.center)
            Button("Try again") {
                browser.reload()
            }
            .buttonStyle(ZoixFillButtonStyle())
            Button("Open in Safari") {
                SafariOpener.open(AppLinks.homePage)
            }
            .foregroundStyle(ZoixPalette.primaryText)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ZoixPalette.background)
    }
}
