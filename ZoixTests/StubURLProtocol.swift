import Foundation

/// Answers one URLSession with a canned result. Each subclass has its own box
/// so article tests and word tests do not share state.
class StubURLProtocol: URLProtocol {
    struct Box {
        var data: Data?
        var status: Int = 200
        var error: Error?
    }

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canInit(with task: URLSessionTask) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func stopLoading() {}

    func finish(with box: Box) {
        if let error = box.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let url = request.url ?? URL(string: "https://example.invalid/")!
        let response = HTTPURLResponse(
            url: url,
            statusCode: box.status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: box.data ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }
}

final class ArticleStubURLProtocol: StubURLProtocol {
    nonisolated(unsafe) static var storage = Box()
    override func startLoading() {
        finish(with: Self.storage)
    }
}

final class WordStubURLProtocol: StubURLProtocol {
    nonisolated(unsafe) static var storage = Box()
    override func startLoading() {
        finish(with: Self.storage)
    }
}

enum StubSession {
    static func make(protocolClass: URLProtocol.Type) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        return URLSession(configuration: configuration)
    }
}
