import UIKit
import XCTest
@testable import Zoix

final class PaletteTests: XCTestCase {
    func testLogoHexes() {
        assertHex(ZoixColor.navy, red: 6, green: 24, blue: 44)
        assertHex(ZoixColor.ivory, red: 253, green: 253, blue: 206)
        assertHex(ZoixColor.cyan, red: 27, green: 188, blue: 227)
    }

    func testLightModeUsesNavyTextAndWhiteField() {
        let light = UITraitCollection(userInterfaceStyle: .light)
        assertHex(ZoixColor.primaryText, traits: light, red: 6, green: 24, blue: 44)
        assertHex(ZoixColor.background, traits: light, red: 255, green: 255, blue: 255)
        assertHex(ZoixColor.kicker, traits: light, red: 6, green: 24, blue: 44)
        assertHex(ZoixColor.cardBorder, traits: light, red: 6, green: 24, blue: 44)
    }

    func testDarkModeUsesIvoryTextOnNavy() {
        let dark = UITraitCollection(userInterfaceStyle: .dark)
        assertHex(ZoixColor.primaryText, traits: dark, red: 253, green: 253, blue: 206)
        assertHex(ZoixColor.background, traits: dark, red: 6, green: 24, blue: 44)
        assertHex(ZoixColor.kicker, traits: dark, red: 27, green: 188, blue: 227)
        assertHex(ZoixColor.cardBorder, traits: dark, red: 27, green: 188, blue: 227)
    }

    func testAccentColorIsCyan() throws {
        let bundles = [Bundle.main, Bundle(identifier: "ai.zoix.app")].compactMap { $0 }
        let accent = try XCTUnwrap(
            bundles.lazy.compactMap { UIColor(named: "AccentColor", in: $0, compatibleWith: nil) }.first
        )
        assertHex(accent, traits: UITraitCollection(userInterfaceStyle: .light), red: 27, green: 188, blue: 227)
    }

    private func assertHex(_ color: UIColor, traits: UITraitCollection? = nil, red: Int, green: Int, blue: Int) {
        let resolved = traits.map { color.resolvedColor(with: $0) } ?? color
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        XCTAssertTrue(resolved.getRed(&r, green: &g, blue: &b, alpha: &a))
        XCTAssertEqual(Int((r * 255).rounded()), red)
        XCTAssertEqual(Int((g * 255).rounded()), green)
        XCTAssertEqual(Int((b * 255).rounded()), blue)
        XCTAssertEqual(Int((a * 255).rounded()), 255)
    }
}
