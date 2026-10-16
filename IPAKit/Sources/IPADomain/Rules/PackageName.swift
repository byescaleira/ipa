import Foundation

public enum PackageName {
    public static func file(bundleID: String, appID: Int64, version: String) -> String {
        let safe = [bundleID, String(appID), version]
            .map { $0.replacing(/[^A-Za-z0-9._-]/, with: "_") }
            .filter { !$0.isEmpty }
        return safe.joined(separator: "_") + ".ipa"
    }

    public static func folder(email: String) -> String {
        let safe = email.lowercased().replacing(/[^a-z0-9._@-]/, with: "_")
        return safe.isEmpty ? "account" : safe
    }
}
