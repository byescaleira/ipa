import FeatureCore
import IPADesignSystem

extension Guide {
    static var jitPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .jit, title: "Turn On JIT",
                message:
                    "On iPhone, iPad and Apple Vision, sign-in and downloads run Apple's store engine, which needs JIT. Turn it on with StikDebug, then come back to IPA."
            )
        ]
    }

    static var installPages: [TutorialPage] {
        [
            TutorialPage(
                animation: .install, title: "Install an IPA",
                message:
                    "Share the package from Downloads to AltStore or SideStore, or AirDrop it to a Mac with Sideloadly."
            )
        ]
    }
}
