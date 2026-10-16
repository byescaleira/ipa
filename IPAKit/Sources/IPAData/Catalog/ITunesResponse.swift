import Foundation
import IPADomain

struct ITunesResponse: Decodable {
    let results: [Result]

    struct Result: Decodable {
        let kind: String?
        let trackId: Int64?
        let bundleId: String?
        let trackName: String?
        let sellerName: String?
        let artistName: String?
        let version: String?
        let minimumOsVersion: String?
        let fileSizeBytes: String?
        let artworkUrl512: URL?
        let artworkUrl100: URL?
        let price: Double?
        let formattedPrice: String?
        let trackViewUrl: URL?
        let currentVersionReleaseDate: Date?
    }

    static func apps(from data: Data) throws -> [StoreApp] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(ITunesResponse.self, from: data).results.compactMap(\.app)
        } catch {
            throw IPAError.onFetch
        }
    }
}

extension ITunesResponse.Result {
    var app: StoreApp? {
        guard let trackId, let bundleId, let trackName,
            kind == nil || kind == "software" || kind == "mac-software"
        else { return nil }
        return StoreApp(
            id: trackId, bundleID: bundleId, name: trackName,
            seller: sellerName ?? artistName ?? "", version: version ?? "",
            minimumOSVersion: minimumOsVersion, sizeBytes: fileSizeBytes.flatMap { Int64($0) },
            artworkURL: artworkUrl512 ?? artworkUrl100, price: price ?? 0,
            formattedPrice: formattedPrice, storeURL: trackViewUrl,
            releaseDate: currentVersionReleaseDate)
    }
}
