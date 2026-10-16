import Foundation
import IPAData
import IPADomain
import IPAMock
import Testing

@testable import FeatureCore

@MainActor
struct StoreModelsTests {
    private func defaults() -> UserDefaults {
        let name = "test." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test func preferencesRememberTheStoreAndLimit() {
        let defaults = defaults()
        let preferences = StorePreferences(defaults: defaults)
        #expect(preferences.resultsLimit == 50)
        #expect(preferences.storefront(for: SampleApps.account) == .unitedStates)
        preferences.storefront = Storefront(code: "BR")
        preferences.resultsLimit = 200
        let again = StorePreferences(defaults: defaults)
        #expect(again.storefront?.code == "BR")
        #expect(again.resultsLimit == 200)
        again.reset()
        #expect(again.storefront == nil)
        #expect(again.resultsLimit == 50)
    }

    @Test func accountsKeepTheActiveOne() throws {
        let other = Account(
            email: "z@example.com", name: "Z", storefront: .unitedStates, directoryServicesID: "2")
        let vault = InMemoryAccountVault(accounts: [SampleApps.account, other])
        let accounts = AccountsModel(vault: vault, defaults: defaults())
        accounts.load()
        #expect(accounts.active == SampleApps.account)
        accounts.selection = other.email
        #expect(accounts.active == other)
        accounts.selection = "missing@example.com"
        #expect(accounts.active == other)
        #expect(accounts.others == [SampleApps.account])
        accounts.remove(other)
        #expect(accounts.active == SampleApps.account)
        #expect(try vault.accounts() == [SampleApps.account])
    }

    private func center(availability: EngineAvailability = .ready) throws -> (DownloadCenter, URL) {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let vault = InMemoryAccountVault()
        let services = StoreServices(
            catalog: SampleCatalog(),
            engine: SimulatedStoreEngine(vault: vault, availability: availability, step: .zero),
            vault: vault, folder: DownloadFolder(root: root))
        let repositories = try IPADatabase.open(inMemory: true).repositories
        return (DownloadCenter(repositories: repositories, services: services), root)
    }

    private func finish(_ center: DownloadCenter) async throws {
        for _ in 0..<200 where center.tasks.contains(where: { $0.failure == nil }) {
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    @Test func downloadsAndRecordsTheApp() async throws {
        let (center, root) = try center()
        defer { try? FileManager.default.removeItem(at: root) }
        center.start(SampleApps.all[0], account: SampleApps.account)
        try await finish(center)
        let record = try #require(center.records.first)
        #expect(center.tasks.isEmpty)
        #expect(record.version == SampleApps.all[0].version)
        #expect(
            FileManager.default.fileExists(
                atPath: center.fileURL(for: record).path(percentEncoded: false)))
        await center.delete(record)
        #expect(center.records.isEmpty)
        #expect(
            !FileManager.default.fileExists(
                atPath: center.fileURL(for: record).path(percentEncoded: false)))
    }

    @Test func keepsTheFailureWithARetry() async throws {
        let (center, root) = try center(availability: .needsJIT)
        defer { try? FileManager.default.removeItem(at: root) }
        center.start(SampleApps.all[0], account: SampleApps.account)
        try await finish(center)
        #expect(center.tasks.first?.failure == .engine(.needsJIT))
        #expect(center.task(for: SampleApps.all[0]) == nil)
        if let task = center.tasks.first { center.cancel(task) }
        #expect(center.tasks.isEmpty)
    }

    @Test func refusesPaidApps() async throws {
        let (center, root) = try center()
        defer { try? FileManager.default.removeItem(at: root) }
        let paid = try #require(SampleApps.all.first { !$0.isFree })
        center.start(paid, account: SampleApps.account)
        try await finish(center)
        #expect(center.tasks.first?.failure == .paidApp)
    }

    @Test func accountsShowAStableColor() {
        let account = Account(
            email: "ana@example.com", name: "Ana Souza", storefront: .unitedStates,
            directoryServicesID: "3")
        let renamed = Account(
            email: "ana@example.com", name: "Ana", storefront: .unitedStates,
            directoryServicesID: "3")
        #expect(account.avatarColor == renamed.avatarColor)
    }

    @Test func avatarsDescribeWhatTheyDraw() {
        let account: Account? = Account(
            email: "ana@example.com", name: "Ana Souza", storefront: .unitedStates,
            directoryServicesID: "3")
        let nobody: Account? = nil
        #expect(account.avatarAccessibilityLabel.contains("AS"))
        #expect(!nobody.avatarAccessibilityLabel.isEmpty)
        #expect(nobody.avatarColor == .default)
        if case .monogram(let text) = account.avatarContent {
            #expect(text == "AS")
        } else {
            Issue.record("Expected a monogram")
        }
    }
}
