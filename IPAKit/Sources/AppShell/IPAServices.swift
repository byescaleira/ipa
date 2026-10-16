import Foundation
import IPAData
import Observation

@MainActor @Observable
public final class IPAServices {
    public static let shared = IPAServices()
    public var pendingURL: URL?
    @ObservationIgnored private var opening: Task<IPADatabase, any Error>?

    private init() {}

    public func database(cloudSync: Bool) async throws -> IPADatabase {
        if let opening {
            do { return try await opening.value } catch { self.opening = nil }
        }
        let task = Task.detached(priority: .userInitiated) {
            try IPADatabase.open(cloudSync: cloudSync)
        }
        opening = task
        do {
            return try await task.value
        } catch {
            opening = nil
            throw error
        }
    }

    public static var launchCloudSync: Bool {
        #if targetEnvironment(simulator)
            false
        #else
            true
        #endif
    }
}
