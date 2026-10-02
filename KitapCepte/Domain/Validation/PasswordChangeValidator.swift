enum PasswordChangeIssue: Hashable, Sendable {
    case currentEmpty
    case newTooShort
    case newSameAsCurrent
    case confirmationMismatch
}

enum PasswordChangeValidator {
    static func validate(current: String, new: String, confirmation: String) -> [PasswordChangeIssue] {
        var issues: [PasswordChangeIssue] = []
        if current.isEmpty { issues.append(.currentEmpty) }
        if new.count < AuthValidator.minPasswordLength {
            issues.append(.newTooShort)
        } else if new == current {
            issues.append(.newSameAsCurrent)
        }
        if new != confirmation { issues.append(.confirmationMismatch) }
        return issues
    }
}
