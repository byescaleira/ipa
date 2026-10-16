import FeatureCore
import IPADesignSystem
import SwiftUI

struct ServerSection: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.appTint) private var appTint
    @FocusState private var focus: Field?

    var body: some View {
        @Bindable var store = store
        Section {
            TextField(
                "Address", text: $store.serverAddress,
                prompt: Text(verbatim: "https://host:8080")
            )
            .textContentType(.URL)
            .urlKeyboard()
            .autocorrectionDisabled()
            .submitLabel(.next)
            .focused($focus, equals: .address)
            .onSubmit { focus = .token }
            SecureField("Token", text: $store.serverToken)
                .textContentType(.password)
                .submitLabel(.done)
                .focused($focus, equals: .token)
                .onSubmit { store.saveServer() }
        } header: {
            ServerHero()
        } footer: {
            Text(verbatim: store.serverFooter)
        }
        Section {
            Button {
                store.saveServer()
            } label: {
                IconRow("Save Server", symbol: "checkmark.circle", color: appTint)
            }
            Button {
                Task { await store.checkServer() }
            } label: {
                IconRow(
                    "Check Connection", symbol: "antenna.radiowaves.left.and.right",
                    color: .companion)
            }
            if store.serverEnabled {
                Button(role: .destructive) {
                    store.removeServer()
                } label: {
                    IconRow(
                        "Remove Server", symbol: "trash", color: .negative, titleColor: .negative)
                }
            }
        }
        .errorAlert($store.error)
    }

    private enum Field: Hashable {
        case address, token
    }
}

private struct ServerHero: View {
    @Environment(StoreSettingsModel.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: .spaceS) {
            Chip(store.serverChip, color: store.serverChipColor, shape: .capsule)
                .contentTransition(.opacity)
            Text("Run the engine on your server").font(.subheadline).foregroundStyle(.secondary)
        }
        .textCase(nil)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceL)
        .accessibilityElement(children: .combine)
        .animation(reduceMotion ? nil : .smooth, value: store.serverStatus)
    }
}

extension View {
    @ViewBuilder fileprivate func urlKeyboard() -> some View {
        #if os(iOS) || os(visionOS)
            keyboardType(.URL).textInputAutocapitalization(.never)
        #else
            self
        #endif
    }
}
