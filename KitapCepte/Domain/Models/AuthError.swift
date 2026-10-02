enum AuthError: Error, Equatable, Sendable {
    case invalidCredentials
    case emailAlreadyRegistered
    case invalidInput([ValidationIssue])
}
