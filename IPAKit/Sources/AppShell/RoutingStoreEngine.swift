import Foundation
import IPADomain
import IPAEngine
import os

private let log = Logger(subsystem: "com.byescaleira.ipa", category: "routing")

struct RoutingStoreEngine: StoreEngine {
    private let configStore: any ServerConfigStoring
    private let vault: any AccountVault
    private let local: any StoreEngine

    init(configStore: any ServerConfigStoring, vault: any AccountVault, local: any StoreEngine) {
        self.configStore = configStore
        self.vault = vault
        self.local = local
    }

    private func engine() -> any StoreEngine {
        if let config = configStore.load() {
            log.info("routing to server \(config.baseURL.absoluteString, privacy: .public)")
            return RemoteStoreEngine(config: config, vault: vault)
        }
        log.info("routing to local engine (no server configured)")
        return local
    }

    func availability() async -> EngineAvailability {
        await engine().availability()
    }

    func signIn(_ request: SignInRequest) async throws -> Account {
        try await engine().signIn(request)
    }

    func versions(of app: StoreApp, for account: Account) async throws -> [String] {
        try await engine().versions(of: app, for: account)
    }

    func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        try await engine().version(externalID, of: app, for: account)
    }

    func purchase(_ app: StoreApp, for account: Account) async throws {
        try await engine().purchase(app, for: account)
    }

    func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        try await engine().download(request, progress: progress)
    }
}
