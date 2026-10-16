import Foundation
import IPAData
import IPADomain
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
            catalog: ITunesCatalog(), engine: SimulatedStoreEngine(vault: vault), vault: vault,
            folder: .documents)
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
