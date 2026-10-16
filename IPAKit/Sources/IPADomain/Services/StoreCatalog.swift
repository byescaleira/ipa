import Foundation

public protocol StoreCatalog: Sendable {
    func search(_ term: String, in storefront: Storefront, limit: Int) async throws -> [StoreApp]
    func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp?
}
