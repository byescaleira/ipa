import IPADesignSystem
import IPADomain
import SwiftUI

extension EngineAvailability {
    public var title: String {
        switch self {
        case .ready: String(appLocalized: "Ready")
        case .needsJIT: String(appLocalized: "Needs JIT")
        case .unsupported: String(appLocalized: "Not Available")
        }
    }

    public var detail: String {
        switch self {
        case .ready: String(appLocalized: "Sign-in, versions and downloads work on this device.")
        case .needsJIT:
            String(appLocalized: "Sign-in, versions and downloads wait until JIT is on.")
        case .unsupported: String(appLocalized: "This device can't run the store engine yet.")
        }
    }

    public var symbol: String {
        switch self {
        case .ready: "checkmark.seal.fill"
        case .needsJIT: "bolt.slash.fill"
        case .unsupported: "xmark.octagon.fill"
        }
    }

    public var color: Color {
        switch self {
        case .ready: .positive
        case .needsJIT: .warning
        case .unsupported: .negative
        }
    }

    public var needsGuide: Bool { self != .ready }
}
