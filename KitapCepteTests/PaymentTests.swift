import Foundation
import SwiftData
import Testing
@testable import KitapCepte

// MARK: - Marka, doğrulama, biçimlendirme

struct CardBrandTests {
    @Test(arguments: [
        ("4242", CardBrand.visa), ("4", .visa), ("5555", .mastercard), ("51", .mastercard), ("55", .mastercard),
        ("2221", .mastercard), ("2720", .mastercard), ("2721", .unknown), ("222", .unknown),
        ("34", .amex), ("37", .amex), ("36", .unknown), ("9792", .troy), ("979", .unknown), ("", .unknown), ("6011", .unknown)
    ])
    func detectsBrandFromPrefix(digits: String, brand: CardBrand) {
        #expect(CardBrand.detect(from: digits) == brand)
    }

    @Test func amexHasFifteenDigitsAndFourDigitCvv() {
        #expect(CardBrand.amex.numberLength == 15)
        #expect(CardBrand.amex.cvvLength == 4)
        #expect(CardBrand.visa.numberLength == 16)
        #expect(CardBrand.visa.cvvLength == 3)
    }
}

struct CardValidatorTests {
    private let sut = CardValidator.fixed

    @Test(arguments: ["4242424242424242", "5555555555554444", "378282246310005", "9792000000000003", "2221000000000009"])
    func luhnAcceptsValidNumbers(number: String) {
        #expect(CardValidator.passesLuhn(number))
    }

    @Test(arguments: ["4242424242424241", "", "abcd", "1234567890123456"])
    func luhnRejectsInvalidNumbers(number: String) {
        #expect(!CardValidator.passesLuhn(number))
    }

    @Test func validCardsHaveNoIssues() {
        #expect(sut.validate(.validVisa).isEmpty)
        let amex = PaymentCard(number: "378282246310005", holderName: "Ada", expiry: "06/30", cvv: "1234")
        #expect(sut.validate(amex).isEmpty)
        let troy = PaymentCard(number: "9792000000000003", holderName: "Ada", expiry: "07/30", cvv: "123")
        #expect(sut.validate(troy).isEmpty)
    }

    @Test func numberMustMatchBrandLengthAndLuhn() {
        var card = PaymentCard.validVisa
        card.number = "424242424242424" // 15 hane
        #expect(sut.validate(card)[.number] == .numberInvalid)
        card.number = "4242424242424241" // Luhn hatalı
        #expect(sut.validate(card)[.number] == .numberInvalid)
        card.number = "" // boş
        #expect(sut.validate(card)[.number] == .numberInvalid)
    }

    @Test func expiryBoundaries() {
        var card = PaymentCard.validVisa
        card.expiry = "06/30" // şimdi: bu ay geçerli
        #expect(sut.validate(card)[.expiry] == nil)
        card.expiry = "05/30" // geçen ay
        #expect(sut.validate(card)[.expiry] == .expiryExpired)
        card.expiry = "12/29" // geçen yıl
        #expect(sut.validate(card)[.expiry] == .expiryExpired)
        card.expiry = "13/31"
        #expect(sut.validate(card)[.expiry] == .expiryInvalid)
        card.expiry = "00/31"
        #expect(sut.validate(card)[.expiry] == .expiryInvalid)
        card.expiry = "1/3"
        #expect(sut.validate(card)[.expiry] == .expiryInvalid)
        card.expiry = "06/51" // 20 yıldan ileri
        #expect(sut.validate(card)[.expiry] == .expiryInvalid)
        card.expiry = "06/50"
        #expect(sut.validate(card)[.expiry] == nil)
    }

    @Test func cvvLengthDependsOnBrand() {
        var visa = PaymentCard.validVisa
        visa.cvv = "1234"
        #expect(sut.validate(visa)[.cvv] == .cvvInvalid)
        visa.cvv = "12"
        #expect(sut.validate(visa)[.cvv] == .cvvInvalid)
        var amex = PaymentCard(number: "378282246310005", holderName: "Ada", expiry: "06/30", cvv: "123")
        #expect(sut.validate(amex)[.cvv] == .cvvInvalid)
        amex.cvv = "1234"
        #expect(sut.validate(amex)[.cvv] == nil)
    }

    @Test func holderNameMustNotBeBlank() {
        var card = PaymentCard.validVisa
        card.holderName = "   "
        #expect(sut.validate(card)[.holder] == .holderEmpty)
    }

    @Test func emptyFormReportsEveryField() {
        #expect(Set(sut.validate(.empty).keys) == Set(CardField.allCases))
    }
}

struct CardFormatterTests {
    @Test func groupsNumberInFours() {
        #expect(CardFormatter.formatNumber("4242424242424242") == "4242 4242 4242 4242")
        #expect(CardFormatter.formatNumber("42424") == "4242 4")
        #expect(CardFormatter.formatNumber("4242 4242") == "4242 4242")
    }

    @Test func amexGroupsFourSixFive() {
        #expect(CardFormatter.formatNumber("378282246310005") == "3782 822463 10005")
    }

    @Test func numberIsCappedAtBrandLengthAndStripsNonDigits() {
        #expect(CardFormatter.formatNumber("4242 4242 4242 4242 99") == "4242 4242 4242 4242")
        #expect(CardFormatter.formatNumber("37828224631000599") == "3782 822463 10005")
        #expect(CardFormatter.formatNumber("42a4-2") == "4242")
    }

    @Test func expiryGetsSlashAfterMonth() {
        #expect(CardFormatter.formatExpiry("1") == "1")
        #expect(CardFormatter.formatExpiry("12") == "12")
        #expect(CardFormatter.formatExpiry("123") == "12/3")
        #expect(CardFormatter.formatExpiry("1230") == "12/30")
        #expect(CardFormatter.formatExpiry("12/3099") == "12/30")
    }

    @Test func expiryPrefixesZeroForLargeFirstDigit() {
        #expect(CardFormatter.formatExpiry("5") == "05")
        #expect(CardFormatter.formatExpiry("530") == "05/30")
        #expect(CardFormatter.formatExpiry("0") == "0")
    }

    @Test func cvvIsDigitsOnlyAndCappedByBrand() {
        #expect(CardFormatter.formatCvv("12a345", brand: .visa) == "123")
        #expect(CardFormatter.formatCvv("12345", brand: .amex) == "1234")
    }

    @Test func holderNameIsCapped() {
        #expect(CardFormatter.formatHolder(String(repeating: "A", count: 40)).count == CardFormatter.maxHolderLength)
    }
}

// MARK: - Simülasyon ağ geçidi

struct SimulatedPaymentGatewayTests {
    private func makeSUT(delay: Duration = .zero) -> SimulatedPaymentGateway {
        SimulatedPaymentGateway(delay: delay, dateProvider: FixedDateProvider(year: 2030, month: 6), makeReference: { "KC-REF" })
    }

    @Test func succeedsWithReceiptWithoutFullNumber() async throws {
        let receipt = try await makeSUT().pay(amount: 149.9, card: .validVisa)
        #expect(receipt.reference == "KC-REF")
        #expect(receipt.amount == 149.9)
        #expect(receipt.brand == .visa)
        #expect(receipt.last4 == "4242")
    }

    @Test func declinesTheConfiguredTestCard() async {
        await #expect(throws: PaymentError.declined) { try await makeSUT().pay(amount: 10, card: .declined) }
    }

    @Test func declinedTestCardIsLuhnValid() {
        #expect(CardValidator.passesLuhn(PaymentSimulation.declinedCardNumber))
    }

    @Test func respectsCancellation() async {
        let sut = makeSUT(delay: .seconds(30))
        let task = Task { try await sut.pay(amount: 10, card: .validVisa) }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test func randomReferenceHasPrefixAndLength() {
        let reference = SimulatedPaymentGateway.randomReference()
        #expect(reference.hasPrefix(PaymentSimulation.referencePrefix))
        #expect(reference.count == PaymentSimulation.referencePrefix.count + PaymentSimulation.referenceLength)
    }
}

// MARK: - PayUseCase

@MainActor
struct PayUseCaseTests {
    private struct Harness {
        let sut: PayUseCase
        let gateway: StubPaymentGateway
        let cartRepository: FakeCartRepository
        let cards: FakeSavedCardRepository
    }

    private func makeHarness(items: [CartItem] = [.sample(price: 100)]) async -> Harness {
        let gateway = StubPaymentGateway()
        let cartRepository = FakeCartRepository(items: items)
        let cart = CartStore(repository: cartRepository)
        await cart.reload()
        let cards = FakeSavedCardRepository()
        let sut = PayUseCase(validator: .fixed, gateway: gateway, cart: cart, savedCards: SavedCardsStore(repository: cards))
        return Harness(sut: sut, gateway: gateway, cartRepository: cartRepository, cards: cards)
    }

    @Test func successChargesCartTotalAndClearsCart() async throws {
        let h = await makeHarness(items: [.sample(price: 100)])
        _ = try await h.sut(card: .validVisa, saveCard: false)
        #expect(h.gateway.calls.map(\.amount) == [149.9]) // 100 + 20 KDV + 29,90 kargo
        #expect(h.cartRepository.stored.isEmpty)
        #expect(h.sut.cart.items.isEmpty)
    }

    @Test func savesCardSummaryOnlyWhenAsked() async throws {
        let h = await makeHarness()
        _ = try await h.sut(card: .validVisa, saveCard: true)
        let saved = try #require(h.cards.stored.first)
        #expect(saved.brand == .visa)
        #expect(saved.last4 == "4242")
        #expect(saved.expiryMonth == 12)
        #expect(saved.expiryYear == 2032)
        #expect(saved.holderName == "Ada Lovelace")

        let other = await makeHarness()
        _ = try await other.sut(card: .validVisa, saveCard: false)
        #expect(other.cards.stored.isEmpty)
    }

    @Test func declinedKeepsCartAndSavesNothing() async {
        let h = await makeHarness()
        h.gateway.result = .failure(PaymentError.declined)
        await #expect(throws: PaymentError.declined) { try await h.sut(card: .declined, saveCard: true) }
        #expect(h.cartRepository.stored.count == 1)
        #expect(h.cards.stored.isEmpty)
    }

    @Test func invalidCardNeverReachesGateway() async {
        let h = await makeHarness()
        var card = PaymentCard.validVisa
        card.cvv = "1"
        do {
            _ = try await h.sut(card: card, saveCard: true)
            Issue.record("beklenen hata fırlatılmadı")
        } catch let PaymentError.invalidCard(issues) {
            #expect(issues[.cvv] == .cvvInvalid)
        } catch {
            Issue.record("beklenmeyen hata: \(error)")
        }
        #expect(h.gateway.calls.isEmpty)
        #expect(h.cartRepository.stored.count == 1)
        #expect(h.cards.stored.isEmpty)
    }

    @Test func emptyCartIsRejected() async {
        let h = await makeHarness(items: [])
        await #expect(throws: PaymentError.emptyCart) { try await h.sut(card: .validVisa, saveCard: false) }
        #expect(h.gateway.calls.isEmpty)
    }

    @Test func cardSaveFailureDoesNotFailAPaidOrder() async throws {
        let h = await makeHarness()
        h.cards.shouldFail = true
        _ = try await h.sut(card: .validVisa, saveCard: true)
        #expect(h.cartRepository.stored.isEmpty)
    }
}

// MARK: - SwiftData kayıtlı kart deposu

@MainActor
struct SwiftDataSavedCardRepositoryTests {
    private struct Harness {
        let container: ModelContainer
        let sut: SwiftDataSavedCardRepository
        let user: UserBox
    }

    private final class UserBox { var id: UUID?; init(_ id: UUID?) { self.id = id } }

    private func makeHarness(user: UUID? = UUID()) throws -> Harness {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: SavedCardEntity.self, configurations: config)
        let box = UserBox(user)
        return Harness(container: container, sut: SwiftDataSavedCardRepository(context: container.mainContext, userIDProvider: { box.id }), user: box)
    }

    private func summary(last4: String = "4242", month: Int = 12, year: Int = 2032) -> PaymentCardSummary {
        PaymentCardSummary(brand: .visa, last4: last4, holderName: "Ada", expiryMonth: month, expiryYear: year)
    }

    @Test func savesAndListsSummaries() async throws {
        let h = try makeHarness()
        let card = summary()
        try await h.sut.save(card)
        #expect(await h.sut.cards() == [card])
    }

    @Test func sameCardIsNotSavedTwice() async throws {
        let h = try makeHarness()
        try await h.sut.save(summary())
        try await h.sut.save(summary()) // yeni id, aynı kart
        #expect(await h.sut.cards().count == 1)
        try await h.sut.save(summary(last4: "1111"))
        try await h.sut.save(summary(month: 11))
        #expect(await h.sut.cards().count == 3)
    }

    @Test func cardsAreScopedPerUser() async throws {
        let h = try makeHarness()
        try await h.sut.save(summary())
        h.user.id = UUID()
        #expect(await h.sut.cards().isEmpty)
        try await h.sut.save(summary()) // başka kullanıcı aynı kartı kaydedebilir
        #expect(await h.sut.cards().count == 1)
    }

    @Test func deleteRemovesOnlyOwnCard() async throws {
        let h = try makeHarness()
        let mine = summary()
        try await h.sut.save(mine)
        let owner = h.user.id
        h.user.id = UUID()
        try await h.sut.delete(id: mine.id) // başka kullanıcı silemez
        h.user.id = owner
        #expect(await h.sut.cards().count == 1)
        try await h.sut.delete(id: mine.id)
        #expect(await h.sut.cards().isEmpty)
    }

    @Test func noSessionListsNothingAndRefusesSave() async throws {
        let h = try makeHarness(user: nil)
        #expect(await h.sut.cards().isEmpty)
        await #expect(throws: AppError.unknown) { try await h.sut.save(summary()) }
    }

    @Test func entityPersistsOnlySummaryFields() async throws {
        let h = try makeHarness()
        try await h.sut.save(summary())
        let entity = try #require(try h.container.mainContext.fetch(FetchDescriptor<SavedCardEntity>()).first)
        let stored = Set(Mirror(reflecting: entity).children.compactMap(\.label))
        let allowed: Set<String> = ["id", "ownerID", "brandRaw", "last4", "holderName", "expiryMonth", "expiryYear", "addedAt"]
        #expect(stored.isSubset(of: allowed.union(stored.filter { $0.hasPrefix("_") || $0.hasPrefix("$") })))
        #expect(!stored.contains { $0.localizedCaseInsensitiveContains("number") || $0.localizedCaseInsensitiveContains("cvv") })
        #expect(entity.last4.count == 4)
    }
}

@MainActor
struct SavedCardsStoreTests {
    @Test func saveAndDeleteKeepStoreInSync() async throws {
        let store = SavedCardsStore(repository: FakeSavedCardRepository())
        let card = PaymentCardSummary(brand: .visa, last4: "4242", holderName: "Ada", expiryMonth: 1, expiryYear: 2031)
        try await store.save(card)
        #expect(store.cards == [card])
        try await store.delete(id: card.id)
        #expect(store.cards.isEmpty)
    }
}

// MARK: - PaymentViewModel

@MainActor
struct PaymentViewModelTests {
    private struct Harness {
        let sut: PaymentViewModel
        let gateway: StubPaymentGateway
        let cartRepository: FakeCartRepository
        let cards: FakeSavedCardRepository
    }

    private func makeHarness(items: [CartItem] = [.sample(price: 100)]) async -> Harness {
        let gateway = StubPaymentGateway()
        let cartRepository = FakeCartRepository(items: items)
        let cart = CartStore(repository: cartRepository)
        await cart.reload()
        let cards = FakeSavedCardRepository()
        let pay = PayUseCase(validator: .fixed, gateway: gateway, cart: cart, savedCards: SavedCardsStore(repository: cards))
        return Harness(sut: PaymentViewModel(pay: pay, cart: cart), gateway: gateway, cartRepository: cartRepository, cards: cards)
    }

    private func fill(_ sut: PaymentViewModel, card: PaymentCard = .validVisa) {
        sut.send(.numberChanged(card.number))
        sut.send(.holderChanged(card.holderName))
        sut.send(.expiryChanged(card.expiry))
        sut.send(.cvvChanged(card.cvv))
    }

    @Test func formatsWhileTyping() async {
        let h = await makeHarness()
        h.sut.send(.numberChanged("42424242"))
        h.sut.send(.expiryChanged("1232"))
        #expect(h.sut.displayNumber == "4242 4242")
        #expect(h.sut.state.card.expiry == "12/32")
        h.sut.send(.cvvChanged("12ab3456"))
        #expect(h.sut.state.card.cvv == "123")
    }

    @Test func brandChangeTrimsCvv() async {
        let h = await makeHarness()
        h.sut.send(.cvvChanged("1234"))
        #expect(h.sut.state.card.cvv == "123") // henüz marka yok: 3 hane
        h.sut.send(.numberChanged("3782"))
        h.sut.send(.cvvChanged("1234"))
        #expect(h.sut.state.card.cvv == "1234")
        h.sut.send(.numberChanged("4242"))
        #expect(h.sut.state.card.cvv == "123")
    }

    @Test func errorsAppearOnlyAfterFieldIsLeft() async {
        let h = await makeHarness()
        h.sut.send(.numberChanged("4242"))
        #expect(h.sut.errors.isEmpty)
        h.sut.send(.fieldLeft(.number))
        #expect(h.sut.errors[.number] == .numberInvalid)
        #expect(h.sut.errors[.holder] == nil)
        h.sut.send(.numberChanged("4242424242424242"))
        #expect(h.sut.errors[.number] == nil)
    }

    @Test func payWithInvalidFormShowsAllErrorsAndSkipsGateway() async {
        let h = await makeHarness()
        await h.sut.submit()
        #expect(Set(h.sut.errors.keys) == Set(CardField.allCases))
        #expect(h.gateway.calls.isEmpty)
        #expect(h.sut.state.phase == .editing)
    }

    @Test func successStoresReceiptClearsCartAndWipesSensitiveData() async {
        let h = await makeHarness()
        h.gateway.result = .success(PaymentReceipt(reference: "KC-1", amount: 149.9, brand: .visa, last4: "4242", paidAt: .distantPast))
        fill(h.sut)
        await h.sut.submit()
        #expect(h.sut.receipt?.reference == "KC-1")
        #expect(h.cartRepository.stored.isEmpty)
        #expect(h.sut.state.card == .empty)
        #expect(h.sut.displayNumber.isEmpty)
        #expect(h.sut.state.card.cvv.isEmpty)
        #expect(!h.sut.canPay)
    }

    @Test func saveCardOptionPersistsSummaryOnly() async {
        let h = await makeHarness()
        fill(h.sut)
        h.sut.send(.saveCardChanged(true))
        await h.sut.submit()
        #expect(h.cards.stored.map(\.last4) == ["4242"])
    }

    @Test func declinedShowsBannerAndKeepsCart() async {
        let h = await makeHarness()
        h.gateway.result = .failure(PaymentError.declined)
        fill(h.sut, card: .declined)
        await h.sut.submit()
        #expect(h.sut.state.formError == Strings.Payment.declined)
        #expect(h.sut.state.phase == .editing)
        #expect(h.cartRepository.stored.count == 1)
        #expect(h.sut.canPay)
        h.sut.send(.numberChanged("4242"))
        #expect(h.sut.state.formError == nil)
    }

    @Test func doubleTapChargesOnce() async {
        let h = await makeHarness()
        h.gateway.delay = .milliseconds(100)
        fill(h.sut)
        h.sut.startPayment()
        h.sut.startPayment()
        try? await Task.sleep(for: .milliseconds(20))
        #expect(h.sut.isPaying)
        #expect(!h.sut.canPay)
        await h.sut.submit() // paying iken yok sayılır
        try? await Task.sleep(for: .milliseconds(300))
        #expect(h.gateway.calls.count == 1)
        #expect(h.sut.receipt != nil)
    }

    @Test func emptyCartCannotPay() async {
        let h = await makeHarness(items: [])
        fill(h.sut)
        #expect(h.sut.isCartEmpty)
        #expect(!h.sut.canPay)
        await h.sut.submit()
        #expect(h.gateway.calls.isEmpty)
    }

    @Test func leavingWipesSensitiveDataAndCancelsPayment() async {
        let h = await makeHarness()
        h.gateway.delay = .seconds(30)
        fill(h.sut)
        h.sut.startPayment()
        try? await Task.sleep(for: .milliseconds(50))
        h.sut.leave()
        try? await Task.sleep(for: .milliseconds(100))
        #expect(h.sut.state.card == .empty)
        #expect(h.sut.state.phase == .editing)
        #expect(h.cartRepository.stored.count == 1)
    }

    @Test func totalMatchesCartPricing() async {
        let h = await makeHarness(items: [.sample(price: 100)])
        #expect(h.sut.total == 149.9)
    }

    @Test func previewReflectsInputAndMasksRest() async {
        let h = await makeHarness()
        #expect(h.sut.preview.numberText == "•••• •••• •••• ••••")
        #expect(h.sut.preview.holderText == Strings.Payment.holderPlaceholder)
        fill(h.sut)
        let preview = h.sut.preview
        #expect(preview.numberText == "4242 4242 4242 4242")
        #expect(preview.holderText == "ADA LOVELACE")
        #expect(preview.expiryText == "12/32")
        #expect(preview.brandName == Strings.Payment.brandVisa)
        // Erişilebilirlik özeti tam numarayı içermez.
        #expect(!preview.accessibilityText.contains("4242 4242"))
        #expect(preview.accessibilityText.contains("4242"))
    }

    @Test func amexPreviewUsesFourSixFiveMask() async {
        let h = await makeHarness()
        h.sut.send(.numberChanged("37"))
        #expect(h.sut.preview.numberText == "37•• •••••• •••••")
    }
}

// MARK: - Navigasyon

@MainActor
struct PaymentNavigationTests {
    @Test func finishPaymentClearsPathAndSelectsHome() {
        let session = SessionManager(repository: FakeAuthRepository())
        session.signedIn(.sample)
        let sut = MainViewModel(gate: GuestGate(sessionManager: session))
        sut.select(.cart)
        sut.openPayment()
        #expect(sut.path == [.payment])
        sut.finishPayment()
        #expect(sut.path.isEmpty)
        #expect(sut.selectedTab == .home)
    }

    @Test func guestCannotOpenPayment() {
        let session = SessionManager(repository: FakeAuthRepository())
        session.continueAsGuest()
        let gate = GuestGate(sessionManager: session)
        let sut = MainViewModel(gate: gate)
        sut.openPayment()
        #expect(sut.path.isEmpty)
        #expect(gate.isSheetPresented)
    }
}
