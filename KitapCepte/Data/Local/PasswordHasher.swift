import CryptoKit
import Foundation

/// Tuzlu SHA-256. Yerel mock hesap sistemi içindir; gerçek backend'de sunucu tarafı hash kullanılır.
enum PasswordHasher {
    private static let saltByteCount = 16

    static func makeSalt() -> String {
        (0..<saltByteCount).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max)) }.joined()
    }

    static func hash(_ password: String, salt: String) -> String {
        SHA256.hash(data: Data((salt + password).utf8)).map { String(format: "%02x", $0) }.joined()
    }

    static func verify(_ password: String, salt: String, hash expected: String) -> Bool {
        hash(password, salt: salt) == expected
    }
}
