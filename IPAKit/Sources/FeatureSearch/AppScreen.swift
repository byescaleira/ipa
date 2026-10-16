import FeatureCore
import IPADesignSystem
import SwiftUI

public struct AppScreen: View {
    @Environment(AppModel.self) private var model

    public init() {}

    public var body: some View {
        @Bindable var model = model
        AdaptiveList {}
            .fontDesign(.rounded)
            .errorAlert($model.error)
    }
}
