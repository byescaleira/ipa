import FeatureCore
import IPADomain
import SwiftUI

@MainActor
public struct IPAWindow {
    public let session: SessionModel
    public let navigation: IPANavigation

    public init(provider: any RepositoryProvider) {
        session = SessionModel(repositories: provider.repositories)
        navigation = IPANavigation()
    }
}

extension View {
    public func ipaWindow(_ window: IPAWindow) -> some View {
        environment(window.session)
            .environment(window.navigation)
    }
}
