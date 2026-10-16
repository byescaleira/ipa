import IPADomain
import Testing

struct AccountTests {
    private func account(_ name: String, _ email: String = "a@example.com") -> Account {
        Account(email: email, name: name, storefront: .unitedStates, directoryServicesID: "1")
    }

    @Test func initialsUseTheFirstAndLastName() {
        #expect(account("Ana Maria Souza").initials == "AS")
        #expect(account("ana").initials == "A")
    }

    @Test func initialsFallBackToTheEmailName() {
        #expect(account(" ", "joe@example.com").initials == "J")
        #expect(account("", "john.doe@example.com").initials == "JD")
    }

    @Test func displayNameFallsBackToTheEmail() {
        #expect(account(" ", "joe@example.com").displayName == "joe@example.com")
    }
}
