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

    var identityValue: String? {
        identity.map { "…" + String($0.macAddress.suffix(5)) }
    }

    var identityValues: [SettingsValue] {
        [
            SettingsValue(label: String(appLocalized: "Current Identity"), value: identityText),
            SettingsValue(
                label: String(appLocalized: "Accounts to Sign In Again"), value: accountsValue,
                color: accounts.accounts.isEmpty ? .primary : .negative),
        ]
    }

    var engineTitle: String { availability.title }

    var engineColor: Color { availability.color }

    var engineCaption: String { availability.detail }

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

    var serverValue: String {
        guard let config = session.services.serverConfig.load() else {
            return String(appLocalized: "Off")
        }
        return config.baseURL.host ?? config.baseURL.absoluteString
    }

    var serverChip: String {
        switch serverStatus {
        case .idle:
            serverEnabled
                ? String(appLocalized: "Saved") : String(appLocalized: "Not Set")
        case .checking: String(appLocalized: "Checking…")
        case .online: String(appLocalized: "Online")
        case .failed: String(appLocalized: "Unreachable")
        }
    }

    var serverChipColor: Color {
        switch serverStatus {
        case .online: .positive
        case .failed: .negative
        case .checking: .info
        case .idle: serverEnabled ? .info : .secondary
        }
    }

    var serverFooter: String {
        String(
            appLocalized:
                "Point IPA at your own server running the store engine, so sign-in and downloads work without JIT on this device. Your Apple ID and password travel to that server, so use only a server you trust over HTTPS."
        )
    }

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
