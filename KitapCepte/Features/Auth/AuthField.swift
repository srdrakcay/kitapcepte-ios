enum AuthField: Hashable {
    case name, email, password, confirmPassword
}

extension ValidationIssue {
    var field: AuthField {
        switch self {
        case .nameEmpty: .name
        case .emailInvalid: .email
        case .passwordEmpty, .passwordTooShort: .password
        case .passwordMismatch: .confirmPassword
        }
    }

    var message: String {
        switch self {
        case .nameEmpty: Strings.Validation.nameEmpty
        case .emailInvalid: Strings.Validation.emailInvalid
        case .passwordEmpty: Strings.Validation.passwordEmpty
        case .passwordTooShort: Strings.Validation.passwordShort
        case .passwordMismatch: Strings.Validation.passwordMismatch
        }
    }
}

/// Auth hatalarını alan bazlı mesajlara çevirir; eşleşmeyen hata `formError` olur.
struct AuthFailure: Equatable {
    var fieldErrors: [AuthField: String] = [:]
    var formError: String?

    init(_ error: Error) {
        switch error {
        case AuthError.invalidInput(let issues):
            for issue in issues where fieldErrors[issue.field] == nil {
                fieldErrors[issue.field] = issue.message
            }
        case AuthError.invalidCredentials:
            fieldErrors[.password] = Strings.Auth.invalidCredentials
        case AuthError.emailAlreadyRegistered:
            fieldErrors[.email] = Strings.Auth.emailTaken
        default:
            formError = AppError.unknown.message
        }
    }
}
