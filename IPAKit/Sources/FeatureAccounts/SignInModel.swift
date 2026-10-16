import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class SignInModel {
    public var email = ""
    public var password = ""
    public var code = ""
    public var error: IPAError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let accounts: AccountsModel

    public init(session: SessionModel, accounts: AccountsModel) {
        self.session = session
        self.accounts = accounts
    }
}
