import Testing

@testable import FeatureLibrary

struct FeatureLibrarySmokeTests {
    @Test func builds() {
        #expect(Bool(true))
    }
}
