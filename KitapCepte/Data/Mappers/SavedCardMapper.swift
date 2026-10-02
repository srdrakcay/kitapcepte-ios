enum SavedCardMapper {
    static func summary(from entity: SavedCardEntity) -> PaymentCardSummary {
        PaymentCardSummary(
            id: entity.id,
            brand: CardBrand(rawValue: entity.brandRaw) ?? .unknown,
            last4: entity.last4,
            holderName: entity.holderName,
            expiryMonth: entity.expiryMonth,
            expiryYear: entity.expiryYear
        )
    }
}
