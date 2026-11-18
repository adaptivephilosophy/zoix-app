import SafariServices
import SwiftUI

/// In-app browser for one article. This is not the Home web view, and it is not used for donations.
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let configuration = SFSafariViewController.Configuration()
        configuration.barCollapsingEnabled = true
        let controller = SFSafariViewController(url: url, configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        context.coordinator.dismiss = dismiss
    }

    final class Coordinator: NSObject, SFSafariViewControllerDelegate {
        var dismiss: DismissAction

        init(dismiss: DismissAction) {
            self.dismiss = dismiss
        }

        func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
            dismiss()
        }
    }
}
