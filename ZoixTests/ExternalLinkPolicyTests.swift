import XCTest
@testable import Zoix

final class ExternalLinkPolicyTests: XCTestCase {
    func testGivingLinksLeaveTheApp() {
        let outside = [
            "https://www.paypal.com/ncp/payment/7LP669JW6TBYW",
            "https://paypal.com/checkoutnow?token=abc",
            "https://donate.stripe.com/7sYbJ0dKwdf51tbgit2Ji00",
            "https://buy.stripe.com/test",
            "https://cash.app/$dancredit",
            "https://zoix.ai/fund",
            "https://zoix.ai/donate",
            "https://github.com/sponsors/adaptivephilosophy",
            "http://www.paypal.com/payment/abc",
            "mailto:DanBoice@adaptivephilosophy.foundation",
            "tel:+12065550100"
        ]
        for raw in outside {
            let url = URL(string: raw)!
            XCTAssertEqual(ExternalLinkPolicy.decision(for: url), .openOutsideApp, raw)
        }
    }

    func testOrdinaryLinksStayInTheWebView() {
        let inside = [
            "https://zoix.ai/",
            "https://zoix.ai/connect",
            "https://adaptivephilosophy.notion.site/Tuesday-Nov-17-2026-41ba657440a58189946ffcdbed575d5b",
            "https://ap-notion-articles.vercel.app/api/articles",
            "https://x.com/IDZoixAi",
            "https://www.facebook.com/ZoixAi",
            "about:blank"
        ]
        for raw in inside {
            let url = URL(string: raw)!
            XCTAssertEqual(ExternalLinkPolicy.decision(for: url), .loadInWebView, raw)
        }
    }

    func testUnknownSchemesAreCancelled() {
        XCTAssertEqual(ExternalLinkPolicy.decision(for: URL(string: "javascript:alert(1)")!), .cancel)
        XCTAssertEqual(ExternalLinkPolicy.decision(for: URL(string: "zoix://home")!), .cancel)
    }

    func testHomepageIsOnlyTheZoixFrontPage() {
        let home = [
            "https://zoix.ai",
            "https://zoix.ai/",
            "https://www.zoix.ai",
            "https://www.zoix.ai/",
            "http://zoix.ai"
        ]
        for raw in home {
            XCTAssertTrue(AppLinks.isHomepage(URL(string: raw)!), raw)
        }
        let elsewhere = [
            "https://zoix.ai/connect",
            "https://zoix.ai/fund",
            "https://adaptivephilosophy.notion.site",
            "https://example.com"
        ]
        for raw in elsewhere {
            XCTAssertFalse(AppLinks.isHomepage(URL(string: raw)!), raw)
        }
    }

    func testLookalikeHostsAreNotPaymentHosts() {
        XCTAssertEqual(ExternalLinkPolicy.decision(for: URL(string: "https://notpaypal.com/hello")!), .loadInWebView)
        XCTAssertEqual(ExternalLinkPolicy.decision(for: URL(string: "https://stripe.com.example/pay")!), .loadInWebView)
        XCTAssertEqual(ExternalLinkPolicy.decision(for: URL(string: "https://example.com/funding-notes")!), .loadInWebView)
    }
}
