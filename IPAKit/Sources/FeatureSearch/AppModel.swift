import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class AppModel {
    public enum VersionsStatus: Hashable, Sendable {
        case idle, loading, loaded
        case failed(IPAError)
    }

    public struct LoadKey: Hashable, Sendable {
        public let storefront: Storefront
        public let account: String?
    }

    public let id: Int64
    public private(set) var app: StoreApp?
    public private(set) var isLoading = false
    public private(set) var loadFailure: IPAError?
    public var error: IPAError?
    public private(set) var versionIDs: [String] = []
    public internal(set) var versions: [String: AppVersion] = [:]
    public internal(set) var versionsStatus: VersionsStatus = .idle
    public var confirmation: VersionChoice?
    public var versionIDText = ""
    public private(set) var copyCount = 0
    public private(set) var startCount = 0
    @ObservationIgnored let session: SessionModel
    @ObservationIgnored let accounts: AccountsModel
    @ObservationIgnored let batchSize: Int
    @ObservationIgnored var versionsRequest = 0
    @ObservationIgnored var requestedMetadata: Set<String> = []
    @ObservationIgnored var pendingMetadata: [String] = []
    @ObservationIgnored var metadataTask: Task<Void, Never>?
    @ObservationIgnored private let preferences: StorePreferences
    @ObservationIgnored private let downloads: DownloadCenter
    @ObservationIgnored private let copy: @MainActor (String) -> Void
    @ObservationIgnored private var request = 0

    public init(
        id: Int64, session: SessionModel, preferences: StorePreferences, accounts: AccountsModel,
        downloads: DownloadCenter, batchSize: Int = 10,
        copy: @escaping @MainActor (String) -> Void = Pasteboard.copy
    ) {
        self.id = id
        self.session = session
        self.preferences = preferences
        self.accounts = accounts
        self.downloads = downloads
        self.batchSize = max(batchSize, 1)
        self.copy = copy
    }

    public var storefront: Storefront { preferences.storefront(for: accounts.active) }

    public var loadKey: LoadKey { LoadKey(storefront: storefront, account: accounts.active?.email) }

    public var task: DownloadTask? { app.flatMap(downloads.task(for:)) }

    public var failedTask: DownloadTask? {
        guard let app, task == nil else { return nil }
        return downloads.tasks.last { $0.app.id == app.id && $0.failure != nil }
    }

    public var action: AppAction? {
        guard let app else { return nil }
        if task != nil { return .progress }
        if !app.isFree { return .paid }
        if session.availability != .ready { return .engine(session.availability) }
        if accounts.active == nil { return .signIn }
        return .download
    }

    public var canDownload: Bool { action == .download }

    public func load() async {
        request += 1
        let current = request
        let storefront = storefront
        if app == nil { isLoading = true }
        loadFailure = nil
        defer { if current == request { isLoading = false } }
        await session.refreshAvailability()
        do {
            let found = try await session.services.catalog.lookup(.appID(id), in: storefront)
            try Task.checkCancellation()
            guard current == request else { return }
            guard let found else {
                app = nil
                loadFailure = .appNotFound
                return
            }
            app = found
            await loadVersions()
        } catch is CancellationError {} catch {
            if current == request && !Task.isCancelled {
                loadFailure = error as? IPAError ?? .network
            }
        }
    }

    public func downloadCurrent() {
        guard canDownload, let app, let account = accounts.active else { return }
        downloads.start(app, account: account)
        startCount += 1
    }

    public func choose(_ externalID: String) {
        guard canDownload else { return }
        confirmation = VersionChoice(externalID: externalID)
        requestMetadata(for: externalID)
    }

    public func download(_ choice: VersionChoice) {
        confirmation = nil
        guard canDownload, let app, let account = accounts.active else { return }
        downloads.start(
            app, version: versions[choice.externalID], externalVersionID: choice.externalID,
            account: account)
        startCount += 1
    }

    public func downloadVersionID() {
        guard canDownloadVersionID, let app, let account = accounts.active else { return }
        downloads.start(app, externalVersionID: versionID, account: account)
        versionIDText = ""
        startCount += 1
    }

    public func copy(_ identifier: AppIdentifier) {
        copy(identifier.value)
        copyCount += 1
    }

    func setVersionIDs(_ ids: [String]) {
        versionIDs = ids.sorted { (Int64($0) ?? 0) > (Int64($1) ?? 0) }
    }
}
