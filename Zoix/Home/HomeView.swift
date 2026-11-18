import SwiftUI

struct HomeView: View {
    var words: WordOfTheDayStore
    @Binding var tab: AppTab
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var reloadToken = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                wordStrip
                ZStack {
                    HomeWebView(
                        reloadToken: reloadToken,
                        isLoading: $isLoading,
                        errorMessage: $errorMessage
                    )
                    if let errorMessage {
                        errorPane(errorMessage)
                    } else if isLoading {
                        ProgressView("Loading zoix.ai")
                            .padding(12)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .navigationTitle("Zoix")
            .navigationBarTitleDisplayMode(.inline)
            .donateButton()
            .zoixScreen()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        reloadToken += 1
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .accessibilityLabel("Reload homepage")
                }
            }
        }
    }

    private var wordStrip: some View {
        Button {
            tab = .word
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Mot du jour")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ZoixPalette.kicker)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background {
                            if colorScheme == .light {
                                Capsule().fill(ZoixPalette.cyan)
                            }
                        }
                    Text(words.word.french)
                        .font(.headline)
                        .foregroundStyle(ZoixPalette.primaryText)
                    Text(words.word.english)
                        .font(.subheadline)
                        .foregroundStyle(ZoixPalette.primaryText)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(ZoixPalette.primaryText)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(ZoixPalette.background, in: RoundedRectangle(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(ZoixPalette.cardBorder, lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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
                reloadToken += 1
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
