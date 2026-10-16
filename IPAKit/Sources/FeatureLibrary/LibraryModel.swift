import FeatureCore
import Foundation
import IPADomain
import Observation

@MainActor @Observable
public final class LibraryModel {
    public var text = ""
    @ObservationIgnored private let downloads: DownloadCenter
    @ObservationIgnored private let accounts: AccountsModel

    public init(downloads: DownloadCenter, accounts: AccountsModel) {
        self.downloads = downloads
        self.accounts = accounts
    }
}
