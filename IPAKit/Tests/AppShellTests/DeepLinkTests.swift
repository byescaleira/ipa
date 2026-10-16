import Foundation
import Testing

@testable import AppShell

struct DeepLinkTests {
    @Test(arguments: [
        ("ipa://search?q=youtube", DeepLink.search("youtube")),
        ("ipa://search", DeepLink.section(.search)),
        ("ipa://apps/544007664", DeepLink.route(.app(id: 544_007_664), in: .search)),
        ("ipa://apps/abc", DeepLink.section(.search)),
        ("ipa://downloads", DeepLink.section(.downloads)),
        ("ipa://accounts", DeepLink.section(.accounts)),
        ("ipa://accounts/new", DeepLink.route(.signIn, in: .accounts)),
        ("ipa://settings", DeepLink.section(.settings)),
        ("ipa://unknown", DeepLink.section(.search)),
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
