/// Yerel (mock) hesap sistemi; ileride gerçek backend ile değiştirilebilir.
@MainActor
protocol AuthRepository: AnyObject {
    func register(name: String, email: String, password: String) async throws -> User
    func login(email: String, password: String) async throws -> User
    func restoreSession() async -> User?
    func logout() async
}
