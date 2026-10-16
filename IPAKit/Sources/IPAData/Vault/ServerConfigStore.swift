import Foundation
import IPADomain
import Security

public struct ServerConfigStore: ServerConfigStoring {
    private let service: String

    public init(service: String = "com.byescaleira.ipa") {
        self.service = service
    }

    public func load() -> ServerConfig? {
        guard let data = read(key: Self.key) else { return nil }
        return try? JSONDecoder().decode(ServerConfig.self, from: data)
    }

    public func save(_ config: ServerConfig) throws {
        let data = try JSONEncoder().encode(config)
        try write(data, key: Self.key)
    }

    public func clear() throws {
        try delete(key: Self.key)
    }

    private static let key = "server.config"

    private func read(key: String) -> Data? {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        query[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
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
            guard SecItemAdd(query as CFDictionary, nil) == errSecSuccess else { throw IPAError.onSave }
        } else if status != errSecSuccess {
            throw IPAError.onSave
        }
    }

    private func delete(key: String) throws {
        var query = baseQuery()
        query[kSecAttrAccount as String] = key
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw IPAError.onRemove }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }
}
