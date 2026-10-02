# ARCHITECTURE SKILL — Kitap Cepte (Swift / iOS)

## Yaklaşım
**Tek target, MVVM + Clean Architecture + UDF.** Modüler yapı yok; katman sınırları klasörlerle ve bağımlılık kuralıyla korunur.

## Klasör yapısı (`KitapCepte/`)
```
App/              -> KitapCepteApp.swift, AppContainer (DI), RootView
Core/
  DesignSystem/
    Theme/        -> AppColors, AppTypography, AppDimens, AppShapes, AppTheme (Environment)
    Components/   -> ortak UI bileşenleri
  Network/        -> APIClient, Endpoint, NetworkError
  Navigation/     -> Route enum'ları, Router
  Common/         -> Extension'lar, yardımcılar, Loadable<T>
Domain/
  Models/         -> Book, CartItem, User, PaymentCardSummary …
  Repositories/   -> protocol'ler
  UseCases/       -> tek sorumluluklu use case'ler (GetBooksUseCase, ToggleFavoriteUseCase …)
Data/
  Remote/         -> OpenLibraryService, DTO (…DTO: Codable)
  Local/          -> SwiftData @Model'ler, KeychainStore
  Repositories/   -> *RepositoryImpl
  Mappers/        -> DTO/Entity <-> Domain
Features/
  Onboarding/ Auth/ Home/ Detail/ Favorites/ Cart/ Payment/ Profile/
    -> XxxView.swift, XxxViewModel.swift, (XxxState / XxxAction)
Resources/        -> Assets, Localizable.xcstrings, Fonts
Tests/
```

## Bağımlılık kuralı
`Features → Domain ← Data`. `Domain` SwiftUI, SwiftData, URLSession bilmez (saf Swift). `Features`, `Data`'yı doğrudan import etmez; protocol üzerinden konuşur.

## MVVM / UDF
- `@MainActor @Observable final class XxxViewModel` → `private(set) var state: XxxState`, `func send(_ action: XxxAction)`.
- View **stateless'a yakın** yazılır: işi ViewModel'e delege eder, iş mantığı içermez.
- Tek seferlik olaylar (navigasyon, toast, login gerekli): state içinde optional `event` veya Router/closure üzerinden.
- Liste/ekran durumu: `enum Loadable<T> { idle, loading, loaded(T), failed(AppError) }`.

## Navigasyon
- `TabView` (Home, Favoriler, Sepet, Profil) + her sekmede `NavigationStack(path:)`, **type-safe** `Hashable` route enum'ları.
- Auth/Onboarding akışı RootView'da `SessionManager` durumuna göre değişir.

## Misafir (Guest) akışı
- `SessionManager` (domain protocol): `enum Session { loggedIn(User), guest, none }`.
- Kısıtlı aksiyon tek yerde kontrol edilir (`GuestGate`) → ortak `LoginRequiredSheet` gösterilir.
- Misafir kısıtları: Detay, Favoriler, Profil, Sepet/Ödeme.

## Hata yönetimi
- Repository `async throws`; hatalar `AppError` (`network`, `decoding`, `notFound`, `validation`, `unknown`) tipine map edilir.
- Her ekranda loading / error (retry) / empty durumu.

## Test edilebilirlik
- Use case, ViewModel ve repository protocol arkasından enjekte edilir; testlerde Fake/Stub kullanılır.
- Zaman, UUID, rastgelelik protocol ile soyutlanır.
- Ağ testleri `URLProtocol` stub'ı ile; SwiftData testleri in-memory container ile.
- Hedef: Domain + ViewModel + Mapper + Repository katmanlarında %80+ kapsam.
