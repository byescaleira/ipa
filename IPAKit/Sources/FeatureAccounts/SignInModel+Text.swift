import FeatureCore
import Foundation
import IPADomain

extension SignInModel {
    public var primaryTitle: String {
        switch step {
        case .credentials: String(appLocalized: "Sign In")
        case .code: String(appLocalized: "Verify")
        }
    }

    public var codeMessage: String {
        String(appLocalized: "Enter the code sent to your devices.")
    }

    public var keychainFooter: String {
        String(
            appLocalized:
                "Your password stays only in this device's Keychain, and IPA sends it only to Apple."
        )
    }
}
