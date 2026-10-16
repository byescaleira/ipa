import FeatureCore
import IPADesignSystem
import SwiftUI

struct AboutScreen: View {
    var body: some View {
        ModelHost(AboutModel()) { AboutPage() }
    }
}

private struct AboutPage: View {
    var body: some View {
        SettingsPage("About IPA") {
            AboutHeroSection()
            AboutValuesSection()
            AboutShareSection()
            AboutLinksSection()
            AboutCreditsSection()
        }
    }
}

private struct AboutHeroSection: View {
    @Environment(SettingsModel.self) private var settings
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShown = false

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                AppIconImage(icon: settings.appIcon, size: .badgeXL * 1.5)
                    .shadow(color: .black.opacity(.opacityTint), radius: 10, y: 4)
                    .scaleEffect(isShown || reduceMotion ? 1 : 0.7)
                    .opacity(isShown || reduceMotion ? 1 : 0)
                VStack(spacing: .space2XS) {
                    Text(verbatim: "IPA").font(.titleLarge)
                    Text("Version \(settings.info.version)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spaceM)
            .animation(reduceMotion ? nil : .bouncy, value: isShown)
            .accessibilityElement(children: .combine)
            .task { isShown = true }
        }
    }
}
