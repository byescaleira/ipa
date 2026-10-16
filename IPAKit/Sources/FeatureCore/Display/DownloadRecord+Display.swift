import Foundation
import IPADomain

extension DownloadRecord {
    public var sizeText: String { ByteCount.text(sizeBytes) }

    public var detailLine: String {
        [version.isEmpty ? nil : String(appLocalized: "v\(version)"), sizeText]
            .compactMap(\.self).joined(separator: " · ")
    }

    public var dateText: String {
        downloadedAt.formatted(.relative(presentation: .named).locale(.app))
    }
}
