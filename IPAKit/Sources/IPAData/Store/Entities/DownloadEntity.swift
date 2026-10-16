import Foundation
import IPADomain
import SwiftData

@Model
public class DownloadEntity {
    #Index<DownloadEntity>([\.id])
    public var id: String = ""
    public var accountEmail: String = ""
    public var appID: Int64 = 0
    public var bundleID: String = ""
    public var name: String = ""
    public var version: String = ""
    public var externalVersionID: String?
    public var fileName: String = ""
    public var sizeBytes: Int64 = 0
    public var artworkURL: URL?
    public var downloadedAt: Date = Date.distantPast

    public init(_ record: DownloadRecord) {
        id = record.id
        apply(record)
    }

    func apply(_ record: DownloadRecord) {
        accountEmail = record.accountEmail
        appID = record.appID
        bundleID = record.bundleID
        name = record.name
        version = record.version
        externalVersionID = record.externalVersionID
        fileName = record.fileName
        sizeBytes = record.sizeBytes
        artworkURL = record.artworkURL
        downloadedAt = record.downloadedAt
    }

    var record: DownloadRecord {
        DownloadRecord(
            id: id, accountEmail: accountEmail, appID: appID, bundleID: bundleID, name: name,
            version: version, externalVersionID: externalVersionID, fileName: fileName,
            sizeBytes: sizeBytes, artworkURL: artworkURL, downloadedAt: downloadedAt)
    }
}
