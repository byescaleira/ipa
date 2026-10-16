import Foundation
import IPADomain

public struct SimulatedStoreEngine: StoreEngine {
    public static let codeEmailMarker = "2fa"
    public static let wrongPassword = "wrong"
    private let vault: any AccountVault
    private let availabilityValue: EngineAvailability
    private let step: Duration

    public init(
        vault: any AccountVault, availability: EngineAvailability = .ready,
        step: Duration = .milliseconds(120)
    ) {
        self.vault = vault
        availabilityValue = availability
        self.step = step
    }

    public func availability() async -> EngineAvailability { availabilityValue }

    public func signIn(_ request: SignInRequest) async throws -> Account {
        try ensureReady()
        guard request.password != Self.wrongPassword, !request.password.isEmpty else {
            throw IPAError.signInFailed(
                String(appLocalized: "The Apple ID or password is incorrect."))
        }
        if request.email.contains(Self.codeEmailMarker) && request.code == nil {
            throw IPAError.codeRequired
        }
        let name = request.email.split(separator: "@").first.map(String.init) ?? request.email
        let account = Account(
            email: request.email, name: name.capitalized, storefront: .unitedStates,
            directoryServicesID: String(abs(request.email.hashValue % 1_000_000_000)))
        try vault.save(account, credential: Data(request.email.utf8))
        return account
    }

    public func versions(of app: StoreApp, for account: Account) async throws -> [String] {
        try ensureReady()
        return (0..<24).map { String(875_214_761 - $0 * 97_000) }
    }

    public func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        try ensureReady()
        let offset = ((Int(externalID) ?? 875_214_761) - 875_214_761) / -97_000
        let parts = app.version.split(separator: ".").compactMap { Int($0) }
        let major = parts.first ?? 1
        let minor = max((parts.dropFirst().first ?? 0) - offset, 0)
        let date = Calendar(identifier: .gregorian).date(
            byAdding: .day, value: -7 * offset, to: Date(timeIntervalSince1970: 1_790_000_000))
        return AppVersion(
            externalID: externalID, displayVersion: "\(major).\(minor).0", releaseDate: date)
    }

    public func purchase(_ app: StoreApp, for account: Account) async throws {
        try ensureReady()
        guard app.isFree else { throw IPAError.paidApp }
    }

    public func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        try ensureReady()
        guard request.app.isFree else { throw IPAError.paidApp }
        let total = request.app.sizeBytes ?? 50 * 1_048_576
        progress(DownloadProgress(phase: .preparing))
        try await Task.sleep(for: step)
        for slice in 1...10 {
            try await Task.sleep(for: step)
            progress(
                DownloadProgress(
                    phase: .downloading, completedBytes: total * Int64(slice) / 10,
                    totalBytes: total))
        }
        progress(DownloadProgress(phase: .signing))
        let version =
            if let id = request.externalVersionID {
                try await self.version(id, of: request.app, for: request.account).displayVersion
            } else {
                request.app.version
            }
        let file = request.destination.appending(
            path: PackageName.file(
                bundleID: request.app.bundleID, appID: request.app.id, version: version))
        try Data("IPA".utf8).write(to: file)
        return DownloadedPackage(fileURL: file, version: version, sizeBytes: total)
    }

    private func ensureReady() throws {
        guard availabilityValue == .ready else { throw IPAError.engine(availabilityValue) }
    }
}
