@MainActor
struct LoginUseCase {
    let repository: AuthRepository

    func callAsFunction(email: String, password: String) async throws -> User {
        let issues = AuthValidator.validateLogin(email: email, password: password)
        guard issues.isEmpty else { throw AuthError.invalidInput(issues) }
        return try await repository.login(email: AuthValidator.normalizedEmail(email), password: password)
    }
}

@MainActor
struct RegisterUseCase {
    let repository: AuthRepository

    func callAsFunction(name: String, email: String, password: String, confirmation: String) async throws -> User {
        let issues = AuthValidator.validateRegistration(name: name, email: email, password: password, confirmation: confirmation)
        guard issues.isEmpty else { throw AuthError.invalidInput(issues) }
        return try await repository.register(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            email: AuthValidator.normalizedEmail(email),
            password: password
        )
    }
}
