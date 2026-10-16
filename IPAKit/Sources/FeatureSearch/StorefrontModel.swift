import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class StorefrontModel {
    public var text = ""
    @ObservationIgnored private let preferences: StorePreferences
    @ObservationIgnored private let accounts: AccountsModel
    @ObservationIgnored private let region: Storefront
    @ObservationIgnored private let sorted: [Storefront]

    public init(
        preferences: StorePreferences, accounts: AccountsModel, locale: Locale = .current
    ) {
        self.preferences = preferences
        self.accounts = accounts
        region = .current(locale: locale)
        sorted = Storefront.all.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    public var query: String { text.trimmingCharacters(in: .whitespacesAndNewlines) }

    public var storefronts: [Storefront] {
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.name.localizedStandardContains(query) || $0.code == query.uppercased()
        }
    }

    public var isShowingAccountStore: Bool { query.isEmpty }

    public var isShowingNoResults: Bool { storefronts.isEmpty }

    public var selection: Storefront? { preferences.storefront }

    public var isAccountStoreSelected: Bool { preferences.storefront == nil }

    public var accountStorefront: Storefront { accounts.active?.storefront ?? region }

    public var accountStoreDetail: String {
        let store = accountStorefront.title
        guard let account = accounts.active else {
            return String(appLocalized: "\(store), this device's region")
        }
        return String(appLocalized: "\(store), the store of \(account.email)")
    }

    public func isSelected(_ storefront: Storefront) -> Bool {
        preferences.storefront == storefront
    }

    public func select(_ storefront: Storefront?) {
        preferences.storefront = storefront
    }
}
