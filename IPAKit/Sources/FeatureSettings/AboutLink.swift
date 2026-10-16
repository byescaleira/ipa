import Foundation
import SwiftUI

struct AboutLink: Identifiable {
    enum Kind {
        case website, help, contact, privacy, terms
    }

    let kind: Kind
    let url: URL

    var id: Kind { kind }

    var title: LocalizedStringKey {
        switch kind {
        case .website: "Source Code"
        case .help: "Help Center"
        case .contact: "Contact Us"
        case .privacy: "Privacy Policy"
        case .terms: "Terms of Use"
        }
    }

    var symbol: String {
        switch kind {
        case .website: "chevron.left.forwardslash.chevron.right"
        case .help: "questionmark.circle"
        case .contact: "envelope"
        case .privacy: "hand.raised"
        case .terms: "doc.text"
        }
    }
}

extension AppInfo {
    var links: [AboutLink] {
        let pairs: [(AboutLink.Kind, URL?)] = [
            (.website, websiteURL), (.help, helpURL), (.contact, supportURL),
            (.privacy, privacyURL), (.terms, termsURL),
        ]
        var seen: Set<URL> = []
        return pairs.compactMap { kind, url in
            guard let url, seen.insert(url).inserted else { return nil }
            return AboutLink(kind: kind, url: url)
        }
    }
}
