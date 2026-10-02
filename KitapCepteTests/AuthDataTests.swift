import Foundation
import SwiftData
import Testing
@testable import KitapCepte

struct PasswordHasherTests {
    @Test func verifiesCorrectPasswordOnly() {
        let salt = PasswordHasher.makeSalt()
        let hash = PasswordHasher.hash("secret1", salt: salt)
        #expect(PasswordHasher.verify("secret1", salt: salt, hash: hash))
        #expect(!PasswordHasher.verify("secret2", salt: salt, hash: hash))
    }

    @Test func saltsDifferAndHashDoesNotContainPassword() {
        #expect(PasswordHasher.makeSalt() != PasswordHasher.makeSalt())
        #expect(!PasswordHasher.hash("secret1", salt: "s").contains("secret1"))
    }
}

struct KeychainStoreTests {
    @Test func roundTripsAndRemovesValue() throws {
        let sut = KeychainStore(service: "test.\(UUID().uuidString)")
        try sut.set("value", for: "key")
        #expect(sut.get("key") == "value")
        try sut.set("updated", for: "key")
        #expect(sut.get("key") == "updated")
        sut.remove("key")
        #expect(sut.get("key") == nil)
    }
}

@MainActor
struct SwiftDataAuthRepositoryTests {
    /// ModelContainer, context'ten uzun yaşamalıdır; bu yüzden birlikte tutulur.
    private struct Harness {
        let container: ModelContainer
        let sut: SwiftDataAuthRepository
    }

    private func makeHarness(store: SecureStore = InMemorySecureStore()) throws -> Harness {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AccountEntity.self, configurations: config)
        return Harness(container: container, sut: SwiftDataAuthRepository(context: container.mainContext, secureStore: store))
    }

    @Test func registerThenLoginWithSameCredentials() async throws {
        let h = try makeHarness()
        let user = try await h.sut.register(name: "Ada", email: "ada@b.co", password: "secret1")
        let loggedIn = try await h.sut.login(email: "ada@b.co", password: "secret1")
        #expect(loggedIn == user)
        #expect(user.name == "Ada")
    }

    @Test func duplicateEmailIsRejected() async throws {
        let h = try makeHarness()
        _ = try await h.sut.register(name: "Ada", email: "ada@b.co", password: "secret1")
        await #expect(throws: AuthError.emailAlreadyRegistered) {
            try await h.sut.register(name: "Other", email: "ada@b.co", password: "secret2")
        }
    }

    @Test func wrongPasswordAndUnknownEmailAreInvalidCredentials() async throws {
        let h = try makeHarness()
        _ = try await h.sut.register(name: "Ada", email: "ada@b.co", password: "secret1")
        await #expect(throws: AuthError.invalidCredentials) { try await h.sut.login(email: "ada@b.co", password: "nope") }
        await #expect(throws: AuthError.invalidCredentials) { try await h.sut.login(email: "x@b.co", password: "secret1") }
    }

    @Test func restoresSessionAfterRegisterAndClearsOnLogout() async throws {
        let h = try makeHarness()
        let user = try await h.sut.register(name: "Ada", email: "ada@b.co", password: "secret1")
        #expect(await h.sut.restoreSession() == user)
        await h.sut.logout()
        #expect(await h.sut.restoreSession() == nil)
    }

    @Test func restoreIgnoresUnknownStoredId() async throws {
        let store = InMemorySecureStore()
        try store.set(UUID().uuidString, for: SwiftDataAuthRepository.sessionKey)
        let h = try makeHarness(store: store)
        #expect(await h.sut.restoreSession() == nil)
        #expect(store.get(SwiftDataAuthRepository.sessionKey) == nil)
    }

    @Test func storesHashedPasswordNotPlainText() async throws {
        let h = try makeHarness()
        _ = try await h.sut.register(name: "Ada", email: "ada@b.co", password: "secret1")
        let entity = try #require(try h.container.mainContext.fetch(FetchDescriptor<AccountEntity>()).first)
        #expect(entity.passwordHash != "secret1")
        #expect(!entity.salt.isEmpty)
    }
}
