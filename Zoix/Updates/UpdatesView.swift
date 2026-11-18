import SwiftUI

struct UpdatesView: View {
    var store: ArticleStore
    @State private var search = ""
    @State private var tag: String?
    @State private var newestFirst = true
    @State private var selected: Article?

    private var query: ArticleQuery {
        ArticleQuery(searchText: search, tag: tag, newestFirst: newestFirst)
    }

    private var visible: [Article] {
        query.filtered(store.articles)
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Updates")
                .searchable(text: $search, prompt: "Search title or tag")
                .donateButton()
                .zoixScreen()
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        sortButton
                        tagMenu
                    }
                }
                .refreshable {
                    await store.refresh()
                }
                .sheet(item: $selected) { article in
                    SafariView(url: article.url)
                        .ignoresSafeArea()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.articles.isEmpty {
            ProgressView("Loading articles")
        } else if case .failed(let message) = store.status, store.articles.isEmpty {
            ContentUnavailableView(
                "Articles unavailable",
                systemImage: "wifi.exclamationmark",
                description: Text(message)
            )
        } else if visible.isEmpty {
            ContentUnavailableView(
                "No matches",
                systemImage: "line.3.horizontal.decrease.circle",
                description: Text("Try another title or tag.")
            )
        } else {
            list
        }
    }

    private var list: some View {
        List {
            if case .showingCached(let message) = store.status {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(ZoixPalette.primaryText)
                        .listRowBackground(ZoixPalette.background)
                }
            }
            if let tag {
                Section {
                    Button("Clear tag: \(tag)") {
                        self.tag = nil
                    }
                    .foregroundStyle(ZoixPalette.primaryText)
                    .listRowBackground(ZoixPalette.background)
                }
            }
            Section {
                ForEach(visible) { article in
                    Button {
                        selected = article
                    } label: {
                        ArticleRow(article: article)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(ZoixPalette.background)
                    .accessibilityHint("Opens the page in the app")
                }
            } header: {
                Text("\(visible.count) of \(store.articles.count)")
                    .foregroundStyle(ZoixPalette.primaryText)
            } footer: {
                if let generatedAt = store.generatedAt {
                    Text("Feed generated \(ArticleDateFormat.string(from: generatedAt)). Sorted by last updated.")
                        .foregroundStyle(ZoixPalette.primaryText)
                } else {
                    Text("Sorted by last updated.")
                        .foregroundStyle(ZoixPalette.primaryText)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ZoixPalette.background)
        .listRowSeparatorTint(ZoixPalette.cardBorder)
    }

    private var sortButton: some View {
        Button {
            newestFirst.toggle()
        } label: {
            Image(systemName: newestFirst ? "arrow.down" : "arrow.up")
        }
        .accessibilityLabel(newestFirst ? "Newest updated" : "Oldest updated")
        .accessibilityHint("Sorts articles by last updated")
    }

    private var tagMenu: some View {
        Menu {
            Button("All tags") { tag = nil }
            ForEach(ArticleQuery.tags(in: store.articles), id: \.self) { name in
                Button(name) { tag = name }
            }
        } label: {
            Image(systemName: tag == nil ? "tag" : "tag.fill")
        }
        .accessibilityLabel(tag.map { "Tag filter, \($0)" } ?? "Tag filter, all tags")
    }
}

private struct ArticleRow: View {
    let article: Article

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(article.title)
                .font(.headline)
                .foregroundStyle(ZoixPalette.primaryText)
                .multilineTextAlignment(.leading)
            HStack(spacing: 8) {
                if !article.kind.isEmpty {
                    Text(article.kind)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ZoixPalette.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.quaternary, in: Capsule())
                }
                Text("Updated \(ArticleDateFormat.string(from: article.lastEdited))")
                    .font(.caption)
                    .foregroundStyle(ZoixPalette.primaryText)
            }
            if !article.tags.isEmpty {
                Text(article.tags.prefix(4).joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(ZoixPalette.primaryText)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }
}
