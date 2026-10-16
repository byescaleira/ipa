import FeatureCore
import Foundation
import IPADomain

extension AppModel {
    public static let placeholderVersionIDs = ["875214761", "875117761", "875020761"]

    public var shownVersionIDs: [String] {
        versionsStatus == .loading ? Self.placeholderVersionIDs : versionIDs
    }

    public var isShowingVersionPlaceholders: Bool { versionsStatus == .loading }

    public var versionsCount: String {
        versionIDs.count.formatted(.number.locale(.app))
    }

    public var versionsFailure: String? {
        guard case .failed(let error) = versionsStatus else { return nil }
        return error.localizedDescription
    }

    public var versionsFooter: String {
        String(appLocalized: "Tap a version to download that build. Names appear as they load.")
    }

    public func isLoaded(_ externalID: String) -> Bool {
        versions[externalID] != nil
    }

    public func versionTitle(_ externalID: String) -> String {
        guard let version = versions[externalID] else { return "v0.0.0" }
        return String(appLocalized: "v\(version.displayVersion)")
    }

    public func versionAccessibilityLabel(_ externalID: String) -> String {
        guard isLoaded(externalID) else {
            return String(appLocalized: "Version ID \(externalID), loading")
        }
        return [versionTitle(externalID), versionDetail(externalID)].joined(separator: ", ")
    }

    public func versionDetail(_ externalID: String) -> String {
        guard let date = versions[externalID]?.releaseDate else { return externalID }
        return [externalID, Self.dateText(date)].joined(separator: " · ")
    }

    public func displayVersion(of choice: VersionChoice) -> String? {
        versions[choice.externalID]?.displayVersion
    }

    public func choiceTitle(_ choice: VersionChoice) -> String {
        let name = shownApp.name
        guard let version = displayVersion(of: choice) else { return name }
        return [name, version].joined(separator: " ")
    }

    public var choiceMessage: String {
        guard let email = accounts.active?.email else { return "" }
        return String(appLocalized: "The package goes to Downloads, in the list of \(email).")
    }

    public func choiceRows(_ choice: VersionChoice) -> [(label: String, value: String)] {
        var rows: [(label: String, value: String)] = []
        if let version = displayVersion(of: choice) {
            rows.append((String(appLocalized: "Version"), version))
        }
        if let date = versions[choice.externalID]?.releaseDate {
            rows.append((String(appLocalized: "Released"), Self.dateText(date)))
        }
        rows.append((String(appLocalized: "Version ID"), choice.externalID))
        return rows
    }

    static func dateText(_ date: Date) -> String {
        date.formatted(Date.FormatStyle(locale: .app).day().month(.abbreviated).year())
    }
}
