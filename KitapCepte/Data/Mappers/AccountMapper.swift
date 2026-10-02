enum AccountMapper {
    static func user(from entity: AccountEntity) -> User {
        User(id: entity.id, name: entity.name, email: entity.email)
    }
}
