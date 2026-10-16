import FeatureCore
import Foundation
import IPADomain
import IPAMock
import Testing

@testable import FeatureSearch

@MainActor
struct AppModelTests {
    private let paid = SampleApps.all[6]

    @Test func loadsTheAppAndItsVersionsNewestFirst() async throws {
        let fixture = try SearchFixture(engine: CountingEngine())
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        #expect(model.app?.name == "YouTube")
        #expect(model.action == .download)
        #expect(model.primaryTitle?.contains("20.22.1") == true)
        #expect(model.versionsStatus == .loaded)
        #expect(model.versionIDs.count == 24)
        #expect(model.versionIDs.first == "875214761")
        #expect(model.isShowingVersions)
        #expect(model.chips.map(\.tone) == [.tint, .neutral, .neutral, .positive])
    }

    @Test func asksToSignInWithoutAnAccount() async throws {
        let fixture = try SearchFixture(accounts: [])
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        #expect(model.action == .signIn)
        #expect(model.versionsStatus == .idle)
        #expect(!model.isShowingVersions)
        #expect(!model.canDownload)
        #expect(model.heroFooter != nil)
    }

    @Test func explainsPaidApps() async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = fixture.app(paid.id)
        await model.load()
        #expect(model.action == .paid)
        #expect(model.primaryTitle == nil)
        #expect(model.heroFooter?.contains(model.shownApp.priceText) == true)
        #expect(model.chips.last?.tone == .warning)
        #expect(!model.isShowingVersions)
    }

    @Test(arguments: [EngineAvailability.needsJIT, .unsupported])
    func pointsToTheGuideWhenTheEngineIsOff(availability: EngineAvailability) async throws {
        let engine = SimulatedStoreEngine(vault: InMemoryAccountVault(), availability: availability)
        let fixture = try SearchFixture(engine: engine)
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        #expect(model.action == .engine(availability))
        #expect(model.primaryTitle != nil)
        #expect(!model.isShowingVersions)
    }

    @Test func reportsAMissingApp() async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = fixture.app(42)
        await model.load()
        #expect(model.app == nil)
        #expect(model.isAppNotFound)
        #expect(!model.isLoading)
        #expect(model.action == nil)
    }

    @Test func reportsANetworkFailure() async throws {
        let fixture = try SearchFixture(catalog: FailingCatalog())
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        #expect(model.loadFailure == .network)
        #expect(!model.isAppNotFound)
        #expect(!model.loadFailureMessage.isEmpty)
    }

    @Test func loadsMetadataOnDemandInBatches() async throws {
        let engine = CountingEngine()
        let fixture = try SearchFixture(engine: engine)
        defer { fixture.clean() }
        let model = fixture.app(batchSize: 4)
        await model.load()
        #expect(engine.metadataCalls.isEmpty)
        let visible = Array(model.versionIDs.prefix(6))
        for id in visible { model.requestMetadata(for: id) }
        await model.metadataTask?.value
        #expect(Set(engine.metadataCalls) == Set(visible))
        #expect(visible.allSatisfy(model.isLoaded))
        #expect(model.versionTitle(visible[0]).hasPrefix("v20."))
        #expect(model.versionDetail(visible[0]).hasPrefix(visible[0]))
        for id in visible { model.requestMetadata(for: id) }
        #expect(model.metadataTask == nil)
        #expect(engine.metadataCalls.count == 6)
    }

    @Test func confirmsAndDownloadsAVersion() async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        let id = try #require(model.versionIDs.dropFirst().first)
        model.choose(id)
        let choice = try #require(model.confirmation)
        await model.metadataTask?.value
        #expect(model.displayVersion(of: choice) != nil)
        #expect(model.choiceRows(choice).count == 3)
        model.download(choice)
        #expect(model.confirmation == nil)
        #expect(model.action == .progress)
        #expect(fixture.downloads.tasks.first?.externalVersionID == id)
        #expect(model.startCount == 1)
    }

    @Test func validatesTheVersionID() async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        for text in ["abc", "0", "12a", "１２３", String(repeating: "9", count: 20)] {
            model.versionIDText = text
            #expect(model.isVersionIDInvalid, "\(text)")
            #expect(!model.canDownloadVersionID)
        }
        model.versionIDText = ""
        #expect(!model.isVersionIDInvalid)
        model.versionIDText = " 875214761 "
        #expect(model.canDownloadVersionID)
        model.downloadVersionID()
        #expect(model.versionIDText.isEmpty)
        #expect(fixture.downloads.tasks.first?.externalVersionID == "875214761")
    }

    @Test func copiesIdentifiers() async throws {
        var copied: [String] = []
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = fixture.app { copied.append($0) }
        await model.load()
        #expect(model.identifiers.map(\.kind) == [.bundleID, .appID, .link])
        for identifier in model.identifiers { model.copy(identifier) }
        #expect(copied.first == "com.google.ios.youtube")
        #expect(copied[1] == "544007664")
        #expect(model.copyCount == 3)
        #expect(model.shareURL != nil)
    }

    @Test func showsProgressInsteadOfTheButton() async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = fixture.app()
        await model.load()
        model.downloadCurrent()
        #expect(model.action == .progress)
        #expect(model.primaryTitle == nil)
        #expect(!model.progressPhase.isEmpty)
    }
}
