import Foundation

public struct StoreServices: Sendable {
    public let catalog: any StoreCatalog
    public let engine: any StoreEngine
    public let vault: any AccountVault
    public let folder: DownloadFolder
    public let serverConfig: any ServerConfigStoring

    public init(
        catalog: any StoreCatalog, engine: any StoreEngine, vault: any AccountVault,
        folder: DownloadFolder, serverConfig: any ServerConfigStoring = DisabledServerConfig()
    ) {
        self.catalog = catalog
        self.engine = engine
        self.vault = vault
        self.folder = folder
        self.serverConfig = serverConfig
    }
}
