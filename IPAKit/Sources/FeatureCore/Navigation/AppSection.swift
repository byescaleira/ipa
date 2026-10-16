import IPADomain
import SwiftUI

public enum AppSection: String, CaseIterable, Identifiable, Sendable {
    case search, downloads, accounts, settings

    public var id: String { rawValue }

    public static var barSections: [AppSection] { allCases.filter { $0.role == nil } }

    public static var prominent: AppSection { .search }

    public var title: String {
        switch self {
        case .search: String(appLocalized: "Search")
        case .downloads: String(appLocalized: "Downloads")
        case .accounts: String(appLocalized: "Accounts")
        case .settings: String(appLocalized: "Settings")
        }
    }

    public var systemImage: String {
        switch self {
        case .search: "magnifyingglass"
        case .downloads: "arrow.down.circle"
        case .accounts: "person.crop.circle"
        case .settings: "gearshape"
        }
    }

    public var role: TabRole? {
        switch self {
        case .search: .search
        case .downloads, .accounts, .settings: nil
        }
    }
}
