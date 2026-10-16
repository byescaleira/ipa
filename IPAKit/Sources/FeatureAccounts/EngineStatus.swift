import IPADesignSystem
import IPADomain
import SwiftUI

struct EngineStatus: Hashable {
    let availability: EngineAvailability

    init(_ availability: EngineAvailability) {
        self.availability = availability
    }

    var title: String {
        switch availability {
        case .ready: String(appLocalized: "Ready")
        case .needsJIT: String(appLocalized: "Needs JIT")
        case .unsupported: String(appLocalized: "Not available on this device")
        }
    }

    var detail: String {
        switch availability {
        case .ready:
            String(appLocalized: "Sign-in, versions and downloads work on this device.")
        case .needsJIT:
            String(
                appLocalized:
                    "Turn on JIT for IPA with StikDebug, then come back. Search works without it.")
        case .unsupported:
            String(
                appLocalized:
                    "Search works here. Sign in and download on a Mac or on an iPhone with JIT.")
        }
    }

    var symbol: String {
        switch availability {
        case .ready: "checkmark.seal"
        case .needsJIT: "bolt.slash"
        case .unsupported: "xmark.octagon"
        }
    }

    var color: Color {
        switch availability {
        case .ready: .positive
        case .needsJIT: .warning
        case .unsupported: .negative
        }
    }

    var needsGuide: Bool { availability != .ready }
}
