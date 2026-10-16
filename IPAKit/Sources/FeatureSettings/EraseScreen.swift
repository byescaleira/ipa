import FeatureCore
import IPADesignSystem
import SwiftUI

struct EraseScreen: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.appTint) private var appTint

    var body: some View {
        @Bindable var store = store
        GuideSheet(
            index: store.eraseStep.rawValue, count: StoreSettingsModel.EraseStep.allCases.count,
            isWorking: store.isWorking, primary: primary, secondary: secondary
        ) {
            switch store.eraseStep {
            case .confirm: EraseConfirmPage()
            case .done:
                GuidePage(
                    title: "Everything Erased",
                    message:
                        "IPA is back to how it was on the first launch. Add an account under Accounts to start again."
                ) {
                    IPAAnimationView(.done)
                }
            }
        }
        .tint(store.eraseStep == .confirm ? Color.negative : appTint)
        .errorAlert($store.error)
    }

    private var primary: GuideAction {
        switch store.eraseStep {
        case .confirm: GuideAction("Erase Everything") { Task { await store.erase() } }
        case .done: GuideAction("Done") { store.closeErase() }
        }
    }

    private var secondary: GuideAction? {
        switch store.eraseStep {
        case .confirm: GuideAction("Cancel") { store.closeErase() }
        case .done: nil
        }
    }
}

private struct EraseConfirmPage: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isShaking = false

    var body: some View {
        GuidePage(
            title: "Erase Everything?",
            message: "This can't be undone. IPA keeps nothing on a server to bring it back."
        ) {
            Image(systemName: "trash")
                .font(.icon(.xl, weight: .medium))
                .foregroundStyle(Color.negative)
                .frame(width: .medallion, height: .medallion)
                .background(Color.negative.opacity(.opacityFill), in: .circle)
                .symbolEffect(.wiggle, value: isShaking)
                .padding(.vertical, .spaceS)
                .task { if !reduceMotion { isShaking = true } }
        } content: {
            GuideValueList(
                store.eraseValues.map { GuideValue($0.label, value: $0.value, color: $0.color) })
        }
    }
}
