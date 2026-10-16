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

    @Test func resetPutsTheLookBackToDefaults() throws {
        let settings = SettingsModel(defaults: try defaults(), languageSetting: LanguageSetting())
        settings.appearance = .dark
        settings.tint = RetroColor.teal.hex
        settings.language = .portuguese
        settings.reset()
        #expect(settings.appearance == .system)
        #expect(settings.tint == RetroColor.default.hex)
        #expect(settings.language == .system)
    }

    @Test func aboutListsTheRepositoryOnceAndSharesIt() throws {
        let repository = "https://github.com/byescaleira/ipa"
        let info = AppInfo(info: ["IPAWebsiteURL": repository, "IPAHelpURL": repository])
        #expect(info.links.map(\.kind) == [.website])
        #expect(info.shareURL == URL(string: repository))
        let store = AppInfo(info: ["IPAAppStoreID": "42", "IPAWebsiteURL": repository])
        #expect(store.shareURL == URL(string: "https://apps.apple.com/app/id42"))
    }
}
