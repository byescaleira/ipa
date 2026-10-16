import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class SearchModel {
    public enum Status: Hashable, Sendable {
        case idle, results, noResults
        case failed(IPAError)
    }

    public struct Key: Hashable, Sendable {
        public let text: String
        public let storefront: Storefront
        public let limit: Int
    }

    public var text = ""
    public private(set) var results: [StoreApp] = []
    public private(set) var status: Status = .idle
    public private(set) var isSearching = false
    public private(set) var searchedStorefront: Storefront?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let preferences: StorePreferences
    @ObservationIgnored private let accounts: AccountsModel
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var request = 0

    public init(
        session: SessionModel, preferences: StorePreferences, accounts: AccountsModel,
        debounce: Duration = .milliseconds(350)
    ) {
        self.session = session
        self.preferences = preferences
        self.accounts = accounts
        self.debounce = debounce
    }

    public var storefront: Storefront { preferences.storefront(for: accounts.active) }

    public var key: Key {
        Key(
            text: text.trimmingCharacters(in: .whitespacesAndNewlines), storefront: storefront,
            limit: preferences.resultsLimit)
    }

    public func receive(_ pending: String) {
        text = pending
    }

    public func search() async {
        request += 1
        let current = request
        let key = key
        guard let query = AppQuery(key.text) else {
            results = []
            searchedStorefront = nil
            status = .idle
            isSearching = false
            return
        }
        isSearching = true
        defer { if current == request { isSearching = false } }
        do {
            try await Task.sleep(for: debounce)
            let found = try await fetch(query, key: key)
            try Task.checkCancellation()
            guard current == request else { return }
            results = found
            searchedStorefront = key.storefront
            status = found.isEmpty ? .noResults : .results
        } catch is CancellationError {} catch {
            guard current == request, !Task.isCancelled else { return }
            results = []
            status = .failed(error as? IPAError ?? .network)
        }
    }

    private func fetch(_ query: AppQuery, key: Key) async throws -> [StoreApp] {
        let catalog = session.services.catalog
        switch query {
        case .term(let term):
            return try await catalog.search(term, in: key.storefront, limit: key.limit)
        case .bundleID(let bundleID):
            if let app = try await catalog.lookup(query, in: key.storefront) { return [app] }
            try Task.checkCancellation()
            return try await catalog.search(bundleID, in: key.storefront, limit: key.limit)
        case .appID:
            return try await catalog.lookup(query, in: key.storefront).map { [$0] } ?? []
        }
    }
}
