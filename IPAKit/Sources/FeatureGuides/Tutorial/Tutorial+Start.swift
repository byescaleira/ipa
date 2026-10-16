import FeatureCore
import IPADesignSystem

extension Guide {
    static var tourPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .find, title: "Search Any Store",
                message:
                    "Type a name, a bundle ID or an App Store link. The flag in Search picks the country."
            ),
            TutorialPage(
                animation: .setup, title: "Sign In Once",
                message:
                    "Add your Apple ID under Accounts. The password stays in this device's Keychain."
            ),
            TutorialPage(
                animation: .download, title: "Keep the Package",
                message:
                    "Download any version of a free app. Downloads keeps each .ipa, one list per account."
            ),
        ]
    }

    static var privacyPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .privacy, title: "Your Data Stays Yours",
                message:
                    "Accounts and the device identity stay in this device's Keychain, packages in the Files app. IPA has no servers of its own."
            ),
            TutorialPage(
                animation: .direct, title: "Straight to Apple",
                message:
                    "Sign-in, versions and downloads go only to Apple's servers, as in the App Store."
            ),
        ]
    }
}
