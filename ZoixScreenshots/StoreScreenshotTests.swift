import UIKit
import XCTest

/// Captures the three tabs from bundled sample data. The host takes the pixels
/// with `simctl io screenshot` when it sees a ready flag, which avoids the
/// XCUITest screenshot timeout. A direct screenshot is the fallback.
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
        app.launchArguments += ["-ZoixScreenshotDark", "-ZoixScreenshotSample"]
        app.launch()

        XCTAssertTrue(wait(app, "home-ready", timeout: 20), "the sample home page did not appear")
        settle(1)
        try capture("01-home")

        tap(app, "tab-updates", "Updates")
        XCTAssertTrue(wait(app, "updates-ready", timeout: 10), "the sample article list did not appear")
        XCTAssertTrue(app.cells.firstMatch.waitForExistence(timeout: 10))
        settle(1)
        try capture("02-updates")

        tap(app, "tab-word", "Mot du jour")
        XCTAssertTrue(wait(app, "word-ready", timeout: 10), "the sample word did not appear")
        settle(1)
        try capture("03-mot-du-jour")
    }

    private func tap(_ app: XCUIApplication, _ identifier: String, _ label: String) {
        let identified = app.buttons[identifier]
        if identified.waitForExistence(timeout: 8) {
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
        wait(for: [expectation], timeout: seconds + 2)
    }

    /// Asks the host to photograph the simulator, then falls back to XCUITest.
    private func capture(_ name: String) throws {
        let ready = outputDirectory.appendingPathComponent("ready-\(name).flag")
        try Data("ready".utf8).write(to: ready, options: .atomic)
        let done = outputDirectory.appendingPathComponent("done-\(name).flag")
        let start = Date()
        while !FileManager.default.fileExists(atPath: done.path), Date().timeIntervalSince(start) < 20 {
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        if FileManager.default.fileExists(atPath: done.path) {
            return
        }
        try saveWithRetry(name)
    }

    private func saveWithRetry(_ name: String) throws {
        var last = "screenshot was not taken"
        for _ in 1...3 {
            do {
                try writeXCUIScreenshot(name)
                return
            } catch {
                last = error.localizedDescription
                settle(1)
            }
        }
        XCTFail("Failed to get screenshot for \(name): \(last)")
    }

    private func writeXCUIScreenshot(_ name: String) throws {
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
        try png.write(to: outputDirectory.appendingPathComponent("\(name).png"), options: .atomic)
    }
}
