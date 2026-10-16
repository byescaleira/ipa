import Foundation
import IPADomain

public enum SampleApps {
    public static let account = Account(
        email: "sample@example.com", name: "Sample User", storefront: .unitedStates,
        directoryServicesID: "1000000001")

    public static let all: [StoreApp] = [
        app(544_007_664, "com.google.ios.youtube", "YouTube", "Google LLC", "20.22.1", "16.0", 330),
        app(
            1_017_492_454, "com.google.ios.youtubemusic", "YouTube Music", "Google LLC", "8.22",
            "16.0", 252),
        app(
            310_633_997, "net.whatsapp.WhatsApp", "WhatsApp Messenger", "WhatsApp Inc.", "25.17.0",
            "15.1", 257),
        app(
            324_684_580, "com.spotify.client", "Spotify: Music and Podcasts", "Spotify", "9.0.50",
            "16.0", 189),
        app(
            686_449_807, "ph.telegra.Telegraph", "Telegram Messenger", "Telegram FZ-LLC", "11.12",
            "15.0", 125),
        app(363_590_051, "com.netflix.Netflix", "Netflix", "Netflix, Inc.", "17.33.0", "17.0", 147),
        app(
            1_000_000_001, "com.example.paid", "Paid Example", "Example", "1.0", "17.0", 42,
            price: 4.99),
    ]

    public static func search(_ term: String) -> [StoreApp] {
        let query = term.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return all }
        return all.filter {
            $0.name.localizedStandardContains(query) || $0.bundleID.localizedStandardContains(query)
        }
    }

    private static func app(
        _ id: Int64, _ bundleID: String, _ name: String, _ seller: String, _ version: String,
        _ minimum: String, _ megabytes: Int64, price: Double = 0
    ) -> StoreApp {
        StoreApp(
            id: id, bundleID: bundleID, name: name, seller: seller, version: version,
            minimumOSVersion: minimum, sizeBytes: megabytes * 1_048_576, price: price,
            formattedPrice: price == 0 ? "Free" : "$\(price)",
            storeURL: URL(string: "https://apps.apple.com/app/id\(id)"))
    }
}
