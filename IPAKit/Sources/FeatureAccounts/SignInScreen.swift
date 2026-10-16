import FeatureCore
import IPADesignSystem
import SwiftUI

public struct SignInScreen: View {
    @Environment(SignInModel.self) private var model

    public init() {}

    public var body: some View {
        @Bindable var model = model
        Form {
            SignInEngineSection()
            switch model.step {
            case .credentials: SignInCredentialsSection()
            case .code: SignInCodeSection()
            }
            SignInButtonSection()
        }
        .fontDesign(.rounded)
        .readableWidth()
        .errorAlert($model.error)
        .task { await model.refreshAvailability() }
        .navigationTitle("Add Account")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct SignInEngineSection: View {
    @Environment(SignInModel.self) private var model

    var body: some View {
        if model.availability != .ready {
            Section {
                EngineStatusRows(model.availability)
            } header: {
                Text("Store Engine").sectionTitle()
            }
        }
    }
}

private struct SignInCredentialsSection: View {
    @Environment(SignInModel.self) private var model
    @Environment(\.close) private var close
    @FocusState private var focus: Field?

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Email", text: $model.email, prompt: Text(verbatim: "name@icloud.com"))
                .textContentType(.username)
                .emailKeyboard()
                .autocorrectionDisabled()
                .submitLabel(.next)
                .focused($focus, equals: .email)
                .onSubmit { focus = .password }
            SecureField("Password", text: $model.password)
                .textContentType(.password)
                .submitLabel(.go)
                .focused($focus, equals: .password)
                .onSubmit { Task { if await model.submit() { close() } } }
        } header: {
            Text("Apple ID").sectionTitle()
        } footer: {
            if let failure = model.failure {
                Text(verbatim: failure).foregroundStyle(Color.negative)
            }
        }
        .disabled(model.isWorking)
        .task { focus = .email }
    }

    private enum Field: Hashable {
        case email, password
    }
}

private struct SignInCodeSection: View {
    @Environment(SignInModel.self) private var model
    @FocusState private var isFocused: Bool

    var body: some View {
        @Bindable var model = model
        Section {
            TextField("Code", text: $model.code, prompt: Text(verbatim: "000000"))
                .textContentType(.oneTimeCode)
                .numberKeyboard()
                .font(.amountTitle)
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .focused($isFocused)
        } header: {
            Text("Verification Code").sectionTitle()
        } footer: {
            Text(verbatim: model.failure ?? model.codeMessage)
                .foregroundStyle(model.failure == nil ? Color.secondary : Color.negative)
        }
        .disabled(model.isWorking)
        .task { isFocused = true }
    }
}

private struct SignInButtonSection: View {
    @Environment(SignInModel.self) private var model
    @Environment(\.close) private var close

    var body: some View {
        Section {
            VStack(spacing: .spaceM) {
                Button {
                    Task { if await model.submit() { close() } }
                } label: {
                    ZStack {
                        Text(verbatim: model.primaryTitle).opacity(model.isWorking ? 0 : 1)
                        if model.isWorking { ProgressView() }
                    }
                }
                .primaryButton()
                .disabled(!model.canSubmit)
                if model.step == .code {
                    Button("Use a Different Apple ID") { model.changeAccount() }
                        .font(.buttonLabel)
                        .buttonStyle(.borderless)
                        .disabled(model.isWorking)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        } footer: {
            Text(verbatim: model.keychainFooter)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
        }
    }
}

extension View {
    @ViewBuilder fileprivate func emailKeyboard() -> some View {
        #if os(iOS) || os(visionOS)
            keyboardType(.emailAddress).textInputAutocapitalization(.never)
        #else
            self
        #endif
    }

    @ViewBuilder fileprivate func numberKeyboard() -> some View {
        #if os(iOS) || os(visionOS)
            keyboardType(.numberPad)
        #else
            self
        #endif
    }
}
