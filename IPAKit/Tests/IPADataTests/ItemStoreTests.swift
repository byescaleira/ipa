import Foundation
import IPAData
import IPADomain
import Testing

struct ItemStoreTests {
    private func repository() throws -> any ItemRepository {
        try IPADatabase.open(inMemory: true).repositories.items
    }

    @Test func savesAndListsNewestFirst() async throws {
        let items = try repository()
        try await items.save(Item(id: "old", title: "Old", createdAt: .distantPast))
        try await items.save(Item(id: "new", title: " New ", createdAt: .now))
        let saved = try await items.items()
        #expect(saved.map(\.id) == ["new", "old"])
        #expect(saved.first?.title == "New")
    }

    @Test func updatesInPlace() async throws {
        let items = try repository()
        try await items.save(Item(id: "a", title: "First"))
        try await items.save(Item(id: "a", title: "Second"))
        #expect(try await items.items().count == 1)
        #expect(try await items.item(id: "a")?.title == "Second")
    }

    @Test func rejectsBlankTitles() async throws {
        let items = try repository()
        await #expect(throws: IPAError.onSave) { try await items.save(Item(title: " ")) }
    }

    @Test func deletesAndReportsMissingRecords() async throws {
        let items = try repository()
        try await items.save(Item(id: "a", title: "First"))
        try await items.delete(id: "a")
        #expect(try await items.item(id: "a") == nil)
        await #expect(throws: IPAError.missingRecord) { try await items.delete(id: "a") }
    }
}
