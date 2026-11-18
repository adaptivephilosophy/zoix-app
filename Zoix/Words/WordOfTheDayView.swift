import SwiftUI

struct WordOfTheDayView: View {
    var words: WordOfTheDayStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Mot du jour")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(words.word.french)
                        .font(.largeTitle.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Text(words.word.english)
                        .font(.title3)
                    if let part = words.word.partOfSpeech, !part.isEmpty {
                        Text(part)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.quaternary, in: Capsule())
                    }
                    if let exampleFrench = words.word.exampleFrench {
                        Text(exampleFrench)
                            .font(.body)
                        if let exampleEnglish = words.word.exampleEnglish {
                            Text(exampleEnglish)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Text(caption)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Button(words.isLoading ? "Loading today's word…" : "Reload today's word") {
                        Task { await words.load(force: true) }
                    }
                    .disabled(words.isLoading)
                    Divider()
                    about
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Mot du jour")
            .donateButton()
        }
    }

    private var caption: String {
        if words.word.source == .liveFeed {
            return "Today's French word is from the public Transparent Language word of the day."
        }
        return "This word is from the list saved in the app. A connection is needed for today's live word."
    }

    private var about: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Adaptive Philosophy Foundation · Olympia, WA")
                .font(.subheadline.weight(.semibold))
            Text("Questions: \(AppLinks.contactEmail)")
                .font(.footnote)
            Button("Write to the foundation") {
                if let url = URL(string: "mailto:\(AppLinks.contactEmail)") {
                    SafariOpener.open(url)
                }
            }
            .font(.footnote)
            Text("Donations open in Safari. The app does not handle payment cards and does not issue tax receipts.")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("Privacy policy") {
                SafariOpener.open(AppLinks.privacyPolicy)
            }
            .font(.footnote)
            Text(AppInfo.versionLine)
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text("Human-directed, AI-assisted.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}
