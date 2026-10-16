import Foundation
import Testing

@testable import AppShell

struct DeepLinkTests {
    @Test(arguments: [
        ("ipa://items/new", DeepLink.route(.item(id: nil), in: .home)),
        ("ipa://items/abc", DeepLink.route(.item(id: "abc"), in: .home)),
        ("ipa://settings", DeepLink.section(.settings)),
        ("ipa://unknown", DeepLink.section(.home)),
    ])
    func opensTheRightPlace(link: String, expected: DeepLink) throws {
        let url = try #require(URL(string: link))
        #expect(DeepLink.handles(url))
        #expect(DeepLink(url: url) == expected)
    }

    @Test func ignoresOtherSchemes() throws {
        #expect(!DeepLink.handles(try #require(URL(string: "https://example.com"))))
    }
}
