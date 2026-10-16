import Foundation

public enum AppQuery: Hashable, Sendable {
    case term(String)
    case bundleID(String)
    case appID(Int64)

    public init?(_ input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if let id = Int64(text), id > 0 {
            self = .appID(id)
        } else if let id = Self.linkedID(in: text) {
            self = .appID(id)
        } else if Self.isBundleID(text) {
            self = .bundleID(text)
        } else {
            self = .term(text)
        }
    }

    public var term: String {
        switch self {
        case .term(let text), .bundleID(let text): text
        case .appID(let id): String(id)
        }
    }

    private static func linkedID(in text: String) -> Int64? {
        guard let url = URL(string: text), let host = url.host(),
            host.hasSuffix("apple.com")
        else { return nil }
        for component in url.pathComponents.reversed() where component.hasPrefix("id") {
            if let id = Int64(component.dropFirst(2)), id > 0 { return id }
        }
        return nil
    }

    private static func isBundleID(_ text: String) -> Bool {
        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count >= 2, !text.contains(" ") else { return false }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return parts.allSatisfy { part in
            !part.isEmpty && part.unicodeScalars.allSatisfy(allowed.contains)
        }
    }
}
