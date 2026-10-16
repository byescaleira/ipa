import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

struct AppIdentifiersSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if !model.identifiers.isEmpty {
            Section {
                ForEach(model.identifiers) { IdentifierRow(identifier: $0) }
                if let url = model.shareURL {
                    ShareButton([url]) {
                        Label("Share Link", systemImage: "square.and.arrow.up")
                            .font(.buttonLabel)
                    }
                }
            } header: {
                Text("Identifiers").sectionTitle()
            } footer: {
                Text("Tap an identifier to copy it.")
            }
        }
    }
}

private struct IdentifierRow: View {
    @Environment(AppModel.self) private var model
    let identifier: AppIdentifier

    var body: some View {
        Button {
            model.copy(identifier)
        } label: {
            HStack(spacing: .spaceM) {
                VStack(alignment: .leading, spacing: .spaceHairline) {
                    Text(verbatim: model.title(for: identifier.kind))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(verbatim: identifier.value)
                        .font(.body.monospaced())
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "doc.on.doc")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Copies to the clipboard")
    }
}

struct AppVersionIDSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if model.canDownload {
            Section {
                TextField("Version ID, like 875214761", text: $model.versionIDText)
                    .monospacedDigit()
                    .onSubmit(model.downloadVersionID)
                    #if os(iOS) || os(visionOS)
                        .keyboardType(.numberPad)
                    #endif
                Button("Download This Version", action: model.downloadVersionID)
                    .font(.buttonLabel)
                    .disabled(!model.canDownloadVersionID)
            } header: {
                Text("Download by Version ID").sectionTitle()
            } footer: {
                Text(verbatim: model.versionIDFooter)
                    .foregroundStyle(model.isVersionIDInvalid ? Color.negative : .secondary)
            }
        }
    }
}
