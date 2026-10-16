import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class StorePreferences {
    public static let limits = [25, 50, 100, 200]
    public static let defaultLimit = 50

    public var storefront: Storefront? {
        didSet { defaults.set(storefront?.code, forKey: Key.storefront) }
    }

    public var resultsLimit: Int {
        didSet { defaults.set(resultsLimit, forKey: Key.limit) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        storefront = defaults.string(forKey: Key.storefront).flatMap { Storefront(code: $0) }
        let limit = defaults.integer(forKey: Key.limit)
        resultsLimit = Self.limits.contains(limit) ? limit : Self.defaultLimit
    }

    public func storefront(for account: Account?, locale: Locale = .current) -> Storefront {
        storefront ?? account?.storefront ?? .current(locale: locale)
    }

    public func reset() {
        storefront = nil
        resultsLimit = Self.defaultLimit
    }

    private enum Key {
        static let storefront = "ipa.search.storefront"
        static let limit = "ipa.search.limit"
    }
}
