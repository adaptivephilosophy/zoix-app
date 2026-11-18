import Foundation

/// Search, tag filter, and last-updated sort for the Updates tab.
struct ArticleQuery: Equatable, Sendable {
    var searchText: String = ""
    var tag: String?
    var newestFirst: Bool = true

    func filtered(_ articles: [Article]) -> [Article] {
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let wantedTag = tag?.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = articles.filter { article in
            if let wantedTag, !wantedTag.isEmpty {
                let hasTag = article.tags.contains { $0.caseInsensitiveCompare(wantedTag) == .orderedSame }
                if !hasTag {
                    return false
                }
            }
            if needle.isEmpty {
                return true
            }
            if article.title.lowercased().contains(needle) {
                return true
            }
            return article.tags.contains { $0.lowercased().contains(needle) }
        }
        return matched.sorted { lhs, rhs in
            if lhs.lastEdited != rhs.lastEdited {
                return newestFirst ? lhs.lastEdited > rhs.lastEdited : lhs.lastEdited < rhs.lastEdited
            }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
    }

    /// Tags sorted by how many articles use them, then by name.
    static func tags(in articles: [Article]) -> [String] {
        var counts: [String: Int] = [:]
        for article in articles {
            let unique = Set(article.tags.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty })
            for tag in unique {
                counts[tag, default: 0] += 1
            }
        }
        return counts.keys.sorted { lhs, rhs in
            let leftCount = counts[lhs] ?? 0
            let rightCount = counts[rhs] ?? 0
            if leftCount != rightCount {
                return leftCount > rightCount
            }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }
}
