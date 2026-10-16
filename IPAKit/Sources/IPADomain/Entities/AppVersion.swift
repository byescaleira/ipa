import Foundation

public struct AppVersion: Hashable, Sendable, Identifiable, Codable {
    public let externalID: String
    public let displayVersion: String
    public let releaseDate: Date?

    public init(externalID: String, displayVersion: String, releaseDate: Date? = nil) {
        self.externalID = externalID
        self.displayVersion = displayVersion
        self.releaseDate = releaseDate
    }

    public var id: String { externalID }
}
