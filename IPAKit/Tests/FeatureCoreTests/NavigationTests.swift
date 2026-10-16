import Testing

@testable import FeatureCore

@MainActor
struct NavigationTests {
    @Test func pushesInCompactWidth() {
        let navigation = IPANavigation()
        navigation.open(.storefronts, in: .search, beside: false)
        #expect(navigation.paths[.search] == [.storefronts])
        navigation.close(in: .search, inspecting: false)
        #expect(navigation.paths[.search]?.isEmpty == true)
    }

    @Test func opensBesideInRegularWidthAndStacksInside() {
        let navigation = IPANavigation()
        navigation.open(.app(id: 1), in: .search, beside: true)
        #expect(navigation.inspector?.route == .app(id: 1))
        navigation.open(.app(id: 2), in: .search, beside: true)
        #expect(navigation.inspectorPath == [.app(id: 2)])
        navigation.close(in: .search, inspecting: true)
        navigation.close(in: .search, inspecting: true)
        #expect(navigation.inspector == nil)
    }

    @Test func switchingTabsClosesTheInspectorOfAnotherTab() {
        let navigation = IPANavigation()
        navigation.open(.app(id: 1), in: .search, beside: true)
        navigation.selectedSection = .settings
        navigation.closeInspectorOutsideSelection()
        #expect(navigation.inspector == nil)
    }
}
