import Foundation
import IPADomain

public struct DownloadTask: Identifiable, Hashable, Sendable {
    public let id: String
    public let app: StoreApp
    public let account: Account
    public let externalVersionID: String?
    public let version: String
    public var progress: DownloadProgress
    public var failure: IPAError?

    public init(
        id: String = UUID().uuidString, app: StoreApp, account: Account,
        externalVersionID: String?, version: String
    ) {
        self.id = id
        self.app = app
        self.account = account
        self.externalVersionID = externalVersionID
        self.version = version
        progress = DownloadProgress(phase: .preparing)
    }
}
