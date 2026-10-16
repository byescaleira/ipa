import SwiftUI

#if canImport(UIKit)
    import UIKit
#endif

public struct ShareButton<Label: View>: View {
    private let items: [Any]
    private let label: Label

    public init(_ items: [Any], @ViewBuilder label: () -> Label) {
        self.items = items
        self.label = label()
    }

    public var body: some View {
        #if os(iOS) || os(visionOS)
            Button {
                ActivitySheet.present(items)
            } label: {
                label
            }
        #elseif os(macOS)
            macShareLink
        #else
            label
        #endif
    }

    #if os(macOS)
        @ViewBuilder private var macShareLink: some View {
            if let url = items.compactMap({ $0 as? URL }).first {
                ShareLink(item: url) { label }
            } else if let text = items.compactMap({ $0 as? String }).first {
                ShareLink(item: text) { label }
            } else {
                label
            }
        }
    #endif
}

#if os(iOS) || os(visionOS)
    @MainActor
    private enum ActivitySheet {
        static func present(_ items: [Any]) {
            guard let top = topController() else { return }
            let controller = UIActivityViewController(
                activityItems: items, applicationActivities: nil)
            if let popover = controller.popoverPresentationController {
                popover.sourceView = top.view
                popover.sourceRect = CGRect(
                    x: top.view.bounds.midX, y: top.view.bounds.maxY - 1, width: 1, height: 1)
                popover.permittedArrowDirections = []
            }
            top.present(controller, animated: true)
        }

        private static func topController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene =
                scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
            guard let root = window?.rootViewController else { return nil }
            return leaf(of: root)
        }

        private static func leaf(of controller: UIViewController) -> UIViewController {
            if let presented = controller.presentedViewController {
                return leaf(of: presented)
            }
            if let tab = controller as? UITabBarController, let selected = tab.selectedViewController
            {
                return leaf(of: selected)
            }
            if let navigation = controller as? UINavigationController,
                let top = navigation.visibleViewController
            {
                return leaf(of: top)
            }
            return controller
        }
    }
#endif
