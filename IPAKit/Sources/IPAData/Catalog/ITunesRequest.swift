import Foundation
import IPADomain

enum ITunesRequest {
    static let maximumLimit = 200

    static func search(_ term: String, in storefront: Storefront, limit: Int) -> URL {
        url(
            path: "/search",
            items: [
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "entity", value: "software"),
                URLQueryItem(name: "media", value: "software"),
                URLQueryItem(name: "limit", value: String(min(max(limit, 1), maximumLimit))),
                URLQueryItem(name: "country", value: storefront.code.lowercased()),
            ])
    }

    static func lookup(_ query: AppQuery, in storefront: Storefront) -> URL? {
        let item: URLQueryItem
        switch query {
        case .term: return nil
        case .bundleID(let bundleID): item = URLQueryItem(name: "bundleId", value: bundleID)
        case .appID(let id): item = URLQueryItem(name: "id", value: String(id))
        }
        return url(
            path: "/lookup",
            items: [
                item,
                URLQueryItem(name: "entity", value: "software"),
                URLQueryItem(name: "country", value: storefront.code.lowercased()),
            ])
    }

    private static func url(path: String, items: [URLQueryItem]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "itunes.apple.com"
        components.path = path
        components.queryItems = items
        return components.url ?? URL(filePath: "/")
    }
}
