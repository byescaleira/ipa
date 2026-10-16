import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class SearchModel {
    public var text = ""
    public private(set) var results: [StoreApp] = []
    public var error: IPAError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let preferences: StorePreferences
    @ObservationIgnored private let accounts: AccountsModel

    public init(session: SessionModel, preferences: StorePreferences, accounts: AccountsModel) {
        self.session = session
        self.preferences = preferences
        self.accounts = accounts
    }

    public var storefront: Storefront { preferences.storefront(for: accounts.active) }
}
