import Foundation
import IPADomain
import Security

public struct KeychainAccountVault: AccountVault {
    private let service: String

    public init(service: String = "com.byescaleira.ipa") {
        self.service = service
    }

    public func accounts() throws -> [Account] {
        try entries().map(\.account).sorted { $0.email < $1.email }
    }

    public func credential(for email: String) throws -> Data? {
        try entries().first { $0.account.email == email }?.credential
    }

    public func save(_ account: Account, credential: Data) throws {
        let data = try JSONEncoder().encode(VaultEntry(account: account, credential: credential))
        try write(data, key: Self.accountKey(account.email))
    }

    public func remove(email: String) throws {
        try delete(key: Self.accountKey(email))
    }

    public func removeAll() throws {
        for entry in try entries() { try remove(email: entry.account.email) }
        try delete(key: Self.identityKey)
    }

    public func identity() throws -> DeviceIdentity {
        if let data = try read(key: Self.identityKey),
            let identity = DeviceIdentity(bytes: Array(data))
        {
            return identity
        }
        return try regenerateIdentity()
    }

    public func regenerateIdentity() throws -> DeviceIdentity {
        let identity = DeviceIdentity.random()
        try write(Data(identity.bytes), key: Self.identityKey)
        return identity
    }

    private static let identityKey = "identity"

    private static func accountKey(_ email: String) -> String { "account." + email.lowercased() }

    private func entries() throws -> [VaultEntry] {
        var query = baseQuery()
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess, let items = result as? [[String: Any]] else {
            throw IPAError.onFetch
        }
        return items.compactMap { item in
            guard let key = item[kSecAttrAccount as String] as? String,
                key.hasPrefix("account."), let data = item[kSecValueData as String] as? Data
            else { return nil }
            return try? JSONDecoder().decode(VaultEntry.self, from: data)
        }
    }

    private func read(key: String) throws -> Data? {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw IPAError.onFetch }
        return result as? Data
    }

    private func write(_ data: Data, key: String) throws {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        let update = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else {
                throw IPAError.onSave
            }
        } else if status != errSecSuccess {
            throw IPAError.onSave
        }
    }

    private func delete(key: String) throws {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw IPAError.onRemove
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}

struct VaultEntry: Codable {
    let account: Account
    let credential: Data
}
