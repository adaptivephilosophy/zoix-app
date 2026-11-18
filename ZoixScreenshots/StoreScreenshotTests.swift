import UIKit
import XCTest

/// Captures the three tabs on a booted simulator. The workflow passes
/// ZOIX_SCREENSHOT_DIR through TEST_RUNNER_ZOIX_SCREENSHOT_DIR.
final class StoreScreenshotTests: XCTestCase {
    private var outputDirectory: URL!

    override func setUpWithError() throws {
        continueAfterFailure = false
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ZoixStoreScreenshots", isDirectory: true)
        outputDirectory = caches
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    func testCaptureStoreTabs() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ZoixScreenshotDark"]
        app.launch()

        XCTAssertTrue(wait(app, "home-ready", timeout: 120), "zoix.ai did not finish loading")
        XCTAssertFalse(app.descendants(matching: .any)["home-error"].exists)
        settle(4)
        try save(app, "01-home")

        tap(app, "tab-updates", "Updates")
        XCTAssertTrue(wait(app, "updates-ready", timeout: 120), "the article list did not load")
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 30))
        settle(2)
        try save(app, "02-updates")

        tap(app, "tab-word", "Mot du jour")
        XCTAssertTrue(wait(app, "word-ready", timeout: 30), "the word of the day did not appear")
        _ = wait(app, "word-live", timeout: 25)
        settle(2)
        try save(app, "03-mot-du-jour")
    }

    private func tap(_ app: XCUIApplication, _ identifier: String, _ label: String) {
        let identified = app.buttons[identifier]
        if identified.waitForExistence(timeout: 15) {
            identified.tap()
            return
        }
        app.buttons[label].tap()
    }

    private func wait(_ app: XCUIApplication, _ identifier: String, timeout: TimeInterval) -> Bool {
        app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout)
    }

    private func settle(_ seconds: TimeInterval) {
        let start = Date()
        let expectation = expectation(
            for: NSPredicate { _, _ in Date().timeIntervalSince(start) >= seconds },
            evaluatedWith: nil
        )
        wait(for: [expectation], timeout: seconds + 5)
    }

    private func save(_ app: XCUIApplication, _ name: String) throws {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let image = try XCTUnwrap(UIImage(data: screenshot.pngRepresentation))
        let format = UIGraphicsImageRendererFormat()
        format.opaque = true
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let png = renderer.pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        let url = outputDirectory.appendingPathComponent("\(name).png")
        try png.write(to: url, options: .atomic)
        if let path = ProcessInfo.processInfo.environment["ZOIX_SCREENSHOT_DIR"], !path.isEmpty {
            let folder = URL(fileURLWithPath: path, isDirectory: true)
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try? png.write(to: folder.appendingPathComponent("\(name).png"), options: .atomic)
        }
    }
}
