import Foundation
import IPADomain

public enum AppAction: Hashable, Sendable {
    case download, signIn, paid, progress
    case engine(EngineAvailability)
}

public struct VersionChoice: Identifiable, Hashable, Sendable {
    public let externalID: String

    public init(externalID: String) {
        self.externalID = externalID
    }

    public var id: String { externalID }
}

public struct AppIdentifier: Identifiable, Hashable, Sendable {
    public enum Kind: String, Hashable, Sendable {
        case bundleID, appID, link
    }

    public let kind: Kind
    public let value: String

    public init(kind: Kind, value: String) {
        self.kind = kind
        self.value = value
    }

    public var id: Kind { kind }
}
