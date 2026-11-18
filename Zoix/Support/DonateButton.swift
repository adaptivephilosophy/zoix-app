import SwiftUI

extension View {
    /// Donate always leaves the app. The giving page is PayPal, opened in Safari.
    func donateButton() -> some View {
        toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    SafariOpener.open(AppLinks.givingPage)
                } label: {
                    Label("Donate", systemImage: "heart")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(ZoixPalette.navy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(ZoixPalette.cyan, in: Capsule())
                }
                .buttonStyle(.plain)
                .tint(ZoixPalette.navy)
                .accessibilityHint("Opens the giving page in Safari, outside the app")
            }
        }
    }
}
