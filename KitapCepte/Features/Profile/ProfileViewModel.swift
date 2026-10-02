import Foundation
import Observation

enum ProfileField: Hashable {
    case currentPassword, newPassword, confirmPassword
}

extension PasswordChangeIssue {
    var field: ProfileField {
        switch self {
        case .currentEmpty: .currentPassword
        case .newTooShort, .newSameAsCurrent: .newPassword
        case .confirmationMismatch: .confirmPassword
        }
    }

    var message: String {
        switch self {
        case .currentEmpty: Strings.Profile.errorCurrentEmpty
        case .newTooShort: Strings.Profile.errorNewShort
        case .newSameAsCurrent: Strings.Profile.errorNewSame
        case .confirmationMismatch: Strings.Profile.errorMismatch
        }
    }
}

/// Şifre değiştirme hatalarını alan bazlı mesajlara çevirir; eşleşmeyen hata `formError` olur.
struct ProfileFailure: Equatable {
    var fieldErrors: [ProfileField: String] = [:]
    var formError: String?

    init(_ error: Error) {
        switch error {
        case ChangePasswordError.invalidInput(let issues):
            for issue in issues where fieldErrors[issue.field] == nil {
                fieldErrors[issue.field] = issue.message
            }
        case AuthError.invalidCredentials:
            fieldErrors[.currentPassword] = Strings.Profile.errorCurrentWrong
        default:
            formError = AppError.unknown.message
        }
    }
}

@MainActor @Observable
final class ProfileViewModel {
    struct State: Equatable {
        var currentPassword = ""
        var newPassword = ""
        var confirmation = ""
        var errors: [ProfileField: String] = [:]
        var formError: String?
        var successMessage: String?
        var isLoading = false
        var isConfirmingSignOut = false
    }

    enum Action {
        case currentPasswordChanged(String)
        case newPasswordChanged(String)
        case confirmationChanged(String)
        case signOutTapped
        case signOutDismissed
    }

    private(set) var state = State()
    private let userProvider: () -> User?
    private let changePassword: ChangePasswordUseCase
    private let signOut: () async -> Void

    init(userProvider: @escaping () -> User?, changePassword: ChangePasswordUseCase, signOut: @escaping () async -> Void) {
        self.userProvider = userProvider
        self.changePassword = changePassword
        self.signOut = signOut
    }

    var user: User? { userProvider() }

    func send(_ action: Action) {
        switch action {
        case .currentPasswordChanged(let value):
            state.currentPassword = value
            state.errors[.currentPassword] = nil
            clearFeedback()
        case .newPasswordChanged(let value):
            state.newPassword = value
            state.errors[.newPassword] = nil
            clearFeedback()
        case .confirmationChanged(let value):
            state.confirmation = value
            state.errors[.confirmPassword] = nil
            clearFeedback()
        case .signOutTapped:
            state.isConfirmingSignOut = true
        case .signOutDismissed:
            state.isConfirmingSignOut = false
        }
    }

    func submit() async {
        guard !state.isLoading, let user else { return }
        state.isLoading = true
        state.errors = [:]
        state.formError = nil
        state.successMessage = nil
        do {
            try await changePassword(
                userID: user.id, current: state.currentPassword,
                new: state.newPassword, confirmation: state.confirmation
            )
            state.currentPassword = ""
            state.newPassword = ""
            state.confirmation = ""
            state.successMessage = Strings.Profile.passwordSuccess
        } catch {
            let failure = ProfileFailure(error)
            state.errors = failure.fieldErrors
            state.formError = failure.formError
        }
        state.isLoading = false
    }

    func confirmSignOut() async {
        state.isConfirmingSignOut = false
        await signOut()
    }

    private func clearFeedback() {
        state.formError = nil
        state.successMessage = nil
    }
}
