import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

public struct AppScreen: View {
    @Environment(AppModel.self) private var model

    public init() {}

    public var body: some View {
        @Bindable var model = model
        AdaptiveList {
            if model.app != nil || model.isShowingPlaceholder {
                AppHeroSection()
                AppVersionsSection()
                AppIdentifiersSection()
                AppVersionIDSection()
            }
        }
        .overlay { AppFailureView() }
        .fontDesign(.rounded)
        .sheet(item: $model.confirmation) { VersionSheet(choice: $0) }
        .sensoryFeedback(.success, trigger: model.copyCount)
        .sensoryFeedback(.start, trigger: model.startCount)
        .errorAlert($model.error)
        .refreshable { await model.load() }
        .task(id: model.loadKey) { await model.load() }
        .navigationTitle(model.title)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

private struct AppFailureView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if model.app == nil, !model.isLoading, model.loadFailure != nil {
            ContentUnavailableView {
                Label {
                    Text(verbatim: model.loadFailureTitle)
                } icon: {
                    Image(systemName: model.loadFailureSymbol)
                }
            } description: {
                Text(verbatim: model.loadFailureMessage)
            } actions: {
                Button("Try Again") { Task { await model.load() } }
                    .primaryButton()
                if model.isAppNotFound {
                    Button("Change Store") { open(.storefronts, in: section) }
                        .font(.buttonLabel)
                        .buttonStyle(.borderless)
                }
            }
        }
    }
}

private struct VersionSheet: View {
    @Environment(AppModel.self) private var model
    let choice: VersionChoice

    var body: some View {
        GuideSheet(
            index: 0, count: 1, primary: primary,
            secondary: GuideAction("Not Now") { model.confirmation = nil }
        ) {
            GuidePage(verbatim: model.choiceTitle(choice), message: model.choiceMessage) {
                IPAAnimationView(.find)
            } content: {
                GuideValueList(
                    model.choiceRows(choice).map { GuideValue($0.label, value: $0.value) })
            }
        }
    }

    private var primary: GuideAction {
        if let version = model.displayVersion(of: choice) {
            GuideAction("Download v\(version)") { model.download(choice) }
        } else {
            GuideAction("Download This Version") { model.download(choice) }
        }
    }
}
