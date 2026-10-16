import FeatureCore
import IPADesignSystem
import SwiftUI

struct EngineSection: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.showGuide) private var showGuide
    @Environment(\.appTint) private var appTint

    var body: some View {
        Section {
            if let showGuide {
                Button {
                    showGuide(.jit)
                } label: {
                    IconRow("How to Turn On JIT", symbol: "bolt", color: appTint)
                }
            }
            if store.canCheckEngine {
                Button {
                    Task { await store.refreshEngine() }
                } label: {
                    IconRow("Check Again", symbol: "arrow.clockwise", color: .companion)
                }
            }
        } header: {
            EngineHero()
        } footer: {
            Text(verbatim: store.engineFooter)
        }
        .task { await store.refreshEngine() }
    }
}

private struct EngineHero: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: .spaceM) {
            IPAAnimationView(.jit).frame(maxWidth: 220)
            VStack(spacing: .spaceS) {
                Chip(store.engineTitle, color: store.engineColor, shape: .capsule)
                    .contentTransition(.opacity)
                Text(verbatim: store.engineCaption)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
        .textCase(nil)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceS)
        .animation(reduceMotion ? nil : .smooth, value: store.availability)
    }
}
