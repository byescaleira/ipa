import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

struct AppHeroSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Section {
            AppPrimaryRow()
        } header: {
            AppHero()
        } footer: {
            if let footer = model.heroFooter {
                Text(verbatim: footer)
                    .foregroundStyle(model.isHeroFooterAlert ? Color.negative : .secondary)
            }
        }
        .redacted(reason: model.isShowingPlaceholder ? .placeholder : [])
    }
}

private struct AppHero: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let app = model.shownApp
        VStack(spacing: .spaceM) {
            AppArtwork(app.artworkURL, size: .badgeXL * 2)
                .shadow(color: .black.opacity(.opacityFill), radius: .spaceM, y: .spaceS)
            VStack(spacing: .space2XS) {
                Text(verbatim: app.name).font(.titleLarge).foregroundStyle(Color.primary)
                Text(verbatim: app.seller).font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            AppChips()
        }
        .textCase(nil)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spaceL)
    }
}

private struct AppChips: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appTint) private var appTint

    var body: some View {
        ViewThatFits {
            HStack(spacing: .spaceXS) { chips }
            FlowLayout(spacing: .spaceXS, alignment: .center) { chips }
        }
        .accessibilityElement(children: .combine)
    }

    private var chips: some View {
        ForEach(model.chips) {
            Chip($0.text, color: $0.color(tint: appTint), shape: .capsule).fixedSize()
        }
    }
}

private struct AppPrimaryRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.open) private var open
    @Environment(\.showGuide) private var showGuide
    @Environment(\.navigationSection) private var section

    var body: some View {
        if model.action == .progress {
            AppProgressRow()
        } else if let title = model.primaryTitle {
            Button(title, action: perform)
                .primaryButton()
                .disabled(model.isShowingPlaceholder)
                .padding(.vertical, .space2XS)
        }
    }

    private func perform() {
        switch model.action {
        case .download: model.downloadCurrent()
        case .signIn: open(.signIn, in: section)
        case .engine: showGuide?(.jit)
        case .paid, .progress, nil: break
        }
    }
}

private struct AppProgressRow: View {
    @Environment(AppModel.self) private var model
    @Environment(\.appTint) private var appTint
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: model.progressPhase)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(appTint)
                Spacer(minLength: .spaceS)
                Text(verbatim: model.progressDetail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .lineLimit(1)
            ProgressView(value: model.progressFraction)
                .tint(appTint)
                .animation(reduceMotion ? nil : .smooth, value: model.progressFraction)
        }
        .padding(.vertical, .space2XS)
        .accessibilityElement(children: .combine)
    }
}

struct AppVersionsSection: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.isShowingVersions {
            Section {
                if let failure = model.versionsFailure {
                    VersionsFailureRow(message: failure)
                } else {
                    ForEach(model.shownVersionIDs, id: \.self) { VersionRow(externalID: $0) }
                        .redacted(reason: model.isShowingVersionPlaceholders ? .placeholder : [])
                        .disabled(model.isShowingVersionPlaceholders)
                }
            } header: {
                HStack(spacing: .spaceS) {
                    Text("Versions").sectionTitle()
                    Spacer()
                    if !model.versionIDs.isEmpty {
                        Chip(model.versionsCount, color: .secondary)
                    }
                }
            } footer: {
                Text(verbatim: model.versionsFooter)
            }
        }
    }
}

private struct VersionRow: View {
    @Environment(AppModel.self) private var model
    let externalID: String

    var body: some View {
        Button {
            model.choose(externalID)
        } label: {
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(verbatim: model.versionTitle(externalID))
                    .font(.rowTitle)
                    .redacted(reason: model.isLoaded(externalID) ? [] : .placeholder)
                Text(verbatim: model.versionDetail(externalID))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
        }
        .tint(Color.primary)
        .disabled(!model.canDownload)
        .onAppear { model.requestMetadata(for: externalID) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.versionAccessibilityLabel(externalID))
        .accessibilityAddTraits(.isButton)
    }
}

private struct VersionsFailureRow: View {
    @Environment(AppModel.self) private var model
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spaceS) {
            Text(verbatim: message).font(.subheadline).foregroundStyle(.secondary)
            Button("Try Again") { Task { await model.reloadVersions() } }
                .font(.buttonLabel)
                .buttonStyle(.borderless)
        }
        .padding(.vertical, .space2XS)
    }
}
