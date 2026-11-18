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

    var body: some View {
        TabView(selection: $tab) {
            HomeView(words: words, tab: $tab)
                .tabItem { Label("Home", systemImage: "house") }
                .tag(AppTab.home)
            UpdatesView(store: articles)
                .tabItem { Label("Updates", systemImage: "newspaper") }
                .tag(AppTab.updates)
            WordOfTheDayView(words: words)
                .tabItem { Label("Mot du jour", systemImage: "text.book.closed") }
                .tag(AppTab.word)
        }
        .tint(Color.accentColor)
        .task { await words.load() }
        .task { await articles.loadCachedThenRefresh() }
    }
}
