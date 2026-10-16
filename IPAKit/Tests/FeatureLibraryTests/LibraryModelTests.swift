import FeatureCore
import Foundation
import IPAData
import IPADomain
import IPAMock
import Testing

@testable import FeatureLibrary

@MainActor
struct LibraryModelTests {
    private let ana = Account(
        email: "ana@example.com", name: "Ana Souza", storefront: .unitedStates,
        directoryServicesID: "1")
    private let bia = Account(
        email: "bia@example.com", name: "Bia", storefront: .unitedStates, directoryServicesID: "2")

    private func defaults() -> UserDefaults {
        let name = "test." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func record(
        _ name: String, bundleID: String, account: Account, megabytes: Int64, hoursAgo: Double
    ) -> DownloadRecord {
        DownloadRecord(
            accountEmail: account.email, appID: 1, bundleID: bundleID, name: name,
            version: "1.0", fileName: "\(bundleID).ipa", sizeBytes: megabytes * 1_048_576,
            downloadedAt: Date.now.addingTimeInterval(-hoursAgo * 3_600))
    }

    private func library(
        records: [DownloadRecord], accounts list: [Account],
        availability: EngineAvailability = .ready
    ) async throws -> (LibraryModel, DownloadCenter, AccountsModel, URL) {
        let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let vault = InMemoryAccountVault(accounts: list)
        let services = StoreServices(
            catalog: SampleCatalog(),
            engine: SimulatedStoreEngine(vault: vault, availability: availability, step: .zero),
            vault: vault, folder: DownloadFolder(root: root))
        let repositories = try IPADatabase.open(inMemory: true).repositories
        for record in records { try await repositories.downloads.save(record) }
        let downloads = DownloadCenter(repositories: repositories, services: services)
        let accounts = AccountsModel(vault: vault, defaults: defaults())
        accounts.load()
        let library = LibraryModel(downloads: downloads, accounts: accounts)
        await library.load()
        return (library, downloads, accounts, root)
    }

    @Test func showsTheEmptyStateOnlyAfterLoading() async throws {
        let (library, downloads, _, root) = try await library(records: [], accounts: [ana])
        defer { try? FileManager.default.removeItem(at: root) }
        #expect(library.isShowingEmptyState)
        #expect(!library.hasRecords)
        let fresh = LibraryModel(
            downloads: DownloadCenter(
                repositories: try IPADatabase.open(inMemory: true).repositories,
                services: StoreServices(
                    catalog: SampleCatalog(),
                    engine: SimulatedStoreEngine(vault: InMemoryAccountVault()),
                    vault: InMemoryAccountVault(), folder: DownloadFolder(root: root))),
            accounts: AccountsModel(vault: InMemoryAccountVault(), defaults: defaults()))
        #expect(!fresh.isShowingEmptyState)
        #expect(downloads.records.isEmpty)
    }

    @Test func groupsByAccountWithTheActiveOneFirst() async throws {
        let records = [
            record(
                "YouTube", bundleID: "com.google.ios.youtube", account: ana, megabytes: 200,
                hoursAgo: 5),
            record(
                "Netflix", bundleID: "com.netflix.Netflix", account: ana, megabytes: 100,
                hoursAgo: 1),
            record(
                "Spotify", bundleID: "com.spotify.client", account: bia, megabytes: 50, hoursAgo: 2),
        ]
        let (library, _, accounts, root) = try await library(
            records: records, accounts: [ana, bia])
        defer { try? FileManager.default.removeItem(at: root) }
        accounts.select(bia)
        let groups = library.groups
        #expect(groups.map(\.email) == [bia.email, ana.email])
        #expect(groups.map(\.title) == ["Bia", "Ana Souza"])
        #expect(groups[1].records.map(\.name) == ["Netflix", "YouTube"])
        #expect(groups[1].totalBytes == 300 * 1_048_576)
    }

    @Test func keepsPackagesOfRemovedAccountsUnderTheirEmail() async throws {
        let records = [
            record(
                "YouTube", bundleID: "com.google.ios.youtube", account: ana, megabytes: 200,
                hoursAgo: 5),
            record(
                "Spotify", bundleID: "com.spotify.client", account: bia, megabytes: 50, hoursAgo: 2),
        ]
        let (library, _, _, root) = try await library(records: records, accounts: [ana])
        defer { try? FileManager.default.removeItem(at: root) }
        #expect(library.groups.map(\.title) == ["Ana Souza", bia.email])
    }

    @Test func summarizesWithoutRepeatingNumbers() async throws {
        let records = [
            record(
                "YouTube", bundleID: "com.google.ios.youtube", account: ana, megabytes: 200,
                hoursAgo: 5),
            record(
                "Netflix", bundleID: "com.netflix.Netflix", account: ana, megabytes: 100,
                hoursAgo: 1),
        ]
        let (library, _, _, root) = try await library(records: records, accounts: [ana])
        defer { try? FileManager.default.removeItem(at: root) }
        #expect(library.packageCount == 2)
        #expect(library.totalBytes == 300 * 1_048_576)
        #expect(library.heroTitle == String(appLocalized: "\(2) packages"))
        #expect(library.heroCaption.contains(ByteCount.text(300 * 1_048_576)))
        let group = try #require(library.groups.first)
        #expect(library.footer(for: group) == ana.email)
    }

    @Test func showsEachAccountTotalWhenThereAreSeveral() async throws {
        let records = [
            record(
                "YouTube", bundleID: "com.google.ios.youtube", account: ana, megabytes: 200,
                hoursAgo: 5),
            record(
                "Spotify", bundleID: "com.spotify.client", account: bia, megabytes: 50, hoursAgo: 2),
        ]
        let (library, _, _, root) = try await library(records: records, accounts: [ana, bia])
        defer { try? FileManager.default.removeItem(at: root) }
        let group = try #require(library.groups.first { $0.email == bia.email })
        #expect(library.footer(for: group) == "\(bia.email) · \(ByteCount.text(50 * 1_048_576))")
        library.text = "you"
        let filtered = try #require(library.groups.first)
        #expect(library.footer(for: filtered).hasSuffix(ByteCount.text(200 * 1_048_576)))
    }

    @Test func filtersByNameOrBundleID() async throws {
        let records = [
            record(
                "YouTube", bundleID: "com.google.ios.youtube", account: ana, megabytes: 200,
                hoursAgo: 5),
            record(
                "Netflix", bundleID: "com.netflix.Netflix", account: ana, megabytes: 100,
                hoursAgo: 1),
        ]
        let (library, _, _, root) = try await library(records: records, accounts: [ana])
        defer { try? FileManager.default.removeItem(at: root) }
        library.text = "netflix"
        #expect(library.groups.flatMap(\.records).map(\.name) == ["Netflix"])
        library.text = "com.google"
        #expect(library.groups.flatMap(\.records).map(\.name) == ["YouTube"])
        #expect(!library.isFilteredOut)
        library.text = "telegram"
        #expect(library.groups.isEmpty)
        #expect(library.isFilteredOut)
        #expect(library.filteredOutText.contains("telegram"))
        #expect(library.packageCount == 2)
    }

    @Test func describesTasksByPhase() async throws {
        let (library, _, _, root) = try await library(records: [], accounts: [ana])
        defer { try? FileManager.default.removeItem(at: root) }
        let app = try #require(SampleApps.all.first)
        var task = DownloadTask(app: app, account: ana, externalVersionID: nil, version: "20.22.1")
        #expect(library.progress(for: task) == 0)
        #expect(library.versionText(for: task) == String(appLocalized: "v\("20.22.1")"))
        task.progress = DownloadProgress(phase: .downloading, completedBytes: 25, totalBytes: 100)
        #expect(library.progress(for: task) == 0.25)
        #expect(library.statusText(for: task).contains(" · "))
        task.progress = DownloadProgress(phase: .signing)
        #expect(library.progress(for: task) == 1)
        #expect(library.statusText(for: task) == task.progress.phaseText)
        task.failure = .engine(.needsJIT)
        #expect(library.statusText(for: task) == IPAError.engine(.needsJIT).localizedDescription)
        let byID = DownloadTask(app: app, account: ana, externalVersionID: "875214761", version: "")
        #expect(library.versionText(for: byID).contains("875214761"))
    }

    @Test func filtersTasksAndRetriesFailures() async throws {
        let (library, downloads, _, root) = try await library(
            records: [], accounts: [ana], availability: .needsJIT)
        defer { try? FileManager.default.removeItem(at: root) }
        downloads.start(SampleApps.all[0], account: ana)
        for _ in 0..<200 where downloads.tasks.contains(where: { $0.failure == nil }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        let task = try #require(library.tasks.first)
        #expect(task.failure == .engine(.needsJIT))
        #expect(!library.isShowingEmptyState)
        library.text = "netflix"
        #expect(library.tasks.isEmpty)
        #expect(library.isFilteredOut)
        library.text = ""
        library.cancel(task)
        #expect(library.tasks.isEmpty)
    }

    @Test func deletesAfterConfirming() async throws {
        let item = record(
            "YouTube", bundleID: "com.google.ios.youtube", account: ana, megabytes: 200, hoursAgo: 5
        )
        let (library, downloads, _, root) = try await library(records: [item], accounts: [ana])
        defer { try? FileManager.default.removeItem(at: root) }
        library.deletion = item
        #expect(library.isConfirmingDeletion)
        #expect(library.deletionTitle.contains("YouTube"))
        library.isConfirmingDeletion = false
        #expect(library.deletion == nil)
        await library.confirmDeletion()
        #expect(downloads.records.count == 1)
        library.deletion = item
        await library.confirmDeletion()
        #expect(downloads.records.isEmpty)
        #expect(library.deletion == nil)
    }

    @Test func offersTwoFilledExamples() async throws {
        let (library, _, _, root) = try await library(records: [], accounts: [])
        defer { try? FileManager.default.removeItem(at: root) }
        #expect(library.examples.count == 2)
        #expect(library.examples.allSatisfy { !$0.record.detailLine.isEmpty })
        #expect(Set(library.examples.map(\.record.dateText)).count == 2)
    }
}
