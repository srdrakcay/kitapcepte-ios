import Foundation
@testable import KitapCepte

struct FixedDateProvider: DateProviding {
    let now: Date

    /// Gregoryen takvimde, UTC saat 12:00.
    init(year: Int, month: Int, day: Int = 15) {
        var components = DateComponents(year: year, month: month, day: day, hour: 12)
        components.timeZone = TimeZone(identifier: "UTC")
        self.now = FixedDateProvider.calendar.date(from: components) ?? .distantPast
    }

    static var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }
}

extension CardValidator {
    /// "Şimdi" = Haziran 2030.
    static var fixed: CardValidator {
        CardValidator(dateProvider: FixedDateProvider(year: 2030, month: 6), calendar: FixedDateProvider.calendar)
    }
}

extension PaymentCard {
    static let validVisa = PaymentCard(number: "4242424242424242", holderName: "Ada Lovelace", expiry: "12/32", cvv: "123")
    static let declined = PaymentCard(number: PaymentSimulation.declinedCardNumber, holderName: "Ada Lovelace", expiry: "12/32", cvv: "123")
}

/// Çağrıları sayan, sonucu ayarlanabilen ödeme sağlayıcısı.
final class StubPaymentGateway: PaymentGateway, @unchecked Sendable {
    private let lock = NSLock()
    private var _calls: [(amount: Decimal, card: PaymentCard)] = []
    var result: Result<PaymentReceipt, any Error> = .success(StubPaymentGateway.receipt)
    var delay: Duration = .zero

    static let receipt = PaymentReceipt(reference: "KC-TEST", amount: 0, brand: .visa, last4: "4242", paidAt: .distantPast)

    var calls: [(amount: Decimal, card: PaymentCard)] { lock.withLock { _calls } }

    func pay(amount: Decimal, card: PaymentCard) async throws -> PaymentReceipt {
        lock.withLock { _calls.append((amount, card)) }
        if delay > .zero { try await Task.sleep(for: delay) }
        return try result.get()
    }
}

@MainActor
final class FakeSavedCardRepository: SavedCardRepository {
    private(set) var stored: [PaymentCardSummary]
    var shouldFail = false

    init(cards: [PaymentCardSummary] = []) {
        stored = cards
    }

    func cards() async -> [PaymentCardSummary] { stored }

    /// Kullanıcı değişimini taklit eder.
    func replaceAll(with cards: [PaymentCardSummary]) { stored = cards }

    func save(_ summary: PaymentCardSummary) async throws {
        if shouldFail { throw AppError.unknown }
        guard !stored.contains(where: { $0.isSameCard(as: summary) }) else { return }
        stored.append(summary)
    }

    func delete(id: UUID) async throws {
        if shouldFail { throw AppError.unknown }
        stored.removeAll { $0.id == id }
    }
}
