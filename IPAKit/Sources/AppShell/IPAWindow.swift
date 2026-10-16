import FeatureCore
import IPADomain
import SwiftUI

@MainActor
public struct IPAWindow {
    public let session: SessionModel
    public let navigation: IPANavigation
    public let preferences: StorePreferences
    public let accounts: AccountsModel
    public let downloads: DownloadCenter

    public init(provider: any RepositoryProvider, services: StoreServices) {
        session = SessionModel(repositories: provider.repositories, services: services)
        navigation = IPANavigation()
        preferences = StorePreferences()
        accounts = AccountsModel(vault: services.vault)
        downloads = DownloadCenter(repositories: provider.repositories, services: services)
        accounts.load()
    }
}

extension View {
    public func ipaWindow(_ window: IPAWindow) -> some View {
        environment(window.session)
            .environment(window.navigation)
            .environment(window.preferences)
            .environment(window.accounts)
            .environment(window.downloads)
    }
}
