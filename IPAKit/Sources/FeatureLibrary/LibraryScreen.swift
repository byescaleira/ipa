import FeatureCore
import IPADesignSystem
import SwiftUI

public struct LibraryScreen: View {
    @Environment(LibraryModel.self) private var library
    @Environment(DownloadCenter.self) private var downloads
    @Environment(SessionModel.self) private var session

    public init() {}

    public var body: some View {
        @Bindable var library = library
        @Bindable var downloads = downloads
        AdaptiveList {}
            .fontDesign(.rounded)
            .toolbar { ToolbarItem(placement: .leading) { AccountMenu() } }
            .searchable(text: $library.text)
            .errorAlert($downloads.error)
            .task(id: session.generation) { await downloads.load() }
            .navigationTitle("Downloads")
    }
}
