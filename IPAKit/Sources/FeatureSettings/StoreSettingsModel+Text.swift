import FeatureCore
import Foundation
import IPADesignSystem
import IPADomain
import SwiftUI

struct SettingsValue: Identifiable {
    let label: String
    let value: String
    var color: Color = .primary

    var id: String { label }
}

extension StoreSettingsModel {
    var resultsValue: String { limitText(resultsLimit) }

    func limitText(_ limit: Int) -> String {
        limit.formatted(.number.locale(.app))
    }

    var identityChip: String { String(appLocalized: "MAC Address").uppercased(with: .app) }

    var identityText: String { identity?.macAddress ?? "—" }

    var identityValues: [SettingsValue] {
        [
            SettingsValue(label: String(appLocalized: "Current Identity"), value: identityText),
            SettingsValue(
                label: String(appLocalized: "Accounts to Sign In Again"), value: accountsValue,
                color: accounts.accounts.isEmpty ? .primary : .negative),
        ]
    }

    var engineTitle: String {
        switch availability {
        case .ready: String(appLocalized: "Ready")
        case .needsJIT: String(appLocalized: "Needs JIT")
        case .unsupported: String(appLocalized: "Not Available")
        }
    }

    var engineColor: Color {
        switch availability {
        case .ready: .positive
        case .needsJIT: .warning
        case .unsupported: .negative
        }
    }

    var engineCaption: String {
        switch availability {
        case .ready: String(appLocalized: "Sign-in and downloads work on this device.")
        case .needsJIT: String(appLocalized: "Sign-in and downloads wait until JIT is on.")
        case .unsupported: String(appLocalized: "This device can't run the store engine yet.")
        }
    }

    var engineFooter: String {
        switch availability {
        case .ready:
            String(
                appLocalized:
                    "The engine runs Apple's store code on this device for sign-in, versions and downloads. Search never needs it."
            )
        case .needsJIT:
            String(
                appLocalized:
                    "Turn on JIT with StikDebug, then check again. Search and app details work without it."
            )
        case .unsupported:
            String(
                appLocalized:
                    "Search and app details still work here. Sign in and download on a Mac, iPhone or iPad."
            )
        }
    }

    var canCheckEngine: Bool { availability == .needsJIT }

    var usedBytes: Int64 { downloads.records.reduce(0) { $0 + $1.sizeBytes } }

    var usedSpaceText: String { ByteCount.text(usedBytes) }

    var storageChip: String { String(appLocalized: "Downloads").uppercased(with: .app) }

    var packagesCaption: String {
        String(appLocalized: "\(downloads.records.count) packages in the Files app")
    }

    var accountsValue: String { accounts.accounts.count.formatted(.number.locale(.app)) }

    var eraseValues: [SettingsValue] {
        [
            SettingsValue(label: String(appLocalized: "Accounts"), value: accountsValue),
            SettingsValue(label: String(appLocalized: "Downloads"), value: usedSpaceText),
            SettingsValue(
                label: String(appLocalized: "Preferences"),
                value: String(appLocalized: "Back to Defaults")),
        ]
    }
}
