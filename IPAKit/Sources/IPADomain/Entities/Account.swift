import Foundation

public struct Account: Hashable, Sendable, Identifiable, Codable {
    public let email: String
    public let name: String
    public let storefront: Storefront
    public let directoryServicesID: String

    public init(email: String, name: String, storefront: Storefront, directoryServicesID: String) {
        self.email = email
        self.name = name
        self.storefront = storefront
        self.directoryServicesID = directoryServicesID
    }

    public var id: String { email }

    public var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let local = email.split(separator: "@").first.map(String.init) ?? email
        let source = trimmed.isEmpty ? local.replacing(/[._\-+]/, with: " ") : trimmed
        let words = source.split(whereSeparator: \.isWhitespace)
        let picked = words.count > 1 ? [words[0], words[words.count - 1]] : words
        return picked.compactMap { word in word.first(where: \.isLetter) ?? word.first }
            .map { String($0).uppercased() }
            .joined()
    }

    public var displayName: String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? email : trimmed
    }
}
