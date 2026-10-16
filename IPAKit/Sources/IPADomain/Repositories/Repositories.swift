public struct Repositories: Sendable {
    public let downloads: any DownloadRepository

    public init(downloads: any DownloadRepository) {
        self.downloads = downloads
    }
}
