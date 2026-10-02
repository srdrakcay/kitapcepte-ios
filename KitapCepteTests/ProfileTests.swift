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
        savedCards: SavedCardsStore = SavedCardsStore(repository: FakeSavedCardRepository()),
        onSignOut: @escaping () -> Void = {}
    ) -> ProfileViewModel {
        ProfileViewModel(
            userProvider: { user },
            changePassword: ChangePasswordUseCase(repository: repo),
            savedCards: savedCards,
            dateProvider: FixedDateProvider(year: 2030, month: 6),
            calendar: FixedDateProvider.calendar,
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

@MainActor
struct ProfileSavedCardsTests {
    private static let visa = PaymentCardSummary(brand: .visa, last4: "4242", holderName: "Ada Lovelace", expiryMonth: 12, expiryYear: 2032)
    private static let expired = PaymentCardSummary(brand: .mastercard, last4: "4444", holderName: "Ada Lovelace", expiryMonth: 5, expiryYear: 2030)

    private func makeSUT(
        cards: [PaymentCardSummary] = [],
        repo: FakeSavedCardRepository? = nil
    ) async -> (sut: ProfileViewModel, store: SavedCardsStore, repo: FakeSavedCardRepository) {
        let repo = repo ?? FakeSavedCardRepository(cards: cards)
        let store = SavedCardsStore(repository: repo)
        await store.reload()
        let sut = ProfileViewModel(
            userProvider: { .sample },
            changePassword: ChangePasswordUseCase(repository: FakeAuthRepository()),
            savedCards: store,
            dateProvider: FixedDateProvider(year: 2030, month: 6),
            calendar: FixedDateProvider.calendar,
            signOut: {}
        )
        return (sut, store, repo)
    }

    @Test func listsRowsWithMaskedLast4AndExpiry() async throws {
        let (sut, _, _) = await makeSUT(cards: [Self.visa])
        let row = try #require(sut.cardRows.first)
        #expect(row.brandName == CardBrand.visa.title)
        #expect(row.maskedNumber == "•••• 4242")
        #expect(row.holderText == "ADA LOVELACE")
        #expect(row.expiryText == Strings.Profile.cardExpiry("12/32"))
        #expect(row.isExpired == false)
    }

    @Test func emptyStoreHasNoRows() async {
        let (sut, _, _) = await makeSUT()
        #expect(sut.cardRows.isEmpty)
    }

    @Test func pastExpiryIsFlaggedButCurrentMonthIsNot() async {
        let current = PaymentCardSummary(brand: .visa, last4: "1111", holderName: "A", expiryMonth: 6, expiryYear: 2030)
        let (sut, _, _) = await makeSUT(cards: [Self.expired, current])
        #expect(sut.cardRows.map(\.isExpired) == [true, false])
        #expect(sut.cardRows.first?.accessibilityText.contains(Strings.Profile.cardExpired) == true)
    }

    @Test func deleteConfirmedRemovesCard() async {
        let (sut, _, repo) = await makeSUT(cards: [Self.visa, Self.expired])
        sut.send(.cardDeleteRequested(Self.visa.id))
        #expect(sut.pendingCardDeletionID == Self.visa.id)
        await sut.confirmCardDeletion()
        #expect(sut.cardRows.map(\.id) == [Self.expired.id])
        #expect(repo.stored.count == 1)
        #expect(sut.pendingCardDeletionID == nil)
        #expect(sut.state.cardError == nil)
    }

    @Test func deleteCancelledKeepsCard() async {
        let (sut, _, repo) = await makeSUT(cards: [Self.visa])
        sut.send(.cardDeleteRequested(Self.visa.id))
        sut.send(.cardDeleteCancelled)
        await sut.confirmCardDeletion()
        #expect(sut.pendingCardDeletionID == nil)
        #expect(sut.cardRows.count == 1)
        #expect(repo.stored.count == 1)
    }

    @Test func deleteFailureShowsErrorAndKeepsCard() async {
        let (sut, _, repo) = await makeSUT(cards: [Self.visa])
        repo.shouldFail = true
        sut.send(.cardDeleteRequested(Self.visa.id))
        await sut.confirmCardDeletion()
        #expect(sut.state.cardError == Strings.Profile.cardDeleteError)
        #expect(sut.cardRows.count == 1)
        sut.send(.cardDeleteRequested(Self.visa.id))
        #expect(sut.state.cardError == nil)
    }

    @Test func newlySavedCardAppearsImmediately() async throws {
        let (sut, store, _) = await makeSUT()
        try await store.save(Self.visa)
        #expect(sut.cardRows.count == 1)
    }

    @Test func rowsClearWhenUserChanges() async {
        let (sut, store, repo) = await makeSUT(cards: [Self.visa])
        sut.send(.cardDeleteRequested(Self.visa.id))
        repo.replaceAll(with: [])   // yeni kullanıcının kartı yok
        await store.reload()
        #expect(sut.cardRows.isEmpty)
        #expect(sut.pendingCardDeletionID == nil)
    }
}

struct SavedCardRowContentTests {
    @Test func expiryStringIsZeroPaddedTwoDigitYear() {
        #expect(SavedCardRowContent.expiryString(month: 3, year: 2031) == "03/31")
    }

    @Test func maskedNumberShowsOnlyLast4() {
        let summary = PaymentCardSummary(brand: .amex, last4: "0005", holderName: "ada", expiryMonth: 1, expiryYear: 2040)
        let content = SavedCardRowContent(summary: summary, isExpired: false)
        #expect(content.maskedNumber == "•••• 0005")
        #expect(content.holderText == "ADA")
        #expect(!content.accessibilityText.contains("••"))
    }
}
