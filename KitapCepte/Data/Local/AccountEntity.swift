import Foundation
import SwiftData

@Model
final class AccountEntity {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var email: String
    var name: String
    var passwordHash: String
    var salt: String
    var createdAt: Date

    init(id: UUID = UUID(), name: String, email: String, passwordHash: String, salt: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.email = email
        self.passwordHash = passwordHash
        self.salt = salt
        self.createdAt = createdAt
    }
}
