import Foundation
import IPADomain

extension DownloadProgress {
    public var phaseText: String {
        switch phase {
        case .preparing: String(appLocalized: "Preparing the store engine")
        case .licensing: String(appLocalized: "Getting license")
        case .downloading: String(appLocalized: "Downloading")
        case .signing: String(appLocalized: "Signing package")
        }
    }

    public var bytesText: String? {
        guard phase == .downloading, totalBytes > 0 else { return nil }
        return String(
            appLocalized: "\(ByteCount.text(completedBytes)) of \(ByteCount.text(totalBytes))")
    }
}
