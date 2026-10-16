import FeatureCore
import IPADesignSystem
import SwiftUI

struct StorageSection: View {
    @Environment(StoreSettingsModel.self) private var store

    var body: some View {
        @Bindable var store = store
        Section {
            Button(role: .destructive) {
                store.startErase()
            } label: {
                IconRow(
                    "Erase Everything", detail: "Accounts, downloads and preferences.",
                    symbol: "trash", color: .negative, titleColor: .negative)
            }
            .sheet(isPresented: $store.isErasing, onDismiss: { store.closeErase() }) {
                EraseScreen().environment(store)
            }
        } header: {
            StorageHero()
        } footer: {
            Text(
                "Packages are in the Files app, in IPA › Downloads. Erasing also gives this device a new identity."
            )
        }
    }
}

private struct StorageHero: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: .spaceS) {
            Chip(store.storageChip, color: appTint, shape: .capsule)
            Text(verbatim: store.usedSpaceText)
                .font(.amountHero)
                .foregroundStyle(Color.primary)
                .contentTransition(.numericText(value: Double(store.usedBytes)))
                .amountLine()
            Text(verbatim: store.packagesCaption).font(.subheadline).foregroundStyle(.secondary)
        }
        .textCase(nil)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceL)
        .accessibilityElement(children: .combine)
        .animation(reduceMotion ? nil : .smooth, value: store.usedBytes)
    }
}
