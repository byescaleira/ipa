import Foundation
import IPADomain
import SwiftData

public struct IPADatabase: RepositoryProvider {
    public static let cloudContainer = "iCloud.ipa"
    public let modelContainer: ModelContainer
    let store: IPAStore

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        store = IPAStore(modelContainer: modelContainer)
    }

    public static func open(inMemory: Bool = false, cloudSync: Bool = true, storeURL: URL? = nil)
        throws -> IPADatabase
    {
        let schema = Schema(versionedSchema: IPASchemaV1.self)
        let database: ModelConfiguration.CloudKitDatabase =
            inMemory || !cloudSync ? .none : .private(cloudContainer)
        let configuration =
            if let storeURL {
                ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: database)
            } else {
                ModelConfiguration(
                    schema: schema, isStoredInMemoryOnly: inMemory, cloudKitDatabase: database)
            }
        return IPADatabase(
            modelContainer: try ModelContainer(
                for: schema, migrationPlan: IPAMigrationPlan.self,
                configurations: configuration))
    }

    public var storeURL: URL? { modelContainer.configurations.first?.url }

    public var repositories: Repositories {
        Repositories(items: SwiftDataItemRepository(store: store))
    }
}
