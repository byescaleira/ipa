import Foundation
import IPADomain
import IPAMock
import Testing

@testable import FeatureCore

struct DisplayTests {
    @Test func describesAnAppInOneLine() throws {
        let app = try #require(SampleApps.all.first)
        #expect(app.detailLine.hasPrefix("v20.22.1 · iOS 16.0 · "))
        #expect(app.priceText == String(appLocalized: "Free"))
        let bare = StoreApp(id: 1, bundleID: "a", name: "A")
        #expect(bare.detailLine.isEmpty)
    }

    @Test func showsThePriceOfPaidApps() throws {
        let paid = try #require(SampleApps.all.first { !$0.isFree })
        #expect(paid.priceText == paid.formattedPrice)
    }

    @Test func describesProgressByPhase() {
        #expect(DownloadProgress(phase: .preparing).bytesText == nil)
        #expect(
            DownloadProgress(phase: .downloading, completedBytes: 1, totalBytes: 2).bytesText != nil
        )
        #expect(
            Set(
                [DownloadPhase.preparing, .licensing, .downloading, .signing].map {
                    DownloadProgress(phase: $0).phaseText
                }
            ).count == 4)
    }

    @Test func titlesTheStoreWithItsFlag() throws {
        let brazil = try #require(Storefront(code: "BR"))
        #expect(brazil.title.hasPrefix("🇧🇷 "))
    }

    @Test func describesARecord() {
        let record = DownloadRecord(
            accountEmail: "a@b.com", appID: 1, bundleID: "a", name: "A", version: "2.0",
            fileName: "a.ipa", sizeBytes: 2_000_000)
        #expect(record.detailLine.hasPrefix("v2.0 · "))
        #expect(!record.dateText.isEmpty)
    }
}
