import Foundation
import SwiftData
import Testing
@testable import KitapCepte

@MainActor
struct ChangePasswordRepositoryTests {
    private struct Harness {
        let container: ModelContainer
        let sut: SwiftDataAuthRepository
        let user: User
    }

    private func makeHarness() async throws -> Harness {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: AccountEntity.self, configurations: config)
        let sut = SwiftDataAuthRepository(context: container.mainContext, secureStore: InMemorySecureStore())
        let user = try await sut.register(name: "Ada", email: "ada@b.co", password: "secret1")
        return Harness(container: container, sut: sut, user: user)
    }

    private func entity(_ h: Harness) throws -> AccountEntity {
        try #require(try h.container.mainContext.fetch(FetchDescriptor<AccountEntity>()).first)
    }

    @Test func oldPasswordStopsWorkingAndNewPasswordLogsIn() async throws {
        let h = try await makeHarness()
        try await h.sut.changePassword(userID: h.user.id, current: "secret1", new: "newsecret")
        await #expect(throws: AuthError.invalidCredentials) { try await h.sut.login(email: "ada@b.co", password: "secret1") }
        let loggedIn = try await h.sut.login(email: "ada@b.co", password: "newsecret")
        #expect(loggedIn == h.user)
    }

    @Test func wrongCurrentPasswordIsInvalidCredentialsAndKeepsOldPassword() async throws {
        let h = try await makeHarness()
        await #expect(throws: AuthError.invalidCredentials) {
            try await h.sut.changePassword(userID: h.user.id, current: "wrong", new: "newsecret")
        }
        _ = try await h.sut.login(email: "ada@b.co", password: "secret1")
    }

    @Test func unknownUserIsInvalidCredentials() async throws {
        let h = try await makeHarness()
        await #expect(throws: AuthError.invalidCredentials) {
            try await h.sut.changePassword(userID: UUID(), current: "secret1", new: "newsecret")
        }
    }

    @Test func hashAndSaltAreRenewedAndPlainTextIsNotStored() async throws {
        let h = try await makeHarness()
        let before = try entity(h)
        let (oldHash, oldSalt) = (before.passwordHash, before.salt)
        try await h.sut.changePassword(userID: h.user.id, current: "secret1", new: "newsecret")
        let after = try entity(h)
        #expect(after.passwordHash != oldHash)
        #expect(after.salt != oldSalt)
        #expect(after.passwordHash != "newsecret")
        #expect(PasswordHasher.verify("newsecret", salt: after.salt, hash: after.passwordHash))
    }
}

struct PasswordChangeValidatorTests {
    @Test func validInputHasNoIssues() {
        #expect(PasswordChangeValidator.validate(current: "secret1", new: "newsecret", confirmation: "newsecret").isEmpty)
    }

    @Test func reportsEmptyCurrentShortNewAndMismatch() {
        let issues = PasswordChangeValidator.validate(current: "", new: "abc", confirmation: "abd")
        #expect(issues.contains(.currentEmpty))
        #expect(issues.contains(.newTooShort))
        #expect(issues.contains(.confirmationMismatch))
    }

    @Test func newPasswordMustDifferFromCurrent() {
        let issues = PasswordChangeValidator.validate(current: "secret1", new: "secret1", confirmation: "secret1")
        #expect(issues == [.newSameAsCurrent])
    }
}

@MainActor
struct ChangePasswordUseCaseTests {
    @Test func invalidInputDoesNotReachRepository() async {
        let repo = FakeAuthRepository()
        let sut = ChangePasswordUseCase(repository: repo)
        await #expect(throws: ChangePasswordError.invalidInput([.newTooShort, .confirmationMismatch])) {
            try await sut(userID: UUID(), current: "secret1", new: "abc", confirmation: "abd")
        }
        #expect(repo.changeCalls.isEmpty)
    }

    @Test func validInputCallsRepositoryOnce() async throws {
        let repo = FakeAuthRepository()
        let sut = ChangePasswordUseCase(repository: repo)
        let id = UUID()
        try await sut(userID: id, current: "secret1", new: "newsecret", confirmation: "newsecret")
        #expect(repo.changeCalls.count == 1)
        #expect(repo.changeCalls.first?.userID == id)
        #expect(repo.changeCalls.first?.new == "newsecret")
    }

    @Test func repositoryErrorIsPropagated() async {
        let repo = FakeAuthRepository()
        repo.changePasswordResult = .failure(AuthError.invalidCredentials)
        let sut = ChangePasswordUseCase(repository: repo)
        await #expect(throws: AuthError.invalidCredentials) {
            try await sut(userID: UUID(), current: "secret1", new: "newsecret", confirmation: "newsecret")
        }
    }
}

@MainActor
struct ProfileViewModelTests {
    private func makeSUT(
        repo: FakeAuthRepository = FakeAuthRepository(),
        user: User? = .sample,
        onSignOut: @escaping () -> Void = {}
    ) -> ProfileViewModel {
        ProfileViewModel(
            userProvider: { user },
            changePassword: ChangePasswordUseCase(repository: repo),
            signOut: { onSignOut() }
        )
    }

    private func fill(_ sut: ProfileViewModel, current: String = "secret1", new: String = "newsecret", confirmation: String = "newsecret") {
        sut.send(.currentPasswordChanged(current))
        sut.send(.newPasswordChanged(new))
        sut.send(.confirmationChanged(confirmation))
    }

    @Test func exposesCurrentUserAndInitials() {
        let sut = makeSUT()
        #expect(sut.user == .sample)
        #expect(User.sample.initials == "AL")
        #expect(User(id: UUID(), name: "  ada  ", email: "a@b.co").initials == "A")
    }

    @Test func emptyFormShowsFieldErrors() async {
        let sut = makeSUT()
        await sut.submit()
        #expect(sut.state.errors[.currentPassword] == Strings.Profile.errorCurrentEmpty)
        #expect(sut.state.errors[.newPassword] == Strings.Profile.errorNewShort)
        #expect(sut.state.successMessage == nil)
    }

    @Test func mismatchedConfirmationShowsConfirmError() async {
        let sut = makeSUT()
        fill(sut, confirmation: "other")
        await sut.submit()
        #expect(sut.state.errors[.confirmPassword] == Strings.Profile.errorMismatch)
    }

    @Test func wrongCurrentPasswordShowsCurrentFieldError() async {
        let repo = FakeAuthRepository()
        repo.changePasswordResult = .failure(AuthError.invalidCredentials)
        let sut = makeSUT(repo: repo)
        fill(sut)
        await sut.submit()
        #expect(sut.state.errors[.currentPassword] == Strings.Profile.errorCurrentWrong)
        #expect(sut.state.successMessage == nil)
        #expect(!sut.state.isLoading)
    }

    @Test func unexpectedErrorBecomesFormError() async {
        let repo = FakeAuthRepository()
        repo.changePasswordResult = .failure(AppError.network)
        let sut = makeSUT(repo: repo)
        fill(sut)
        await sut.submit()
        #expect(sut.state.formError == AppError.unknown.message)
    }

    @Test func successClearsFormAndShowsMessage() async {
        let repo = FakeAuthRepository()
        let sut = makeSUT(repo: repo)
        fill(sut)
        await sut.submit()
        #expect(sut.state.successMessage == Strings.Profile.passwordSuccess)
        #expect(sut.state.currentPassword.isEmpty && sut.state.newPassword.isEmpty && sut.state.confirmation.isEmpty)
        #expect(sut.state.errors.isEmpty)
        #expect(repo.changeCalls.first?.userID == User.sample.id)
        #expect(!sut.state.isLoading)
    }

    @Test func editingFieldClearsItsErrorAndSuccessMessage() async {
        let sut = makeSUT()
        await sut.submit()
        sut.send(.currentPasswordChanged("a"))
        #expect(sut.state.errors[.currentPassword] == nil)
        #expect(sut.state.errors[.newPassword] != nil)
        fill(sut)
        await sut.submit()
        #expect(sut.state.successMessage != nil)
        sut.send(.newPasswordChanged("x"))
        #expect(sut.state.successMessage == nil)
    }

    @Test func submitWithoutUserDoesNothing() async {
        let repo = FakeAuthRepository()
        let sut = makeSUT(repo: repo, user: nil)
        fill(sut)
        await sut.submit()
        #expect(repo.changeCalls.isEmpty)
        #expect(sut.state.errors.isEmpty)
    }

    @Test func signOutRequiresConfirmation() async {
        var signOutCount = 0
        let sut = makeSUT(onSignOut: { signOutCount += 1 })
        sut.send(.signOutTapped)
        #expect(sut.state.isConfirmingSignOut)
        #expect(signOutCount == 0)
        sut.send(.signOutDismissed)
        #expect(!sut.state.isConfirmingSignOut)
        #expect(signOutCount == 0)
    }

    @Test func confirmingSignOutClosesSheetAndSignsOut() async {
        var signOutCount = 0
        let sut = makeSUT(onSignOut: { signOutCount += 1 })
        sut.send(.signOutTapped)
        await sut.confirmSignOut()
        #expect(!sut.state.isConfirmingSignOut)
        #expect(signOutCount == 1)
    }
}
