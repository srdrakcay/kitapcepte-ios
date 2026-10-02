import Foundation
import Observation

/// Kart bilgileri YALNIZCA bu ViewModel'in belleğinde yaşar; ödeme bitince/ekrandan çıkınca temizlenir.
@MainActor @Observable
final class PaymentViewModel {
    enum Phase: Equatable {
        case editing
        case paying
        case paid(PaymentReceipt)
    }

    struct State: Equatable {
        var card = PaymentCard.empty
        var saveCard = false
        var phase = Phase.editing
        /// Hatası gösterilecek alanlar (alan terk edilince veya Öde'ye basılınca eklenir).
        var touched: Set<CardField> = []
        var formError: String?
    }

    enum Action {
        case numberChanged(String)
        case holderChanged(String)
        case expiryChanged(String)
        case cvvChanged(String)
        case saveCardChanged(Bool)
        case fieldLeft(CardField)
        case dismissError
    }

    private(set) var state = State()
    private let pay: PayUseCase
    private let cart: CartStore
    private let validator: CardValidator
    private var payTask: Task<Void, Never>?

    init(pay: PayUseCase, cart: CartStore) {
        self.pay = pay
        self.cart = cart
        self.validator = pay.validator
    }

    // MARK: Türetilmiş durum

    var brand: CardBrand { state.card.brand }
    var isPaying: Bool { state.phase == .paying }
    var isCartEmpty: Bool { cart.items.isEmpty }
    var total: Decimal { CartPricing.summary(for: cart.items).total }
    /// Çift dokunma ve boş sepete karşı koruma.
    var canPay: Bool { state.phase == .editing && !isCartEmpty }

    var receipt: PaymentReceipt? {
        if case .paid(let receipt) = state.phase { receipt } else { nil }
    }

    /// Yalnızca kullanıcının terk ettiği (veya Öde'ye basılan) alanların hataları.
    var errors: [CardField: CardIssue] {
        validator.validate(state.card).filter { state.touched.contains($0.key) }
    }

    var preview: CardPreviewContent { CardPreviewContent(card: state.card) }

    // MARK: Aksiyonlar

    func send(_ action: Action) {
        guard state.phase == .editing else { return }
        switch action {
        case .numberChanged(let value):
            state.formError = nil
            state.card.number = CardFormatter.digits(CardFormatter.formatNumber(value))
            // Marka değişince CVV uzunluğu da değişir.
            state.card.cvv = CardFormatter.formatCvv(state.card.cvv, brand: brand)
        case .holderChanged(let value):
            state.formError = nil
            state.card.holderName = CardFormatter.formatHolder(value)
        case .expiryChanged(let value):
            state.formError = nil
            state.card.expiry = CardFormatter.formatExpiry(value)
        case .cvvChanged(let value):
            state.formError = nil
            state.card.cvv = CardFormatter.formatCvv(value, brand: brand)
        case .saveCardChanged(let isOn):
            state.saveCard = isOn
        case .fieldLeft(let field):
            state.touched.insert(field)
        case .dismissError:
            state.formError = nil
        }
    }

    /// Ekrandaki girdi alanlarının metni (numara gruplu gösterilir).
    var displayNumber: String { CardFormatter.formatNumber(state.card.number) }

    /// Ödemeyi başlatır; ekrandan çıkılırsa `leave()` iptal eder.
    func startPayment() {
        guard canPay, payTask == nil else { return }
        payTask = Task { await submit() }
    }

    func submit() async {
        guard canPay else { return }
        state.touched = Set(CardField.allCases)
        state.formError = nil
        guard validator.validate(state.card).isEmpty else { return }
        state.phase = .paying
        defer { payTask = nil }
        do {
            let receipt = try await pay(card: state.card, saveCard: state.saveCard)
            clearSensitiveData()
            state.phase = .paid(receipt)
        } catch is CancellationError {
            state.phase = .editing
        } catch let error as PaymentError {
            state.phase = .editing
            fail(with: error)
        } catch {
            state.phase = .editing
            state.formError = Strings.Payment.failed
        }
    }

    /// Ekrandan ayrılma: sürmekte olan ödemeyi iptal eder, hassas veriyi bellekten siler.
    func leave() {
        payTask?.cancel()
        payTask = nil
        clearSensitiveData()
    }

    private func fail(with error: PaymentError) {
        switch error {
        case .declined: state.formError = Strings.Payment.declined
        case .invalidCard: state.touched = Set(CardField.allCases)
        case .emptyCart, .failed: state.formError = Strings.Payment.failed
        }
    }

    private func clearSensitiveData() {
        state.card = .empty
        state.touched = []
    }
}

/// Kart önizlemesinde gösterilecek hazır metinler.
struct CardPreviewContent: Equatable {
    let brandName: String
    let numberText: String
    let holderText: String
    let expiryText: String
    let accessibilityText: String

    private static let mask: Character = "•"

    init(card: PaymentCard) {
        let brand = card.brand
        let sizes = brand.groupSizes
        // Girilmemiş haneler maske karakteriyle gösterilir.
        let padded = card.number + String(repeating: Self.mask, count: max(0, brand.numberLength - card.number.count))
        brandName = brand.title
        numberText = CardFormatter.group(padded, sizes: sizes)
        let holder = card.holderName.trimmingCharacters(in: .whitespacesAndNewlines)
        holderText = holder.isEmpty ? Strings.Payment.holderPlaceholder : holder.uppercased()
        expiryText = card.expiry.isEmpty ? Strings.Payment.expiryPlaceholder : card.expiry
        // Numara tek tek okunmaz: yalnızca marka ve (tamamlandıysa) son dört hane.
        accessibilityText = card.number.count == brand.numberLength
            ? Strings.Payment.previewA11yLast4(brand: brand.title, last4: card.last4)
            : Strings.Payment.previewA11y(brand: brand.title)
    }
}
