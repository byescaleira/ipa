import FeatureCore
import IPADesignSystem
import IPADomain
import SwiftUI

public struct SearchScreen: View {
    @Environment(SearchModel.self) private var search
    @Environment(IPANavigation.self) private var navigation

    public init() {}

    public var body: some View {
        @Bindable var search = search
        AdaptiveList {
            SearchResultsSection()
        }
        .overlay { SearchStateView() }
        .fontDesign(.rounded)
        .toolbar { ToolbarItem(placement: .leading) { AccountMenu() } }
        .toolbar { ToolbarItem(placement: .primaryAction) { StorefrontButton() } }
        .searchable(text: $search.text, prompt: Text("Name, bundle ID, link or app ID"))
        .autocorrectionDisabled()
        .task(id: search.key) { await search.search() }
        .onChange(of: navigation.pendingSearch, initial: true) { _, pending in
            guard let pending else { return }
            navigation.pendingSearch = nil
            search.receive(pending)
        }
        .navigationTitle("Search")
    }
}

private struct StorefrontButton: View {
    @Environment(SearchModel.self) private var search
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        Button {
            open(.storefronts, in: section)
        } label: {
            Text(verbatim: search.storefrontTitle).lineLimit(1)
        }
        .tint(Color.primary)
        .accessibilityLabel("Store")
        .accessibilityValue(Text(verbatim: search.storefrontName))
    }
}

private struct SearchResultsSection: View {
    @Environment(SearchModel.self) private var search
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if !search.rows.isEmpty {
            Section {
                ForEach(search.rows) { app in
                    Button {
                        open(.app(id: app.id), in: section)
                    } label: {
                        SearchResultRow(app: app)
                    }
                    .tint(Color.primary)
                }
            } footer: {
                if !search.isShowingPlaceholders { Text(verbatim: search.footer) }
            }
            .redacted(reason: search.isShowingPlaceholders ? .placeholder : [])
            .disabled(search.isShowingPlaceholders)
        }
    }
}

private struct SearchResultRow: View {
    let app: StoreApp

    var body: some View {
        HStack(spacing: .spaceM) {
            AppArtwork(app.artworkURL)
            VStack(alignment: .leading, spacing: .spaceHairline) {
                Text(verbatim: app.name).font(.rowTitle).lineLimit(2)
                Text(verbatim: app.detailLine)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if !app.isFree {
                Chip(app.priceText, color: .warning).fixedSize()
            }
        }
        .padding(.vertical, .space2XS)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

private struct SearchStateView: View {
    @Environment(SearchModel.self) private var search
    @Environment(\.open) private var open
    @Environment(\.navigationSection) private var section

    var body: some View {
        if search.isIdle {
            EmptyStateView(
                title: "Find Any App",
                description:
                    "Type a name, a bundle ID such as com.google.ios.youtube, an App Store link or an app ID.",
                actionTitle: "Search for YouTube", action: search.useExample
            ) {
                ForEach(SearchModel.examples) { app in
                    ExampleRow(
                        app.name, detail: app.detailLine, value: search.examplePrice(app),
                        valueColor: .warning, symbol: "app", color: .secondary)
                }
            }
        } else if search.isShowingNoResults {
            ContentUnavailableView {
                Label("No Results", systemImage: "magnifyingglass")
            } description: {
                Text(verbatim: search.noResultsMessage)
            } actions: {
                Button("Change Store") { open(.storefronts, in: section) }
                    .font(.buttonLabel)
                    .buttonStyle(.borderless)
            }
        } else if search.failure != nil {
            ContentUnavailableView {
                Label("Couldn't Search", systemImage: "wifi.exclamationmark")
            } description: {
                Text(verbatim: search.failureMessage)
            } actions: {
                Button("Try Again") { Task { await search.search() } }
                    .primaryButton()
            }
        }
    }
}
