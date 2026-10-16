import Foundation

public protocol ServerConfigStoring: Sendable {
    func load() -> ServerConfig?
    func save(_ config: ServerConfig) throws
    func clear() throws
}

public struct DisabledServerConfig: ServerConfigStoring {
    public init() {}
    public func load() -> ServerConfig? { nil }
    public func save(_ config: ServerConfig) throws {}
    public func clear() throws {}
}
