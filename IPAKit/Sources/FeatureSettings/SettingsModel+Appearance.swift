import FeatureCore
import Foundation
import IPADomain

struct ThemeSample {
    struct Row: Identifiable {
        let symbol: String
        let title: String
        let color: RetroColor
        let detail: String
        let fraction: Double

        var id: String { symbol }
    }

    let title: String
    let caption: String
    let headline: String
    let rows: [Row]
    let tabs: [AppSection]
    let selected: AppSection
}

extension SettingsModel {
    var tintName: String { RetroColor.name(for: tint) }

    var themeFooter: String {
        switch appearance {
        case .system:
            String(appLocalized: "IPA follows the light and dark setting of your device.")
        case .light, .dark:
            String(appLocalized: "IPA keeps this look whatever your device uses.")
        }
    }

    var themeSample: ThemeSample {
        ThemeSample(
            title: AppSection.downloads.title,
            caption: String(appLocalized: "Packages on this device"),
            headline: 5.formatted(.number.locale(.app)),
            rows: [
                ThemeSample.Row(
                    symbol: "cloud.sun.fill", title: "Weather Pro", color: .mustard,
                    detail: sampleDetail("4.2", 120_000_000), fraction: 0.64),
                ThemeSample.Row(
                    symbol: "camera.fill", title: "Photo Lab", color: .teal,
                    detail: sampleDetail("2.1", 85_000_000), fraction: 1),
            ],
            tabs: AppSection.barSections, selected: .downloads)
    }

    private func sampleDetail(_ version: String, _ bytes: Int64) -> String {
        let size = bytes.formatted(.byteCount(style: .file).locale(.app))
        return String(appLocalized: "v\(version) · \(size)")
    }

    var languageFooter: String {
        String(
            appLocalized:
                "IPA changes language right away. System texts, such as the keyboard and date pickers, follow the next time the app opens."
        )
    }
}
