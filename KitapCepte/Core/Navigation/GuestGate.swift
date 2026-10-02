import Observation

/// Kısıtlı aksiyonların tek kontrol noktası: üyeyse çalıştırır, değilse "üye ol" sheet'ini açar.
@MainActor @Observable
final class GuestGate {
    var isSheetPresented = false
    private let sessionManager: SessionManager

    init(sessionManager: SessionManager) {
        self.sessionManager = sessionManager
    }

    func require(_ action: () -> Void) {
        if sessionManager.isLoggedIn {
            action()
        } else {
            isSheetPresented = true
        }
    }

    func proceedToSignUp() {
        isSheetPresented = false
        sessionManager.leaveGuest()
    }

    func dismiss() {
        isSheetPresented = false
    }
}
