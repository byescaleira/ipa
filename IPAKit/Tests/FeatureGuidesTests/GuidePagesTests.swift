import FeatureCore
import Testing

@testable import FeatureGuides

struct GuidePagesTests {
    @Test(arguments: Guide.allCases)
    func everyGuideHasPages(guide: Guide) {
        #expect(!guide.pages.isEmpty)
        #expect(guide.minutes > 0)
    }

    @Test(arguments: Guide.allCases)
    func everyPageStaysShort(guide: Guide) {
        #expect((1...5).contains(guide.pages.count))
        for page in guide.pages {
            #expect(page.steps.count <= 3)
        }
    }

    @Test(arguments: [Guide.jit, .install])
    func stepsOutsideTheAppOpenThePlace(guide: Guide) {
        let pages = guide.pages.filter { !$0.steps.isEmpty }
        #expect(!pages.isEmpty)
        #expect(pages.allSatisfy { $0.link?.url.scheme == "https" })
    }

    @Test func everyCategoryHasGuides() {
        for category in GuideCategory.allCases {
            #expect(!category.guides.isEmpty)
        }
    }
}
