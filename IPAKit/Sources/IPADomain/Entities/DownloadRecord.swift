import Foundation

public struct DownloadRecord: Hashable, Sendable, Identifiable, Codable {
    public let id: String
    public let accountEmail: String
    public let appID: Int64
    public let bundleID: String
    public let name: String
    public let version: String
    public let externalVersionID: String?
    public let fileName: String
    public let sizeBytes: Int64
    public let artworkURL: URL?
    public let downloadedAt: Date

    public init(
        id: String = UUID().uuidString, accountEmail: String, appID: Int64, bundleID: String,
        name: String, version: String, externalVersionID: String? = nil, fileName: String,
        sizeBytes: Int64, artworkURL: URL? = nil, downloadedAt: Date = .now
    ) {
        self.id = id
        self.accountEmail = accountEmail
        self.appID = appID
        self.bundleID = bundleID
        self.name = name
        self.version = version
        self.externalVersionID = externalVersionID
        self.fileName = fileName
        self.sizeBytes = sizeBytes
        self.artworkURL = artworkURL
        self.downloadedAt = downloadedAt
    }

    public func matches(_ text: String) -> Bool {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        return name.localizedStandardContains(query) || bundleID.localizedStandardContains(query)
    }
}
