import Foundation
import IPADomain
import IPAMock
import Testing

struct SimulatedStoreEngineTests {
    @Test func asksForTheCodeThenSavesTheAccount() async throws {
        let vault = InMemoryAccountVault()
        let engine = SimulatedStoreEngine(vault: vault, step: .zero)
        await #expect(throws: IPAError.codeRequired) {
            try await engine.signIn(SignInRequest(email: "2fa@example.com", password: "x"))
        }
        let account = try await engine.signIn(
            SignInRequest(email: "2fa@example.com", password: "x", code: "123456"))
        #expect(try vault.accounts() == [account])
    }

    @Test func refusesWhenTheEngineNeedsJIT() async {
        let engine = SimulatedStoreEngine(vault: InMemoryAccountVault(), availability: .needsJIT)
        await #expect(throws: IPAError.engine(.needsJIT)) {
            try await engine.versions(of: SampleApps.all[0], for: SampleApps.account)
        }
    }

    @Test func downloadsAFreeApp() async throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let engine = SimulatedStoreEngine(vault: InMemoryAccountVault(), step: .zero)
        let package = try await engine.download(
            DownloadRequest(
                app: SampleApps.all[0], account: SampleApps.account, externalVersionID: nil,
                destination: folder)
        ) { _ in }
        #expect(FileManager.default.fileExists(atPath: package.fileURL.path(percentEncoded: false)))
        #expect(package.version == SampleApps.all[0].version)
    }

    @Test func vaultKeepsOneIdentityUntilRegenerated() throws {
        let vault = InMemoryAccountVault()
        let first = try vault.identity()
        #expect(try vault.identity() == first)
        #expect(try vault.regenerateIdentity() != first)
    }
}
