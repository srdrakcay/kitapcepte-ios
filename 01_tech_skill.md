# TECH SKILL — Kitap Cepte (Swift / iOS)

## Platform kararı
- Native **iOS uygulaması**, dil: **Swift 6** (strict concurrency açık), UI: **SwiftUI**.
- **Tek Xcode target** (`KitapCepte`) + test target'ları. SPM ile local modül/paket ayrımı YOK; katmanlar klasör/grup ile ayrılır.
- Minimum iOS: **17.0** (Observation, SwiftData için). Onayına açık soru.
- Proje oluşturma: Xcode projesi (`.xcodeproj`), bağımlılıklar yalnızca **Swift Package Manager**.

## Teknoloji yığını
| Alan | Seçim | Not |
|---|---|---|
| UI | SwiftUI | `NavigationStack`, `TabView`, `LazyVGrid`, `.sheet` / `presentationDetents` |
| State | **Observation** (`@Observable`) | ViewModel'ler `@MainActor @Observable final class` |
| MVVM / UDF | ViewModel + `State` struct + `Action` enum | Tek yönlü veri akışı |
| Asenkron | Swift Concurrency (`async/await`, `Task`, `AsyncStream`, actor) | Combine kullanılmaz (gerekmedikçe) |
| Network | `URLSession` + `async/await` + `Codable` | Üçüncü parti ağ kütüphanesi yok |
| Görsel yükleme | **Nuke / NukeUI** (SPM) | Kapak görselleri, disk/bellek cache |
| Yerel veri | **SwiftData** (favoriler, sepet, kayıtlı kart özeti) | Protocol arkasında soyutlanır (test için in-memory) |
| Güvenli saklama | **Keychain** (oturum token'ı, şifre hash'i) | Basit `KeychainStore` wrapper |
| Basit ayarlar | `UserDefaults` / `@AppStorage` | Onboarding görüldü bilgisi |
| DI | Constructor injection + hafif `AppContainer` | Üçüncü parti DI yok |
| Lokalizasyon | String Catalog (`Localizable.xcstrings`) | Tüm metinler buradan |
| Test | **Swift Testing** (`@Test`, `#expect`) + XCTest (UI testleri) | Mock kütüphanesi yok → protocol + Fake/Stub, `URLProtocol` stub |
| Lint/format | SwiftLint + SwiftFormat | Build phase'de çalışır |
| Build/CI | `xcodebuild` | Faz sonu derleme komutu: aşağıda |

## Faz sonu derleme/test komutları
```
xcodebuild -scheme KitapCepte -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -scheme KitapCepte -destination 'platform=iOS Simulator,name=iPhone 16' test
```
(Simülatör adı makineye göre ayarlanır.)

## Kurallar
- Her SPM bağımlılığı eklenmeden önce gerekçelendirilir ve onaya sunulur.
- Force unwrap (`!`), `try!`, `as!` yasak. Singleton'dan kaçın (DI kullan).
- Tüm async kod `Sendable`/actor izolasyonuna uygun; UI güncellemeleri `@MainActor`.
