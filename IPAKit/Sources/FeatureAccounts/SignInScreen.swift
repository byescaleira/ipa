import FeatureCore
import IPADesignSystem
import SwiftUI

public struct SignInScreen: View {
    @Environment(SignInModel.self) private var model

    public init() {}

    public var body: some View {
        @Bindable var model = model
        Form {}
            .fontDesign(.rounded)
            .readableWidth()
            .errorAlert($model.error)
    }
}
