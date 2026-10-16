import IPADomain
import Testing

struct AppQueryTests {
    @Test(arguments: [
        ("youtube", AppQuery.term("youtube")),
        ("  YouTube Music ", AppQuery.term("YouTube Music")),
        ("544007664", AppQuery.appID(544_007_664)),
        ("com.google.ios.youtube", AppQuery.bundleID("com.google.ios.youtube")),
        ("net.whatsapp.WhatsApp", AppQuery.bundleID("net.whatsapp.WhatsApp")),
        ("https://apps.apple.com/us/app/youtube/id544007664", AppQuery.appID(544_007_664)),
        ("https://apps.apple.com/app/id310633997?l=pt", AppQuery.appID(310_633_997)),
        ("version 2.0", AppQuery.term("version 2.0")),
    ])
    func readsWhatWasTyped(input: String, expected: AppQuery) {
        #expect(AppQuery(input) == expected)
    }

    @Test func ignoresBlankInput() {
        #expect(AppQuery("   ") == nil)
    }

    @Test func linksFromOtherSitesAreSearchedAsText() {
        #expect(AppQuery("https://example.com/id123") == .term("https://example.com/id123"))
    }
}
