import FeatureCore
import Foundation
import IPADomain

extension SearchModel {
    public static let examples: [StoreApp] = [
        StoreApp(
            id: 544_007_664, bundleID: "com.google.ios.youtube", name: "YouTube",
            seller: "Google LLC", version: "20.22.1", minimumOSVersion: "16.0",
            sizeBytes: 346_465_894),
        StoreApp(
            id: 425_073_498, bundleID: "com.savage.procreate", name: "Procreate",
            seller: "Savage Interactive", version: "5.3.2", minimumOSVersion: "17.0",
            sizeBytes: 536_870_912, price: 12.99, formattedPrice: "$12.99"),
    ]

    public static let exampleQuery = "YouTube"

    public var rows: [StoreApp] {
        if !results.isEmpty { return results }
        return isSearching ? Self.examples : []
    }

    public var isShowingPlaceholders: Bool { results.isEmpty && isSearching }

    public var isIdle: Bool { status == .idle && !isSearching }

    public var isShowingNoResults: Bool { status == .noResults && !isSearching }

    public var failure: IPAError? {
        guard case .failed(let error) = status, !isSearching else { return nil }
        return error
    }

    public var footer: String {
        let store = (searchedStorefront ?? storefront).title
        return [
            String(appLocalized: "\(results.count) results found."),
            String(appLocalized: "Prices and availability are from \(store)."),
        ].joined(separator: " ")
    }

    public var noResultsMessage: String {
        String(
            appLocalized:
                "Nothing matches “\(key.text)” in \(storefront.title). Check the spelling or try another store."
        )
    }

    public var failureMessage: String {
        failure?.localizedDescription ?? ""
    }

    public var storefrontTitle: String { storefront.title }

    public var storefrontName: String { storefront.name }

    public func examplePrice(_ app: StoreApp) -> String {
        app.isFree ? "" : app.priceText
    }

    public func useExample() {
        text = Self.exampleQuery
    }
}
