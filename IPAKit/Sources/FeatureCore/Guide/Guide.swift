import IPADomain
import SwiftUI

public enum Guide: String, CaseIterable, Identifiable, Sendable {
    case tour, jit, install, privacy

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .tour: String(appLocalized: "Meet IPA")
        case .jit: String(appLocalized: "Turn On JIT")
        case .install: String(appLocalized: "Install an IPA")
        case .privacy: String(appLocalized: "Privacy")
        }
    }

    public var subtitle: String {
        switch self {
        case .tour: String(appLocalized: "Search, sign in and download")
        case .jit: String(appLocalized: "Why the store engine needs it on iPhone")
        case .install: String(appLocalized: "Ways to put a package on a device")
        case .privacy: String(appLocalized: "Where your data lives")
        }
    }

    public var systemImage: String {
        switch self {
        case .tour: "sparkles"
        case .jit: "bolt"
        case .install: "square.and.arrow.down"
        case .privacy: "lock.shield"
        }
    }

    public var animation: IPAAnimation {
        switch self {
        case .tour: .find
        case .jit: .jit
        case .install: .install
        case .privacy: .privacy
        }
    }

    public var category: GuideCategory {
        switch self {
        case .tour: .start
        case .jit, .install: .sideload
        case .privacy: .data
        }
    }

    public var minutes: Int {
        switch self {
        case .tour, .jit, .install: 2
        case .privacy: 1
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
