import FeatureCore
import SwiftUI

struct InspectorScreen: View {
    @Environment(IPANavigation.self) private var navigation
    let inspector: IPANavigation.Inspector

    var body: some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.inspectorPath) {
            RouteScreen(route: inspector.route)
                .navigationDestination(for: Route.self) { RouteScreen(route: $0) }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Close", systemImage: "xmark") { navigation.closeInspector() }
                    }
                }
        }
        .environment(\.navigationSection, inspector.section)
        .environment(
            \.close,
            CloseAction { navigation.close(in: inspector.section, inspecting: true) }
        )
        #if os(macOS)
            .inspectorColumnWidth(min: 320, ideal: 400, max: 480)
        #endif
    }
}
