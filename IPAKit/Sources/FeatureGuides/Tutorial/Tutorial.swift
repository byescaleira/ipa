import FeatureCore
import Foundation
import SwiftUI

struct TutorialPage: Identifiable {
    let id = UUID()
    let animation: IPAAnimation
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    var steps: [GuideStep] = []
    var link: TutorialLink?
}

struct TutorialLink {
    let title: LocalizedStringKey
    let symbol: String
    let url: URL

    private init?(_ title: LocalizedStringKey, address: String) {
        guard let url = URL(string: address) else { return nil }
        self.title = title
        symbol = "arrow.up.right"
        self.url = url
    }

    static var stikDebug: TutorialLink? {
        TutorialLink("Open StikDebug", address: "https://github.com/StephenDev0/StikDebug")
    }

    static var altStore: TutorialLink? {
        TutorialLink("Open AltStore", address: "https://altstore.io")
    }

    static var sideloadly: TutorialLink? {
        TutorialLink("Open Sideloadly", address: "https://sideloadly.io")
    }
}

extension Guide {
    var pages: [TutorialPage] {
        switch self {
        case .tour: Self.tourPages
        case .jit: Self.jitPages
        case .install: Self.installPages
        case .privacy: Self.privacyPages
        }
    }
}
