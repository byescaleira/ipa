import Foundation
import IPADomain
import Synchronization

public final class InMemoryAccountVault: AccountVault {
    private let state = Mutex(State())

    public init(accounts: [Account] = []) {
        state.withLock { state in
            for account in accounts { state.entries[account.email] = (account, Data()) }
        }
    }

    public func accounts() throws -> [Account] {
        state.withLock { $0.entries.values.map(\.0).sorted { $0.email < $1.email } }
    }

    public func credential(for email: String) throws -> Data? {
        state.withLock { $0.entries[email]?.1 }
    }

    public func save(_ account: Account, credential: Data) throws {
        state.withLock { $0.entries[account.email] = (account, credential) }
    }

    public func remove(email: String) throws {
        _ = state.withLock { $0.entries.removeValue(forKey: email) }
    }

    public func removeAll() throws {
        state.withLock { $0 = State() }
    }

    public func identity() throws -> DeviceIdentity {
        if let identity = state.withLock({ $0.identity }) { return identity }
        return try regenerateIdentity()
    }

    public func regenerateIdentity() throws -> DeviceIdentity {
        let identity = DeviceIdentity.random()
        state.withLock { $0.identity = identity }
        return identity
    }

    private struct State {
        var entries: [String: (Account, Data)] = [:]
        var identity: DeviceIdentity?
    }
}
