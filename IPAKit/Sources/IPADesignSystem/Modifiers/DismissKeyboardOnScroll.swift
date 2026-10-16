import SwiftUI

extension View {
    @ViewBuilder public func dismissKeyboardOnScroll() -> some View {
        #if os(visionOS)
            self
        #else
            scrollDismissesKeyboard(.immediately)
        #endif
    }
}
