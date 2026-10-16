import FeatureCore
import FeatureGuides
import IPADesignSystem
import IPADomain
import SwiftUI

public struct MainScreen: View {
    @Environment(SessionModel.self) private var session
    @Environment(IPANavigation.self) private var navigation
    @Environment(LaunchProgress.self) private var launch
    @Environment(\.featureFlags) private var flags
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.locale) private var locale
    public init() {}

    @ViewBuilder
    public var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedSection) {
            ForEach(AppSection.allCases) { section in
                Tab(
                    section.title, systemImage: section.systemImage, value: section,
                    role: section.role
                ) {
                    SectionStack(section: section)
                }
            }
        }
        .id(locale.identifier)
        .tabViewStyle(.sidebarAdaptable)
        .overlay {
            if !launch.isDismissed {
                SplashScreen(progress: launch.fraction, status: launch.status)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.4), value: launch.isDismissed)
        .sheet(item: $navigation.guide) { GuideScreen($0) }
        .environment(\.showGuide, ShowGuideAction { navigation.guide = $0 })
        .routeInspector(isPresented: navigation.isInspecting) {
            if let inspector = navigation.inspector {
                InspectorScreen(inspector: inspector)
            }
        }
        .environment(
            \.open,
            IPADestination { route, section in
                navigation.open(route, in: section, beside: horizontalSizeClass == .regular)
            }
        )
        .onChange(of: session.generation, initial: true) { launch.finish(.content) }
        .task(id: launch.isComplete) {
            try? await Task.sleep(for: launch.isComplete ? .milliseconds(600) : .seconds(8))
            launch.dismiss()
        }
        .onChange(of: navigation.selectedSection) { navigation.closeInspectorOutsideSelection() }
        .modifier(DeepLinks())
    }
}
