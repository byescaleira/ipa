import FeatureCore
import IPADesignSystem
import SwiftUI

struct StoreSettingsHost: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(SessionModel.self) private var session: SessionModel?
    @Environment(StorePreferences.self) private var preferences: StorePreferences?
    @Environment(AccountsModel.self) private var accounts: AccountsModel?
    @Environment(DownloadCenter.self) private var downloads: DownloadCenter?

    var body: some View {
        if let session, let preferences, let accounts, let downloads {
            ModelHost(
                StoreSettingsModel(
                    settings: settings, session: session, preferences: preferences,
                    accounts: accounts, downloads: downloads)
            ) {
                StoreRowsSection()
                StorageRowSection()
            }
        }
    }
}

private struct StoreRowsSection: View {
    @Environment(StoreSettingsModel.self) private var store

    var body: some View {
        Section {
            SettingsRow(
                "Search", symbol: "magnifyingglass", color: RetroColor.terracotta.color,
                value: store.resultsValue
            ) {
                SettingsPage("Search") { SearchLimitSection() }.environment(store)
            }
            SettingsRow(
                "Device Identity", symbol: "number", color: RetroColor.mustard.color,
                value: store.identityValue
            ) {
                SettingsPage("Device Identity") { IdentitySection() }.environment(store)
            }
            SettingsRow(
                "Store Engine", symbol: "bolt", color: RetroColor.plum.color,
                value: store.engineTitle
            ) {
                SettingsPage("Store Engine") { EngineSection() }.environment(store)
            }
            SettingsRow(
                "Server", symbol: "server.rack", color: RetroColor.teal.color,
                value: store.serverValue
            ) {
                SettingsPage("Server") { ServerSection() }.environment(store)
            }
        } header: {
            Text("Store")
        }
        .task { await store.load() }
    }
}

private struct StorageRowSection: View {
    @Environment(StoreSettingsModel.self) private var store

    var body: some View {
        Section {
            SettingsRow(
                "Storage", symbol: "externaldrive", color: RetroColor.slate.color,
                value: store.usedSpaceText
            ) {
                SettingsPage("Storage") { StorageSection() }.environment(store)
            }
        } header: {
            Text("Data")
        }
    }
}
