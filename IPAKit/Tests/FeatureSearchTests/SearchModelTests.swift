import FeatureCore
import Foundation
import IPADomain
import IPAMock
import Testing

@testable import FeatureSearch

@MainActor
struct SearchModelTests {
    @Test func staysIdleWithoutText() async throws {
        let catalog = RecordingCatalog()
        let fixture = try SearchFixture(catalog: catalog)
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = "   "
        await search.search()
        #expect(search.isIdle)
        #expect(search.results.isEmpty)
        #expect(catalog.recorded.isEmpty)
    }

    @Test func searchesTextInTheStoreAndLimitFromPreferences() async throws {
        let catalog = RecordingCatalog()
        let fixture = try SearchFixture(catalog: catalog)
        defer { fixture.clean() }
        fixture.preferences.storefront = Storefront(code: "BR")
        fixture.preferences.resultsLimit = 25
        let search = fixture.search()
        search.text = "YouTube"
        await search.search()
        #expect(catalog.recorded == ["search:YouTube:BR:25"])
        #expect(search.results.map(\.name) == ["YouTube", "YouTube Music"])
        #expect(search.status == .results)
        #expect(search.searchedStorefront?.code == "BR")
        #expect(search.footer.contains("2"))
    }

    @Test func looksUpABundleID() async throws {
        let catalog = RecordingCatalog()
        let fixture = try SearchFixture(catalog: catalog)
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = "net.whatsapp.WhatsApp"
        await search.search()
        #expect(catalog.recorded == ["lookup:net.whatsapp.WhatsApp"])
        #expect(search.results.map(\.id) == [310_633_997])
    }

    @Test func searchesAsTextWhenTheBundleIsNotFound() async throws {
        let catalog = RecordingCatalog()
        let fixture = try SearchFixture(catalog: catalog)
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = "com.google"
        await search.search()
        #expect(catalog.recorded.first == "lookup:com.google")
        #expect(catalog.recorded.last?.hasPrefix("search:com.google") == true)
        #expect(search.results.map(\.name) == ["YouTube", "YouTube Music"])
    }

    @Test(arguments: ["544007664", "https://apps.apple.com/us/app/youtube/id544007664"])
    func looksUpAnIDOrLink(text: String) async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = text
        await search.search()
        #expect(search.results.map(\.name) == ["YouTube"])
    }

    @Test func reportsNoResults() async throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = "999"
        await search.search()
        #expect(search.isShowingNoResults)
        #expect(search.noResultsMessage.contains("999"))
    }

    @Test func reportsNetworkFailure() async throws {
        let fixture = try SearchFixture(catalog: FailingCatalog())
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = "YouTube"
        await search.search()
        #expect(search.failure == .network)
        #expect(search.results.isEmpty)
        #expect(!search.failureMessage.isEmpty)
    }

    @Test func ignoresALateResponse() async throws {
        let catalog = DelayedCatalog(delays: ["Netflix": .milliseconds(300)])
        let fixture = try SearchFixture(catalog: catalog)
        defer { fixture.clean() }
        let search = fixture.search()
        search.text = "Netflix"
        let slow = Task { await search.search() }
        try await Task.sleep(for: .milliseconds(20))
        search.text = "Telegram"
        await search.search()
        await slow.value
        #expect(search.results.map(\.name) == ["Telegram Messenger"])
        #expect(!search.isSearching)
    }

    @Test func cancelsDuringTheDebounce() async throws {
        let catalog = RecordingCatalog()
        let fixture = try SearchFixture(catalog: catalog)
        defer { fixture.clean() }
        let search = SearchModel(
            session: fixture.session, preferences: fixture.preferences,
            accounts: fixture.accounts, debounce: .seconds(5))
        search.text = "YouTube"
        let pending = Task { await search.search() }
        try await Task.sleep(for: .milliseconds(20))
        #expect(search.isShowingPlaceholders)
        pending.cancel()
        await pending.value
        #expect(catalog.recorded.isEmpty)
        #expect(!search.isSearching)
        #expect(search.results.isEmpty)
    }

    @Test func keyFollowsTheTextStoreAndLimit() throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let search = fixture.search()
        search.receive("  Spotify ")
        let first = search.key
        #expect(first.text == "Spotify")
        #expect(first.storefront == SampleApps.account.storefront)
        fixture.preferences.storefront = Storefront(code: "JP")
        #expect(search.key != first)
        #expect(search.storefrontTitle.contains(search.storefrontName))
    }

    @Test func examplesShowOneFreeAndOnePaidApp() {
        let free = SearchModel.examples.filter(\.isFree)
        #expect(free.count == 1)
        #expect(SearchModel.examples.count == 2)
    }
}
