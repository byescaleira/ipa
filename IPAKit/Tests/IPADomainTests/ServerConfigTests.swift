import Foundation
import Testing

@testable import IPADomain

struct ServerConfigTests {
    @Test func addsHTTPSWhenTheSchemeIsMissing() {
        let config = ServerConfig(address: "host.example:8080", token: " abc ")
        #expect(config?.baseURL.absoluteString == "https://host.example:8080")
        #expect(config?.token == "abc")
    }

    @Test func keepsAnExplicitScheme() {
        #expect(ServerConfig(address: "http://10.0.0.2:8080")?.baseURL.scheme == "http")
    }

    @Test func rejectsBlankOrHostlessAddresses() {
        #expect(ServerConfig(address: "   ") == nil)
        #expect(ServerConfig(address: "https://") == nil)
    }

    @Test func buildsEndpoints() {
        let config = ServerConfig(baseURL: URL(string: "https://host.example")!)
        #expect(config.endpoint("v1/login").absoluteString == "https://host.example/v1/login")
    }
}
