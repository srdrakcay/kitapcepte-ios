import Foundation

enum ValidationIssue: Hashable, Sendable {
    case nameEmpty
    case emailInvalid
    case passwordEmpty
    case passwordTooShort
    case passwordMismatch
}

enum AuthValidator {
    static let minPasswordLength = 6

    static func normalizedEmail(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func isValidEmail(_ email: String) -> Bool {
        let parts = normalizedEmail(email).split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[0].contains(" ") else { return false }
        let domain = parts[1]
        guard !domain.contains(" "), domain.contains("."), !domain.hasPrefix("."), !domain.hasSuffix(".") else { return false }
        return true
    }

    static func validateLogin(email: String, password: String) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if !isValidEmail(email) { issues.append(.emailInvalid) }
        if password.isEmpty { issues.append(.passwordEmpty) }
        return issues
    }

    static func validateRegistration(name: String, email: String, password: String, confirmation: String) -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { issues.append(.nameEmpty) }
        if !isValidEmail(email) { issues.append(.emailInvalid) }
        if password.count < minPasswordLength { issues.append(.passwordTooShort) }
        if password != confirmation { issues.append(.passwordMismatch) }
        return issues
    }
}
