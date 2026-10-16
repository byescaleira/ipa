import SwiftUI

extension View {
    @ViewBuilder func routeInspector<Content: View>(
        isPresented: Binding<Bool>, @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
            inspector(isPresented: isPresented, content: content)
        #elseif os(visionOS)
            sheet(isPresented: isPresented, content: content)
        #else
            modifier(RouteSheet(isPresented: isPresented, sheet: content))
        #endif
    }
}

#if os(iOS)
    private struct RouteSheet<Sheet: View>: ViewModifier {
        @Binding var isPresented: Bool
        let sheet: () -> Sheet
        @State private var isLandscape = false

        func body(content: Content) -> some View {
            content
                .onGeometryChange(for: Bool.self) {
                    $0.size.width > $0.size.height
                } action: {
                    isLandscape = $0
                }
                .sheet(isPresented: $isPresented) {
                    SideSheet(isLandscape: isLandscape, content: sheet)
                }
        }
    }

    private struct SideSheet<Content: View>: View {
        @State private var detent = PresentationDetent.large
        let isLandscape: Bool
        let content: () -> Content

        var body: some View {
            content()
                .presentationPlacement(isLandscape ? .trailing : .center)
                .presentationSizing(.form)
                .presentationDetents([.height(72), .medium, .large], selection: $detent)
                .presentationBackgroundInteraction(.enabled)
                .presentationContentInteraction(.resizes)
        }
    }
#endif
