import Foundation
import IPADomain
import SwiftData

@ModelActor
public actor IPAStore {
    public func downloads() throws -> [DownloadRecord] {
        try modelContext.fetch(
            FetchDescriptor<DownloadEntity>(
                sortBy: [SortDescriptor(\.downloadedAt, order: .reverse), SortDescriptor(\.id)])
        )
        .map(\.record)
    }

    public func save(_ record: DownloadRecord) throws {
        let id = record.id
        do {
            let descriptor = FetchDescriptor<DownloadEntity>(predicate: #Predicate { $0.id == id })
            if let entity = try modelContext.fetch(descriptor).first {
                entity.apply(record)
            } else {
                modelContext.insert(DownloadEntity(record))
            }
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw IPAError.onSave
        }
    }

    public func removeDownload(id: String) throws {
        do {
            let descriptor = FetchDescriptor<DownloadEntity>(predicate: #Predicate { $0.id == id })
            guard let entity = try modelContext.fetch(descriptor).first else {
                throw IPAError.missingRecord
            }
            modelContext.delete(entity)
            try modelContext.save()
        } catch let error as IPAError {
            modelContext.rollback()
            throw error
        } catch {
            modelContext.rollback()
            throw IPAError.onRemove
        }
    }

    public func removeAllDownloads() throws {
        do {
            try modelContext.delete(model: DownloadEntity.self)
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw IPAError.onRemove
        }
    }
}
