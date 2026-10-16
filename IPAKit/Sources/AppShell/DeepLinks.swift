import FeatureCore
import SwiftUI

struct DeepLinks: ViewModifier {
    @Environment(IPANavigation.self) private var navigation
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    func body(content: Content) -> some View {
        content
            .onOpenURL(perform: handle)
            .onChange(of: IPAServices.shared.pendingURL, initial: true) { _, url in
                guard let url else { return }
                IPAServices.shared.pendingURL = nil
                handle(url)
            }
            .task { handleLaunchArgument() }
    }

    private func handleLaunchArgument() {
        #if DEBUG
            guard let value = UserDefaults.standard.string(forKey: "ipa.developer.openURL"),
                let url = URL(string: value)
            else { return }
            UserDefaults.standard.removeObject(forKey: "ipa.developer.openURL")
            handle(url)
        #endif
    }

    private func handle(_ url: URL) {
        guard DeepLink.handles(url) else { return }
        switch DeepLink(url: url) {
        case .section(let section):
            navigation.selectedSection = section
        case .route(let route, let section):
            navigation.open(route, in: section, beside: horizontalSizeClass == .regular)
        case .search(let text):
            navigation.selectedSection = .search
            navigation.pendingSearch = text
        }
    }
}
