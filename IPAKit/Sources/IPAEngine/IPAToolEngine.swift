import Foundation
import IPADomain

#if os(iOS)
    import IPAToolCore
#endif

public struct IPAToolEngine: StoreEngine {
    private let vault: any AccountVault

    public init(vault: any AccountVault) {
        self.vault = vault
    }

    public func availability() async -> EngineAvailability {
        JITStatus.availability
    }

    public func signIn(_ request: SignInRequest) async throws -> Account {
        let identity = try vault.identity()
        let response = try await run("login", [
            "email": request.email,
            "password": request.password,
            "code": request.code ?? "",
            "macAddress": identity.macAddress,
            "home": NSTemporaryDirectory(),
        ])
        guard let raw = response["account"] as? [String: Any],
            let data = try? JSONSerialization.data(withJSONObject: raw),
            let account = Self.account(from: raw)
        else {
            throw IPAError.signInFailed(String(appLocalized: "Apple returned an unexpected response."))
        }
        try vault.save(account, credential: data)
        return account
    }

    public func versions(of app: StoreApp, for account: Account) async throws -> [String] {
        let response = try await run("versions", base(app: app, account: try credential(for: account)))
        guard let versions = response["versions"] as? [String] else { return [] }
        return versions.reversed()
    }

    public func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        var payload = base(app: app, account: try credential(for: account))
        payload["versionID"] = externalID
        let response = try await run("version_metadata", payload)
        let display = response["displayVersion"] as? String ?? ""
        let date = (response["releaseDate"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
        return AppVersion(externalID: externalID, displayVersion: display, releaseDate: date)
    }

    public func purchase(_ app: StoreApp, for account: Account) async throws {
        _ = try await run("purchase", base(app: app, account: try credential(for: account)))
    }

    public func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        var payload = base(app: request.app, account: try credential(for: request.account))
        payload["versionID"] = request.externalVersionID ?? ""
        payload["outputPath"] = request.destination.path(percentEncoded: false)
        let start = try await run("download_start", payload)
        guard let taskID = start["taskID"] as? String else {
            throw IPAError.store(String(appLocalized: "The store engine could not start the download."))
        }

        while true {
            if Task.isCancelled {
                cancelTask(taskID)
                throw CancellationError()
            }
            try await Task.sleep(for: .milliseconds(300))
            let status = try status(taskID)
            if let error = status["error"] as? [String: Any] {
                throw Self.map(error)
            }
            let phase = Self.phase(status["phase"] as? String)
            progress(
                DownloadProgress(
                    phase: phase, completedBytes: Self.int(status["completed"]),
                    totalBytes: Self.int(status["total"])))
            if status["done"] as? Bool == true {
                return DownloadedPackage(
                    fileURL: URL(filePath: status["fileName"] as? String ?? ""),
                    version: status["version"] as? String ?? request.app.version,
                    sizeBytes: Self.int(status["size"]))
            }
        }
    }

    private func credential(for account: Account) throws -> Any {
        guard let data = try vault.credential(for: account.email) else {
            throw IPAError.signInFailed(String(appLocalized: "Sign in to this account again."))
        }
        return try JSONSerialization.jsonObject(with: data)
    }

    private func base(app: StoreApp, account: Any) -> [String: Any] {
        [
            "credential": account,
            "appID": app.id,
            "bundleID": app.bundleID,
            "macAddress": (try? vault.identity().macAddress) ?? "",
            "home": NSTemporaryDirectory(),
        ]
    }

    private func run(_ name: String, _ payload: [String: Any]) async throws -> [String: Any] {
        guard JITStatus.availability == .ready else { throw IPAError.engine(JITStatus.availability) }
        let request = String(
            data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8) ?? "{}"
        let text = await Task.detached(priority: .userInitiated) { Bridge.call(name, request) }.value
        let object = Self.object(from: text)
        if let error = object["error"] as? [String: Any] { throw Self.map(error) }
        return object
    }

    private func status(_ taskID: String) throws -> [String: Any] {
        let object = Self.object(from: Bridge.status(taskID))
        return object
    }

    private func cancelTask(_ taskID: String) {
        Bridge.cancel(taskID)
    }

    private static func object(from text: String?) -> [String: Any] {
        guard let text,
            let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]
        else { return [:] }
        return object
    }

    private static func account(from raw: [String: Any]) -> Account? {
        guard let email = raw["email"] as? String else { return nil }
        let storefront =
            (raw["storeFront"] as? String).flatMap(Storefront.init(header:)) ?? .unitedStates
        return Account(
            email: email, name: raw["name"] as? String ?? "", storefront: storefront,
            directoryServicesID: raw["directoryServicesIdentifier"] as? String ?? "")
    }

    private static func phase(_ value: String?) -> DownloadPhase {
        switch value {
        case "licensing": .licensing
        case "signing": .signing
        case "preparing": .preparing
        default: .downloading
        }
    }

    private static func int(_ value: Any?) -> Int64 {
        (value as? NSNumber)?.int64Value ?? 0
    }

    private static func map(_ error: [String: Any]) -> IPAError {
        let message = error["message"] as? String ?? String(appLocalized: "The store engine failed.")
        switch error["code"] as? String {
        case "code_required": return .codeRequired
        case "license_required": return .licenseRequired
        case "not_found": return .appNotFound
        case "paid_app": return .paidApp
        case "cancelled": return .onFetch
        default: return .signInFailed(message)
        }
    }
}

private enum Bridge {
    static func call(_ name: String, _ request: String) -> String? {
        #if os(iOS)
            return invoke(function(name), request)
        #else
            return nil
        #endif
    }

    static func status(_ taskID: String) -> String? {
        #if os(iOS)
            return invoke(ipa_task_status, taskID)
        #else
            return nil
        #endif
    }

    static func cancel(_ taskID: String) {
        #if os(iOS)
            taskID.withCString { ipa_task_cancel(UnsafeMutablePointer(mutating: $0)) }
        #endif
    }

    #if os(iOS)
        private typealias Entry = (UnsafeMutablePointer<CChar>?) -> UnsafeMutablePointer<CChar>?

        private static func function(_ name: String) -> Entry {
            switch name {
            case "login": ipa_login
            case "versions": ipa_versions
            case "version_metadata": ipa_version_metadata
            case "purchase": ipa_purchase
            case "download_start": ipa_download_start
            default: ipa_login
            }
        }

        private static func invoke(_ entry: Entry, _ argument: String) -> String? {
            argument.withCString { pointer in
                guard let out = entry(UnsafeMutablePointer(mutating: pointer)) else { return nil }
                defer { ipa_free(out) }
                return String(cString: out)
            }
        }
    #endif
}
