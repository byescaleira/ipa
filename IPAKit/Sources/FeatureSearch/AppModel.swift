import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class AppModel {
    public let id: Int64
    public private(set) var app: StoreApp?
    public var error: IPAError?
    @ObservationIgnored private let session: SessionModel
    @ObservationIgnored private let preferences: StorePreferences
    @ObservationIgnored private let accounts: AccountsModel
    @ObservationIgnored private let downloads: DownloadCenter

    public init(
        id: Int64, session: SessionModel, preferences: StorePreferences, accounts: AccountsModel,
        downloads: DownloadCenter
    ) {
        self.id = id
        self.session = session
        self.preferences = preferences
        self.accounts = accounts
        self.downloads = downloads
    }
}
