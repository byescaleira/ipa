import FeatureCore
import Foundation
import IPADomain
import IPAMock
import Testing

@testable import FeatureSearch

@MainActor
struct StorefrontModelTests {
    @Test func listsEveryStoreSortedByName() throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = StorefrontModel(preferences: fixture.preferences, accounts: fixture.accounts)
        #expect(model.storefronts.count == Storefront.all.count)
        let names = model.storefronts.map(\.name)
        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(model.isShowingAccountStore)
    }

    @Test func filtersByNameOrCode() throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = StorefrontModel(preferences: fixture.preferences, accounts: fixture.accounts)
        model.text = "br"
        #expect(model.storefronts.contains { $0.code == "BR" })
        #expect(!model.isShowingAccountStore)
        model.text = "zzzz"
        #expect(model.isShowingNoResults)
    }

    @Test func selectsAndReturnsToTheAccountStore() throws {
        let fixture = try SearchFixture()
        defer { fixture.clean() }
        let model = StorefrontModel(preferences: fixture.preferences, accounts: fixture.accounts)
        #expect(model.isAccountStoreSelected)
        #expect(model.accountStorefront == SampleApps.account.storefront)
        #expect(model.accountStoreDetail.contains(SampleApps.account.email))
        let brazil = try #require(Storefront(code: "BR"))
        model.select(brazil)
        #expect(model.isSelected(brazil))
        #expect(fixture.preferences.storefront(for: fixture.accounts.active) == brazil)
        model.select(nil)
        #expect(model.isAccountStoreSelected)
        #expect(fixture.preferences.storefront == nil)
    }

    @Test func usesTheDeviceRegionWithoutAnAccount() throws {
        let fixture = try SearchFixture(accounts: [])
        defer { fixture.clean() }
        let model = StorefrontModel(
            preferences: fixture.preferences, accounts: fixture.accounts,
            locale: Locale(identifier: "pt_BR"))
        #expect(model.accountStorefront.code == "BR")
        #expect(!model.accountStoreDetail.contains("@"))
    }
}
