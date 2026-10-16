import FeatureCore
import Foundation
import IPAData
import IPADomain
import Testing

@testable import FeatureSettings

@MainActor
struct StoreSettingsModelTests {
    private struct Fixture {
        let store: StoreSettingsModel
        let settings: SettingsModel
        let preferences: StorePreferences
        let accounts: AccountsModel
        let downloads: DownloadCenter
        let vault: TestVault
        let repositories: Repositories
    }

    private let ana = Account(
        email: "ana@example.com", name: "Ana Lima", storefront: .unitedStates,
        directoryServicesID: "1")
    private let bruno = Account(
        email: "bruno@example.com", name: "Bruno", storefront: .unitedStates,
        directoryServicesID: "2")

    private func fixture(
        availability: EngineAvailability = .ready,
        serverConfig: any ServerConfigStoring = DisabledServerConfig()
    ) throws -> Fixture {
        let defaults = try #require(UserDefaults(suiteName: "StoreSettings.\(UUID().uuidString)"))
        let vault = TestVault(accounts: [ana, bruno])
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let services = StoreServices(
            catalog: TestCatalog(), engine: TestEngine(state: availability), vault: vault,
            folder: DownloadFolder(root: root), serverConfig: serverConfig)
        let repositories = try IPADatabase.open(inMemory: true).repositories
        let settings = SettingsModel(defaults: defaults, languageSetting: LanguageSetting())
        let session = SessionModel(repositories: repositories, services: services)
        let preferences = StorePreferences(defaults: defaults)
        let accounts = AccountsModel(vault: vault, defaults: defaults)
        let downloads = DownloadCenter(repositories: repositories, services: services)
        accounts.load()
        let store = StoreSettingsModel(
            settings: settings, session: session, preferences: preferences, accounts: accounts,
            downloads: downloads)
        return Fixture(
            store: store, settings: settings, preferences: preferences, accounts: accounts,
            downloads: downloads, vault: vault, repositories: repositories)
    }

    private func record(_ name: String, bytes: Int64, account: Account) -> DownloadRecord {
        DownloadRecord(
            accountEmail: account.email, appID: 1, bundleID: "com.example.\(name)", name: name,
            version: "1.0", fileName: "\(name).ipa", sizeBytes: bytes)
    }

    @Test func choosingResultsPerSearchUpdatesThePreference() throws {
        let fixture = try fixture()
        #expect(fixture.store.resultsValue == "50")
        fixture.store.resultsLimit = 200
        #expect(fixture.preferences.resultsLimit == 200)
        #expect(fixture.store.resultsValue == "200")
    }

    @Test func savingAServerNormalizesAndStoresIt() throws {
        let config = TestServerConfig()
        let fixture = try fixture(serverConfig: config)
        fixture.store.serverAddress = "host.example:8080"
        fixture.store.serverToken = " token "
        fixture.store.saveServer()
        #expect(config.load()?.baseURL.absoluteString == "https://host.example:8080")
        #expect(config.load()?.token == "token")
        #expect(fixture.store.serverValue == "host.example")
        #expect(fixture.store.serverEnabled)
    }

    @Test func savingABlankServerReportsAnError() throws {
        let fixture = try fixture()
        fixture.store.serverAddress = "   "
        fixture.store.saveServer()
        #expect(fixture.store.error == .invalidInput(String(appLocalized: "Enter the server address.")))
        #expect(!fixture.store.serverEnabled)
    }

    @Test func removingAServerClearsTheFields() throws {
        let config = TestServerConfig(ServerConfig(baseURL: URL(string: "https://host.example")!))
        let fixture = try fixture(serverConfig: config)
        fixture.store.loadServer()
        #expect(fixture.store.serverAddress == "https://host.example")
        fixture.store.removeServer()
        #expect(config.load() == nil)
        #expect(fixture.store.serverAddress.isEmpty)
        #expect(!fixture.store.serverEnabled)
    }

    @Test func newIdentitySignsOutEveryAccount() async throws {
        let fixture = try fixture()
        await fixture.store.load()
        let old = try #require(fixture.store.identity)
        #expect(fixture.store.identityText == old.macAddress)
        fixture.store.startIdentityChange()
        #expect(fixture.store.isConfirmingIdentity)
        #expect(fixture.store.identityValues.last?.value == "2")
        fixture.store.regenerateIdentity()
        #expect(fixture.store.identity != old)
        #expect(try fixture.vault.identity() == fixture.store.identity)
        #expect(try fixture.vault.accounts().isEmpty)
        #expect(fixture.accounts.accounts.isEmpty)
        #expect(!fixture.store.isConfirmingIdentity)
    }

    @Test func eraseRemovesAccountsDownloadsAndPreferences() async throws {
        let fixture = try fixture()
        try await fixture.repositories.downloads.save(
            record("Notes", bytes: 1_000_000, account: ana))
        await fixture.store.load()
        let old = try #require(fixture.store.identity)
        fixture.preferences.resultsLimit = 200
        fixture.preferences.storefront = Storefront(code: "BR")
        fixture.settings.appearance = .dark
        fixture.store.startErase()
        #expect(fixture.store.isErasing)
        await fixture.store.erase()
        #expect(fixture.store.eraseStep == .done)
        #expect(fixture.downloads.records.isEmpty)
        #expect(try await fixture.repositories.downloads.records().isEmpty)
        #expect(fixture.accounts.accounts.isEmpty)
        #expect(fixture.preferences.resultsLimit == StorePreferences.defaultLimit)
        #expect(fixture.preferences.storefront == nil)
        #expect(fixture.store.identity != old)
        #expect(fixture.settings.appearance == .dark)
        fixture.store.closeErase()
        #expect(fixture.settings.appearance == .system)
        #expect(!fixture.store.isErasing)
        #expect(fixture.store.eraseStep == .confirm)
    }

    @Test func cancellingTheEraseKeepsThePreferences() throws {
        let fixture = try fixture()
        fixture.settings.appearance = .dark
        fixture.store.startErase()
        fixture.store.closeErase()
        #expect(fixture.settings.appearance == .dark)
        #expect(fixture.accounts.accounts.count == 2)
    }

    @Test func storageAddsUpEveryPackage() async throws {
        let fixture = try fixture()
        try await fixture.repositories.downloads.save(
            record("Notes", bytes: 1_500_000, account: ana))
        try await fixture.repositories.downloads.save(
            record("Maps", bytes: 2_500_000, account: bruno))
        await fixture.store.load()
        #expect(fixture.store.usedBytes == 4_000_000)
        #expect(fixture.store.usedSpaceText == ByteCount.text(4_000_000))
        #expect(fixture.store.packagesCaption.contains("2"))
        #expect(
            fixture.store.eraseValues.map(\.value).prefix(2) == ["2", ByteCount.text(4_000_000)])
    }

    @Test(arguments: [EngineAvailability.ready, .needsJIT, .unsupported])
    func engineStateNamesWhatToDo(availability: EngineAvailability) async throws {
        let fixture = try fixture(availability: availability)
        await fixture.store.refreshEngine()
        #expect(fixture.store.availability == availability)
        #expect(fixture.store.canCheckEngine == (availability == .needsJIT))
        let titles: [EngineAvailability: String] = [
            .ready: "Ready", .needsJIT: "Needs JIT", .unsupported: "Not Available",
        ]
        #expect(fixture.store.engineTitle == titles[availability])
        #expect(!fixture.store.engineCaption.isEmpty)
        #expect(!fixture.store.engineFooter.isEmpty)
    }
}
