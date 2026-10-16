import Foundation

public enum Route: Hashable, Sendable {
    case app(id: Int64)
    case storefronts
    case signIn
}
