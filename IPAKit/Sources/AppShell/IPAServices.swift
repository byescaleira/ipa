import Foundation
import IPAData
import IPADomain
import IPAEngine
import IPAMock
import Observation

@MainActor @Observable
public final class IPAServices {
    public static let shared = IPAServices()
    public var pendingURL: URL?
    public let store: StoreServices
    @ObservationIgnored private var opening: Task<IPADatabase, any Error>?

    private init() {
        let vault = KeychainAccountVault()
        store = StoreServices(
            catalog: ITunesCatalog(), engine: Self.engine(vault: vault), vault: vault,
            folder: .documents)
    }

    private static func engine(vault: any AccountVault) -> any StoreEngine {
        let local: any StoreEngine
        #if os(iOS)
            local = isSimulator ? SimulatedStoreEngine(vault: vault) : IPAToolEngine(vault: vault)
        #else
            local = UnavailableStoreEngine()
        #endif
        return RoutingStoreEngine(configStore: ServerConfigStore(), vault: vault, local: local)
    }

    private static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            true
        #else
            false
        #endif
    }

    public func database() async throws -> IPADatabase {
        if let opening {
            do { return try await opening.value } catch { self.opening = nil }
        }
        let task = Task.detached(priority: .userInitiated) {
            try IPADatabase.open()
        }
        opening = task
        do {
            return try await task.value
        } catch {
            opening = nil
            throw error
        }
    }
}
