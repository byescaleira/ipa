import FeatureCore
import IPADesignSystem

extension Guide {
    static var jitPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .direct, title: "Why IPA Needs JIT",
                message:
                    "Apple signs every sign-in and download. IPA runs Apple's own store code for that, and iPhone and iPad allow it only with JIT."
            ),
            TutorialPage(
                animation: .jit, title: "Turn It On with StikDebug",
                message: "StikDebug turns on JIT right on the device, no computer needed.",
                steps: [
                    GuideStep(
                        "arrow.down.app.fill", color: .retroTeal, title: "Install StikDebug",
                        detail: "Follow its setup to add the pairing file."),
                    GuideStep(
                        "bolt.fill", color: .retroDenim, title: "Enable JIT",
                        detail: "Tap Enable JIT and pick IPA. Do it again after IPA closes."),
                    GuideStep(
                        "checkmark.circle.fill", color: .retroOrange, title: "Back to IPA",
                        detail: "Settings › Store Engine shows Ready."),
                ],
                link: .stikDebug),
            TutorialPage(
                animation: .find, title: "Without JIT",
                message:
                    "Search and app details still work. Sign-in and downloads wait, and IPA says why instead of failing."
            ),
        ]
    }

    static var installPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .install, title: "AltStore or SideStore",
                message:
                    "Both sign the package with your Apple ID and install it on this iPhone or iPad.",
                steps: [
                    GuideStep(
                        "square.and.arrow.up.fill", color: .retroOrange,
                        title: "Share from Downloads", detail: "Choose Share on the package."),
                    GuideStep(
                        "checkmark.circle.fill", color: .retroTeal,
                        title: "Pick AltStore or SideStore",
                        detail: "It signs the app and puts it on the Home Screen."),
                ],
                link: .altStore),
            TutorialPage(
                animation: .share, title: "AirDrop to Another Device",
                message:
                    "Share the package with AirDrop. Open it there with AltStore or SideStore, or with Sideloadly on a Mac."
            ),
            TutorialPage(
                animation: .computer, title: "Sideloadly on a Computer",
                message: "Sideloadly installs the package from a Mac or PC over a cable.",
                steps: [
                    GuideStep(
                        "laptopcomputer", color: .retroDenim, title: "Install Sideloadly",
                        detail: "On a Mac or a Windows PC."),
                    GuideStep(
                        "cable.connector", color: .retroTeal, title: "Connect and Drop",
                        detail: "Plug in the iPhone and drag the .ipa into Sideloadly."),
                    GuideStep(
                        "play.fill", color: .retroOrange, title: "Start",
                        detail: "Sign in with your Apple ID and tap Start."),
                ],
                link: .sideloadly),
        ]
    }
}
