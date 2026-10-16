import Foundation
import IPADomain
import IPAMock
import Synchronization
import Testing

@testable import IPAEngine

private final class MockURLProtocol: URLProtocol {
    struct Reply: Sendable {
        var status: Int
        var headers: [String: String]
        var body: Data
    }

    static let routes = Mutex([String: Reply]())
    static let requests = Mutex([URL]())

    static func reset() {
        routes.withLock { $0 = [:] }
        requests.withLock { $0 = [] }
    }

    static func stub(_ path: String, _ reply: Reply) {
        routes.withLock { $0[path] = reply }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        Self.requests.withLock { $0.append(url) }
        let reply =
            Self.routes.withLock { $0[url.path] }
            ?? Reply(status: 404, headers: [:], body: Data())
        let response = HTTPURLResponse(
            url: url, statusCode: reply.status, httpVersion: "HTTP/1.1", headerFields: reply.headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: reply.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}

private func json(_ value: [String: Any]) -> Data {
    try! JSONSerialization.data(withJSONObject: value)
}

@Suite(.serialized)
struct RemoteStoreEngineTests {
    private let config = ServerConfig(baseURL: URL(string: "https://host.example")!, token: "secret")
    private let app = StoreApp(id: 42, bundleID: "com.example.app", name: "Example", version: "1.0")

    private func engine(vault: any AccountVault) -> RemoteStoreEngine {
        RemoteStoreEngine(config: config, vault: vault, session: makeSession())
    }

    private func signedInVault() throws -> InMemoryAccountVault {
        let vault = InMemoryAccountVault()
        try vault.save(
            SampleAccount.value,
            credential: json(["directoryServicesIdentifier": "9000", "storeFront": "143441-1,29"]))
        return vault
    }

    @Test func signsInAndStoresTheCredential() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.stub(
            "/v1/login",
            .init(
                status: 200, headers: ["Content-Type": "application/json"],
                body: json([
                    "account": [
                        "email": "person@example.com", "name": "Person",
                        "storeFront": "143441-1,29", "directoryServicesIdentifier": "9000",
                    ]
                ])))
        let vault = InMemoryAccountVault()
        let account = try await engine(vault: vault).signIn(
            SignInRequest(email: "person@example.com", password: "pw"))
        #expect(account.email == "person@example.com")
        #expect(account.directoryServicesID == "9000")
        #expect(try vault.credential(for: "person@example.com") != nil)
    }

    @Test func mapsTheAuthCodeError() async {
        MockURLProtocol.reset()
        MockURLProtocol.stub(
            "/v1/login",
            .init(
                status: 502, headers: ["Content-Type": "application/json"],
                body: json(["error": ["code": "code_required", "message": "need code"]])))
        await #expect(throws: IPAError.codeRequired) {
            try await engine(vault: InMemoryAccountVault()).signIn(
                SignInRequest(email: "a@example.com", password: "pw"))
        }
    }

    @Test func listsVersionsNewestFirst() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.stub(
            "/v1/versions",
            .init(
                status: 200, headers: ["Content-Type": "application/json"],
                body: json(["versions": ["100", "200", "300"]])))
        let vault = try signedInVault()
        let versions = try await engine(vault: vault).versions(of: app, for: SampleAccount.value)
        #expect(versions == ["300", "200", "100"])
    }

    @Test func downloadsAndWritesThePackage() async throws {
        MockURLProtocol.reset()
        let payload = Data("ipa-bytes".utf8)
        MockURLProtocol.stub(
            "/v1/download",
            .init(
                status: 200,
                headers: [
                    "Content-Type": "application/octet-stream",
                    "Content-Length": String(payload.count), "X-IPA-Version": "3.1",
                ], body: payload))
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let destination = folder.appending(path: "app.ipa")

        let vault = try signedInVault()
        let package = try await engine(vault: vault).download(
            DownloadRequest(
                app: app, account: SampleAccount.value, externalVersionID: "300",
                destination: destination), progress: { _ in })
        #expect(package.version == "3.1")
        #expect(package.sizeBytes == Int64(payload.count))
        #expect(try Data(contentsOf: destination) == payload)
    }

    @Test func sendsTheBearerToken() async throws {
        MockURLProtocol.reset()
        MockURLProtocol.stub(
            "/v1/versions",
            .init(
                status: 200, headers: ["Content-Type": "application/json"],
                body: json(["versions": []])))
        let vault = try signedInVault()
        _ = try await engine(vault: vault).versions(of: app, for: SampleAccount.value)
        let hit = MockURLProtocol.requests.withLock { $0.contains { $0.path == "/v1/versions" } }
        #expect(hit)
    }
}

private enum SampleAccount {
    static let value = Account(
        email: "person@example.com", name: "Person", storefront: .unitedStates,
        directoryServicesID: "9000")
}
