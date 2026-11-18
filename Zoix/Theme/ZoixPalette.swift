import SwiftUI
import UIKit

/// Option C, sampled from the Adaptive Philosophy logo at https://zoix.ai/25341.png.
///
/// Navy `#06182C` is the field (pixel 507, 99). Cyan `#1BBCE3` is a bright branch
/// sample (pixel 328, 460). Ivory `#FDFDCE` is the wordmark (pixel 478, 509).
/// In light mode cyan is a fill only. Labels on that fill are navy, because cyan
/// text on white is 2.25:1. Navy on cyan is 7.96:1. Ivory on navy is 17.13:1.
enum ZoixColor {
    static let navy = UIColor(red: 6.0 / 255.0, green: 24.0 / 255.0, blue: 44.0 / 255.0, alpha: 1)
    static let ivory = UIColor(red: 253.0 / 255.0, green: 253.0 / 255.0, blue: 206.0 / 255.0, alpha: 1)
    static let cyan = UIColor(red: 27.0 / 255.0, green: 188.0 / 255.0, blue: 227.0 / 255.0, alpha: 1)

    static let background = UIColor { traits in
        traits.userInterfaceStyle == .dark ? navy : .white
    }

    static let primaryText = UIColor { traits in
        traits.userInterfaceStyle == .dark ? ivory : navy
    }

    /// Light mode outlines cards in navy. Dark mode outlines them in cyan.
    static let cardBorder = UIColor { traits in
        traits.userInterfaceStyle == .dark ? cyan : navy
    }

    static let kicker = UIColor { traits in
        traits.userInterfaceStyle == .dark ? cyan : navy
    }

    static func navigationAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = background
        appearance.shadowColor = cardBorder
        appearance.titleTextAttributes = [.foregroundColor: primaryText]
        appearance.largeTitleTextAttributes = [.foregroundColor: primaryText]
        return appearance
    }

    static func applyChrome() {
        let navigation = navigationAppearance()
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = navigation
        bar.scrollEdgeAppearance = navigation
        bar.compactAppearance = navigation
        bar.compactScrollEdgeAppearance = navigation
        bar.tintColor = primaryText
    }
}

enum ZoixPalette {
    static let navy = Color(uiColor: ZoixColor.navy)
    static let ivory = Color(uiColor: ZoixColor.ivory)
    static let cyan = Color(uiColor: ZoixColor.cyan)
    static let background = Color(uiColor: ZoixColor.background)
    static let primaryText = Color(uiColor: ZoixColor.primaryText)
    static let cardBorder = Color(uiColor: ZoixColor.cardBorder)
    static let kicker = Color(uiColor: ZoixColor.kicker)
}

/// Cyan capsule, navy label. Used for Donate and the other filled actions.
struct ZoixFillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        FillLabel(isPressed: configuration.isPressed, label: configuration.label)
    }

    private struct FillLabel<Label: View>: View {
        @Environment(\.isEnabled) private var isEnabled
        var isPressed: Bool
        var label: Label

        var body: some View {
            label
                .font(.body.weight(.semibold))
                .foregroundStyle(ZoixPalette.navy)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(ZoixPalette.cyan, in: Capsule())
                .opacity(!isEnabled ? 0.55 : isPressed ? 0.88 : 1)
        }
    }
}

extension View {
    func zoixScreen() -> some View {
        modifier(ZoixScreenModifier())
    }
}

private struct ZoixScreenModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .foregroundStyle(ZoixPalette.primaryText)
            .background(ZoixPalette.background)
            .background {
                ZoixNavigationBarConfigurator()
                    .frame(width: 0, height: 0)
            }
            .toolbarBackground(ZoixPalette.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
            .tint(ZoixPalette.primaryText)
    }
}

/// SwiftUI's navigation bar does not always pick up the global appearance.
/// This applies the navy and ivory title colors to the bar that is actually showing.
private struct ZoixNavigationBarConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.apply()
    }

    final class Controller: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (controller: Self, _: UITraitCollection) in
                controller.apply()
            }
        }

        override func viewIsAppearing(_ animated: Bool) {
            super.viewIsAppearing(animated)
            apply()
        }

        func apply() {
            guard let bar = navigationController?.navigationBar else { return }
            let appearance = ZoixColor.navigationAppearance()
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.compactScrollEdgeAppearance = appearance
            bar.tintColor = ZoixColor.primaryText
        }
    }
}
