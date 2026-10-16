import Foundation
import IPADomain

extension StoreApp {
    public var versionText: String? {
        version.isEmpty ? nil : String(appLocalized: "v\(version)")
    }

    public var systemText: String? {
        minimumOSVersion.map { String(appLocalized: "iOS \($0)") }
    }

    public var sizeText: String? {
        sizeBytes.map(ByteCount.text)
    }

    public var priceText: String {
        isFree
            ? String(appLocalized: "Free") : formattedPrice ?? price.formatted(.number.locale(.app))
    }

    public var detailLine: String {
        [versionText, systemText, sizeText].compactMap(\.self).joined(separator: " · ")
    }
}
