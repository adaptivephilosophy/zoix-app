import SwiftUI

enum AppTab: Hashable {
    case home
    case updates
    case word
}

struct RootView: View {
    @State private var tab: AppTab = .home
    @State private var articles = ArticleStore()
    @State private var words = WordOfTheDayStore()
    @StateObject private var browser = HomeBrowser()

    var body: some View {
        TabView(selection: $tab) {
            HomeView(browser: browser, words: words, tab: $tab)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.home)
            UpdatesView(store: articles)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.updates)
            WordOfTheDayView(words: words)
                .toolbar(.hidden, for: .tabBar)
                .tag(AppTab.word)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ZoixTabBar(tab: $tab, browser: browser)
        }
        .tint(ZoixPalette.primaryText)
        .preferredColorScheme(screenshotDark ? .dark : nil)
        .task {
            if ScreenshotSample.isEnabled {
                words.showSample()
                articles.showSample()
            }
        }
        .task {
            if !ScreenshotSample.isEnabled {
                await words.load()
            }
        }
        .task {
            if !ScreenshotSample.isEnabled {
                await articles.loadCachedThenRefresh()
            }
        }
    }

    /// Screenshot runs pass this argument so the navy field is showing.
    private var screenshotDark: Bool {
        ProcessInfo.processInfo.arguments.contains("-ZoixScreenshotDark")
    }
}

/// Selected tab is a cyan fill with a navy label in both modes.
/// Unselected labels are navy on white, and ivory on the navy field.
private struct ZoixTabBar: View {
    @Binding var tab: AppTab
    var browser: HomeBrowser

    var body: some View {
        HStack(spacing: 0) {
            item(.home, "Home", "house", "tab-home")
            item(.updates, "Updates", "newspaper", "tab-updates")
            item(.word, "Mot du jour", "text.book.closed", "tab-word")
        }
        .padding(.horizontal, 8)
        .padding(.top, 6)
        .padding(.bottom, 6)
        .background {
            ZoixPalette.background
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(ZoixPalette.cardBorder)
                .frame(height: 1)
                .ignoresSafeArea(edges: .horizontal)
        }
    }

    private func item(_ value: AppTab, _ title: String, _ symbol: String, _ identifier: String) -> some View {
        let selected = tab == value
        return Button {
            if selected && value == .home {
                browser.goHome()
            } else {
                tab = value
            }
        } label: {
            VStack(spacing: 2) {
                Image(systemName: symbol)
                    .font(.system(size: 20))
                Text(title)
                    .font(.caption2.weight(selected ? .semibold : .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(selected ? ZoixPalette.navy : ZoixPalette.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background {
                if selected {
                    Capsule().fill(ZoixPalette.cyan)
                }
            }
            .padding(.horizontal, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityHint(selected && value == .home ? "Returns to zoix.ai" : "")
    }
}
