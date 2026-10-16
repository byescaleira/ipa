import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class AccountsModel {
    public private(set) var accounts: [Account] = []
    public private(set) var activeEmail: String?
    public private(set) var hasLoaded = false
    public var error: IPAError?
    @ObservationIgnored private let vault: any AccountVault
    @ObservationIgnored private let defaults: UserDefaults

    public init(vault: any AccountVault, defaults: UserDefaults = .standard) {
        self.vault = vault
        self.defaults = defaults
        activeEmail = defaults.string(forKey: Key.active)
    }

    public var active: Account? {
        accounts.first { $0.email == activeEmail } ?? accounts.first
    }

    public var others: [Account] {
        accounts.filter { $0.email != active?.email }
    }

    public var isEmpty: Bool { hasLoaded && accounts.isEmpty }

    public var selection: String? {
        get { active?.email }
        set {
            guard let account = accounts.first(where: { $0.email == newValue }) else { return }
            select(account)
        }
    }

    public func load() {
        do {
            accounts = try vault.accounts()
            hasLoaded = true
        } catch {
            self.error = error as? IPAError ?? .onFetch
        }
    }

    public func select(_ account: Account) {
        activeEmail = account.email
        defaults.set(account.email, forKey: Key.active)
    }

    public func didSignIn(_ account: Account) {
        load()
        select(account)
    }

    public func remove(_ account: Account) {
        do {
            try vault.remove(email: account.email)
            if activeEmail == account.email {
                activeEmail = nil
                defaults.removeObject(forKey: Key.active)
            }
            load()
        } catch {
            self.error = error as? IPAError ?? .onRemove
        }
    }

    public func reset() {
        activeEmail = nil
        defaults.removeObject(forKey: Key.active)
        load()
    }

    private enum Key {
        static let active = "ipa.accounts.active"
    }
}
