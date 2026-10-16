import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class StoreSettingsModel {
    public enum EraseStep: Int, CaseIterable, Sendable {
        case confirm, done
    }

    public enum ServerStatus: Equatable, Sendable {
        case idle, checking, online, failed
    }

    public private(set) var identity: DeviceIdentity?
    public private(set) var isWorking = false
    public var isConfirmingIdentity = false
    public var isErasing = false
    public var eraseStep = EraseStep.confirm
    public var serverAddress = ""
    public var serverToken = ""
    public private(set) var serverStatus = ServerStatus.idle
    public var error: IPAError?
    @ObservationIgnored let settings: SettingsModel
    @ObservationIgnored let session: SessionModel
    @ObservationIgnored let preferences: StorePreferences
    @ObservationIgnored let accounts: AccountsModel
    @ObservationIgnored let downloads: DownloadCenter

    public init(
        settings: SettingsModel, session: SessionModel, preferences: StorePreferences,
        accounts: AccountsModel, downloads: DownloadCenter
    ) {
        self.settings = settings
        self.session = session
        self.preferences = preferences
        self.accounts = accounts
        self.downloads = downloads
    }

    var resultsLimit: Int {
        get { preferences.resultsLimit }
        set { preferences.resultsLimit = newValue }
    }

    var availability: EngineAvailability { session.availability }

    func load() async {
        loadIdentity()
        loadServer()
        if !downloads.hasLoaded { await downloads.load() }
        await session.refreshAvailability()
    }

    var serverEnabled: Bool { session.services.serverConfig.load() != nil }

    func loadServer() {
        guard let config = session.services.serverConfig.load() else { return }
        serverAddress = config.baseURL.absoluteString
        serverToken = config.token
    }

    func saveServer() {
        guard let config = ServerConfig(address: serverAddress, token: serverToken) else {
            error = .invalidInput(String(appLocalized: "Enter the server address."))
            return
        }
        do {
            try session.services.serverConfig.save(config)
            serverAddress = config.baseURL.absoluteString
            serverStatus = .idle
            session.reload()
            Task { await refreshEngine() }
        } catch {
            self.error = error as? IPAError ?? .onSave
        }
    }

    func removeServer() {
        do {
            try session.services.serverConfig.clear()
            serverAddress = ""
            serverToken = ""
            serverStatus = .idle
            session.reload()
            Task { await refreshEngine() }
        } catch {
            self.error = error as? IPAError ?? .onRemove
        }
    }

    func checkServer() async {
        guard let config = ServerConfig(address: serverAddress, token: serverToken) else {
            error = .invalidInput(String(appLocalized: "Enter the server address."))
            return
        }
        serverStatus = .checking
        var request = URLRequest(url: config.endpoint("health"))
        if !config.token.isEmpty {
            request.setValue("Bearer " + config.token, forHTTPHeaderField: "Authorization")
        }
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            serverStatus = code == 200 ? .online : .failed
        } catch {
            serverStatus = .failed
        }
    }

    func refreshEngine() async {
        await session.refreshAvailability()
    }

    func startIdentityChange() {
        isConfirmingIdentity = true
    }

    func regenerateIdentity() {
        let vault = session.services.vault
        do {
            for account in try vault.accounts() { try vault.remove(email: account.email) }
            identity = try vault.regenerateIdentity()
            accounts.reset()
            isConfirmingIdentity = false
        } catch {
            self.error = error as? IPAError ?? .onSave
        }
    }

    func startErase() {
        eraseStep = .confirm
        isErasing = true
    }

    func erase() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try session.services.vault.removeAll()
        } catch {
            self.error = error as? IPAError ?? .onRemove
            return
        }
        await downloads.deleteAll()
        accounts.reset()
        preferences.reset()
        loadIdentity()
        session.reload()
        eraseStep = .done
    }

    func closeErase() {
        if eraseStep == .done { settings.reset() }
        eraseStep = .confirm
        isErasing = false
    }

    private func loadIdentity() {
        do {
            identity = try session.services.vault.identity()
        } catch {
            self.error = error as? IPAError ?? .onFetch
        }
    }
}
