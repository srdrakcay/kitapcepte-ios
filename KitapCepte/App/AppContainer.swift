import Foundation

/// Bağımlılıkların oluşturulduğu tek yer (constructor injection). Sonraki fazlarda repository/use case'ler eklenir.
struct AppContainer {
    let theme: AppTheme
    let userDefaults: UserDefaults

    static func live() -> AppContainer {
        AppContainer(theme: .standard, userDefaults: .standard)
    }
}
