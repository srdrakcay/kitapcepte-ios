enum CartMapper {
    static func item(from entity: CartItemEntity) -> CartItem {
        CartItem(
            bookID: entity.bookID, title: entity.title, authors: entity.authors, coverID: entity.coverID,
            unitPrice: entity.unitPrice, quantity: entity.quantity
        )
    }
}
