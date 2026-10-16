import Foundation
import SwiftData

public enum IPASchemaV1: VersionedSchema {
    public static var versionIdentifier: Schema.Version { .init(1, 0, 0) }
    public static var models: [any PersistentModel.Type] {
        [ItemEntity.self]
    }
}

public enum IPAMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [IPASchemaV1.self]
    }
    public static var stages: [MigrationStage] {
        []
    }
}
