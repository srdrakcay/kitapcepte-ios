import Foundation
@testable import KitapCepte

final class InMemorySecureStore: SecureStore, @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String: String] = [:]

    func set(_ value: String, for key: String) throws { lock.withLock { storage[key] = value } }
    func get(_ key: String) -> String? { lock.withLock { storage[key] } }
    func remove(_ key: String) { lock.withLock { storage[key] = nil } }
}

@MainActor
final class FakeAuthRepository: AuthRepository {
    var registerResult: Result<User, Error> = .success(User.sample)
    var loginResult: Result<User, Error> = .success(User.sample)
    var restoredUser: User?
    private(set) var logoutCount = 0
    private(set) var lastLoginEmail: String?
    private(set) var lastRegisterName: String?

    func register(name: String, email: String, password: String) async throws -> User {
        lastRegisterName = name
        return try registerResult.get()
    }

    func login(email: String, password: String) async throws -> User {
        lastLoginEmail = email
        return try loginResult.get()
    }

    func restoreSession() async -> User? { restoredUser }
    func logout() async { logoutCount += 1 }
}

extension User {
    static let sample = User(id: UUID(), name: "Ada Lovelace", email: "ada@example.com")
}
