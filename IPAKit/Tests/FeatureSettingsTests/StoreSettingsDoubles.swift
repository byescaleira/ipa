import Foundation
import IPADomain
import Synchronization

final class TestVault: AccountVault {
    private let state: Mutex<State>

    init(accounts: [Account] = []) {
        state = Mutex(State(accounts: accounts))
    }

    func accounts() throws -> [Account] {
        state.withLock { $0.accounts }
    }

    func credential(for email: String) throws -> Data? { nil }

    func save(_ account: Account, credential: Data) throws {
        state.withLock { $0.accounts.append(account) }
    }

    func remove(email: String) throws {
        state.withLock { $0.accounts.removeAll { $0.email == email } }
    }

    func removeAll() throws {
        state.withLock { $0 = State(accounts: []) }
    }

    func identity() throws -> DeviceIdentity {
        if let identity = state.withLock({ $0.identity }) { return identity }
        return try regenerateIdentity()
    }

    func regenerateIdentity() throws -> DeviceIdentity {
        let identity = DeviceIdentity.random()
        state.withLock { $0.identity = identity }
        return identity
    }

    private struct State {
        var accounts: [Account]
        var identity: DeviceIdentity?
    }
}

struct TestEngine: StoreEngine {
    let state: EngineAvailability

    func availability() async -> EngineAvailability { state }

    func signIn(_ request: SignInRequest) async throws -> Account {
        throw IPAError.engine(state)
    }

    func versions(of app: StoreApp, for account: Account) async throws -> [String] { [] }

    func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        throw IPAError.engine(state)
    }

    func purchase(_ app: StoreApp, for account: Account) async throws {}

    func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        throw IPAError.engine(state)
    }
}

struct TestCatalog: StoreCatalog {
    func search(_ term: String, in storefront: Storefront, limit: Int) async throws -> [StoreApp] {
        []
    }

    func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp? { nil }
}
