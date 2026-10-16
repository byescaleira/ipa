import Foundation
import IPADomain

public struct UnavailableStoreEngine: StoreEngine {
    public init() {}

    public func availability() async -> EngineAvailability { .unsupported }

    public func signIn(_ request: SignInRequest) async throws -> Account {
        throw IPAError.engine(.unsupported)
    }

    public func versions(of app: StoreApp, for account: Account) async throws -> [String] {
        throw IPAError.engine(.unsupported)
    }

    public func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        throw IPAError.engine(.unsupported)
    }

    public func purchase(_ app: StoreApp, for account: Account) async throws {
        throw IPAError.engine(.unsupported)
    }

    public func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        throw IPAError.engine(.unsupported)
    }
}
