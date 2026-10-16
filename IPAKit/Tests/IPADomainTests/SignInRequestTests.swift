import IPADomain
import Testing

struct SignInRequestTests {
    @Test func cleansTheEmailAndCode() {
        let request = SignInRequest(email: " me@example.com\n", password: "secret", code: "123 456")
        #expect(request.email == "me@example.com")
        #expect(request.code == "123456")
        #expect(SignInRequest(email: "a", password: "b", code: "  ").code == nil)
    }
}
