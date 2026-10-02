import Foundation
import SwiftData

/// Kayıtlı kart: YALNIZCA özet alanlar. Tam numara ve CVV için alan yoktur (bilinçli).
@Model
final class SavedCardEntity {
    var id: UUID
    var ownerID: UUID
    var brandRaw: String
    var last4: String
    var holderName: String
    var expiryMonth: Int
    var expiryYear: Int
    var addedAt: Date

    init(ownerID: UUID, summary: PaymentCardSummary, addedAt: Date = .now) {
        self.id = summary.id
        self.ownerID = ownerID
        self.brandRaw = summary.brand.rawValue
        self.last4 = summary.last4
        self.holderName = summary.holderName
        self.expiryMonth = summary.expiryMonth
        self.expiryYear = summary.expiryYear
        self.addedAt = addedAt
    }
}
