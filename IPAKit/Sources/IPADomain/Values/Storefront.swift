import Foundation

public struct Storefront: Hashable, Sendable, Identifiable, Codable {
    public let code: String
    public let id: String

    public init(code: String, id: String) {
        self.code = code.uppercased()
        self.id = id
    }

    public init?(code: String) {
        guard let match = Self.all.first(where: { $0.code == code.uppercased() }) else {
            return nil
        }
        self = match
    }

    public init?(header: String) {
        let id = header.split(separator: "-").first.map(String.init) ?? header
        guard let match = Self.all.first(where: { $0.id == id }) else { return nil }
        self = match
    }

    public static func current(locale: Locale = .current) -> Storefront {
        locale.region.flatMap { Storefront(code: $0.identifier) } ?? .unitedStates
    }

    public static let unitedStates = Storefront(code: "US", id: "143441")

    public var flag: String {
        String(
            String.UnicodeScalarView(
                code.unicodeScalars.compactMap { Unicode.Scalar(127_397 + $0.value) }))
    }

    public func name(locale: Locale) -> String {
        locale.localizedString(forRegionCode: code) ?? code
    }
}
