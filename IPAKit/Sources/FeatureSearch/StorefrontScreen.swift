import FeatureCore
import IPADesignSystem
import SwiftUI

public struct StorefrontScreen: View {
    public init() {}

    public var body: some View {
        List {}
            .fontDesign(.rounded)
            .readableWidth()
            .navigationTitle("Storefront")
    }
}
