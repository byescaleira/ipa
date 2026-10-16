import FeatureAccounts
import FeatureCore
import FeatureSearch
import SwiftUI

struct RouteScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(StorePreferences.self) private var preferences
    @Environment(AccountsModel.self) private var accounts
    @Environment(DownloadCenter.self) private var downloads
    let route: Route

    @ViewBuilder var body: some View {
        switch route {
        case .app(let id):
            ModelHost(
                AppModel(
                    id: id, session: session, preferences: preferences, accounts: accounts,
                    downloads: downloads)
            ) {
                AppScreen()
            }
        case .storefronts: StorefrontScreen()
        case .signIn:
            ModelHost(SignInModel(session: session, accounts: accounts)) { SignInScreen() }
        }
    }
}
