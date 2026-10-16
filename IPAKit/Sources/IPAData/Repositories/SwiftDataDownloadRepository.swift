import IPADomain

struct SwiftDataDownloadRepository: DownloadRepository {
    let store: IPAStore

    func records() async throws -> [DownloadRecord] { try await store.downloads() }

    func save(_ record: DownloadRecord) async throws { try await store.save(record) }

    func delete(id: String) async throws { try await store.removeDownload(id: id) }

    func deleteAll() async throws { try await store.removeAllDownloads() }
}
