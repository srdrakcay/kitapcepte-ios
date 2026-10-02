import Foundation
@testable import KitapCepte

/// `Fakes.swift`'e dokunmadan mevcut `FakeAuthRepository`'nin yeni protokol metodunu karşılaması için (kayıt tutmaz).
extension FakeAuthRepository {
    func changePassword(userID: UUID, current: String, new: String) async throws {}
}

/// Profil testleri için parola değişikliğini kaydeden/sonucunu belirleyen fake.
@MainActor
final class FakeProfileAuthRepository: AuthRepository {
    var changePasswordResult: Result<Void, Error> = .success(())
    private(set) var changeCalls: [(userID: UUID, current: String, new: String)] = []

    func register(name: String, email: String, password: String) async throws -> User { User.sample }
    func login(email: String, password: String) async throws -> User { User.sample }
    func restoreSession() async -> User? { nil }
    func logout() async {}

    func changePassword(userID: UUID, current: String, new: String) async throws {
        changeCalls.append((userID, current, new))
        try changePasswordResult.get()
    }
}
