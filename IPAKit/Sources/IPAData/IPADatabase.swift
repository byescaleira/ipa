import Foundation
import IPADomain
import SwiftData

public struct IPADatabase: RepositoryProvider {
    public let modelContainer: ModelContainer
    let store: IPAStore

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        store = IPAStore(modelContainer: modelContainer)
    }

    public static func open(inMemory: Bool = false, storeURL: URL? = nil) throws -> IPADatabase {
        let schema = Schema(versionedSchema: IPASchemaV1.self)
        let configuration =
            if let storeURL {
                ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none)
            } else {
                ModelConfiguration(
                    schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: .none)
            }
        return IPADatabase(
            modelContainer: try ModelContainer(
                for: schema, migrationPlan: IPAMigrationPlan.self,
                configurations: configuration))
    }

    public var storeURL: URL? { modelContainer.configurations.first?.url }

    public var repositories: Repositories {
        Repositories(downloads: SwiftDataDownloadRepository(store: store))
    }
}
