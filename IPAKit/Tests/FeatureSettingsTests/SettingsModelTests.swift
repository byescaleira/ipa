import FeatureCore
import Foundation
import IPADomain
import Testing

@testable import FeatureSettings

@MainActor
struct SettingsModelTests {
    private func defaults() throws -> UserDefaults {
        try #require(UserDefaults(suiteName: "SettingsModelTests.\(UUID().uuidString)"))
    }

    @Test func startsWithTheSystemLookAndTheDefaultTint() throws {
        let settings = SettingsModel(defaults: try defaults(), languageSetting: LanguageSetting())
        #expect(settings.appearance == .system)
        #expect(settings.language == .system)
        #expect(settings.tintName == RetroColor.default.name)
    }

    @Test func persistsTheChoices() throws {
        let defaults = try defaults()
        let language = LanguageSetting()
        let settings = SettingsModel(defaults: defaults, languageSetting: language)
        settings.appearance = .dark
        settings.tint = RetroColor.teal.hex
        settings.language = .portuguese
        #expect(language.language == .portuguese)
        let reopened = SettingsModel(defaults: defaults, languageSetting: LanguageSetting())
        #expect(reopened.appearance == .dark)
        #expect(reopened.tint == RetroColor.teal.hex)
        #expect(reopened.language == .portuguese)
    }

    @Test func readsVersionAndLinksFromTheInfoDictionary() {
        let info = AppInfo(info: [
            "CFBundleShortVersionString": "1.2", "CFBundleVersion": "7",
            "IPAPrivacyURL": "https://example.com/privacy", "IPAHelpURL": "",
        ])
        #expect(info.version == "1.2 (7)")
        #expect(info.links.map(\.kind) == [.privacy])
    }
}
