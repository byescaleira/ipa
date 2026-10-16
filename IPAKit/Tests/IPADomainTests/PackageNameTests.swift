import Foundation
import IPADomain
import Testing

struct PackageNameTests {
    @Test func buildsASafeFileName() {
        #expect(
            PackageName.file(
                bundleID: "com.google.ios.youtube", appID: 544_007_664, version: "20.22.1")
                == "com.google.ios.youtube_544007664_20.22.1.ipa")
        #expect(PackageName.file(bundleID: "a/b", appID: 1, version: "1 0") == "a_b_1_1_0.ipa")
    }

    @Test func buildsOneFolderPerAccount() {
        #expect(PackageName.folder(email: "Me@Example.com") == "me@example.com")
        #expect(PackageName.folder(email: "a b/c@x.com") == "a_b_c@x.com")
    }

    @Test func measuresProgressOnlyWhileDownloading() {
        #expect(DownloadProgress(phase: .preparing).fraction == nil)
        #expect(
            DownloadProgress(phase: .downloading, completedBytes: 50, totalBytes: 200).fraction
                == 0.25)
        #expect(
            DownloadProgress(phase: .downloading, completedBytes: 300, totalBytes: 200).fraction
                == 1)
    }

    @Test func filtersRecordsByNameOrBundle() {
        let record = DownloadRecord(
            accountEmail: "a@b.com", appID: 1, bundleID: "com.example.notes", name: "Notes Pro",
            version: "1.0", fileName: "x.ipa", sizeBytes: 1)
        #expect(record.matches(""))
        #expect(record.matches("notes"))
        #expect(record.matches("example"))
        #expect(!record.matches("music"))
    }
}
