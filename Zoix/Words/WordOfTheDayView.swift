import SwiftUI

struct WordOfTheDayView: View {
    var words: WordOfTheDayStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    wordCard
                    Button(words.isLoading ? "Loading today's word…" : "Reload today's word") {
                        Task { await words.load(force: true) }
                    }
                    .buttonStyle(ZoixFillButtonStyle())
                    .disabled(words.isLoading)
                    Divider()
                        .overlay(ZoixPalette.cardBorder)
                    about
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Mot du jour")
            .donateButton()
            .zoixScreen()
        }
    }

    private var wordCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("MOT DU JOUR")
                .font(.caption.weight(.semibold))
                .foregroundStyle(colorScheme == .light ? ZoixPalette.navy : ZoixPalette.cyan)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(colorScheme == .light ? ZoixPalette.cyan : Color.clear)
            VStack(alignment: .leading, spacing: 12) {
                Text(words.word.french)
                    .font(.largeTitle.weight(.semibold))
                    .foregroundStyle(ZoixPalette.primaryText)
                    .accessibilityAddTraits(.isHeader)
                Text(words.word.english)
                    .font(.title3)
                    .foregroundStyle(ZoixPalette.primaryText)
                if let part = words.word.partOfSpeech, !part.isEmpty {
                    Text(part)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ZoixPalette.navy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(ZoixPalette.cyan, in: Capsule())
                }
                if let exampleFrench = words.word.exampleFrench {
                    Text(exampleFrench)
                        .font(.body)
                        .foregroundStyle(ZoixPalette.primaryText)
                    if let exampleEnglish = words.word.exampleEnglish {
                        Text(exampleEnglish)
                            .font(.body)
                            .foregroundStyle(ZoixPalette.primaryText)
                    }
                }
                Text(caption)
                    .font(.footnote)
                    .foregroundStyle(ZoixPalette.primaryText)
            }
            .padding(16)
        }
        .background(ZoixPalette.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(ZoixPalette.cardBorder, lineWidth: 1.5)
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
                .foregroundStyle(ZoixPalette.primaryText)
            Text("Questions: \(AppLinks.contactEmail)")
                .font(.footnote)
                .foregroundStyle(ZoixPalette.primaryText)
            Button("Write to the foundation") {
                if let url = URL(string: "mailto:\(AppLinks.contactEmail)") {
                    SafariOpener.open(url)
                }
            }
            .font(.footnote)
            .foregroundStyle(ZoixPalette.primaryText)
            Text("Donations open in Safari. The app does not handle payment cards and does not issue tax receipts.")
                .font(.footnote)
                .foregroundStyle(ZoixPalette.primaryText)
            Button("Privacy policy") {
                SafariOpener.open(AppLinks.privacyPolicy)
            }
            .font(.footnote)
            .foregroundStyle(ZoixPalette.primaryText)
            Text(AppInfo.versionLine)
                .font(.caption)
                .foregroundStyle(ZoixPalette.primaryText)
            Text("Human-directed, AI-assisted.")
                .font(.caption)
                .foregroundStyle(ZoixPalette.primaryText)
        }
    }
}
