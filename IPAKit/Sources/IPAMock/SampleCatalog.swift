import Foundation
import IPADomain

public struct SampleCatalog: StoreCatalog {
    public init() {}

    public func search(_ term: String, in storefront: Storefront, limit: Int) async throws
        -> [StoreApp]
    {
        Array(SampleApps.search(term).prefix(limit))
    }

    public func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp? {
        switch query {
        case .appID(let id): SampleApps.all.first { $0.id == id }
        case .bundleID(let bundleID): SampleApps.all.first { $0.bundleID == bundleID }
        case .term(let term): SampleApps.search(term).first
        }
    }
}
