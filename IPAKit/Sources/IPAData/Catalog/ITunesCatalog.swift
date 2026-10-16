import Foundation
import IPADomain

public struct ITunesCatalog: StoreCatalog {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func search(_ term: String, in storefront: Storefront, limit: Int) async throws
        -> [StoreApp]
    {
        try await fetch(ITunesRequest.search(term, in: storefront, limit: limit))
    }

    public func lookup(_ query: AppQuery, in storefront: Storefront) async throws -> StoreApp? {
        guard let request = ITunesRequest.lookup(query, in: storefront) else {
            return try await search(query.term, in: storefront, limit: 1).first
        }
        return try await fetch(request).first
    }

    private func fetch(_ url: URL) async throws -> [StoreApp] {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw IPAError.network
        }
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw IPAError.network }
        return try ITunesResponse.apps(from: data)
    }
}
