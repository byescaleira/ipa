import FeatureCore
import IPADesignSystem
import SwiftUI

struct AppearanceScreen: View {
    var body: some View {
        SettingsPage("Appearance") {
            ThemeSection()
            AccentColorSection()
        }
    }
}
