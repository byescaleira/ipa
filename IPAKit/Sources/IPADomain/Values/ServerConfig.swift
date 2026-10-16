import Foundation

public struct ServerConfig: Hashable, Sendable, Codable {
    public let baseURL: URL
    public let token: String

    public init(baseURL: URL, token: String = "") {
        self.baseURL = baseURL
        self.token = token.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public init?(address: String, token: String = "") {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let normalized = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: normalized), url.host != nil else { return nil }
        self.init(baseURL: url, token: token)
    }

    public func endpoint(_ path: String) -> URL {
        baseURL.appending(path: path)
    }
}
