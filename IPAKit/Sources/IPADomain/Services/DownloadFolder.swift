import Foundation

public struct DownloadFolder: Hashable, Sendable {
    public let root: URL

    public init(root: URL) {
        self.root = root
    }

    public static var documents: DownloadFolder {
        DownloadFolder(
            root: URL.documentsDirectory.appending(path: "Downloads", directoryHint: .isDirectory))
    }

    public func folder(for email: String) -> URL {
        root.appending(path: PackageName.folder(email: email), directoryHint: .isDirectory)
    }

    public func fileURL(for record: DownloadRecord) -> URL {
        folder(for: record.accountEmail).appending(path: record.fileName)
    }

    public func prepareFolder(for email: String) throws -> URL {
        let url = folder(for: email)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    public func remove(_ record: DownloadRecord) throws {
        let url = fileURL(for: record)
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return
        }
        try FileManager.default.removeItem(at: url)
    }

    public func removeAll() throws {
        guard FileManager.default.fileExists(atPath: root.path(percentEncoded: false)) else {
            return
        }
        try FileManager.default.removeItem(at: root)
    }
}
