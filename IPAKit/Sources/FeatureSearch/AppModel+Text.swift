import FeatureCore
import Foundation
import IPADesignSystem
import IPADomain
import SwiftUI

public struct AppChip: Identifiable, Hashable {
    public enum Tone: Hashable {
        case tint, neutral, positive, warning
    }

    public let text: String
    public let tone: Tone

    public var id: String { text }

    public func color(tint: Color) -> Color {
        switch tone {
        case .tint: tint
        case .neutral: .secondary
        case .positive: .positive
        case .warning: .warning
        }
    }
}

extension AppModel {
    public static let placeholder = StoreApp(
        id: 0, bundleID: "com.example.app", name: "App Name", seller: "Developer Name",
        version: "1.0.0", minimumOSVersion: "17.0", sizeBytes: 104_857_600)

    public var shownApp: StoreApp { app ?? Self.placeholder }

    public var isShowingPlaceholder: Bool { app == nil && isLoading }

    public var title: String { app?.name ?? "" }

    public var chips: [AppChip] {
        let app = shownApp
        var chips: [AppChip] = []
        if let version = app.versionText { chips.append(AppChip(text: version, tone: .tint)) }
        if let system = app.systemText { chips.append(AppChip(text: system, tone: .neutral)) }
        if let size = app.sizeText { chips.append(AppChip(text: size, tone: .neutral)) }
        chips.append(AppChip(text: app.priceText, tone: app.isFree ? .positive : .warning))
        return chips
    }

    public var primaryTitle: String? {
        switch action {
        case .download:
            app.map(\.version).flatMap {
                $0.isEmpty ? nil : String(appLocalized: "Download v\($0)")
            }
                ?? String(appLocalized: "Download")
        case .signIn: String(appLocalized: "Sign In to Download")
        case .engine(.needsJIT): String(appLocalized: "Turn On JIT")
        case .engine: String(appLocalized: "Why Downloads Are Off")
        case .paid, .progress, nil: nil
        }
    }

    public var heroFooter: String? {
        if let failure = failedTask?.failure, action == .download {
            return failure.localizedDescription
        }
        switch action {
        case .download:
            guard let email = accounts.active?.email else { return nil }
            return String(appLocalized: "The package goes to Downloads, in the list of \(email).")
        case .signIn:
            return String(
                appLocalized:
                    "Search works without an account. Downloading needs an Apple ID that can get this app."
            )
        case .paid:
            return String(
                appLocalized:
                    "Only free apps can be downloaded. This one costs \(shownApp.priceText) in \(storefront.title)."
            )
        case .engine(.needsJIT):
            return String(
                appLocalized: "The store engine needs JIT on this device. The guide shows how.")
        case .engine:
            return String(
                appLocalized:
                    "The store engine doesn't run on this device yet. Search and details still work."
            )
        case .progress:
            return String(appLocalized: "Follow or cancel it in Downloads.")
        case nil:
            return nil
        }
    }

    public var isHeroFooterAlert: Bool { failedTask != nil && action == .download }

    public var progressPhase: String { task?.progress.phaseText ?? "" }

    public var progressDetail: String {
        guard let task else { return "" }
        if let bytes = task.progress.bytesText { return bytes }
        return task.version.isEmpty ? "" : String(appLocalized: "v\(task.version)")
    }

    public var progressFraction: Double { task?.progress.fraction ?? 0 }

    public var isAppNotFound: Bool { loadFailure == .appNotFound }

    public var loadFailureTitle: String {
        isAppNotFound
            ? String(appLocalized: "App Not Found") : String(appLocalized: "Couldn't Load the App")
    }

    public var loadFailureMessage: String {
        guard let loadFailure else { return "" }
        guard isAppNotFound else { return loadFailure.localizedDescription }
        return String(
            appLocalized:
                "This app isn't in \(storefront.title). Try another store or check the ID.")
    }

    public var loadFailureSymbol: String {
        isAppNotFound ? "questionmark.app.dashed" : "wifi.exclamationmark"
    }

    public var identifiers: [AppIdentifier] {
        guard let app else { return [] }
        var identifiers = [
            AppIdentifier(kind: .bundleID, value: app.bundleID),
            AppIdentifier(kind: .appID, value: String(app.id)),
        ]
        if let url = app.storeURL {
            identifiers.append(AppIdentifier(kind: .link, value: url.absoluteString))
        }
        return identifiers
    }

    public var shareURL: URL? { app?.storeURL }

    public func title(for kind: AppIdentifier.Kind) -> String {
        switch kind {
        case .bundleID: String(appLocalized: "Bundle ID")
        case .appID: String(appLocalized: "App ID")
        case .link: String(appLocalized: "Link")
        }
    }

    public var versionIDFooter: String {
        isVersionIDInvalid
            ? String(appLocalized: "Version IDs are numbers only, like 875214761.")
            : String(appLocalized: "Paste an ID from another tool to get that exact build.")
    }
}
