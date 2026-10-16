import FeatureCore
import Foundation
import IPAData
import IPADomain
import IPAMock
import Synchronization

@testable import FeatureSearch

@MainActor
struct SearchFixture {
    let session: SessionModel
    let preferences: StorePreferences
    let accounts: AccountsModel
    let downloads: DownloadCenter
    let root: URL

    init(
        catalog: any StoreCatalog = SampleCatalog(), engine: (any StoreEngine)? = nil,
        accounts list: [Account] = [SampleApps.account]
    ) throws {
        let vault = InMemoryAccountVault(accounts: list)
        root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let services = StoreServices(
            catalog: catalog, engine: engine ?? SimulatedStoreEngine(vault: vault, step: .zero),
            vault: vault, folder: DownloadFolder(root: root))
        let repositories = try IPADatabase.open(inMemory: true).repositories
        session = SessionModel(repositories: repositories, services: services)
        let name = "test." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        preferences = StorePreferences(defaults: defaults)
        accounts = AccountsModel(vault: vault, defaults: defaults)
        accounts.load()
        downloads = DownloadCenter(repositories: repositories, services: services)
    }

    func search() -> SearchModel {
        SearchModel(session: session, preferences: preferences, accounts: accounts, debounce: .zero)
    }

    func app(
        _ id: Int64 = SampleApps.all[0].id, batchSize: Int = 10,
        copy: @escaping @MainActor (String) -> Void = { _ in }
    ) -> AppModel {
        AppModel(
            id: id, session: session, preferences: preferences, accounts: accounts,
            downloads: downloads, batchSize: batchSize, copy: copy)
    }

    func clean() {
        try? FileManager.default.removeItem(at: root)
    }
}

struct DelayedCatalog: StoreCatalog {
    let delays: [String: Duration]

    func search(_ term: String, in storefront: Storefront, limit: Int) async throws -> [StoreApp] {
        try await Task.sleep(for: delays[term] ?? .zero)
        return try await SampleCatalog().search(term, in: storefront, limit: limit)
    }

    func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp? {
        try await SampleCatalog().lookup(query, in: storefront)
    }
}

struct FailingCatalog: StoreCatalog {
    func search(_ term: String, in storefront: Storefront, limit: Int) async throws -> [StoreApp] {
        throw IPAError.network
    }

    func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp? {
        throw IPAError.network
    }
}

final class RecordingCatalog: StoreCatalog {
    private let calls = Mutex<[String]>([])

    var recorded: [String] { calls.withLock { $0 } }

    func search(_ term: String, in storefront: Storefront, limit: Int) async throws -> [StoreApp] {
        calls.withLock { $0.append("search:\(term):\(storefront.code):\(limit)") }
        return try await SampleCatalog().search(term, in: storefront, limit: limit)
    }

    func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp? {
        calls.withLock { $0.append("lookup:\(query.term)") }
        return try await SampleCatalog().lookup(query, in: storefront)
    }
}

final class CountingEngine: StoreEngine {
    private let base: SimulatedStoreEngine
    private let calls = Mutex<[String]>([])

    init(vault: any AccountVault = InMemoryAccountVault()) {
        base = SimulatedStoreEngine(vault: vault, step: .zero)
    }

    var metadataCalls: [String] { calls.withLock { $0 } }

    func availability() async -> EngineAvailability { await base.availability() }

    func signIn(_ request: SignInRequest) async throws -> Account {
        try await base.signIn(request)
    }

    func versions(of app: StoreApp, for account: Account) async throws -> [String] {
        try await base.versions(of: app, for: account).reversed()
    }

    func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        calls.withLock { $0.append(externalID) }
        return try await base.version(externalID, of: app, for: account)
    }

    func purchase(_ app: StoreApp, for account: Account) async throws {
        try await base.purchase(app, for: account)
    }

    func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        try await base.download(request, progress: progress)
    }
}
