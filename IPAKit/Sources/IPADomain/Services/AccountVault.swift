import Foundation

public protocol AccountVault: Sendable {
    func accounts() throws -> [Account]
    func credential(for email: String) throws -> Data?
    func save(_ account: Account, credential: Data) throws
    func remove(email: String) throws
    func removeAll() throws
    func identity() throws -> DeviceIdentity
    func regenerateIdentity() throws -> DeviceIdentity
}
