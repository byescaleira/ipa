import FeatureCore
import Foundation
import IPADomain

extension AccountsModel {
    var removalTitle: String {
        guard let removal else { return "" }
        return String(appLocalized: "Remove \(removal.displayName)?")
    }

    var removalMessage: String {
        String(
            appLocalized:
                "The password and the session leave this device's Keychain. You can sign in again at any time."
        )
    }

    var othersFooter: String {
        String(
            appLocalized:
                "Tap to switch the active account. Swipe to remove one from this device.")
    }

    var removeFooter: String {
        String(appLocalized: "Packages downloaded with this account stay in Downloads.")
    }

    var examples: [Account] {
        [
            Account(
                email: "ana@icloud.com", name: "Ana Souza",
                storefront: Storefront(code: "BR") ?? .unitedStates, directoryServicesID: "1"),
            Account(
                email: "leo@example.com", name: "Leo Martins", storefront: .unitedStates,
                directoryServicesID: "2"),
        ]
    }
}
