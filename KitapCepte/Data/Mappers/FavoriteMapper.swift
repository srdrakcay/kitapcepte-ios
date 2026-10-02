enum FavoriteMapper {
    /// `authorKeys`/`subject` anlık görüntüde saklanmaz; boş/nil kalır.
    static func book(from entity: FavoriteEntity) -> Book {
        Book(
            id: entity.bookID, title: entity.title, authors: entity.authors, coverID: entity.coverID,
            firstPublishYear: entity.firstPublishYear, price: entity.price, isTopItem: entity.isTopItem
        )
    }
}
