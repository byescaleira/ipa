import Foundation
import IPAResource
import Testing

struct AnimationResourceTests {
    @Test(arguments: ["direct", "done", "editor", "find", "launch", "privacy", "setup", "widgets"])
    func embedsAPlayableAnimation(name: String) throws {
        let json = try #require(IPAResourceAnimation.json(named: name))
        let object = try #require(
            try JSONSerialization.jsonObject(with: Data(json.utf8)) as? [String: Any])
        #expect(object["w"] as? Int == 320)
        #expect(object["h"] as? Int == 180)
        #expect(object["fr"] as? Int == 60)
    }

    @Test func returnsNothingForUnknownNames() {
        #expect(IPAResourceAnimation.json(named: "missing") == nil)
    }
}
