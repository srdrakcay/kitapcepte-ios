import Observation

@MainActor @Observable
final class SessionManager {
    private(set) var session: Session = .none
    private(set) var isRestoring = true
    /// Misafir "üye ol" dediğinde Auth ekranı doğrudan giriş formuyla açılır.
    private(set) var opensLoginDirectly = false
    private let repository: AuthRepository

    init(repository: AuthRepository) {
        self.repository = repository
    }

    var isLoggedIn: Bool {
        if case .loggedIn = session { return true }
        return false
    }

    var currentUser: User? {
        if case .loggedIn(let user) = session { return user }
        return nil
    }

    func restore() async {
        if let user = await repository.restoreSession() {
            session = .loggedIn(user)
        }
        isRestoring = false
    }

    func signedIn(_ user: User) {
        session = .loggedIn(user)
    }

    func continueAsGuest() {
        opensLoginDirectly = false
        session = .guest
    }

    /// Misafir üyelik akışına girmek için oturumu sıfırlar (Auth ekranına, giriş formuyla döner).
    func leaveGuest() {
        opensLoginDirectly = true
        session = .none
    }

    func signOut() async {
        await repository.logout()
        opensLoginDirectly = false
        session = .none
    }
}
