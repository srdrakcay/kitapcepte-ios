import Foundation

enum ChangePasswordError: Error, Equatable, Sendable {
    case invalidInput([PasswordChangeIssue])
}

@MainActor
struct ChangePasswordUseCase {
    let repository: AuthRepository

    func callAsFunction(userID: UUID, current: String, new: String, confirmation: String) async throws {
        let issues = PasswordChangeValidator.validate(current: current, new: new, confirmation: confirmation)
        guard issues.isEmpty else { throw ChangePasswordError.invalidInput(issues) }
        try await repository.changePassword(userID: userID, current: current, new: new)
    }
}
