import FeatureCore
import Foundation

enum DeepLink: Equatable {
    case section(AppSection)
    case route(Route, in: AppSection)
    case search(String)

    init(url: URL) {
        guard url.scheme == "ipa" else {
            self = .section(.search)
            return
        }
        let path = url.pathComponents.dropFirst().first
        switch url.host() {
        case "search":
            let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "q" }?.value
            self = query.map { .search($0) } ?? .section(.search)
        case "apps":
            self =
                path.flatMap { Int64($0) }.map { .route(.app(id: $0), in: .search) }
                ?? .section(.search)
        case "downloads":
            self = .section(.downloads)
        case "accounts":
            self = path == "new" ? .route(.signIn, in: .accounts) : .section(.accounts)
        case "settings":
            self = .section(.settings)
        default:
            self = .section(.search)
        }
    }

    static func handles(_ url: URL) -> Bool {
        url.scheme == "ipa"
    }
}
