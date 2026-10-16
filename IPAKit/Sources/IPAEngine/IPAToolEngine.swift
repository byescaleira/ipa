import Foundation
import IPADomain

#if os(iOS)
    import IPAToolCore
#endif

public struct IPAToolEngine: StoreEngine {
    @preconcurrency private let vault: any AccountVault

    public init(vault: any AccountVault) {
        self.vault = vault
    }

    public func availability() async -> EngineAvailability {
        JITStatus.availability
    }

    public func signIn(_ request: SignInRequest) async throws -> Account {
        let identity = try vault.identity()
        let response = try await bridge([
            "email": request.email,
            "password": request.password,
            "code": request.code ?? "",
            "macAddress": identity.macAddress,
            "home": NSTemporaryDirectory(),
        ]) { ipa_login_call($0) }

        if let error = response["error"] as? [String: Any] {
            throw Self.map(error)
        }
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
        throw IPAError.engine(JITStatus.availability == .ready ? .unsupported : JITStatus.availability)
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

    private func bridge(
        _ payload: [String: Any], _ call: @Sendable @escaping (String) -> String?
    ) async throws -> [String: Any] {
        guard JITStatus.availability == .ready else { throw IPAError.engine(JITStatus.availability) }
        let request = String(
            data: try JSONSerialization.data(withJSONObject: payload), encoding: .utf8) ?? "{}"
        let text = await Task.detached(priority: .userInitiated) { call(request) }.value
        guard let text,
            let object = try? JSONSerialization.jsonObject(with: Data(text.utf8)) as? [String: Any]
        else {
            throw IPAError.store(String(appLocalized: "The store engine returned no response."))
        }
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

    private static func map(_ error: [String: Any]) -> IPAError {
        let message = error["message"] as? String ?? String(appLocalized: "Sign-in failed.")
        switch error["code"] as? String {
        case "code_required": return .codeRequired
        case "license_required": return .licenseRequired
        case "not_found": return .appNotFound
        case "token_expired": return .signInFailed(message)
        default: return .signInFailed(message)
        }
    }
}

#if os(iOS)
    private func ipa_login_call(_ request: String) -> String? {
        request.withCString { input in
            guard let out = ipa_login(UnsafeMutablePointer(mutating: input)) else { return nil }
            defer { ipa_free(out) }
            return String(cString: out)
        }
    }
#else
    private func ipa_login_call(_ request: String) -> String? { nil }
#endif
