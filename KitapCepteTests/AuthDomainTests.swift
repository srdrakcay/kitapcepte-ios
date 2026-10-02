import Testing
@testable import KitapCepte

struct AuthValidatorTests {
    @Test(arguments: ["a@b.co", " A@B.CO ", "user.name@mail.example.com"])
    func acceptsValidEmails(email: String) {
        #expect(AuthValidator.isValidEmail(email))
    }

    @Test(arguments: ["", "abc", "a@b", "@b.co", "a@.co", "a@b.", "a b@c.de", "a@@b.co"])
    func rejectsInvalidEmails(email: String) {
        #expect(!AuthValidator.isValidEmail(email))
    }

    @Test func normalizesEmail() {
        #expect(AuthValidator.normalizedEmail("  Ada@Mail.COM ") == "ada@mail.com")
    }

    @Test func loginFlagsEmptyPasswordAndBadEmail() {
        #expect(AuthValidator.validateLogin(email: "x", password: "") == [.emailInvalid, .passwordEmpty])
        #expect(AuthValidator.validateLogin(email: "a@b.co", password: "1").isEmpty)
    }

    @Test func registrationFlagsEveryProblem() {
        let issues = AuthValidator.validateRegistration(name: " ", email: "x", password: "123", confirmation: "456")
        #expect(issues == [.nameEmpty, .emailInvalid, .passwordTooShort, .passwordMismatch])
    }

    @Test func registrationAcceptsValidInput() {
        let issues = AuthValidator.validateRegistration(name: "Ada", email: "a@b.co", password: "secret1", confirmation: "secret1")
        #expect(issues.isEmpty)
    }
}

@MainActor
struct AuthUseCaseTests {
    @Test func loginRejectsInvalidInputWithoutHittingRepository() async {
        let repo = FakeAuthRepository()
        let sut = LoginUseCase(repository: repo)
        await #expect(throws: AuthError.invalidInput([.emailInvalid, .passwordEmpty])) {
            try await sut(email: "bad", password: "")
        }
        #expect(repo.lastLoginEmail == nil)
    }

    @Test func loginNormalizesEmail() async throws {
        let repo = FakeAuthRepository()
        _ = try await LoginUseCase(repository: repo)(email: " Ada@B.co ", password: "x")
        #expect(repo.lastLoginEmail == "ada@b.co")
    }

    @Test func registerTrimsName() async throws {
        let repo = FakeAuthRepository()
        _ = try await RegisterUseCase(repository: repo)(name: "  Ada ", email: "a@b.co", password: "secret1", confirmation: "secret1")
        #expect(repo.lastRegisterName == "Ada")
    }

    @Test func registerRejectsMismatchedPasswords() async {
        let sut = RegisterUseCase(repository: FakeAuthRepository())
        await #expect(throws: AuthError.invalidInput([.passwordMismatch])) {
            try await sut(name: "Ada", email: "a@b.co", password: "secret1", confirmation: "secret2")
        }
    }
}

@MainActor
struct SessionManagerTests {
    @Test func startsRestoringWithNoSession() {
        let sut = SessionManager(repository: FakeAuthRepository())
        #expect(sut.isRestoring)
        #expect(sut.session == .none)
    }

    @Test func restoreLogsInStoredUser() async {
        let repo = FakeAuthRepository()
        repo.restoredUser = .sample
        let sut = SessionManager(repository: repo)
        await sut.restore()
        #expect(sut.session == .loggedIn(.sample))
        #expect(!sut.isRestoring)
        #expect(sut.isLoggedIn)
    }

    @Test func restoreWithoutStoredUserStaysSignedOut() async {
        let sut = SessionManager(repository: FakeAuthRepository())
        await sut.restore()
        #expect(sut.session == .none)
        #expect(!sut.isRestoring)
    }

    @Test func guestIsNotLoggedIn() {
        let sut = SessionManager(repository: FakeAuthRepository())
        sut.continueAsGuest()
        #expect(sut.session == .guest)
        #expect(!sut.isLoggedIn)
        #expect(sut.currentUser == nil)
    }

    @Test func signOutReturnsToWelcomeNotLogin() async {
        let sut = SessionManager(repository: FakeAuthRepository())
        sut.continueAsGuest()
        sut.leaveGuest()
        #expect(sut.opensLoginDirectly)
        await sut.signOut()
        #expect(!sut.opensLoginDirectly)
    }

    @Test func continuingAsGuestResetsLoginShortcut() {
        let sut = SessionManager(repository: FakeAuthRepository())
        sut.leaveGuest()
        sut.continueAsGuest()
        #expect(!sut.opensLoginDirectly)
    }

    @Test func signOutClearsSessionAndRepository() async {
        let repo = FakeAuthRepository()
        let sut = SessionManager(repository: repo)
        sut.signedIn(.sample)
        await sut.signOut()
        #expect(sut.session == .none)
        #expect(repo.logoutCount == 1)
    }
}

@MainActor
struct GuestGateTests {
    @Test func runsActionWhenLoggedIn() {
        let session = SessionManager(repository: FakeAuthRepository())
        session.signedIn(.sample)
        let sut = GuestGate(sessionManager: session)
        var ran = false
        sut.require { ran = true }
        #expect(ran)
        #expect(!sut.isSheetPresented)
    }

    @Test func showsSheetForGuest() {
        let session = SessionManager(repository: FakeAuthRepository())
        session.continueAsGuest()
        let sut = GuestGate(sessionManager: session)
        var ran = false
        sut.require { ran = true }
        #expect(!ran)
        #expect(sut.isSheetPresented)
    }

    @Test func signUpDismissesSheetAndLeavesGuestMode() {
        let session = SessionManager(repository: FakeAuthRepository())
        session.continueAsGuest()
        let sut = GuestGate(sessionManager: session)
        sut.require {}
        sut.proceedToSignUp()
        #expect(!sut.isSheetPresented)
        #expect(session.session == .none)
        #expect(session.opensLoginDirectly)
    }
}

@MainActor
struct RootViewModelTests {
    private func makeSUT(seen: Bool, repo: FakeAuthRepository = FakeAuthRepository()) -> (RootViewModel, SessionManager) {
        let session = SessionManager(repository: repo)
        return (RootViewModel(onboardingRepository: FakeOnboardingRepository(hasSeen: seen), sessionManager: session), session)
    }

    @Test func showsOnboardingOnFirstLaunch() {
        #expect(makeSUT(seen: false).0.route == .onboarding)
    }

    @Test func waitsForSessionRestoreAfterOnboarding() {
        #expect(makeSUT(seen: true).0.route == .launching)
    }

    @Test func showsAuthWhenNoSession() async {
        let (sut, session) = makeSUT(seen: true)
        await session.restore()
        #expect(sut.route == .auth)
    }

    @Test func showsMainForGuestAndUser() async {
        let (sut, session) = makeSUT(seen: true)
        await session.restore()
        session.continueAsGuest()
        #expect(sut.route == .main)
        session.signedIn(.sample)
        #expect(sut.route == .main)
    }

    @Test func movesPastOnboardingWhenCompleted() {
        let (sut, _) = makeSUT(seen: false)
        sut.onboardingCompleted()
        #expect(sut.route == .launching)
    }
}
