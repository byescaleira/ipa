import Foundation
import IPADomain
import Testing

@testable import IPAData

struct ITunesCatalogTests {
    @Test func buildsTheSearchURL() throws {
        let brazil = try #require(Storefront(code: "BR"))
        let url = ITunesRequest.search("you tube", in: brazil, limit: 500)
        let items = try #require(
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
        #expect(url.host() == "itunes.apple.com")
        #expect(url.path() == "/search")
        #expect(items.contains(URLQueryItem(name: "term", value: "you tube")))
        #expect(items.contains(URLQueryItem(name: "limit", value: "200")))
        #expect(items.contains(URLQueryItem(name: "country", value: "br")))
    }

    @Test func looksUpByIDOrBundleButNotByTerm() throws {
        let byID = try #require(ITunesRequest.lookup(.appID(42), in: .unitedStates))
        let byBundle = try #require(ITunesRequest.lookup(.bundleID("com.a.b"), in: .unitedStates))
        #expect(byID.absoluteString.contains("id=42"))
        #expect(byBundle.absoluteString.contains("bundleId=com.a.b"))
        #expect(ITunesRequest.lookup(.term("notes"), in: .unitedStates) == nil)
    }

    @Test func decodesApps() throws {
        let json = """
            {"resultCount":2,"results":[
            {"kind":"software","trackId":544007664,"bundleId":"com.google.ios.youtube",
             "trackName":"YouTube","sellerName":"Google LLC","version":"20.22.1",
             "minimumOsVersion":"16.0","fileSizeBytes":"346554368","price":0,
             "formattedPrice":"Free","artworkUrl512":"https://example.com/a.png",
             "trackViewUrl":"https://apps.apple.com/app/id544007664",
             "currentVersionReleaseDate":"2026-06-02T15:12:06Z"},
            {"kind":"podcast","trackId":1,"bundleId":"x","trackName":"Not an app"}]}
            """
        let apps = try ITunesResponse.apps(from: Data(json.utf8))
        let app = try #require(apps.first)
        #expect(apps.count == 1)
        #expect(app.id == 544_007_664)
        #expect(app.sizeBytes == 346_554_368)
        #expect(app.isFree)
        #expect(app.minimumOSVersion == "16.0")
        #expect(app.releaseDate != nil)
    }

    @Test func reportsBrokenResponses() {
        #expect(throws: IPAError.onFetch) { try ITunesResponse.apps(from: Data("nope".utf8)) }
    }
}
