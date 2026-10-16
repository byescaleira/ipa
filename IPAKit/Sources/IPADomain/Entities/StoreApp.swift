import Foundation

public struct StoreApp: Hashable, Sendable, Identifiable, Codable {
    public let id: Int64
    public let bundleID: String
    public let name: String
    public let seller: String
    public let version: String
    public let minimumOSVersion: String?
    public let sizeBytes: Int64?
    public let artworkURL: URL?
    public let price: Double
    public let formattedPrice: String?
    public let storeURL: URL?
    public let releaseDate: Date?

    public init(
        id: Int64, bundleID: String, name: String, seller: String = "", version: String = "",
        minimumOSVersion: String? = nil, sizeBytes: Int64? = nil, artworkURL: URL? = nil,
        price: Double = 0, formattedPrice: String? = nil, storeURL: URL? = nil,
        releaseDate: Date? = nil
    ) {
        self.id = id
        self.bundleID = bundleID
        self.name = name
        self.seller = seller
        self.version = version
        self.minimumOSVersion = minimumOSVersion
        self.sizeBytes = sizeBytes
        self.artworkURL = artworkURL
        self.price = price
        self.formattedPrice = formattedPrice
        self.storeURL = storeURL
        self.releaseDate = releaseDate
    }

    public var isFree: Bool { price == 0 }
}
