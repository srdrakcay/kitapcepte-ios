import Foundation

/// Ödeme simülasyonu sabitleri.
enum PaymentSimulation {
    /// Ağ gecikmesini taklit eden bekleme.
    static let delay: Duration = .seconds(1.5)
    /// Bu numara her zaman reddedilir (Luhn geçerli test kartı).
    static let declinedCardNumber = "4000000000000002"
    static let referencePrefix = "KC-"
    static let referenceLength = 8
}

/// Gerçek bir ödeme yapmaz: gecikme sonrası başarılı fiş döner, belirli test kartını reddeder.
struct SimulatedPaymentGateway: PaymentGateway {
    let delay: Duration
    let declinedNumber: String
    let dateProvider: DateProviding
    let makeReference: @Sendable () -> String

    init(
        delay: Duration = PaymentSimulation.delay,
        declinedNumber: String = PaymentSimulation.declinedCardNumber,
        dateProvider: DateProviding = SystemDateProvider(),
        makeReference: @escaping @Sendable () -> String = SimulatedPaymentGateway.randomReference
    ) {
        self.delay = delay
        self.declinedNumber = declinedNumber
        self.dateProvider = dateProvider
        self.makeReference = makeReference
    }

    func pay(amount: Decimal, card: PaymentCard) async throws -> PaymentReceipt {
        try Task.checkCancellation()
        try await Task.sleep(for: delay)
        try Task.checkCancellation()
        guard card.number != declinedNumber else { throw PaymentError.declined }
        return PaymentReceipt(
            reference: makeReference(), amount: amount,
            brand: card.brand, last4: card.last4, paidAt: dateProvider.now
        )
    }

    @Sendable static func randomReference() -> String {
        let code = UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(PaymentSimulation.referenceLength)
        return PaymentSimulation.referencePrefix + code
    }
}
