import Foundation

public struct AppInfo: Sendable {
    public static let main = AppInfo(info: Bundle.main.infoDictionary ?? [:])

    public let version: String
    let number: String
    let appStoreURL: URL?
    let reviewURL: URL?
    let supportURL: URL?
    let helpURL: URL?
    let privacyURL: URL?
    let termsURL: URL?
    let websiteURL: URL?

    public init(info: [String: Any]) {
        func value(_ key: String) -> String? {
            (info[key] as? String).flatMap { $0.isEmpty ? nil : $0 }
        }
        let number = value("CFBundleShortVersionString") ?? "—"
        self.number = number
        version = value("CFBundleVersion").map { "\(number) (\($0))" } ?? number
        let store = value("IPAAppStoreID").map { "https://apps.apple.com/app/id\($0)" }
        appStoreURL = store.flatMap(URL.init(string:))
        reviewURL = store.flatMap { URL(string: $0 + "?action=write-review") }
        supportURL = value("IPASupportEmail").flatMap { URL(string: "mailto:\($0)") }
        helpURL = value("IPAHelpURL").flatMap(URL.init(string:))
        privacyURL = value("IPAPrivacyURL").flatMap(URL.init(string:))
        termsURL = value("IPATermsURL").flatMap(URL.init(string:))
        websiteURL = value("IPAWebsiteURL").flatMap(URL.init(string:))
    }

    var hasHelp: Bool { reviewURL != nil || supportURL != nil || helpURL != nil }
}
