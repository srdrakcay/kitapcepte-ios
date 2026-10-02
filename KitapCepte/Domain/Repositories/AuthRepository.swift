import Foundation

/// Yerel (mock) hesap sistemi; ileride gerçek backend ile değiştirilebilir.
@MainActor
protocol AuthRepository: AnyObject {
    func register(name: String, email: String, password: String) async throws -> User
    func login(email: String, password: String) async throws -> User
    func restoreSession() async -> User?
    func logout() async
    /// Mevcut parola doğrulanır; yeni parola yeni tuzla hash'lenir. Yanlış mevcut parola: `AuthError.invalidCredentials`.
    func changePassword(userID: UUID, current: String, new: String) async throws
}
