import FeatureCore
import IPADesignSystem
import SwiftUI

struct SearchLimitSection: View {
    @Environment(StoreSettingsModel.self) private var store

    var body: some View {
        @Bindable var store = store
        Section {
            Picker("Results per Search", selection: $store.resultsLimit) {
                ForEach(StorePreferences.limits, id: \.self) { limit in
                    Text(verbatim: store.limitText(limit)).tag(limit)
                }
            }
            .labelsHidden()
            .pickerStyle(.inline)
            .sensoryFeedback(.selection, trigger: store.resultsLimit)
        } header: {
            Text("Results per Search").sectionTitle()
        } footer: {
            Text(
                "The App Store sends up to 200 results per search. Fewer results load faster on a slow connection."
            )
        }
    }
}
