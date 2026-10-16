import IPAResource
import Testing

@testable import FeatureCore

struct AnimationCatalogTests {
    @Test(arguments: IPAAnimation.allCases)
    func everyAnimationIsEmbedded(animation: IPAAnimation) {
        #expect(IPAResourceAnimation.json(named: animation.rawValue) != nil)
    }

    @Test func everyGuideHasACategoryWithItself() {
        for guide in Guide.allCases {
            #expect(guide.category.guides.contains(guide))
        }
    }
}
