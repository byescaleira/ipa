import FeatureAccounts
import FeatureCore
import FeatureLibrary
import FeatureSearch
import FeatureSettings
import SwiftUI

struct SectionScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(StorePreferences.self) private var preferences
    @Environment(AccountsModel.self) private var accounts
    @Environment(DownloadCenter.self) private var downloads
    let section: AppSection

    @ViewBuilder var body: some View {
        switch section {
        case .search:
            ModelHost(SearchModel(session: session, preferences: preferences, accounts: accounts)) {
                SearchScreen()
            }
        case .downloads:
            ModelHost(LibraryModel(downloads: downloads, accounts: accounts)) { LibraryScreen() }
        case .accounts: AccountsScreen()
        case .settings: SettingsScreen()
        }
    }
}
