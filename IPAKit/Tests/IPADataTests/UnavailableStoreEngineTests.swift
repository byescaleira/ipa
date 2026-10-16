import Foundation
import IPAData
import IPADomain
import Testing

struct UnavailableStoreEngineTests {
    @Test func refusesEveryStoreCallUntilTheEngineShips() async {
        let engine = UnavailableStoreEngine()
        #expect(await engine.availability() == .unsupported)
        await #expect(throws: IPAError.engine(.unsupported)) {
            try await engine.signIn(SignInRequest(email: "a@b.com", password: "x"))
        }
    }
}
