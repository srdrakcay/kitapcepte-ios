import Foundation

struct User: Equatable, Identifiable, Sendable {
    let id: UUID
    let name: String
    let email: String
}

enum Session: Equatable, Sendable {
    case none
    case guest
    case loggedIn(User)
}
