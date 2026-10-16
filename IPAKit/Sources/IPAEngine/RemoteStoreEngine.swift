import Foundation
import IPADomain
import os

private let log = Logger(subsystem: "com.byescaleira.ipa", category: "remote")

public struct RemoteStoreEngine: StoreEngine {
    private let config: ServerConfig
    private let vault: any AccountVault
    private let session: URLSession

    public init(config: ServerConfig, vault: any AccountVault, session: URLSession = .shared) {
        self.config = config
        self.vault = vault
        self.session = session
    }

    public func availability() async -> EngineAvailability {
        .ready
    }

    public func signIn(_ request: SignInRequest) async throws -> Account {
        let response = try await send("v1/login", [
            "email": request.email,
            "password": request.password,
            "code": request.code ?? "",
            "macAddress": (try? vault.identity().macAddress) ?? "",
        ])
        guard let raw = response["account"] as? [String: Any],
            let data = try? JSONSerialization.data(withJSONObject: raw),
            let account = Self.account(from: raw)
        else {
            throw IPAError.signInFailed(String(appLocalized: "The server returned an unexpected response."))
        }
        try vault.save(account, credential: data)
        return account
    }

    public func versions(of app: StoreApp, for account: Account) async throws -> [String] {
        let response = try await send("v1/versions", base(app: app, account: try credential(for: account)))
        guard let versions = response["versions"] as? [String] else { return [] }
        return versions.reversed()
    }

    public func version(_ externalID: String, of app: StoreApp, for account: Account) async throws
        -> AppVersion
    {
        var payload = base(app: app, account: try credential(for: account))
        payload["versionID"] = externalID
        let response = try await send("v1/version", payload)
        let display = response["displayVersion"] as? String ?? ""
        let date = (response["releaseDate"] as? String).flatMap {
            ISO8601DateFormatter().date(from: $0)
        }
        return AppVersion(externalID: externalID, displayVersion: display, releaseDate: date)
    }

    public func purchase(_ app: StoreApp, for account: Account) async throws {
        _ = try await send("v1/purchase", base(app: app, account: try credential(for: account)))
    }

    public func download(
        _ request: DownloadRequest, progress: @escaping @Sendable (DownloadProgress) -> Void
    ) async throws -> DownloadedPackage {
        var payload = base(app: request.app, account: try credential(for: request.account))
        payload["versionID"] = request.externalVersionID ?? ""
        progress(DownloadProgress(phase: .preparing))

        let (bytes, response) = try await session.bytes(for: post("v1/download", payload))
        guard let http = response as? HTTPURLResponse else { throw IPAError.network }
        if http.statusCode != 200 {
            throw try await Self.error(from: bytes)
        }

        let total = max(http.expectedContentLength, 0)
        let version = http.value(forHTTPHeaderField: "X-IPA-Version") ?? request.app.version
        let name = PackageName.file(
            bundleID: request.app.bundleID, appID: request.app.id, version: version)
        let destination = request.destination.appending(path: name)
        FileManager.default.createFile(atPath: destination.path(percentEncoded: false), contents: nil)
        let handle = try FileHandle(forWritingTo: destination)
        defer { try? handle.close() }

        var buffer = Data()
        var written: Int64 = 0
        progress(DownloadProgress(phase: .downloading, completedBytes: 0, totalBytes: total))
        for try await byte in bytes {
            buffer.append(byte)
            if buffer.count >= 65_536 {
                try handle.write(contentsOf: buffer)
                written += Int64(buffer.count)
                buffer.removeAll(keepingCapacity: true)
                progress(DownloadProgress(phase: .downloading, completedBytes: written, totalBytes: total))
            }
        }
        if !buffer.isEmpty {
            try handle.write(contentsOf: buffer)
            written += Int64(buffer.count)
        }
        progress(DownloadProgress(phase: .downloading, completedBytes: written, totalBytes: total))

        return DownloadedPackage(fileURL: destination, version: version, sizeBytes: written)
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
        ]
    }

    private func post(_ path: String, _ payload: [String: Any]) throws -> URLRequest {
        var request = URLRequest(url: config.endpoint(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if !config.token.isEmpty {
            request.setValue("Bearer " + config.token, forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return request
    }

    private func send(_ path: String, _ payload: [String: Any]) async throws -> [String: Any] {
        log.info("POST \(path, privacy: .public) → \(config.baseURL.absoluteString, privacy: .public)")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: try post(path, payload))
        } catch let error as IPAError {
            throw error
        } catch {
            log.error("POST \(path, privacy: .public) transport error: \(error.localizedDescription, privacy: .public)")
            throw IPAError.network
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        if let error = object["error"] as? [String: Any] {
            log.error("POST \(path, privacy: .public) ← \(status) error \(String(describing: error["code"]), privacy: .public)")
            throw Self.map(error)
        }
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            log.error("POST \(path, privacy: .public) ← \(status) unexpected")
            throw IPAError.store(String(appLocalized: "The server could not complete the request."))
        }
        log.info("POST \(path, privacy: .public) ← \(status) ok")
        return object
    }

    private static func error(from bytes: URLSession.AsyncBytes) async throws -> IPAError {
        var data = Data()
        for try await byte in bytes {
            data.append(byte)
            if data.count > 8_192 { break }
        }
        if let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
            let error = object["error"] as? [String: Any]
        {
            return map(error)
        }
        return .store(String(appLocalized: "The server could not complete the request."))
    }

    private static func account(from raw: [String: Any]) -> Account? {
        guard let email = raw["email"] as? String else { return nil }
        let storefront =
            (raw["storeFront"] as? String).flatMap(Storefront.init(header:)) ?? .unitedStates
        return Account(
            email: email, name: raw["name"] as? String ?? "", storefront: storefront,
            directoryServicesID: raw["directoryServicesIdentifier"] as? String ?? "")
    }

    private static func map(_ error: [String: Any]) -> IPAError {
        let message = error["message"] as? String ?? String(appLocalized: "The server failed.")
        switch error["code"] as? String {
        case "code_required": return .codeRequired
        case "license_required": return .licenseRequired
        case "not_found": return .appNotFound
        case "paid_app": return .paidApp
        case "cancelled": return .onFetch
        case "unauthorized": return .store(String(appLocalized: "The server rejected the token."))
        default: return .signInFailed(message)
        }
    }
}
