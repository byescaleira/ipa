import Foundation

public struct SignInRequest: Hashable, Sendable {
    public let email: String
    public let password: String
    public let code: String?

    public init(email: String, password: String, code: String? = nil) {
        self.email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        self.password = password
        let digits = code?.filter(\.isNumber) ?? ""
        self.code = digits.isEmpty ? nil : digits
    }
}

public struct DownloadRequest: Hashable, Sendable {
    public let app: StoreApp
    public let account: Account
    public let externalVersionID: String?
    public let destination: URL

    public init(app: StoreApp, account: Account, externalVersionID: String?, destination: URL) {
        self.app = app
        self.account = account
        self.externalVersionID = externalVersionID
        self.destination = destination
    }
}

public struct DownloadedPackage: Hashable, Sendable {
    public let fileURL: URL
    public let version: String
    public let sizeBytes: Int64

    public init(fileURL: URL, version: String, sizeBytes: Int64) {
        self.fileURL = fileURL
        self.version = version
        self.sizeBytes = sizeBytes
    }
}

public protocol StoreEngine: Sendable {
    func availability() async -> EngineAvailability
    func signIn(_ request: SignInRequest) async throws -> Account
    func versions(of app: StoreApp, for account: Account) async throws -> [String]
    func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    func purchase(_ app: StoreApp, for account: Account) async throws
    func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage
}
