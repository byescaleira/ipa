import FeatureCore
import IPADesignSystem

extension Guide {
    static var tourPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .launch, title: "Welcome to IPA",
                message:
                    "Find an app in Search, sign in under Accounts and keep the packages in Downloads."
            ),
            TutorialPage(
                animation: .find, title: "Find and Keep",
                message: "Search finds the app; Downloads keeps the packages.",
                steps: [
                    GuideStep(
                        "magnifyingglass", color: .retroOrange, title: "Search",
                        detail: "Any app, in any App Store country."),
                    GuideStep(
                        "arrow.down.circle.fill", color: .retroDenim, title: "Downloads",
                        detail: "Packages ready to share, one list per account."),
                ]),
            TutorialPage(
                animation: .setup, title: "Yours to Set",
                message: "Accounts and Settings keep the choices that are yours.",
                steps: [
                    GuideStep(
                        "person.crop.circle.fill", color: .retroOrange, title: "Accounts",
                        detail: "Your Apple IDs and the one in use."),
                    GuideStep(
                        "gearshape.fill", color: .retroDenim, title: "Settings",
                        detail: "Appearance, language, guides and more."),
                ]),
        ]
    }

    static var appearancePages: [TutorialPage] {
        [
            TutorialPage(
                animation: .editor, title: "Make It Yours",
                message:
                    "In Settings › Appearance, pick the theme and the accent color. The language is in Settings › Language."
            )
        ]
    }

    static var privacyPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .privacy, title: "Your Data Stays Yours",
                message:
                    "Accounts stay in this device's Keychain and packages in the Files app. IPA has no servers of its own."
            ),
            TutorialPage(
                animation: .direct, title: "Straight to Apple",
                message:
                    "Sign-in, versions and downloads go only to Apple's servers, as in the App Store."
            ),
        ]
    }
}
