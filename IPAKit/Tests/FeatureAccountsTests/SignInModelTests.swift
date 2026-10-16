import FeatureCore
import Foundation
import IPAData
import IPADomain
import IPAMock
import Testing

@testable import FeatureAccounts

@MainActor
struct SignInModelTests {
    private func defaults() -> UserDefaults {
        let name = "test." + UUID().uuidString
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func signIn(availability: EngineAvailability = .ready) throws -> (
        SignInModel, AccountsModel
    ) {
        let vault = InMemoryAccountVault()
        let services = StoreServices(
            catalog: SampleCatalog(),
            engine: SimulatedStoreEngine(vault: vault, availability: availability, step: .zero),
            vault: vault,
            folder: DownloadFolder(
                root: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)))
        let repositories = try IPADatabase.open(inMemory: true).repositories
        let session = SessionModel(repositories: repositories, services: services)
        let accounts = AccountsModel(vault: vault, defaults: defaults())
        accounts.load()
        return (SignInModel(session: session, accounts: accounts), accounts)
    }

    @Test func validatesTheEmailAndPassword() throws {
        let (model, _) = try signIn()
        #expect(!model.canSubmit)
        model.email = "ana"
        model.password = "secret"
        #expect(!model.isEmailValid)
        #expect(!model.canSubmit)
        model.email = " ana@icloud.com "
        #expect(model.isEmailValid)
        #expect(model.canSubmit)
        model.password = ""
        #expect(!model.canSubmit)
        model.email = "ana@icloud"
        #expect(!model.isEmailValid)
    }

    @Test func keepsOnlySixDigitsInTheCode() throws {
        let (model, _) = try signIn()
        model.code = "12a 34-5678"
        #expect(model.code == "123456")
        #expect(model.isCodeComplete)
        model.code = "12"
        #expect(!model.isCodeComplete)
    }

    @Test func signsInAndMakesTheAccountActive() async throws {
        let (model, accounts) = try signIn()
        model.email = "ana@icloud.com"
        model.password = "secret"
        #expect(await model.submit())
        #expect(accounts.active?.email == "ana@icloud.com")
        #expect(model.failure == nil)
        #expect(!model.isWorking)
    }

    @Test func asksForTheCodeOnTheSameScreen() async throws {
        let (model, accounts) = try signIn()
        model.email = "ana2fa@icloud.com"
        model.password = "secret"
        #expect(await model.submit() == false)
        #expect(model.step == .code)
        #expect(model.failure == nil)
        #expect(model.primaryTitle == String(appLocalized: "Verify"))
        #expect(!model.canSubmit)
        model.code = "123456"
        #expect(await model.submit())
        #expect(accounts.active?.email == "ana2fa@icloud.com")
    }

    @Test func goesBackToChangeTheAccount() async throws {
        let (model, _) = try signIn()
        model.email = "ana2fa@icloud.com"
        model.password = "secret"
        _ = await model.submit()
        model.code = "123"
        model.changeAccount()
        #expect(model.step == .credentials)
        #expect(model.code.isEmpty)
        #expect(model.primaryTitle == String(appLocalized: "Sign In"))
    }

    @Test func showsWrongCredentialsInline() async throws {
        let (model, accounts) = try signIn()
        model.email = "ana@icloud.com"
        model.password = SimulatedStoreEngine.wrongPassword
        #expect(await model.submit() == false)
        #expect(model.step == .credentials)
        #expect(model.failure == String(appLocalized: "The Apple ID or password is incorrect."))
        #expect(model.error == nil)
        #expect(accounts.accounts.isEmpty)
        model.password = "secret"
        #expect(model.failure == nil)
    }

    @Test func explainsWhenTheEngineNeedsJIT() async throws {
        let (model, _) = try signIn(availability: .needsJIT)
        await model.refreshAvailability()
        #expect(model.availability == .needsJIT)
        model.email = "ana@icloud.com"
        model.password = "secret"
        #expect(await model.submit() == false)
        #expect(model.failure == IPAError.engine(.needsJIT).localizedDescription)
        #expect(model.error == nil)
    }

    @Test func describesEachEngineState() {
        let states = [EngineAvailability.ready, .needsJIT, .unsupported].map(EngineStatus.init)
        #expect(Set(states.map(\.title)).count == 3)
        #expect(Set(states.map(\.symbol)).count == 3)
        #expect(states.map(\.needsGuide) == [false, true, true])
        #expect(states.allSatisfy { !$0.detail.isEmpty })
    }

    @Test func confirmsBeforeRemovingAnAccount() throws {
        let ana = Account(
            email: "ana@icloud.com", name: "Ana Souza", storefront: .unitedStates,
            directoryServicesID: "1")
        let accounts = AccountsModel(
            vault: InMemoryAccountVault(accounts: [ana]), defaults: defaults())
        accounts.load()
        accounts.removal = ana
        #expect(accounts.isConfirmingRemoval)
        #expect(accounts.removalTitle.contains("Ana Souza"))
        accounts.isConfirmingRemoval = false
        accounts.confirmRemoval()
        #expect(accounts.accounts == [ana])
        accounts.removal = ana
        accounts.confirmRemoval()
        #expect(accounts.accounts.isEmpty)
        #expect(accounts.isEmpty)
        #expect(accounts.removal == nil)
    }

    @Test func offersTwoFilledExamples() throws {
        let accounts = AccountsModel(vault: InMemoryAccountVault(), defaults: defaults())
        #expect(accounts.examples.count == 2)
        #expect(Set(accounts.examples.map(\.storefront)).count == 2)
    }
}
