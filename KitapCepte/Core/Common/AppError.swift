import Foundation

enum AppError: Error, Equatable, Sendable {
    case network
    case decoding
    case notFound
    case validation(String)
    case unknown

    var message: String {
        switch self {
        case .network: Strings.Error.network
        case .decoding: Strings.Error.decoding
        case .notFound: Strings.Error.notFound
        case .validation(let reason): reason
        case .unknown: Strings.Error.unknown
        }
    }
}
