import FeatureCore
import IPADesignSystem
import SwiftUI

public struct SearchScreen: View {
    @Environment(SearchModel.self) private var search

    public init() {}

    public var body: some View {
        @Bindable var search = search
        AdaptiveList {}
            .fontDesign(.rounded)
            .toolbar { ToolbarItem(placement: .leading) { AccountMenu() } }
            .searchable(text: $search.text)
            .errorAlert($search.error)
            .navigationTitle("Search")
    }
}
