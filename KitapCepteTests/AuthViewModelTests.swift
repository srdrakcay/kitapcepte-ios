import Testing
@testable import KitapCepte

@MainActor
struct LoginViewModelTests {
    private func makeSUT(repo: FakeAuthRepository = FakeAuthRepository()) -> (LoginViewModel, () -> User?) {
        var authenticated: User?
        let sut = LoginViewModel(login: LoginUseCase(repository: repo)) { authenticated = $0 }
        return (sut, { authenticated })
    }

    @Test func successfulLoginNotifiesAuthenticatedUser() async {
        let (sut, authenticated) = makeSUT()
        sut.send(.emailChanged("ada@example.com"))
        sut.send(.passwordChanged("secret1"))
        await sut.submit()
        #expect(authenticated() == .sample)
        #expect(!sut.state.isLoading)
    }

    @Test func invalidInputShowsFieldErrors() async {
        let (sut, authenticated) = makeSUT()
        await sut.submit()
        #expect(sut.state.errors[.email] == Strings.Validation.emailInvalid)
        #expect(sut.state.errors[.password] == Strings.Validation.passwordEmpty)
        #expect(authenticated() == nil)
    }

    @Test func wrongCredentialsShowPasswordError() async {
        let repo = FakeAuthRepository()
        repo.loginResult = .failure(AuthError.invalidCredentials)
        let (sut, _) = makeSUT(repo: repo)
        sut.send(.emailChanged("ada@example.com"))
        sut.send(.passwordChanged("wrong"))
        await sut.submit()
        #expect(sut.state.errors[.password] == Strings.Auth.invalidCredentials)
    }

    @Test func unexpectedErrorShowsFormError() async {
        let repo = FakeAuthRepository()
        repo.loginResult = .failure(AppError.network)
        let (sut, _) = makeSUT(repo: repo)
        sut.send(.emailChanged("ada@example.com"))
        sut.send(.passwordChanged("x"))
        await sut.submit()
        #expect(sut.state.formError == AppError.unknown.message)
    }

    @Test func editingFieldClearsItsError() async {
        let (sut, _) = makeSUT()
        await sut.submit()
        sut.send(.emailChanged("a"))
        #expect(sut.state.errors[.email] == nil)
        #expect(sut.state.errors[.password] != nil)
    }
}

@MainActor
struct RegisterViewModelTests {
    private func fill(_ sut: RegisterViewModel, confirmation: String = "secret1") {
        sut.send(.nameChanged("Ada"))
        sut.send(.emailChanged("ada@example.com"))
        sut.send(.passwordChanged("secret1"))
        sut.send(.confirmationChanged(confirmation))
    }

    private func makeSUT(repo: FakeAuthRepository = FakeAuthRepository()) -> (RegisterViewModel, () -> User?) {
        var authenticated: User?
        let sut = RegisterViewModel(register: RegisterUseCase(repository: repo)) { authenticated = $0 }
        return (sut, { authenticated })
    }

    @Test func successfulRegistrationNotifiesUser() async {
        let (sut, authenticated) = makeSUT()
        fill(sut)
        await sut.submit()
        #expect(authenticated() == .sample)
    }

    @Test func mismatchedPasswordsShowConfirmationError() async {
        let (sut, authenticated) = makeSUT()
        fill(sut, confirmation: "other")
        await sut.submit()
        #expect(sut.state.errors[.confirmPassword] == Strings.Validation.passwordMismatch)
        #expect(authenticated() == nil)
    }

    @Test func duplicateEmailShowsEmailError() async {
        let repo = FakeAuthRepository()
        repo.registerResult = .failure(AuthError.emailAlreadyRegistered)
        let (sut, _) = makeSUT(repo: repo)
        fill(sut)
        await sut.submit()
        #expect(sut.state.errors[.email] == Strings.Auth.emailTaken)
    }
}
