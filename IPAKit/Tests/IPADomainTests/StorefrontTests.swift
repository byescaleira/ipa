import Foundation
import IPADomain
import Testing

struct StorefrontTests {
    @Test func listsEveryStoreOnce() {
        #expect(Storefront.all.count == 134)
        #expect(Set(Storefront.all.map(\.code)).count == Storefront.all.count)
        #expect(Set(Storefront.all.map(\.id)).count == Storefront.all.count)
    }

    @Test func findsByCodeAndHeader() {
        #expect(Storefront(code: "br")?.id == "143503")
        #expect(Storefront(header: "143441-1,29")?.code == "US")
        #expect(Storefront(header: "999999-1,29") == nil)
        #expect(Storefront(code: "XX") == nil)
    }

    @Test func showsTheFlagAndLocalizedName() throws {
        let brazil = try #require(Storefront(code: "BR"))
        #expect(brazil.flag == "🇧🇷")
        #expect(brazil.name(locale: Locale(identifier: "en_US")) == "Brazil")
        #expect(brazil.name(locale: Locale(identifier: "pt_BR")) == "Brasil")
    }

    @Test func fallsBackToTheUnitedStates() {
        #expect(Storefront.current(locale: Locale(identifier: "en_BR")).code == "BR")
        #expect(Storefront.current(locale: Locale(identifier: "en")) == .unitedStates)
    }
}
