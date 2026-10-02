import Testing
@testable import KitapCepte

struct AppErrorTests {
    @Test func validationErrorCarriesItsReason() {
        #expect(AppError.validation("Geçersiz").message == "Geçersiz")
    }

    @Test func everyCaseHasNonEmptyMessage() {
        let errors: [AppError] = [.network, .decoding, .notFound, .unknown]
        #expect(errors.allSatisfy { !$0.message.isEmpty })
    }
}
