public protocol DownloadRepository: Sendable {
    func records() async throws -> [DownloadRecord]
    func save(_ record: DownloadRecord) async throws
    func delete(id: String) async throws
    func deleteAll() async throws
}
