import Foundation
import SwiftData

@MainActor
final class SwiftDataAuthRepository: AuthRepository {
    static let sessionKey = "session.userId"

    private let context: ModelContext
    private let secureStore: SecureStore

    init(context: ModelContext, secureStore: SecureStore) {
        self.context = context
        self.secureStore = secureStore
    }

    func register(name: String, email: String, password: String) async throws -> User {
        guard try account(email: email) == nil else { throw AuthError.emailAlreadyRegistered }
        let salt = PasswordHasher.makeSalt()
        let entity = AccountEntity(
            name: name,
            email: email,
            passwordHash: PasswordHasher.hash(password, salt: salt),
            salt: salt
        )
        context.insert(entity)
        try context.save()
        try secureStore.set(entity.id.uuidString, for: Self.sessionKey)
        return AccountMapper.user(from: entity)
    }

    func login(email: String, password: String) async throws -> User {
        guard let entity = try account(email: email),
              PasswordHasher.verify(password, salt: entity.salt, hash: entity.passwordHash)
        else { throw AuthError.invalidCredentials }
        try secureStore.set(entity.id.uuidString, for: Self.sessionKey)
        return AccountMapper.user(from: entity)
    }

    func restoreSession() async -> User? {
        guard let raw = secureStore.get(Self.sessionKey), let id = UUID(uuidString: raw) else { return nil }
        let descriptor = FetchDescriptor<AccountEntity>(predicate: #Predicate { $0.id == id })
        guard let entity = try? context.fetch(descriptor).first else {
            secureStore.remove(Self.sessionKey)
            return nil
        }
        return AccountMapper.user(from: entity)
    }

    func logout() async {
        secureStore.remove(Self.sessionKey)
    }

    private func account(email: String) throws -> AccountEntity? {
        let descriptor = FetchDescriptor<AccountEntity>(predicate: #Predicate { $0.email == email })
        return try context.fetch(descriptor).first
    }
}
