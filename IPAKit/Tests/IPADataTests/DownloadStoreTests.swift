import Foundation
import IPAData
import IPADomain
import Testing

struct DownloadStoreTests {
    private func repository() throws -> any DownloadRepository {
        try IPADatabase.open(inMemory: true).repositories.downloads
    }

    private func record(_ id: String, at date: Date) -> DownloadRecord {
        DownloadRecord(
            id: id, accountEmail: "a@b.com", appID: 1, bundleID: "com.a", name: "A",
            version: "1.0", fileName: "\(id).ipa", sizeBytes: 10, downloadedAt: date)
    }

    @Test func savesAndListsNewestFirst() async throws {
        let downloads = try repository()
        try await downloads.save(record("old", at: .distantPast))
        try await downloads.save(record("new", at: .now))
        #expect(try await downloads.records().map(\.id) == ["new", "old"])
    }

    @Test func deletesOneOrAll() async throws {
        let downloads = try repository()
        try await downloads.save(record("a", at: .now))
        try await downloads.save(record("b", at: .now))
        try await downloads.delete(id: "a")
        #expect(try await downloads.records().map(\.id) == ["b"])
        await #expect(throws: IPAError.missingRecord) { try await downloads.delete(id: "a") }
        try await downloads.deleteAll()
        #expect(try await downloads.records().isEmpty)
    }
}
