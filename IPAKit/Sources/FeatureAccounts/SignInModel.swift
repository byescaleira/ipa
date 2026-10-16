import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class SignInModel {
    public enum Step: Hashable, Sendable {
        case credentials, code
    }

    public static let codeLength = 6

    public var email = "" {
        didSet { if email != oldValue { failure = nil } }
    }
    public var password = "" {
        didSet { if password != oldValue { failure = nil } }
    }
    public var code = "" {
        didSet {
            let digits = String(code.filter(\.isNumber).prefix(Self.codeLength))
            if digits != code { code = digits }
            if code != oldValue { failure = nil }
        }
    }
    public private(set) var step: Step = .credentials
    public private(set) var isWorking = false
    public private(set) var failure: String?
    public var error: IPAError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let accounts: AccountsModel

    public init(session: SessionModel, accounts: AccountsModel) {
        self.session = session
        self.accounts = accounts
    }

    public var availability: EngineAvailability { session.availability }

    public var isEmailValid: Bool {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
            .wholeMatch(of: /[^@\s]+@[^@\s]+\.[^@\s]+/) != nil
    }

    public var isCodeComplete: Bool { code.count == Self.codeLength }

    public var canSubmit: Bool {
        guard !isWorking else { return false }
        switch step {
        case .credentials: return isEmailValid && !password.isEmpty
        case .code: return isCodeComplete
        }
    }

    public func refreshAvailability() async {
        await session.refreshAvailability()
    }

    public func changeAccount() {
        step = .credentials
        code = ""
        failure = nil
    }

    public func submit() async -> Bool {
        guard canSubmit else { return false }
        isWorking = true
        failure = nil
        defer { isWorking = false }
        let request = SignInRequest(
            email: email, password: password, code: step == .code ? code : nil)
        do {
            let account = try await session.services.engine.signIn(request)
            accounts.didSignIn(account)
            return true
        } catch IPAError.codeRequired {
            let wasAskingCode = step == .code
            step = .code
            code = ""
            if wasAskingCode {
                failure = String(appLocalized: "That code didn't work. Check it and try again.")
            }
        } catch let failure as IPAError {
            self.failure = failure.localizedDescription
        } catch is CancellationError {
        } catch {
            self.error = .store(error.localizedDescription)
        }
        return false
    }
}
