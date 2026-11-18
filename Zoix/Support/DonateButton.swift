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
                }
                .accessibilityHint("Opens the giving page in Safari, outside the app")
            }
        }
    }
}
