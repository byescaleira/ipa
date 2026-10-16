import IPADomain
import SwiftUI

public enum Guide: String, CaseIterable, Identifiable, Sendable {
    case tour, jit, install, appearance, privacy

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .tour: String(appLocalized: "Meet IPA")
        case .appearance: String(appLocalized: "Make It Yours")
        case .privacy: String(appLocalized: "Privacy")
        case .jit: String(appLocalized: "Turn On JIT")
        case .install: String(appLocalized: "Install an IPA")
        }
    }

    public var subtitle: String {
        switch self {
        case .tour: String(appLocalized: "The tabs and what each one shows")
        case .appearance: String(appLocalized: "Theme, accent color and language")
        case .privacy: String(appLocalized: "Where your data lives")
        case .jit: String(appLocalized: "Why the store engine needs it on iPhone")
        case .install: String(appLocalized: "Ways to put a package on a device")
        }
    }

    public var systemImage: String {
        switch self {
        case .tour: "sparkles"
        case .appearance: "paintbrush"
        case .privacy: "lock.shield"
        case .jit: "bolt"
        case .install: "square.and.arrow.down"
        }
    }

    public var animation: IPAAnimation {
        switch self {
        case .tour: .launch
        case .appearance: .editor
        case .privacy: .privacy
        case .jit: .jit
        case .install: .install
        }
    }

    public var category: GuideCategory {
        switch self {
        case .tour: .start
        case .appearance: .personalize
        case .privacy: .data
        case .jit, .install: .sideload
        }
    }

    public var minutes: Int {
        switch self {
        case .tour: 2
        case .appearance, .privacy, .jit, .install: 1
        }
    }
}

public struct ShowGuideAction {
    private let action: (Guide) -> Void

    public init(_ action: @escaping (Guide) -> Void) {
        self.action = action
    }

    public func callAsFunction(_ guide: Guide) {
        action(guide)
    }
}

extension EnvironmentValues {
    @Entry public var showGuide: ShowGuideAction?
}
